import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_linear_datepicker/flutter_datepicker.dart';
import 'package:hive/hive.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../models/rollcal.dart';
import '../services/auth_service.dart';
import '../utils/custom_color.dart';
import '../utils/custom_notification.dart';
import '../utils/standard_number_creator.dart';
import '../widgets/app_drawer.dart';
import '../services/action_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AllList(),
    );
  }
}

class AllList extends StatefulWidget {
  @override
  _AllListState createState() => _AllListState();
}

class _AllListState extends State<AllList> {
  bool isLoading = true;
  bool isConnected = false;
  bool isSyncing = false;
  double syncPercent = 0;
  Box<Rollcal>? rollcalBox;
  List<Rollcal> dataList = [];
  bool isSynchronized = true;

  Future<void> initBox() async {
    rollcalBox = await Hive.openBox('rollcalBox');
    dataList =
        (rollcalBox?.values.toList()?..sort((a, b) => b.id.compareTo(a.id)))!;
    final List<Rollcal>? results =
        rollcalBox?.values.where((data) => data.synced == false).toList();
    if (results!.length > 0) {
      for (var result in results) {
        print(result.synced);
      }
      setState(() {
        isSynchronized = false;
      });
    }
    print(results.length);
    setState(() {
      isLoading = false;
    });
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
  void initState() {
    super.initState();
    connectionChecker();
    initBox();
    //fetchData(context);
    //fetchData(context);
  }

  void SendListToServer() async {
    setState(() {
      isSyncing = true;
    });
    ActionService actionService = ActionService('https://afkhambpms.ir/api1');
    final List<Rollcal>? results =
        rollcalBox?.values.where((data) => data.synced == false).toList();
    double percent = 0;
    if (results!.isNotEmpty) {
      percent = 1 / (results!.length);
    }
    if (results!.isNotEmpty) {
      for (var result in results) {
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
            setState(() {
              syncPercent = syncPercent + percent;
            });
          }
        } catch (e) {
          CustomNotification.show(context, 'ناموفق', e.toString(), '');
        }
      }
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        isSyncing = false;
        isSynchronized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          Navigator.pushReplacementNamed(context, '/main');
          return false;
        },
        child: Scaffold(
            appBar: AppBar(
              iconTheme:
                  IconThemeData(color: CustomColor.drawerBackgroundColor),
              title: Text('ورود و خروج',
                  style: TextStyle(color: CustomColor.textColor)),
            ),
            drawer: AppDrawer(),
            body: (isSyncing)
                ? Center(
                child:Stack(children: [
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white,
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    ' در حال به روز رسانی %${(syncPercent * 100).toInt()}',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontStyle: FontStyle.italic),
                                  ),
                                  SizedBox(height: 16),
                                  LinearProgressIndicator(
                                      value: syncPercent,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.green),
                                    ),

                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  ]))
                : Column(children: [
                    Container(
                      color: CustomColor.backgroundColor,
                      width: double.infinity,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          color: CustomColor.buttonColor,
                          child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MyHomePage(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'ثبت ورود و خروج جدید',
                                        style: TextStyle(
                                            color: CustomColor.backgroundColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    (!isSynchronized && isConnected)
                        ? ElevatedButton(
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("به روز رسانی"),
                                SizedBox(width: 8),
                                // Add some spacing between the icon and text
                                Icon(Icons.update),
                                // Add the desired icon
                              ],
                            ),
                            onPressed: () {
                              SendListToServer();
                            },
                          )
                        : Row(),
                    (isLoading)
                        ? Expanded(
                            child: Center(
                            child: CircularProgressIndicator(),
                          ))
                        : (dataList.length == 0)
                            ? Expanded(
                                child: Center(
                                child: Text(
                                  'ورود یا خروج یافت نشد!',
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ))
                            : Expanded(
                                child: SingleChildScrollView(
                                    child: Padding(
                                        padding: EdgeInsets.only(bottom: 15),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          itemCount: dataList.length,
                                          itemBuilder: (context, index) {
                                            var item = dataList[index];
                                            return Card(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              elevation: 4.0,
                                              color:
                                                  CustomColor.backgroundColor,
                                              margin: EdgeInsets.only(
                                                  left: 16, right: 16, top: 12),
                                              child: ExpansionTile(
                                                backgroundColor:
                                                    CustomColor.backgroundColor,
                                                leading: Icon(
                                                    Icons.keyboard_arrow_down,
                                                    color: CustomColor
                                                        .drawerBackgroundColor),
                                                shape: LinearBorder.none,
                                                title: RichText(
                                                  text: TextSpan(
                                                      children: <TextSpan>[
                                                        TextSpan(
                                                          text: 'تاریخ :',
                                                          style: TextStyle(
                                                              fontFamily: 'irs',
                                                              fontSize: 12.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: CustomColor
                                                                  .textColor),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              ' ${item.date}  ',
                                                          style: TextStyle(
                                                              fontFamily: 'irs',
                                                              fontSize: 12.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              color: CustomColor
                                                                  .textColor),
                                                        ),
                                                      ]),
                                                ),
                                                subtitle: RichText(
                                                  text: TextSpan(
                                                      children: <TextSpan>[
                                                        TextSpan(
                                                          text: 'نوع :',
                                                          style: TextStyle(
                                                              fontFamily: 'irs',
                                                              fontSize: 12.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: CustomColor
                                                                  .textColor),
                                                        ),
                                                        TextSpan(
                                                          text: (item.type ==
                                                                  'systemic')
                                                              ? 'سیستمی'
                                                              : 'دستی',
                                                          style: TextStyle(
                                                              fontFamily: 'irs',
                                                              fontSize: 12.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              color: CustomColor
                                                                  .textColor),
                                                        ),
                                                      ]),
                                                ),
                                                trailing: InkWell(
                                                  child:
                                                      (item.status ==
                                                                  'leaving' ||
                                                              item.status ==
                                                                  'mission')
                                                          ? Container(
                                                              //margin: EdgeInsets.all(10),
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(8.0),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: CustomColor
                                                                    .cardColor,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10.0),
                                                              ),

                                                              child: (item.status ==
                                                                      'leaving')
                                                                  ? Text(
                                                                      'مرخصی',
                                                                    )
                                                                  : Text(
                                                                      'ماموریت',
                                                                    ),
                                                            )
                                                          : (item.status ==
                                                                  'arrival')
                                                              ? Container(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              8.0),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: CustomColor
                                                                        .successColor,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10.0),
                                                                  ),
                                                                  child: Text(
                                                                    'ورود',
                                                                  ),
                                                                )
                                                              : Container(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              8.0),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: CustomColor
                                                                        .dangerColor,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10.0),
                                                                  ),
                                                                  child: Text(
                                                                    'خروج',
                                                                  ),
                                                                ),
                                                ),
                                                children: <Widget>[
                                                  //Padding(
                                                  //padding: const EdgeInsets.all(16.0),
                                                  Container(
                                                    color:
                                                        CustomColor.cardColor,
                                                    padding:
                                                        EdgeInsets.all(16.0),
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          children: [
                                                            RichText(
                                                                text: TextSpan(
                                                                    children: <TextSpan>[
                                                                  TextSpan(
                                                                    text:
                                                                        'زمان :',
                                                                    style: TextStyle(
                                                                        fontFamily:
                                                                            'irs',
                                                                        fontSize:
                                                                            12.0,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        color: CustomColor
                                                                            .textColor),
                                                                  ),
                                                                  TextSpan(
                                                                    text:
                                                                        ' ${item.time}  ',
                                                                    style: TextStyle(
                                                                        fontFamily:
                                                                            'irs',
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .normal,
                                                                        fontSize:
                                                                            12.0,
                                                                        color: CustomColor
                                                                            .textColor),
                                                                  ),
                                                                ])),
                                                            Spacer()
                                                          ],
                                                        ),
                                                        if (item.description !=
                                                            null)
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Expanded(
                                                                  child: RichText(
                                                                      text: TextSpan(children: <TextSpan>[
                                                                TextSpan(
                                                                  text:
                                                                      'توضیحات :',
                                                                  style: TextStyle(
                                                                      fontFamily:
                                                                          'irs',
                                                                      fontSize:
                                                                          12.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: CustomColor
                                                                          .textColor),
                                                                ),
                                                                TextSpan(
                                                                  text:
                                                                      ' ${item.description}  ',
                                                                  style: TextStyle(
                                                                      fontFamily:
                                                                          'irs',
                                                                      fontSize:
                                                                          12.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      color: CustomColor
                                                                          .textColor),
                                                                ),
                                                              ]))),
                                                            ],
                                                          ),
                                                      ],
                                                    ),
                                                  )
                                                  //),
                                                ],
                                              ),
                                            );
                                          },
                                        )))),
                  ])));
  }

  Future<void> fetchData(BuildContext context) async {
    var connectivityResult = await Connectivity().checkConnectivity();

    setState(() {
      isLoading = true;
    });
    //DatabaseHelper databaseHelper = DatabaseHelper();
    final AuthService authService = AuthService('https://afkhambpms.ir/api1');
    final token = await authService.getToken();
    if (connectivityResult != ConnectivityResult.none) {
      try {
        final response = await http.get(
            Uri.parse('https://afkhambpms.ir/api1/personnels/get-action'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/x-www-form-urlencoded',
            });
        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          //List<Rollcal> fetchedRollcals =
          //await RollcalRepository().saveRollcalsToLocal(data);

          setState(() {
// Example data, replace with your actual data
          });
        } else {
          throw Exception('خطا در دریافت داده ها');
        }
      } catch (e) {
        CustomNotification.show(
            context,
            'ناموفق',
            e.toString() /*'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.'*/,
            'loc');
        print(e.toString());
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Rollcal? rollcal;
  Box<Rollcal>? rollcalBox;
  bool isConnected = false;
  TextEditingController descriptionController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  bool isLoading = false;
  String type = 'انتخاب';
  List<String> typeList = ['انتخاب', 'ورود', 'خروج', 'مرخصی', 'ماموریت'];
  List<dynamic> targetLatitudes = [];
  List<dynamic> targetLongitudes = [];
  late double distanceThreshold;
  late double distance;
  String dis = '';
  late double minDistance = 0;
  TextEditingController timeController = TextEditingController();
  TimeOfDay? time;
  List<Rollcal>? results;
  bool isSyncing = false;

  @override
  void initState() {
    super.initState();
    connectionChecker();
    initBox();
    sync();
  }

  Future<void> initBox() async {
    rollcalBox = await Hive.openBox('rollcalBox');
    results =
        await rollcalBox?.values.where((data) => data.synced == false).toList();
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

  Future<void> sync() async {
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

  Widget _buildDateTextField() {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 75,
        child: Text(
          'تاریخ :',
          style: TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      SizedBox(width: 8.0),
      Expanded(
          child: Container(
              decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(color: CustomColor.textColor, width: 4.0)),
              ),
              child: TextField(
                controller: dateController,
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                  border: InputBorder.none,
                ),
                onTap: () {
                  showDateDialog(context, dateController);
                },
              )))
    ]);
  }

  void showDateDialog(BuildContext context, controller) {
    DateTime dt = DateTime.now();
    Jalali j = dt.toJalali();
    final f = j.formatter;
    String selected = '${f.yyyy}/${f.mm}/${f.dd}';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('انتخاب تاریخ شروع',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
        content: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearDatePicker(
                addLeadingZero: true,
                dateChangeListener: (String selectedDate) {
                  selected = selectedDate;
                },
                showDay: true,
                labelStyle: TextStyle(
                  fontFamily: 'irs',
                  fontSize: 12.0,
                  color: Colors.black,
                ),
                selectedRowStyle: TextStyle(
                  fontFamily: 'irs',
                  fontSize: 13.0,
                  color: Colors.deepOrange,
                ),
                unselectedRowStyle: TextStyle(
                  fontFamily: 'irs',
                  fontSize: 12.0,
                  color: Colors.blueGrey,
                ),
                yearText: "سال",
                monthText: "ماه",
                dayText: "روز",
                showLabels: true,
                columnWidth: 90,
                showMonthName: true,
                isJalaali: true,
              ),
              ElevatedButton(
                child: Text(
                  "انتخاب",
                ),
                onPressed: () {
                  controller.text = selected;
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/main');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: CustomColor.drawerBackgroundColor),
          title: Text('ثبت ورود و خروج',
              style: TextStyle(color: CustomColor.textColor)),
        ),
        drawer: AppDrawer(),
        body: SingleChildScrollView(
          child: Align(
            alignment: Alignment.center,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        color: CustomColor.cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'ثبت ورود و خروج',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              SizedBox(height: 24.0),
                              _buildDateTextField(),
                              SizedBox(height: 24.0),
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 75,
                                      child: Text(
                                        'ساعت شروع :',
                                        style: TextStyle(
                                          fontSize: 10.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.0),
                                    Expanded(
                                        child: Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                  left: BorderSide(
                                                      color:
                                                          CustomColor.textColor,
                                                      width: 4.0)),
                                            ),
                                            child: TextField(
                                              controller: timeController,
                                              readOnly: true,
                                              onTap: () async {
                                                TimeOfDay? pickedTime =
                                                    await showTimePicker(
                                                  context: context,
                                                  initialTime:
                                                      time ?? TimeOfDay.now(),
                                                );
                                                setState(() {
                                                  time = pickedTime;
                                                  timeController.text =
                                                      MaterialLocalizations.of(
                                                              context)
                                                          .formatTimeOfDay(
                                                              pickedTime!);
                                                });
                                              },
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.white,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        vertical: 8),
                                                isDense: true,
                                                border: InputBorder.none,
                                              ),
                                            )))
                                  ]),
                              SizedBox(height: 24.0),
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 75,
                                      child: Text(
                                        'نوع :',
                                        style: TextStyle(
                                          fontSize: 10.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.0),
                                    Expanded(
                                        child: Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                  left: BorderSide(
                                                      color:
                                                          CustomColor.textColor,
                                                      width: 4.0)),
                                            ),
                                            child: InputDecorator(
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          right: 8, left: 8),
                                                  isDense: true,
                                                  border: InputBorder.none,
                                                ),
                                                child:
                                                    DropdownButtonHideUnderline(
                                                  child: DropdownButton<String>(
                                                    value: type,
                                                    onChanged: (newValue) {
                                                      setState(() {
                                                        type = newValue!;
                                                      });
                                                    },
                                                    iconEnabledColor: CustomColor
                                                        .drawerBackgroundColor,
                                                    items:
                                                        typeList.map((period) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: period,
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      16.0,
                                                                  vertical:
                                                                      12.0),
                                                          child: Text(period,
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                              )),
                                                        ),
                                                      );
                                                    }).toList(),
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 16,
                                                    ),
                                                    isExpanded: true,
                                                    icon: Icon(
                                                        Icons.arrow_drop_down),
                                                    elevation: 3,
                                                  ),
                                                ))))
                                  ]),
                              SizedBox(height: 24.0),
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 75,
                                      child: Text(
                                        'توضیحات :',
                                        style: TextStyle(
                                          fontSize: 10.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.0),
                                    Expanded(
                                        child: Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                  left: BorderSide(
                                                      color:
                                                          CustomColor.textColor,
                                                      width: 4.0)),
                                            ),
                                            child: TextField(
                                              controller: descriptionController,
                                              maxLines: 3,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.white,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        vertical: 8),
                                                isDense: true,
                                                border: InputBorder.none,
                                              ),
                                              style: TextStyle(
                                                fontFamily: 'irs',
                                              ),
                                            )))
                                  ]),
                              SizedBox(height: 24.0),
                              ElevatedButton(
                                onPressed: isLoading ? null : submitAction,
                                child: isLoading
                                    ? CircularProgressIndicator()
                                    : Text('ثبت',
                                        style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        10.0), // Adjust the radius as needed
                                  ),
                                  minimumSize: const Size(double.infinity, 48),
                                  primary: CustomColor.successColor,
                                ),
                              ),
                              Row(
                                children: [Text(dis)],
                              )
                            ],
                          ),
                        ),
                      ),
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void submitAction() async {
    setState(() {
      isLoading = true;
    });
    ActionService actionService = ActionService('https://afkhambpms.ir/api1');
    final box = Hive.box<Rollcal>('rollcalBox');
    int id = box.length;
    var actionType = '';
    switch (type) {
      case 'ورود':
        actionType = 'arrival';
        break;
      case 'مرخصی':
        actionType = 'leaving';
        break;
      case 'ماموریت':
        actionType = 'mission';
        break;
      case 'خروج':
        actionType = 'exit';
        break;
      default:
        actionType = 'choose_type';
    }

    if (isConnected) {
      if (!isSyncing) {
        try {
          final rollcalBox = Hive.box<Rollcal>('rollcalBox');
          int id = rollcalBox.length;
          final actionResponse = await actionService.updateManual(
            dateController.text.trim(),
            StandardNumberCreator.convert(timeController.text.trim()),
            'non-systemic',
            actionType,
            descriptionController.text.trim(),
          );

          if (actionResponse['status'] == 'successful') {
            Rollcal rollcal = Rollcal(
              id: id + 1,
              status: actionType,
              date: dateController.text.trim(),
              time: StandardNumberCreator.convert(timeController.text.trim()),
              type: 'non-systemic',
              synced: true,
              description: descriptionController.text.trim(),
            );
            rollcalBox.add(rollcal);
            CustomNotification.show(
                context, 'موفقیت آمیز', 'درخواست با موفقیت ثبت شد.', '/loc');
          }
        } catch (e) {
          CustomNotification.show(
              context, 'ناموفق', 'در ثبت اطلاعات مشکلی وجود دارد.', '');
        }
      } else {
        final rollcalBox = Hive.box<Rollcal>('rollcalBox');
        int id = rollcalBox.length;
        Rollcal rollcal = Rollcal(
            id: id + 1,
            status: actionType,
            date: dateController.text.trim(),
            time: StandardNumberCreator.convert(timeController.text.trim()),
            type: 'non-systemic',
            synced: false,
            description: '');
        rollcalBox.add(rollcal);
        print(rollcalBox.length);
        CustomNotification.show(
            context, 'موفقیت آمیز', 'درخواست با موفقیت ثبت شد.', '/loc');
      }
    } else {
      Rollcal rollcal = Rollcal(
          id: id + 1,
          status: actionType,
          date: dateController.text.trim(),
          time: StandardNumberCreator.convert(timeController.text.trim()),
          type: 'non-systemic',
          synced: false,
          description: descriptionController.text.trim());

      box.add(rollcal);
      CustomNotification.show(
          context, 'موفقیت آمیز', 'درخواست با موفقیت ثبت شد.', '/loc');
    }
    setState(() {
      isLoading = false;
    });

/*
    var ttt=await db.insert('rollcals', rollcal.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);*/
/*    rollcals.add(rollcal);
    print(rollcals);
    print(ttt);*/
    /*try {

        var actionType = '';
        switch (type) {
          case 'ورود':
            actionType = 'arrival';
            break;
          case 'مرخصی':
            actionType = 'leaving';
            break;
          case 'ماموریت':
            actionType = 'mission';
            break;
          case 'خروج':
            actionType = 'exit';
            break;
          default:
            actionType = 'choose_type';
        }

        try {
          final actionResponse = await actionService.saveManual(
            dateController.text.trim(),
            StandardNumberCreator.convert(timeController.text.trim()),
            actionType,
            descriptionController.text.trim(),
          );

          if (actionResponse['status'] == 'successful') {
            CustomNotification.show(
                context, 'موفقیت آمیز', 'درخواست با موفقیت ثبت شد.', '/loc');

            await RollcalRepository().saveRollcalToLocal([{'status': '7777',
              'date': '7777',
              'time': '7777',
              'type': '7777',
              'stat': '7777',
              'description': '7777'}]);

          } else if (actionResponse['status'] == 'imperfect_data') {
            CustomNotification.show(
                context, 'خطا', 'لطفا اطلاعات را به صورت کامل وارد کنید.', '');
          } else {
            CustomNotification.show(
                context, 'ناموفق', 'در ثبت درخواست مشکلی وجود دارد.', '');
          }
        } catch (e) {
          setState(() {
            isLoading = false;
          });
          CustomNotification.show(
              context, 'ناموفق', e.toString(), '');
        } finally {
          setState(() {
            isLoading = false;
          });
        }

    } catch (e) {
      CustomNotification.show(context, 'ناموفق',
          'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.', '');
      setState(() {
        isLoading = false;
      });
    }*/
  }
}
