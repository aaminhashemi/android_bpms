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
  List<dynamic> allRollcalsList = [];
  bool isLoading = true;
  bool isConnected = false;
  bool isSyncing = false;
  double syncPercent = 0;
  Box<Rollcal>? rollcalBox;
  List<Rollcal>? results;
  bool isSynchronized = true;

  Future<void> initBox() async {
    rollcalBox = await Hive.openBox('rollcalBox');

    final List<Rollcal>? results =
        rollcalBox?.values.where((data) => data.synced == false).toList();
    if (results!.length > 0) {
      setState(() {
        isSynchronized = false;
      });
    }
    setState(() {});
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
    initBox();
    fetchData1(context);
    connectionChecker();
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
/*
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
*/
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
                        : (allRollcalsList.length == 0)
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
                                          itemCount: allRollcalsList.length,
                                          itemBuilder: (context, index) {
                                            var item = allRollcalsList[index];
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
                                                              ' ${item['jalali_date']}  ',
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
                                                          text: (item['type'] ==
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
                                                      (item['status'] ==
                                                                  'leaving' ||
                                                              item['status'] ==
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

                                                              child: (item['status'] ==
                                                                      'leaving')
                                                                  ? Text(
                                                                      'مرخصی',
                                                                    )
                                                                  : Text(
                                                                      'ماموریت',
                                                                    ),
                                                            )
                                                          : (item['status'] ==
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
                                                                        ' ${item['time']} ',
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
                                                        if (item['description']!=
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
                                                                      ' ${item['description']} ',
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

  Future<void> fetchData1(BuildContext context) async {
    final AuthService authService = AuthService('https://afkhambpms.ir/api1');
    final token = await authService.getToken();
    setState(() {
      isLoading = true;
    });
    var connectivityResult = await Connectivity().checkConnectivity();
    rollcalBox = await Hive.openBox('rollcalBox');
    final box = Hive.box<Rollcal>('rollcalBox');
    if (connectivityResult != ConnectivityResult.none) {
      results = (await rollcalBox?.values
          .where((data) => data.synced == false)
          .toList())!;
      if (results?.length == 0) {
        await box.clear();
      try {
        final response = await http.get(
            Uri.parse('https://afkhambpms.ir/api1/personnels/get-action'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/x-www-form-urlencoded',
            });
        if (response.statusCode == 200) {
          var temp = json.decode(response.body);
          var check = await box.values.toList();
          if (check.length == 0) {
            for (var rollcalItem in temp) {
              Rollcal rollcal = Rollcal(
                status: rollcalItem['status'],
                jalali_date: rollcalItem['jalali_date'],
                time: rollcalItem['time'],
                type: rollcalItem['type'],
                description: rollcalItem['description'],
                synced: true,
              );
              box.add(rollcal);
              print('payslipBox.length');
              print(box.length);
            }
          }
          setState(() {
            allRollcalsList = json.decode(response.body);
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          throw Exception('خطا در دریافت داده ها');
        }
      } catch (e) {
        CustomNotification.show(
            context,
            'ناموفق',
            'خطا در دریافت داده ها',
            'loc');
        setState(() {
          isLoading = false;
        });
      }
      }
      else {
        for (var res in box.values.toList()
          ..sort((a, b) => b.key.compareTo(a.key))) {
          var rollcal = {
            'status': res.status,
            'jalali_date': res.jalali_date,
            'time': res.time,
            'type': res.type,
            'description': res.description,
          };
          allRollcalsList.add(rollcal);
          print(res.status);
        }
        setState(() {
          isLoading = false;
        });
      }
    } else {
      for (var res in box.values.toList()
        ..sort((a, b) => b.key.compareTo(a.key))) {
        var rollcal = {
          'status': res.status,
          'jalali_date': res.jalali_date,
          'time': res.time,
          'type': res.type,
          'description': res.description,
        };
        allRollcalsList.add(rollcal);
        print(res.status);
      }
      setState(() {
        isLoading = false;
      });
    }
  }
}

