import 'dart:async';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:afkham/models/assistance.dart';
import 'package:afkham/models/coordinate.dart';
import 'package:afkham/models/leaving.dart';
import 'package:afkham/services/save_leave_request_service.dart';
import 'package:afkham/services/save_mission_request_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:shamsi_date/shamsi_date.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/loan.dart';
import '../models/mission.dart';
import '../models/rollcal.dart';
import '../services/loan_service.dart';
import '../services/save_assistance_service.dart';
import '../utils/custom_notification.dart';
import '../widgets/app_drawer.dart';
import '../utils/custom_color.dart';
import '../services/auth_service.dart';
import '../services/action_service.dart';
import '../services/home_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart' as intl;
import 'package:timezone/data/latest.dart' as tz;

import 'gr.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personnel List App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService authService = AuthService('https://afkhambpms.ir/api1');
  final HomeService homeService = HomeService('https://afkhambpms.ir/api1');
  final ActionService actionService =
      ActionService('https://afkhambpms.ir/api1');
  late QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool isSyncing = false;
  bool isLoading = true;
  late double distance;
  bool _isInRange = false;
  bool isConnected = true;
  bool _requestAllowed = false;
  Box<Coordinate>? coordinateBox;
  Box<Rollcal>? rollcalBox;
  Box<Loan>? loanBox;
  Box<Mission>? missionBox;
  Box<Leaving>? leavingBox;
  Box<Assistance>? assistanceBox;

  late double latitude;
  late double longitude;
  List<Rollcal>? results;
  List<Leaving>? leavingResults;
  List<Loan>? loanResults;
  List<Mission>? missionResults;
  List<Assistance>? assistanceResults;
  List<dynamic> targetLatitudes = [];
  List<dynamic> targetLongitudes = [];
  late double distanceThreshold;
  late Timer _timer;

  late String availableAction;
  late String requestDate;
  late String lastActionType = '';
  late String lastActionDescription = '';

  List<dynamic> personnelList = [];

  @override
  void initState() {
    super.initState();
    initBox();
    tz.initializeTimeZones();
    loadLastState();
    sync();
    fetchCoordinates(context);
    _startLocationTracking();
    _timer =Timer.periodic(Duration(seconds: 10), (timer) {
      _startLocationTracking();
    });
  }

  @override
  void dispose() {
   super.dispose();
   _timer.cancel();//cancel the timer here
  }

  Future<void> _startLocationTracking() async {
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      double latitude = currentPosition.latitude;
      double longitude = currentPosition.longitude;

      bool isInPosition = false;

      for (int i = 0; i < targetLatitudes.length; i++) {
          double distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            targetLatitudes[i],
            targetLongitudes[i],
          );
          print(targetLatitudes[i].runtimeType);
          if (distance < distanceThreshold) {
            isInPosition = true;
            break;
          }
      }
      if (mounted) {
        setState(() {
          _isInRange = isInPosition;
          _requestAllowed = isInPosition;
        });
      }
      simple();
    } catch (e) {
      CustomNotification.show(context, 'خطا',
          'مشکلی وجود دارد.', '');
      print(e.toString());
      if (mounted) {
        setState(() {
          _isInRange = false;
          _requestAllowed = false;
        });
      }
      simple();
    }
  }

  Widget simple() {
    return _isInRange
        ? lastActionType == 'arrival'
            ? Padding(
                padding: EdgeInsets.only(bottom: 8, left: 8, right: 8),
                child: Card(
                  color: CustomColor.cardColor,
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                              text: TextSpan(
                            children: <TextSpan>[
                              TextSpan(
                                  text: 'وضعیت : ',
                                  style: TextStyle(
                                      fontFamily: 'irs',
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.bold,
                                      color: CustomColor.textColor)),
                              TextSpan(
                                  text: 'در حال کار',
                                  style: TextStyle(
                                      fontFamily: 'irs',
                                      fontSize: 12.0,
                                      color: CustomColor.textColor)),
                            ],
                          )),
                          Spacer(),
                        ],
                      ),
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red,
                              width: 1.0,
                            ),
                          ),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.yellow,
                                width: 1.0,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                submitExitAction();
                              },
                              child: Text('خروج'),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.red,
                                onPrimary: Colors.white,
                                shape: OvalBorder(
                                    side: BorderSide.none, eccentricity: 0.07),
                                padding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              )
            : Padding(
                padding: EdgeInsets.all(8),
                child: Card(
                  color: CustomColor.cardColor,
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(children: [
                      Row(
                        children: [
                          RichText(
                              text: TextSpan(children: <TextSpan>[
                            TextSpan(
                                text: 'وضعیت : ',
                                style: TextStyle(
                                    fontFamily: 'irs',
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                    color: CustomColor.textColor)),
                            TextSpan(
                                text: 'حاضر در محل کار',
                                style: TextStyle(
                                    fontFamily: 'irs',
                                    fontSize: 12.0,
                                    color: CustomColor.textColor)),
                          ])),
                          Spacer(),
                        ],
                      ),
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green,
                              width: 1.0,
                            ),
                          ),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.yellow,
                                width: 1.0,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                submitArrivalAction();
                              },
                              child: Text('ورود'),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.green,
                                onPrimary: Colors.white,
                                shape: OvalBorder(
                                    side: BorderSide.none, eccentricity: 0.07),
                                padding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              )
        : Expanded(
            child: Center(
              child: Text('در محل کار حضور ندارید!'),
            ),
          );
  }

  Future<void> loadLastState() async {
    var savedValue = await actionService.getLastActionInfo();
    setState(() {
      distanceThreshold = double.parse(savedValue['distance']);
      lastActionType = savedValue['type'];
      lastActionDescription = savedValue['description'];
    });
    print(distanceThreshold);
    print(lastActionType);
    print(lastActionDescription);
  }

  Future<void> initBox() async {
    coordinateBox = await Hive.openBox('coordinateBox');
    rollcalBox = await Hive.openBox('rollcalBox');
    loanBox = await Hive.openBox('loanBox');
    assistanceBox = await Hive.openBox('assistanceBox');
    leavingBox = await Hive.openBox('leavingBox');
    missionBox = await Hive.openBox('missionBox');
    results =
        await rollcalBox?.values.where((data) => data.synced == false).toList();
    leavingResults =
        await leavingBox?.values.where((data) => data.synced == false).toList();
    loanResults =
        await loanBox?.values.where((data) => data.synced == false).toList();
    missionResults =
        await missionBox?.values.where((data) => data.synced == false).toList();
    assistanceResults = await assistanceBox?.values
        .where((data) => data.synced == false)
        .toList();
  }

  Future<void> sync() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      setState(() {
        isSyncing = true;
      });
      rollcalBox = await Hive.openBox('rollcalBox');
      results = await rollcalBox?.values
          .where((data) => data.synced == false)
          .toList();
      ActionService actionService = ActionService('https://afkhambpms.ir/api1');

      if (results!.isNotEmpty) {
        for (var result in results!) {
          try {
            final actionResponse = await actionService.updateManual(
              result.jalali_date,
              result.time,
              result.type,
              result.status,
              result.description??'',
            );

            if (actionResponse['status'] == 'successful') {
              Rollcal rollcal = Rollcal(
                status: result.status,
                jalali_date: result.jalali_date,
                time: result.time,
                type: result.type,
                synced: true,
                description: result.description,
              );
              rollcalBox?.put(result.key, rollcal);
              print('1');
              print('synced');
              print('1');
            }
          } catch (e) {
            CustomNotification.show(context, 'ناموفق',
                'در به روز رسانی اطلاعات مشکلی وجود دارد.', '');
          }
        }
      }

      setState(() {
        isSyncing = false;
      });
      print(isSyncing);
    }
    if (connectivityResult != ConnectivityResult.none) {
      const LoanApiUrl = 'https://afkhambpms.ir/api1/personnels/save-loan';
      LoanService loanService = LoanService(LoanApiUrl);
      loanBox = await Hive.openBox('loanBox');
      loanResults =
          await loanBox?.values.where((data) => data.synced == false).toList();
      if (loanResults!.isNotEmpty) {
        for (var result in loanResults!) {
          try {
            final response = await loanService.save(
              result.jalali_request_date,
              result.suggested_value,
              result.suggested_repayment_count??'',
              result.description,
            );
            if (response['status'] == 'successful') {
              Loan loan = Loan(
                jalali_request_date: result.jalali_request_date,
                suggested_value: result.suggested_value,
                level: response['loan']['level'],
                status: response['loan']['level'],
                formatted_repayment_value: result.formatted_repayment_value,
                suggested_repayment_count: result.suggested_repayment_count,
                repayment_count: result.repayment_count,
                description: result.description,
                synced: true,
              );
              loanBox?.put(result.key, loan);
              print('1');
              print('synced');
              print('1');
            }
          } catch (e) {
            CustomNotification.show(context, 'ناموفق',
                'در به روز رسانی اطلاعات مشکلی وجود دارد.', '');
          }
        }
      }

      const missionApiUrl =
          'https://afkhambpms.ir/api1/personnels/save_mission_request';
      SaveMissionRequestService saveMissionRequestService =
          SaveMissionRequestService(missionApiUrl);
      missionBox = await Hive.openBox('missionBox');
      missionResults = await missionBox?.values
          .where((data) => data.synced == false)
          .toList();
      if (missionResults!.isNotEmpty) {
        for (var result in missionResults!) {
          try {
            var type = '';
            switch (result.type) {
              case 'روزانه':
                type = 'daily';
                break;
              case 'ساعتی':
                type = 'hourly';
                break;
              default:
                type = 'choose_type';
            }
            final response = await saveMissionRequestService.saveMissionRequest(
              result.jalali_request_date,
              result.start,
              result.end,
              result.start,
              result.end,
              result.origin,
              result.destination,
              result.reason,
              type,
            );
            if (response['status'] == 'successful') {
              Mission mission = Mission(
                jalali_request_date: result.jalali_request_date,
                type: result.type,
                level: response['loan']['level'],
                status: response['loan']['level'],
                start: result.start,
                end: result.end,
                origin: result.origin,
                destination: result.destination,
                reason: result.reason,
                description: null,
                synced: true,
              );
              missionBox?.put(result.key, mission);
              print('1');
              print('synced');
              print('1');
            }
          } catch (e) {
            CustomNotification.show(context, 'ناموفق',
                'در به روز رسانی اطلاعات مشکلی وجود دارد.', '');
          }
        }
      }

      const leavingApiUrl =
          'https://afkhambpms.ir/api1/personnels/save_leaving_request';
      SaveLeaveRequestService saveLeaveRequestService =
          SaveLeaveRequestService(leavingApiUrl);
      leavingBox = await Hive.openBox('leavingBox');
      leavingResults = await leavingBox?.values
          .where((data) => data.synced == false)
          .toList();
      if (leavingResults!.isNotEmpty) {
        for (var result in leavingResults!) {
          try {
            var period = '';
            switch (result.period) {
              case 'روزانه':
                period = 'daily';
                break;
              case 'ساعتی':
                period = 'hourly';
                break;
              default:
                period = 'choose_type';
            }
            var type = '';
            switch (result.type) {
              case 'استحقاقی':
                type = 'deserved';
                break;
              case 'استعلاجی':
                type = 'sickness';
                break;
              case 'بدون حقوق':
                type = 'without_salary';
                break;
              default:
                type = 'choose_type';
            }
            final response = await saveLeaveRequestService.saveLeaveRequest(
              result.jalali_request_date,
              result.start,
              result.end,
              result.start,
              result.end,
              result.reason,
              period,
              type,
            );
            if (response['status'] == 'successful') {
              Leaving leaving = Leaving(
                jalali_request_date: result.jalali_request_date,
                period: result.period,
                status: response['leaving']['status'],
                level: response['leaving']['level'],
                type: result.type,
                start: result.start,
                end: result.end,
                reason: result.reason,
                description: result.description,
                synced: true,
              );
              leavingBox?.put(result.key, leaving);
              print('1');
              print('synced');
              print('1');
            }
          } catch (e) {
            CustomNotification.show(context, 'ناموفق',
                'در به روز رسانی اطلاعات مشکلی وجود دارد.', '');
          }
        }
      }

      const assistanceApiUrl =
          'https://afkhambpms.ir/api1/personnels/save-assistance';
      SaveAssistanceService saveAssistanceService =
          SaveAssistanceService(assistanceApiUrl);
      assistanceBox = await Hive.openBox('assistanceBox');
      assistanceResults = await assistanceBox?.values
          .where((data) => data.synced == false)
          .toList();
      if (assistanceResults!.isNotEmpty) {
        for (var result in assistanceResults!) {
          try {
            final response = await saveAssistanceService.saveAssistance(
              result.record_date,
              result.price,
            );
            if (response['status'] == 'successful') {
              Assistance assistance = Assistance(
                level: response['assistance']['level'],
                price: result.price,
                payment_period: response['assistance']['payment_period'],
                record_date: result.record_date,
                deposit_date: null,
                payment_date: null,
                synced: true,
              );
              assistanceBox?.put(result.key, assistance);
              print('1');
              print('synced');
              print('1');
            } else if (response['status'] == 'existed') {
              await assistanceBox?.delete(result.key);
            }
          } catch (e) {
            CustomNotification.show(context, 'ناموفق',
                'در به روز رسانی اطلاعات مشکلی وجود دارد.', '');
          }
        }
      }
    }
  }

/*  Future<void> connectionChecker() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        isConnected = false;
      });
    } else {
      setState(() {
        isConnected = true;
      });
    }
  }*/
  getCurrentTime() {
    final String preferredTimeZone = 'Asia/Tehran';
    final now = tz.TZDateTime.now(tz.getLocation(preferredTimeZone));
    final formatter = intl.DateFormat('HH:mm:ss');
    return formatter.format(now);
  }

  void submitArrivalAction() async {
    setState(() {
      isLoading = true;
    });
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        isConnected = false;
      });
    } else {
      setState(() {
        isConnected = true;
      });
    }
    if (isConnected) {
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      DateTime dt = DateTime.now();
      Jalali j = dt.toJalali();
      final f = j.formatter;
      requestDate = '${f.yyyy}/${f.mm}/${f.dd}';

      for (int i = 0; i < targetLatitudes.length; i++) {
        if (!_requestAllowed) {
          distance = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            targetLatitudes[i],
            targetLongitudes[i],
          );
          if (distance < distanceThreshold) {
            setState(() {
              _requestAllowed = true;
            });
          }
        }
      }
      if (_requestAllowed) {
        var time = getCurrentTime();

        if (!isSyncing) {
          try {
            final rollcalBox = Hive.box<Rollcal>('rollcalBox');
            int id = rollcalBox.length;
            final actionResponse = await actionService.updateManual(
              requestDate,
              getCurrentTime(),
              'systemic',
              'arrival',
              '',
            );

            if (actionResponse['status'] == 'successful') {
              Rollcal rollcal = Rollcal(
                status: 'arrival',
                jalali_date: requestDate,
                time: time,
                type: 'systemic',
                synced: true,
                description: '',
              );
              rollcalBox.add(rollcal);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('last_action_description', ' ورود ' + time);
              await prefs.setString('last_action_type', 'arrival');
              setState(() {
                lastActionType = 'arrival';
                lastActionDescription = ' ورود ' + time;
              });
            }
          } catch (e) {
            CustomNotification.show(
                context, 'ناموفق', 'در ثبت اطلاعات مشکلی وجود دارد.', '');
          }
        } else {
          final rollcalBox = Hive.box<Rollcal>('rollcalBox');
          int id = rollcalBox.length;
          Rollcal rollcal = Rollcal(
              status: 'arrival',
              jalali_date: requestDate,
              time: time,
              type: 'systemic',
              synced: false,
              description: '');
          rollcalBox.add(rollcal);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_action_description', ' ورود ' + time);
          await prefs.setString('last_action_type', 'arrival');
          setState(() {
            lastActionType = 'arrival';
            lastActionDescription = ' ورود ' + time;
          });
        }
      } else {
        CustomNotification.show(
            context, 'خطا', 'شما در محدوده ی تعیین شده حضور ندارید.', '');
      }
      setState(() {
        isLoading = false;
      });
    } else {
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      print(currentPosition.longitude.runtimeType);
      DateTime dt = DateTime.now();
      Jalali j = dt.toJalali();
      final f = j.formatter;
      requestDate = '${f.yyyy}/${f.mm}/${f.dd}';

      for (int i = 0; i < targetLatitudes.length; i++) {
        if (!_requestAllowed) {
          distance = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            targetLatitudes[i],
            targetLongitudes[i],
          );
          if (distance < distanceThreshold) {
            setState(() {
              _requestAllowed = true;
            });
          }
        }
      }
      if (_requestAllowed) {
        final box = Hive.box<Rollcal>('rollcalBox');
        int id = box.length;
        var time = getCurrentTime();
        Rollcal rollcal = Rollcal(
            status: 'arrival',
            jalali_date: requestDate,
            time: time,
            type: 'systemic',
            synced: false,
            description: '');
        box.add(rollcal);
        print(box.length);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_action_description', ' ورود ' + time);
        await prefs.setString('last_action_type', 'arrival');
        setState(() {
          lastActionType = 'arrival';
          lastActionDescription = ' ورود ' + time;
        });
      } else {
        CustomNotification.show(
            context, 'خطا', 'شما در محدوده ی تعیین شده حضور ندارید.', '');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  void submitExitAction() async {
    setState(() {
      isLoading = true;
    });

    Position currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    DateTime dt = DateTime.now();
    Jalali j = dt.toJalali();
    final f = j.formatter;
    requestDate = '${f.yyyy}/${f.mm}/${f.dd}';
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        isConnected = false;
      });
    } else {
      setState(() {
        isConnected = true;
      });
    }
    if (isConnected) {
      //ActionService actionService = ActionService('https://afkhambpms.ir/api1');
      for (int i = 0; i < targetLatitudes.length; i++) {
        print(targetLatitudes[i]);
        if (!_requestAllowed) {
          distance = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            targetLatitudes[i],
            targetLongitudes[i],
          );
          if (distance < distanceThreshold) {
            setState(() {
              _requestAllowed = true;
            });
          }
        }
      }
      if (_requestAllowed) {
        var time = getCurrentTime();
        if (!isSyncing) {
          try {
            final rollcalBox = Hive.box<Rollcal>('rollcalBox');
            int id = rollcalBox.length;
            final actionResponse = await actionService.updateManual(
              requestDate,
              getCurrentTime(),
              'systemic',
              'exit',
              '',
            );

            if (actionResponse['status'] == 'successful') {
              Rollcal rollcal = Rollcal(
                status: 'exit',
                jalali_date: requestDate,
                time: time,
                type: 'systemic',
                synced: true,
                description: '',
              );
              rollcalBox.add(rollcal);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('last_action_description', ' خروج ' + time);
              await prefs.setString('last_action_type', 'exit');
              setState(() {
                lastActionType = 'exit';
                lastActionDescription = ' خروج ' + time;
              });
            }
          } catch (e) {
            CustomNotification.show(
                context, 'ناموفق', 'در ثبت اطلاعات مشکلی وجود دارد.', '');
          }
        } else {
          final rollcalBox = Hive.box<Rollcal>('rollcalBox');
          int id = rollcalBox.length;
          Rollcal rollcal = Rollcal(
              status: 'exit',
              jalali_date: requestDate,
              time: time,
              type: 'systemic',
              synced: false,
              description: '');
          rollcalBox.add(rollcal);
          print(rollcalBox.length);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_action_description', ' خروج ' + time);
          await prefs.setString('last_action_type', 'exit');
          setState(() {
            lastActionType = 'exit';
            lastActionDescription = ' خروج ' + time;
          });
        }
      } else {
        CustomNotification.show(
            context, 'خطا', 'شما در محدوده ی تعیین شده حضور ندارید.', '');
      }
      setState(() {
        isLoading = false;
      });
    } else {
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      print(currentPosition.longitude.runtimeType);
      DateTime dt = DateTime.now();
      Jalali j = dt.toJalali();
      final f = j.formatter;
      requestDate = '${f.yyyy}/${f.mm}/${f.dd}';

      for (int i = 0; i < targetLatitudes.length; i++) {
        if (!_requestAllowed) {
          distance = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            targetLatitudes[i],
            targetLongitudes[i],
          );
          if (distance < distanceThreshold) {
            setState(() {
              _requestAllowed = true;
            });
          }
        }
      }
      if (_requestAllowed) {
        var time = getCurrentTime();

        final box = Hive.box<Rollcal>('rollcalBox');
        int id = box.length;
        Rollcal rollcal = Rollcal(
            status: 'exit',
            jalali_date: requestDate,
            time: getCurrentTime(),
            type: 'systemic',
            synced: false,
            description: '');
        box.add(rollcal);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_action_description', ' خروج ' + time);
        await prefs.setString('last_action_type', 'exit');
        setState(() {
          lastActionType = 'exit';
          lastActionDescription = ' خروج ' + time;
        });
      } else {
        CustomNotification.show(
            context, 'خطا', 'شما در محدوده ی تعیین شده حضور ندارید.', '');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchCoordinates(BuildContext context) async {
    print(isSyncing);
    print('sync');
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        isConnected = false;
      });
    } else {
      setState(() {
        isConnected = true;
      });
    }

    if (isConnected) {
      print(isConnected);
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
        });
      } catch (e) {
        print('Error: $e');
      }
      final AuthService authService = AuthService('https://afkhambpms.ir/api1');
      final token = await authService.getToken();
      //fetchActionInfo();

      final response = await http
          .get(Uri.parse('https://afkhambpms.ir/api1/get-points'), headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      });

      if (response.statusCode == 200) {
        var res = json.decode(response.body);

        //final prefs = await SharedPreferences.getInstance();
        //await prefs.setString('threshold_distance', res['distance']);
        print(res['latitudes']);
        var tla = [];
        var tlo = [];
        for (var item in res['latitudes']) {
          tla.add(double.parse(item));
        }
        for (var item1 in res['longitudes']) {
          tlo.add(double.parse(item1));
        }
        setState(() {
          targetLatitudes = tla;
          targetLongitudes = tlo;
          //distanceThreshold = double.parse(res['distance']);
          //lastActionType = res['last_action_type'] ?? "";
          // lastActionDescription = res['last_action_description'] ?? "";
        });

        actionService.saveLastActionDescription(res['last_action_description']);
        actionService.saveLastActionType(res['last_action_type']);
        actionService.saveThresholdDistance(res['distance']);

        for (int i = 0; i < targetLatitudes.length; i++) {
          if (!_isInRange) {
            distance = Geolocator.distanceBetween(
              latitude,
              longitude,
              targetLatitudes[i],
              targetLongitudes[i],
            );
            if (distance < distanceThreshold) {
              setState(() {
                _isInRange = true;
              });
            }
          }
        }
        coordinateBox = await Hive.openBox('coordinateBox');

        final box = Hive.box<Coordinate>('coordinateBox');
        await box.clear();

        int id = box.length;

        for (int i = 0; i < targetLatitudes.length; i++) {
          Coordinate coordinate = Coordinate(
            id: id,
            latitude: targetLatitudes[i],
            longitude:targetLongitudes[i],
          );
          box.add(coordinate);
          print('box.length');
          print(box.length);
        }

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('خطا در دریافت داده ها');
      }
    } else {
      print('no-internet');
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
        });
      } catch (e) {
        print('Error: $e');
      }
      var distanceThreshold1 = await actionService.getThresholdDistance();
      var lastActionType1 = await actionService.getLastActionType();
      var lastActionDescription1 =
          await actionService.getLastActionDescription();
      setState(() {
        distanceThreshold = distanceThreshold1;
        lastActionType = lastActionType1;
        lastActionDescription = lastActionDescription1;
      });
      coordinateBox = await Hive.openBox('coordinateBox');

      final box = Hive.box<Coordinate>('coordinateBox');
      var tla = [];
      var tlo = [];
      for (var item in box.values) {
        tla.add(item.latitude);
        tlo.add(item.longitude);
      }
      setState(() {
        targetLatitudes = tla;
        targetLongitudes = tlo;
      });
      //print(targetLatitudes);
      //print(targetLongitudes);
      for (int i = 0; i < targetLatitudes.length; i++) {
        if (!_isInRange) {
          distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            targetLatitudes[i],
            targetLongitudes[i],
          );
          print(distanceThreshold);
          if (distance < distanceThreshold) {
            setState(() {
              _isInRange = true;
            });
          }
        }
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  void _logout(BuildContext context) async {
    await authService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: CustomColor.drawerBackgroundColor),
          title: Text('خانه', style: TextStyle(color: CustomColor.textColor)),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
          ],
        ),
        drawer: AppDrawer(),
        body: isLoading
            ? Center(
          child: CircularProgressIndicator(),
        )
            : Column(
          /*
          * */
            children: [
              Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 8, left: 8, top: 8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Card(
                              color: CustomColor.cardColor,
                              elevation: 2,
                              margin: EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Column(children: [
                                    Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                            text:
                                            TextSpan(children: <TextSpan>[
                                              TextSpan(
                                                text: ' آخرین رویداد : ',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: 'irs',
                                                    fontWeight: FontWeight.bold,
                                                    color: CustomColor.textColor),
                                              ),
                                              TextSpan(
                                                text: '${lastActionDescription}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: 'irs',
                                                    color: CustomColor.textColor),
                                              ),
                                            ])),
                                        Spacer(),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pushReplacementNamed(
                                                context, '/loc');
                                          },
                                          child: Text('مشاهده'),
                                          style: ElevatedButton.styleFrom(
                                            primary: Colors.teal,
                                            // Background color of the button
                                            onPrimary: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(10.0),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 20),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ]))),
                        ]),
                  )),
              (_isInRange)
                  ? (lastActionType == 'arrival')
                  ? Padding(
                  padding: EdgeInsets.only(
                      bottom: 8, left: 8, right: 8),
                  child: Card(
                      color: CustomColor.cardColor,
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(children: [
                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                RichText(
                                    text: TextSpan(
                                        children: <TextSpan>[
                                          TextSpan(
                                              text: 'وضعیت : ',
                                              style: TextStyle(
                                                  fontFamily: 'irs',
                                                  fontSize: 12.0,
                                                  fontWeight:
                                                  FontWeight.bold,
                                                  color: CustomColor
                                                      .textColor)),
                                          TextSpan(
                                              text: 'در حال کار',
                                              style: TextStyle(
                                                  fontFamily: 'irs',
                                                  fontSize: 12.0,
                                                  color: CustomColor
                                                      .textColor)),
                                        ])),
                                Spacer(),
                              ],
                            ),
                            Center(
                                child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.red,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.yellow,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          submitExitAction();
                                        },
                                        child: Text('خروج'),
                                        style: ElevatedButton
                                            .styleFrom(
                                          primary: Colors.red,
                                          onPrimary: Colors.white,
                                          shape: OvalBorder(
                                              side:
                                              BorderSide.none,
                                              eccentricity: 0.07),
                                          padding: EdgeInsets
                                              .symmetric(
                                              vertical: 10,
                                              horizontal: 20),
                                        ),
                                      ),
                                    )))
                            /*Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 5),
                                      Text(
                                        '${lastActionDescription}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: CustomColor.textColor,
                                        ),
                                      ),
                                    ],
                                  ),*/
                          ]))))
                  : Padding(
                  padding: EdgeInsets.all(8),
                  child: Card(
                    color: CustomColor.cardColor,
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(children: [
                        Row(
                          children: [
                            RichText(
                                text:
                                TextSpan(children: <TextSpan>[
                                  TextSpan(
                                      text: 'وضعیت : ',
                                      style: TextStyle(
                                          fontFamily: 'irs',
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                          color:
                                          CustomColor.textColor)),
                                  TextSpan(
                                      text: 'حاضر در محل کار',
                                      style: TextStyle(
                                          fontFamily: 'irs',
                                          fontSize: 12.0,
                                          color:
                                          CustomColor.textColor)),
                                ])),
                            Spacer(),
                          ],
                        ),
                        /*
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Image.asset(
                                                'assets/images/family.png',
                                                //File('/assets/images/family.jpg'),
                                                width: 300,
                                                height: 200,
                                                fit: BoxFit.cover),
                                          )
                                        ],
                                      ),*/
                        Center(
                            child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 1.0,
                                  ),
                                ),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.yellow,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      submitArrivalAction();
                                    },
                                    child: Text('ورود'),
                                    style:
                                    ElevatedButton.styleFrom(
                                      primary: Colors.green,
                                      onPrimary: Colors.white,
                                      shape: OvalBorder(
                                          side: BorderSide.none,
                                          eccentricity: 0.07),
                                      padding:
                                      EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 20),
                                    ),
                                  ),
                                )))
                      ]),
                    ),
                  ))
                  : Expanded(
                  child: Center(
                    child: Text('در محل کار حضور ندارید!'),
                  )),
            ]));
  }
}
