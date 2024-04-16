import 'package:afkham/models/coordinate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:shamsi_date/shamsi_date.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rollcal.dart';
import '../utils/custom_notification.dart';
import '../widgets/app_drawer.dart';
import '../utils/custom_color.dart';
import '../services/auth_service.dart';
import '../services/action_service.dart';
import '../services/home_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart' as intl;
import 'package:timezone/data/latest.dart' as tz;

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

  bool isSyncing = false;
  bool isLoading = true;
  late double distance;
  bool isInRange = false;
  bool isConnected = true;
  bool requestAllowed = false;
  Box<Coordinate>? coordinateBox;
  Box<Rollcal>? rollcalBox;

  late double latitude;
  late double longitude;
  List<Rollcal>? results;
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
    tz.initializeTimeZones();
    loadLastState();
    sync();
    //fetchActionInfo();
    fetchCoordinates(context);
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
    results = await rollcalBox?.values.where((data) => data.synced == false).toList();
  }

  Future<void> sync() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        isSyncing = true;
      });
      rollcalBox = await Hive.openBox('rollcalBox');
      results =
      await rollcalBox?.values.where((data) => data.synced == false).toList();
      ActionService actionService = ActionService('https://afkhambpms.ir/api1');

      if (results!.isNotEmpty) {
        for (var result in results!) {
          try {
            final actionResponse = await actionService.updateManual(
              result.date,
              result.time,
              result.type,
              result.status,
              result.description,
            );

            if (actionResponse['status'] == 'successful') {
              Rollcal rollcal = Rollcal(
                id: result.id,
                status: result.status,
                date: result.date,
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
            CustomNotification.show(
                context, 'ناموفق', 'در ثبت اطلاعات مشکلی وجود دارد.', '');
          }
        }
      }

      setState(() {
        isSyncing = false;
      });
      print(isSyncing);
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
        if (!requestAllowed) {
          distance = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            double.parse(targetLatitudes[i]),
            double.parse(targetLongitudes[i]),
          );
          if (distance < distanceThreshold) {
            setState(() {
              requestAllowed = true;
            });
          }
        }
      }
      if (requestAllowed) {
        var time=getCurrentTime();

        if(!isSyncing){
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
                id: id+1,
                status: 'arrival',
                date: requestDate,
                time: time,
                type: 'systemic',
                synced: true,
                description: '',
              );
              rollcalBox.add(rollcal);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('last_action_description', ' ورود '+time);
              await prefs.setString('last_action_type', 'arrival');
              setState(() {
                lastActionType = 'arrival';
                lastActionDescription = ' ورود '+time;
              });
            }
          } catch (e) {
            CustomNotification.show(context, 'ناموفق', 'در ثبت اطلاعات مشکلی وجود دارد.', '');
          }
        }else{
          final rollcalBox = Hive.box<Rollcal>('rollcalBox');
          int id = rollcalBox.length;
          Rollcal rollcal = Rollcal(
              id: id + 1,
              status: 'arrival',
              date: requestDate,
              time: time,
              type: 'systemic',
              synced: false,
              description: '');
          rollcalBox.add(rollcal);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_action_description', ' ورود '+time);
          await prefs.setString('last_action_type', 'arrival');
          setState(() {
            lastActionType = 'arrival';
            lastActionDescription = ' ورود '+time;
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
        if (!requestAllowed) {
          distance = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            targetLatitudes[i],
            targetLongitudes[i],
          );
          if (distance < distanceThreshold) {
            setState(() {
              requestAllowed = true;
            });
          }
        }
      }
      if (requestAllowed) {
        final box = Hive.box<Rollcal>('rollcalBox');
        int id = box.length;
        var time=getCurrentTime();
        Rollcal rollcal = Rollcal(
            id: id + 1,
            status: 'arrival',
            date: requestDate,
            time: time,
            type: 'systemic',
            synced: false,
            description: '');
        box.add(rollcal);
        print(box.length);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_action_description', ' ورود '+time);
        await prefs.setString('last_action_type', 'arrival');
        setState(() {
          lastActionType = 'arrival';
          lastActionDescription = ' ورود '+time;
        });
      }else {
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
        if (!requestAllowed) {
          distance = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            double.parse(targetLatitudes[i]),
            double.parse(targetLongitudes[i]),
          );
          if (distance < distanceThreshold) {
            setState(() {
              requestAllowed = true;
            });
          }
        }
      }
      if (requestAllowed) {
        var time=getCurrentTime();
        if(!isSyncing){
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
                id: id+1,
                status: 'exit',
                date: requestDate,
                time: time,
                type: 'systemic',
                synced: true,
                description: '',
              );
              rollcalBox.add(rollcal);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('last_action_description', ' خروج '+time);
              await prefs.setString('last_action_type', 'exit');
              setState(() {
                lastActionType = 'exit';
                lastActionDescription = ' خروج '+time;
              });
            }
          } catch (e) {
            CustomNotification.show(context, 'ناموفق', 'در ثبت اطلاعات مشکلی وجود دارد.', '');
          }
        }else{
          final rollcalBox = Hive.box<Rollcal>('rollcalBox');
          int id = rollcalBox.length;
          Rollcal rollcal = Rollcal(
              id: id + 1,
              status: 'exit',
              date: requestDate,
              time: time,
              type: 'systemic',
              synced: false,
              description: '');
          rollcalBox.add(rollcal);
          print(rollcalBox.length);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_action_description', ' خروج '+time);
          await prefs.setString('last_action_type', 'exit');
          setState(() {
            lastActionType = 'exit';
            lastActionDescription = ' خروج '+time;
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
        if (!requestAllowed) {
          distance = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            targetLatitudes[i],
            targetLongitudes[i],
          );
          if (distance < distanceThreshold) {
            setState(() {
              requestAllowed = true;
            });
          }
        }
      }
      if (requestAllowed) {
        var time=getCurrentTime();

        final box = Hive.box<Rollcal>('rollcalBox');
        int id = box.length;
        Rollcal rollcal = Rollcal(
            id: id + 1,
            status: 'exit',
            date: requestDate,
            time: getCurrentTime(),
            type: 'systemic',
            synced: false,
            description: '');
        box.add(rollcal);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_action_description', ' خروج '+time);
        await prefs.setString('last_action_type', 'exit');
        setState(() {
          lastActionType = 'exit';
          lastActionDescription = ' خروج '+time;
        });
      }else {
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
        setState(() {
          targetLatitudes = res['latitudes'];
          targetLongitudes = res['longitudes'];
          //distanceThreshold = double.parse(res['distance']);
          //lastActionType = res['last_action_type'] ?? "";
         // lastActionDescription = res['last_action_description'] ?? "";
        });

        actionService.saveLastActionDescription(res['last_action_description']);
        actionService.saveLastActionType(res['last_action_type']);
        actionService.saveThresholdDistance(res['distance']);

        for (int i = 0; i < targetLatitudes.length; i++) {
          if (!isInRange) {
            distance = Geolocator.distanceBetween(
              latitude,
              longitude,
              double.parse(targetLatitudes[i]),
              double.parse(targetLongitudes[i]),
            );
            if (distance < distanceThreshold) {
              setState(() {
                isInRange = true;
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
            latitude: double.parse(targetLatitudes[i]),
            longitude: double.parse(targetLongitudes[i]),
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
        if (!isInRange) {
          distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            targetLatitudes[i],
            targetLongitudes[i],
          );
          print(distanceThreshold);
          if (distance < distanceThreshold) {
            setState(() {
              isInRange = true;
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
                                            child: Text('ثبت'),
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
                    (isInRange)
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

  Widget _buildCard(String title, String route, int count, String last) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 20),
      color: CustomColor.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CustomColor.textColor),
                ),
                SizedBox(height: 5),
                Text(
                  ': $count',
                  style: TextStyle(fontSize: 16, color: CustomColor.textColor),
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/${route}');
                  },
                  child: Text('مشاهده'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.teal,
                    // Background color of the button
                    onPrimary: Colors.white,
                    // Text color on the button
                    elevation: 5,
                    // Elevation of the button
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10.0), // Rounded corners
                    ),
                    padding: EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20), // Button padding
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'آخرین :',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CustomColor.textColor),
                ),
                SizedBox(height: 5),
                Text(
                  ' $last',
                  style: TextStyle(fontSize: 16, color: CustomColor.textColor),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
