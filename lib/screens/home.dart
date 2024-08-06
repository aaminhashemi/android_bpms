import 'dart:async';
import 'package:afkham/models/assistance.dart';
import 'package:afkham/models/coordinate.dart';
import 'package:afkham/models/leaving.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance.dart';
import '../models/loan.dart';
import '../models/mission.dart';
import '../utils/custom_notification.dart';
import '../widgets/app_drawer.dart';
import '../utils/custom_color.dart';
import '../services/auth_service.dart';
import '../services/action_service.dart';
import '../services/home_service.dart';
import 'package:intl/intl.dart' as intl;

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
      home: SwipeToRefreshExample(),
    );
  }
}

class SwipeToRefreshExample extends StatefulWidget {
  @override
  _SwipeToRefreshExampleState createState() => _SwipeToRefreshExampleState();
}

class _SwipeToRefreshExampleState extends State<SwipeToRefreshExample> {
  final AuthService authService = AuthService('https://afkhambpms.ir/api1');
  final HomeService homeService = HomeService('https://afkhambpms.ir/api1');
  final ActionService actionService =
      ActionService('https://afkhambpms.ir/api1');

  bool isSyncing = false;
  bool isLoading = true;
  late double distance;
  bool _isInRange = false;
  bool isConnected = false;
  bool _requestAllowed = false;
  Box<Coordinate>? coordinateBox;
  Box<Attendance>? attendanceBox;
  Box<Loan>? loanBox;
  Box<Mission>? missionBox;
  Box<Leaving>? leavingBox;
  Box<Assist>? assistanceBox;

  late double latitude;
  late double longitude;
  List<Attendance>? results;
  List<Leaving>? leavingResults;
  List<Loan>? loanResults;
  List<Mission>? missionResults;
  List<Assist>? assistanceResults;
  List<dynamic> targetLatitudes = [];
  List<dynamic> targetLongitudes = [];
  late double distanceThreshold;

  late String availableAction;
  late String requestDate;
  late String lastActionType = '';
  late String lastActionDescription = '';

  List<dynamic> personnelList = [];

  @override
  void initState() {
    super.initState();
    initBox();
    loadLastState();
    connectionChecker();
    fetchCoordinates(context);
  }

  Future<void> connectionChecker() async {
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
  }

  @override
  void dispose() {
    super.dispose();
  }

  Jalali _parseJalaliDate(String dateString) {
    List<String> parts = dateString.split('/');
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    int day = int.parse(parts[2]);
    return Jalali(year, month, day);
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
                                foregroundColor: Colors.white, backgroundColor: Colors.red,
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
                                foregroundColor: Colors.white, backgroundColor: Colors.green,
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

  getCurrentTime() {
    final now = DateTime.now();
    final formatter = DateFormat('HH:mm:ss');
    return formatter.format(now);
  }

  Future<void> loadLastState() async {
    var savedValue = await actionService.getLastActionInfo();
    var shiftValue = await authService.getShiftInfo();
    var date = savedValue['date'];
    var time = savedValue['time'];
    setState(() {
      distanceThreshold = double.parse(savedValue['distance']);
    });
    TimeOfDay givenTime = parseTimeString(getCurrentTime());

    TimeOfDay startTime = parseTimeString(shiftValue['start']);
    TimeOfDay startTimeUntil = parseTimeString(shiftValue['can_start']);

    TimeOfDay endTime = parseTimeString(shiftValue['end']);
    TimeOfDay endTimeUntil = parseTimeString(shiftValue['can_end']);

    bool startIsBetween = isTimeBetween(givenTime, startTime, startTimeUntil);

    bool endIsBetween = isTimeBetween(givenTime, endTime, endTimeUntil);

    if (startIsBetween) {
      if (date.toString().length > 0 && time.toString().length > 0) {
        Jalali jalaliDate = _parseJalaliDate(date);
        Jalali dateWithTime = Jalali.now();
        Jalali now = Jalali(dateWithTime.year, dateWithTime.month, dateWithTime.day);
        if (jalaliDate == now) {
            setState(() {
              lastActionDescription = savedValue['description'];
              lastActionType = savedValue['type'];
            });

        }else{
          setState(() {
            lastActionDescription = savedValue['description'];
            lastActionType = 'exit';
          });
        }
      } else {
        setState(() {
          lastActionDescription = savedValue['description'];
          lastActionType = 'exit';
        });
      }
    }
    if (endIsBetween) {
      if (date.toString().length > 0 && time.toString().length > 0) {
        Jalali jalaliDate = _parseJalaliDate(date);
        Jalali dateWithTime = Jalali.now();
        Jalali now =
        Jalali(dateWithTime.year, dateWithTime.month, dateWithTime.day);
        if (jalaliDate == now) {
            setState(() {
              lastActionDescription = savedValue['description'];
              lastActionType = savedValue['type'];
            });
        }else{
          setState(() {
            lastActionDescription = savedValue['description'];
            lastActionType = 'arrival';
          });
        }
      } else {
        setState(() {
          lastActionDescription = savedValue['description'];
          lastActionType = 'arrival';
        });
      }
    }
  }

  TimeOfDay parseTimeString(String timeString) {
    List<String> parts = timeString.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  bool isTimeBetween(
      TimeOfDay givenTime, TimeOfDay startTime, TimeOfDay endTime) {
    int givenMinutes = givenTime.hour * 60 + givenTime.minute;
    int startMinutes = startTime.hour * 60 + startTime.minute;
    int endMinutes = endTime.hour * 60 + endTime.minute;
    return givenMinutes >= startMinutes && givenMinutes <= endMinutes;
  }

  Future<void> initBox() async {
    coordinateBox = await Hive.openBox('coordinateBox');
    attendanceBox = await Hive.openBox('attendanceBox');
    results = await attendanceBox?.values
        .where((data) => data.synced == false)
        .toList();
  }

  void submitArrivalAction() async {
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
    setState(() {
      _requestAllowed = false;
      _isInRange = false;
    });
    for (int i = 0; i < targetLatitudes.length; i++) {
      distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        targetLatitudes[i],
        targetLongitudes[i],
      );
      if (distance < distanceThreshold) {
        setState(() {
          _requestAllowed = true;
          _isInRange = true;
        });
        break;
      }
    }
    if (_requestAllowed) {
      attendanceBox = await Hive.openBox('attendanceBox');
      final attendanceBox1 = Hive.box<Attendance>('attendanceBox');

      try {
        final actionResponse =
            await actionService.updateManual('systemic', 'arrival', '');

        if (actionResponse['status'] == 'successful') {
          Attendance attendance = Attendance(
            status: 'arrival',
            jalali_date: actionResponse['date'],
            time: actionResponse['time'],
            type: 'systemic',
            synced: true,
            description: '',
          );
          attendanceBox1.add(attendance);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_action_date', actionResponse['date']);
          await prefs.setString('last_action_time', actionResponse['time']);
          await prefs.setString('last_action_description', ' ورود ' + actionResponse['time'] + ' - ' + actionResponse['date']);
          await prefs.setString('last_action_type', 'arrival');
          loadLastState();
        }
      } catch (e) {
        CustomNotification.show(
            context, 'ناموفق', 'در ثبت درخواست مشکلی وجود دارد.', '');
      }
    } else {
      CustomNotification.show(
          context, 'خطا', 'شما در محدوده ی تعیین شده حضور ندارید.', '');
    }
    setState(() {
      isLoading = false;
    });
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
    setState(() {
      _requestAllowed = false;
      _isInRange = false;
    });
    for (int i = 0; i < targetLatitudes.length; i++) {
      distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        targetLatitudes[i],
        targetLongitudes[i],
      );
      if (distance < distanceThreshold) {
        setState(() {
          _requestAllowed = true;
          _isInRange = true;
        });
        break;
      }
    }
    if (_requestAllowed) {
      try {
        attendanceBox = await Hive.openBox('attendanceBox');
        final attendanceBox1 = Hive.box<Attendance>('attendanceBox');
        final actionResponse = await actionService.updateManual(
          'systemic',
          'exit',
          '',
        );
        if (actionResponse['status'] == 'successful') {
          Attendance attendance = Attendance(
            status: 'exit',
            jalali_date: actionResponse['date'],
            time: actionResponse['time'],
            type: 'systemic',
            synced: true,
            description: '',
          );
          attendanceBox1.add(attendance);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_action_date', actionResponse['date']);
          await prefs.setString('last_action_time', actionResponse['time']);
          await prefs.setString('last_action_description',
              ' خروج ' + actionResponse['time'] + ' - ' + actionResponse['date']);
          await prefs.setString('last_action_type', 'exit');
          loadLastState();
        }
      } catch (e) {
        CustomNotification.show(
            context, 'ناموفق', 'در ثبت درخواست مشکلی وجود دارد.', '');
      }
    } else {
      CustomNotification.show(
          context, 'خطا', 'شما در محدوده ی تعیین شده حضور ندارید.', '');
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchCoordinates(BuildContext context) async {
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

      final response = await http
          .get(Uri.parse('https://afkhambpms.ir/api1/get-points'), headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      });

      if (response.statusCode == 200) {
        var res = json.decode(response.body);

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
            longitude: targetLongitudes[i],
          );
          box.add(coordinate);
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
      setState(() {
        isLoading = false;
      });
    }
  }

  void _logout(BuildContext context) async {
    await authService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _refreshItems() async {
    await Future.delayed(Duration(seconds: 1));
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
      CustomNotification.show(context, 'خطا', 'مشکلی وجود دارد.', '');
      if (mounted) {
        setState(() {
          _isInRange = false;
          _requestAllowed = false;
        });
      }
      simple();
    }
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
        body: Container(
            child: RefreshIndicator(
          onRefresh: _refreshItems,
          child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Container(
                  padding: EdgeInsets.all(4.0),
                  height: MediaQuery.of(context).size.height,
                  alignment: Alignment.center,
                  child: Center(
                    child: (isLoading
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : Column(children: [
                            Center(
                                child: Padding(
                              padding:
                                  EdgeInsets.only(right: 8, left: 8, top: 8),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Card(
                                        color: CustomColor.cardColor,
                                        elevation: 2,
                                        margin: EdgeInsets.only(bottom: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
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
                                                          text:
                                                              ' آخرین رویداد : ',
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              fontFamily: 'irs',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: CustomColor
                                                                  .textColor),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '${lastActionDescription}',
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              fontFamily: 'irs',
                                                              color: CustomColor
                                                                  .textColor),
                                                        ),
                                                      ])),
                                                  Spacer(),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator
                                                          .pushReplacementNamed(
                                                              context, '/loc');
                                                    },
                                                    child: Text('مشاهده'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      foregroundColor: Colors.white, backgroundColor: Colors.teal,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10.0),
                                                      ),
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 10,
                                                              horizontal: 20),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ]))),
                                  ]),
                            )),
                            (isConnected)
                                ? (_isInRange)
                                    ? (lastActionType == 'arrival')
                                        ? Padding(
                                            padding: EdgeInsets.only(
                                                bottom: 8, left: 8, right: 8),
                                            child: Card(
                                                color: CustomColor.cardColor,
                                                elevation: 2,
                                                margin:
                                                    EdgeInsets.only(bottom: 20),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.0),
                                                ),
                                                child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            15.0),
                                                    child: Column(children: [
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          RichText(
                                                              text: TextSpan(
                                                                  children: <TextSpan>[
                                                                TextSpan(
                                                                    text:
                                                                        'وضعیت : ',
                                                                    style: TextStyle(
                                                                        fontFamily:
                                                                            'irs',
                                                                        fontSize:
                                                                            12.0,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        color: CustomColor
                                                                            .textColor)),
                                                                TextSpan(
                                                                    text:
                                                                        'در حال کار',
                                                                    style: TextStyle(
                                                                        fontFamily:
                                                                            'irs',
                                                                        fontSize:
                                                                            12.0,
                                                                        color: CustomColor
                                                                            .textColor)),
                                                              ])),
                                                          SizedBox(height: 40.0),
                                                          Spacer(),
                                                        ],
                                                      ),
                                                      Center(
                                                          child: Container(
                                                              width: 100,
                                                              height: 100,
                                                              decoration:
                                                                  BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                border:
                                                                    Border.all(
                                                                  color: Colors
                                                                      .red,
                                                                  width: 1.0,
                                                                ),
                                                              ),
                                                              child: Container(
                                                                width: 100,
                                                                height: 100,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  border: Border
                                                                      .all(
                                                                    color: Colors
                                                                        .yellow,
                                                                    width: 1.0,
                                                                  ),
                                                                ),
                                                                child:
                                                                    ElevatedButton(
                                                                  onPressed:
                                                                      () {
                                                                    submitExitAction();
                                                                  },
                                                                  child: Text('خروج'),
                                                                  style: ElevatedButton
                                                                      .styleFrom(
                                                                    foregroundColor: Colors
                                                                            .white, backgroundColor: Colors
                                                                            .red,
                                                                    shape: OvalBorder(
                                                                        side: BorderSide
                                                                            .none,
                                                                        eccentricity:
                                                                            0.07),
                                                                    padding: EdgeInsets.symmetric(
                                                                        vertical:
                                                                            10,
                                                                        horizontal:
                                                                            20),
                                                                  ),
                                                                ),
                                                              )))
                                                    ]))))
                                        : Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Card(
                                              color: CustomColor.cardColor,
                                              elevation: 2,
                                              margin:
                                                  EdgeInsets.only(bottom: 20),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(15.0),
                                                child: Column(children: [
                                                  Row(
                                                    children: [
                                                      RichText(
                                                          text: TextSpan(
                                                              children: <TextSpan>[
                                                            TextSpan(
                                                                text:
                                                                    'وضعیت : ',
                                                                style: TextStyle(
                                                                    fontFamily:
                                                                        'irs',
                                                                    fontSize:
                                                                        12.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: CustomColor
                                                                        .textColor)),
                                                            TextSpan(
                                                                text:
                                                                    'حاضر در محل کار',
                                                                style: TextStyle(
                                                                    fontFamily:
                                                                        'irs',
                                                                    fontSize:
                                                                        12.0,
                                                                    color: CustomColor
                                                                        .textColor)),
                                                          ])),
                                                      Spacer(),
                                                      SizedBox(height: 40.0),
                                                    ],
                                                  ),
                                                  Center(
                                                      child: Container(
                                                          width: 100,
                                                          height: 100,
                                                          decoration:
                                                              BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                              color:
                                                                  Colors.green,
                                                              width: 1.0,
                                                            ),
                                                          ),
                                                          child: Container(
                                                            width: 100,
                                                            height: 100,
                                                            decoration:
                                                                BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              border:
                                                                  Border.all(
                                                                color: Colors
                                                                    .yellow,
                                                                width: 1.0,
                                                              ),
                                                            ),
                                                            child:
                                                                ElevatedButton(
                                                              onPressed: () {
                                                                submitArrivalAction();
                                                              },
                                                              child:
                                                                  Text('ورود'),
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                foregroundColor: Colors
                                                                        .white, backgroundColor: Colors
                                                                    .green,
                                                                shape: OvalBorder(
                                                                    side: BorderSide
                                                                        .none,
                                                                    eccentricity:
                                                                        0.07),
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        vertical:
                                                                            10,
                                                                        horizontal:
                                                                            20),
                                                              ),
                                                            ),
                                                          )))
                                                ]),
                                              ),
                                            ))
                                    : Expanded(
                                        child: Center(
                                        child: Text('در محل کار حضور ندارید!'),
                                      ))
                                : Expanded(
                                    child: Center(
                                    child: Text('اینترنت دستگاه متصل نیست!'),
                                  )),
                          ])),
                  ))),
        )));
  }
}
