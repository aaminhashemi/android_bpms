import 'dart:convert';
import 'dart:ui';
import 'package:afkham/models/leaving.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_linear_datepicker/flutter_datepicker.dart';
import '../services/action_service.dart';
import '../utils/custom_notification.dart';
import '../utils/standard_number_creator.dart';
import '../utils/custom_color.dart';
import '../widgets/app_drawer.dart';
import '../services/auth_service.dart';
import '../services/save_leave_request_service.dart';

class AllLeaves extends StatefulWidget {
  @override
  _AllLeaveListState createState() => _AllLeaveListState();
}

class _AllLeaveListState extends State<AllLeaves> {
  List<dynamic> allLeavelList = [];
  bool isLoading = true;
  Box<Leaving>? leavingBox;
  List<Leaving>? results;
  late List<bool> _isExpandedList =
  List.generate(allLeavelList.length, (index) => false);
  bool isSynchronized = true;
  bool isSyncing = false;
  bool isConnected = false;
  double syncPercent = 0;

  @override
  void initState() {
    super.initState();
    initBox();
    fetchData(context);
    connectionChecker();
  }

  Future<void> initBox() async {
    leavingBox = await Hive.openBox('leavingBox');
    final List<Leaving>? results =
    leavingBox?.values.where((data) => data.synced == false).toList();
    if (results!.length > 0) {
      setState(() {
        isSynchronized = false;
      });
    }
    setState(() {});
    print(isSynchronized);
    print('object');
  }
  void SendListToServer() async {
    setState(() {
      isSyncing = true;
    });
    const apiUrl = 'https://afkhambpms.ir/api1/personnels/save_leaving_request';
    SaveLeaveRequestService saveLeaveRequestService = SaveLeaveRequestService(apiUrl);
    final List<Leaving>? results =
    leavingBox?.values.where((data) => data.synced == false).toList();
    double percent = 0;
    if (results!.isNotEmpty) {
      percent = 1 / (results!.length);
    }
    if (results.isNotEmpty) {
      for (var result in results) {
        print(result.key);
        print(leavingBox!.get(result.key));
        print('result.period');
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
          print(response['status']);
          print("response['status']");
          if (response['status'] == 'successful') {
            try{
              Leaving leaving = Leaving(
                jalali_request_date: result.jalali_request_date,
                period:result.period,
                status:response['leaving']['status'],
                level:response['leaving']['level'],
                type:result.type,
                start:result.start,
                end:result.end,
                reason:result.reason,
                description:result.description,
                synced:true,
              );
              leavingBox?.put(result.key, leaving);
            }catch(e){
              print('err');
            }
            setState(() {
              syncPercent = syncPercent + percent;
            });
          }

        } catch (e) {
          CustomNotification.show(context, 'ناموفق',  'در ثبت درخواست مشکلی وجود دارد.', '');
        }finally{
          allLeavelList=[];
          print(leavingBox);
          for (var res in leavingBox!.values.toList()) {
            var leaving = {
              'jalali_request_date': res.jalali_request_date,
              'period':res.period,
              'status':res.status,
              'level':res.level,
              'type':res.type,
              'start':res.start,
              'end':res.end,
              'reason':res.reason,
              'description':res.description,
            };
            allLeavelList.add(leaving);
            print(res.synced);
          }
        }
      }
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        isSyncing = false;
        isSynchronized = true;
      });
    }
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
    print(isConnected);
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
          title: Text('مرخصی', style: TextStyle(color: CustomColor.textColor)),
        ),
        drawer: AppDrawer(),
        body: (isSyncing)?
        Center(
          child:  Stack(
            children: [
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
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: syncPercent,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
            :
        Column(
          children: [
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
                              builder: (context) => LeaveRequest(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'درخواست مرخصی جدید',
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
            (!isSynchronized && isConnected)
                ? ElevatedButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
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
                  Icon(Icons.update),
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
                : (allLeavelList.isEmpty)
                ? Expanded(
                child: Center(
                  child: Text(
                    'درخواست مرخصی یافت نشد!',
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
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: allLeavelList.length,
                          itemBuilder: (context, index) {
                            var leave = allLeavelList[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              elevation: 4.0,
                              color: CustomColor.backgroundColor,
                              margin: EdgeInsets.only(
                                  left: 16, right: 16, top: 12),
                              child: ExpansionTile(
                                backgroundColor:
                                CustomColor.backgroundColor,
                                onExpansionChanged: (isExpanded) {
                                  setState(() {
                                    _isExpandedList[index] = isExpanded;
                                  });
                                },
                                leading: _isExpandedList[index]
                                    ? Icon(Icons.keyboard_arrow_up,
                                    color: CustomColor
                                        .drawerBackgroundColor)
                                    : Icon(Icons.keyboard_arrow_down,
                                    color: CustomColor
                                        .drawerBackgroundColor),
                                shape: LinearBorder.none,
                                title: RichText(
                                  text: TextSpan(children: <TextSpan>[
                                    TextSpan(
                                      text: 'تاریخ درخواست :',
                                      style: TextStyle(
                                          fontFamily: 'irs',
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                          color: CustomColor.textColor),
                                    ),
                                    TextSpan(
                                      text:
                                      ' ${leave['jalali_request_date']}  ',
                                      style: TextStyle(
                                          fontFamily: 'irs',
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.normal,
                                          color: CustomColor.textColor),
                                    ),
                                  ]),
                                ),
                                subtitle: RichText(
                                  text: TextSpan(children: <TextSpan>[
                                    TextSpan(
                                      text: 'دوره :',
                                      style: TextStyle(
                                          fontFamily: 'irs',
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                          color: CustomColor.textColor),
                                    ),
                                    TextSpan(
                                      text: ' ${leave['period']}  ',
                                      style: TextStyle(
                                          fontFamily: 'irs',
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.normal,
                                          color: CustomColor.textColor),
                                    ),
                                  ]),
                                ),
                                trailing: InkWell(
                                  child: (leave['status'] == 'recorded')
                                      ? Container(
                                    padding: EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color:
                                      CustomColor.cardColor,
                                      borderRadius:
                                      BorderRadius.circular(
                                          10.0),
                                    ),
                                    child: Text(
                                      '${leave['level']}',
                                    ),
                                  )
                                      : (leave['status'] == 'accepted')
                                      ? Container(
                                    padding:
                                    EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: CustomColor
                                          .successColor,
                                      borderRadius:
                                      BorderRadius
                                          .circular(10.0),
                                    ),
                                    child: Text(
                                      '${leave['level']}',
                                    ),
                                  )
                                      : Container(
                                    padding:
                                    EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: CustomColor
                                          .dangerColor,
                                      borderRadius:
                                      BorderRadius
                                          .circular(10.0),
                                    ),
                                    child: Text(
                                      '${leave['level']}',
                                    ),
                                  ),
                                ),
                                children: <Widget>[
                                  Container(
                                    color: CustomColor.cardColor,
                                    padding: EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            RichText(
                                                text: TextSpan(
                                                    children: <TextSpan>[
                                                      TextSpan(
                                                        text: 'نوع :',
                                                        style: TextStyle(
                                                            fontFamily:
                                                            'irs',
                                                            fontSize: 12.0,
                                                            fontWeight:
                                                            FontWeight
                                                                .bold,
                                                            color: CustomColor
                                                                .textColor),
                                                      ),
                                                      TextSpan(
                                                        text:
                                                        ' ${leave['type']}  ',
                                                        style: TextStyle(
                                                            fontFamily:
                                                            'irs',
                                                            fontWeight:
                                                            FontWeight
                                                                .normal,
                                                            fontSize: 12.0,
                                                            color: CustomColor
                                                                .textColor),
                                                      ),
                                                    ])),
                                            Spacer()
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            RichText(
                                                text: TextSpan(
                                                    children: <TextSpan>[
                                                      TextSpan(
                                                        text: 'شروع :',
                                                        style: TextStyle(
                                                            fontFamily:
                                                            'irs',
                                                            fontSize: 12.0,
                                                            fontWeight:
                                                            FontWeight
                                                                .bold,
                                                            color: CustomColor
                                                                .textColor),
                                                      ),
                                                      TextSpan(
                                                        text:
                                                        ' ${leave['start']}  ',
                                                        style: TextStyle(
                                                            fontFamily:
                                                            'irs',
                                                            fontSize: 12.0,
                                                            fontWeight:
                                                            FontWeight
                                                                .normal,
                                                            color: CustomColor
                                                                .textColor),
                                                      ),
                                                    ])),
                                            Spacer(),
                                            RichText(
                                                text: TextSpan(
                                                    children: <TextSpan>[
                                                      TextSpan(
                                                        text: 'پایان :',
                                                        style: TextStyle(
                                                            fontFamily:
                                                            'irs',
                                                            fontSize: 12.0,
                                                            fontWeight:
                                                            FontWeight
                                                                .bold,
                                                            color: CustomColor
                                                                .textColor),
                                                      ),
                                                      TextSpan(
                                                        text:
                                                        ' ${leave['end']}  ',
                                                        style: TextStyle(
                                                            fontFamily:
                                                            'irs',
                                                            fontSize: 12.0,
                                                            fontWeight:
                                                            FontWeight
                                                                .normal,
                                                            color: CustomColor
                                                                .textColor),
                                                      ),
                                                    ]))
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.start,
                                          children: [
                                            Expanded(
                                                child: RichText(
                                                    text: TextSpan(
                                                        children: <TextSpan>[
                                                          TextSpan(
                                                            text: 'توضیحات :',
                                                            style: TextStyle(
                                                                fontFamily:
                                                                'irs',
                                                                fontSize: 12.0,
                                                                fontWeight:
                                                                FontWeight
                                                                    .bold,
                                                                color: CustomColor
                                                                    .textColor),
                                                          ),
                                                          TextSpan(
                                                            text:
                                                            ' ${leave['reason']}  ',
                                                            style: TextStyle(
                                                                fontFamily:
                                                                'irs',
                                                                fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                                fontSize: 12.0,
                                                                color: CustomColor
                                                                    .textColor),
                                                          ),
                                                        ]))),
                                          ],
                                        ),
                                        if (leave['description'] !=
                                            null)
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                  child: RichText(
                                                      text: TextSpan(
                                                          children: <TextSpan>[
                                                            TextSpan(
                                                              text:
                                                              'توضیحات سرپرست :',
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
                                                              ' ${leave['description']}  ',
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
                                ],
                              ),
                            );
                          },
                        )))),
          ],
        ),
      ),
    );
  }

  Future<void> fetchData(BuildContext context) async {
    final AuthService authService = AuthService('https://afkhambpms.ir/api1');
    final token = await authService.getToken();
    setState(() {
      isLoading = true;
    });
    leavingBox = await Hive.openBox('leavingBox');
    var connectivityResult = await Connectivity().checkConnectivity();
    final box = Hive.box<Leaving>('leavingBox');
    if (connectivityResult != ConnectivityResult.none) {
      results = await leavingBox?.values
          .where((data) => data.synced == false)
          .toList();
      if (results?.length == 0) {
        await box.clear();

      try {
        final response = await http.get(
            Uri.parse('https://afkhambpms.ir/api1/personnels/get-leave'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/x-www-form-urlencoded',
            });

        if (response.statusCode == 200) {
          var temp = json.decode(response.body);
          var check = await box.values.toList();
          if (check.length == 0) {
            for (var leving in temp) {
              print(leving);

              Leaving leaving = Leaving(
                jalali_request_date: leving['jalali_request_date'],
                period: leving['period'],
                status: leving['status'],
                level: leving['level'],
                type: leving['type'],
                start: leving['start'],
                end: leving['end'],
                reason: leving['reason'],
                description: leving['description'],
                synced: true,
              );
              box.add(leaving);
              print('payslipBox.length');
              print(box.length);
            }
          }
          setState(() {
            allLeavelList = json.decode(response.body);
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
            'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.',
            'leave-request');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }else{
      print(box);
      for (var res in box.values.toList()..sort((a, b) => b.key.compareTo(a.key))) {
        var leaving = {
          'jalali_request_date': res.jalali_request_date,
          'period': res.period,
          'status':res.status,
          'level': res.level,
          'type': res.type,
          'start': res.start,
          'end': res.end,
          'reason': res.reason,
          'description': res.description,
        };
        allLeavelList.add(leaving);
        print(res.status);
      }
      setState(() {
        isLoading = false;
      });
    }
    }
    else{
      print(box);
      for (var res in box.values.toList()..sort((a, b) => b.key.compareTo(a.key))) {
        var leaving = {
          'jalali_request_date': res.jalali_request_date,
          'period': res.period,
          'status':res.status,
          'level': res.level,
          'type': res.type,
          'start': res.start,
          'end': res.end,
          'reason': res.reason,
          'description': res.description,
        };
        allLeavelList.add(leaving);
        print(res.status);
      }
      setState(() {
        isLoading = false;
      });
    }
  }
}
class LeaveRequest extends StatefulWidget {
  @override
  _LeaveRequestState createState() => _LeaveRequestState();
}

class _LeaveRequestState extends State<LeaveRequest> {
  @override
  void initState() {
    super.initState();
    setInitialDate();
    initBox();
  }

  Future<void> initBox()async{
    leavingBox= await Hive.openBox('leavingBox');
  }
  DateTime convertTimeOfDayToDateTime(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    return DateTime(
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
  }

  bool isLoading = false;

  TextEditingController dateController = TextEditingController();
  TextEditingController startDateController = TextEditingController();
  TextEditingController typeController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  TextEditingController startTimeController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  TextEditingController reasonController = TextEditingController();
  Box<Leaving>? leavingBox;
  String leavePeriod = 'انتخاب دوره مرخصی';
  List<String> leavePeriods = ['انتخاب دوره مرخصی', 'روزانه', 'ساعتی'];

  String leaveType = 'انتخاب نوع مرخصی';
  List<String> leaveTypes = [
    'انتخاب نوع مرخصی',
    'استحقاقی',
    'استعلاجی',
    'بدون حقوق'
  ];

  void clearHourFields() {
    startTime = null;
    endTime = null;
  }

  Widget buildDateFields() {
    startTimeController.text = '';
    endTimeController.text = '';
    return Column(
      children: [
        SizedBox(height: 16.0),
        Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 75,
                child: Text(
                  'تاریخ شروع :',
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
                                color: CustomColor.textColor, width: 4.0)),
                      ),
                      child: TextField(
                        controller: startDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          isDense: true,
                          border: InputBorder.none,
                        ),
                        onTap: () {
                          showStartDateDialog(context, startDateController);
                        },
                      )))
            ]),
        SizedBox(height: 16.0),
        Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 75,
                child: Text(
                  'تاریخ پایان :',
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
                                color: CustomColor.textColor, width: 4.0)),
                      ),
                      child: TextField(
                        controller: endDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          isDense: true,
                          border: InputBorder.none,
                        ),
                        onTap: () {
                          showEndDateDialog(context, endDateController);
                        },
                      )))
            ]),
      ],
    );
  }

  void showStartDateDialog(BuildContext context, controller) {
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
                startDate: "1402/10/01",
                endDate: endDateController.text,
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

  void setInitialDate() {
    DateTime dt = DateTime.now();
    Jalali j = dt.toJalali();
    final f = j.formatter;
    dateController.text = '${f.yyyy}/${f.mm}/${f.dd}';
  }

  void showEndDateDialog(BuildContext context, controller) {
    DateTime dt = DateTime.now();
    Jalali j = dt.toJalali();
    final f = j.formatter;
    String selected = '${f.yyyy}/${f.mm}/${f.dd}';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('انتخاب تاریخ پایان',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
        content: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearDatePicker(
                startDate: startDateController.text,
                endDate: "1412/10/01",
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

  int timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  Widget _buildDateTextField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 75,
          child: Text(
            'تاریخ درخواست :',
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
            ),
          ),
        ),
      ],
    );
    return TextField(
      controller: dateController,
      decoration: InputDecoration(
        labelText: 'تاریخ درخواست',
        border: OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(12.0),
      ),
    );
  }

  Widget removeFields() {
    startDateController.text = '';
    endDateController.text = '';
    startTimeController.text = '';
    endTimeController.text = '';
    return (Column());
  }

  Widget buildHourFields() {
    startDateController.text = '';
    endDateController.text = '';
    return Column(
      children: [
        SizedBox(height: 16.0),
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
                                color: CustomColor.textColor, width: 4.0)),
                      ),
                      child: TextField(
                        controller: startTimeController,
                        readOnly: true,
                        onTap: () async {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: startTime ?? TimeOfDay.now(),
                          );
                          setState(() {
                            startTime = pickedTime;
                            startTimeController.text =
                                MaterialLocalizations.of(context)
                                    .formatTimeOfDay(pickedTime!);
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      )))
            ]),
        SizedBox(height: 16.0),
        Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 75,
                child: Text(
                  'ساعت پایان :',
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
                                color: CustomColor.textColor, width: 4.0)),
                      ),
                      child: TextField(
                        controller: endTimeController,
                        readOnly: true,
                        onTap: () async {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: startTime ?? TimeOfDay.now(),
                          );
                          setState(() {
                            endTime = pickedTime;
                            int minutesStart = timeOfDayToMinutes(startTime!);
                            int minutesEnd = timeOfDayToMinutes(endTime!);

                            if (minutesStart > minutesEnd) {
                              CustomNotification.showCustomWarning(context,
                                  'زمان پایان نمی تواند زودتر از زمان شروع باشد.');
                              endTimeController.text = '';
                            } else {
                              endTimeController.text =
                                  MaterialLocalizations.of(context)
                                      .formatTimeOfDay(pickedTime!);
                            }
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      )))
            ])
      ],
    );
  }

  Future<void> submitLeaveRequest() async {
    setState(() {
      isLoading = true;
    });
    final apiUrl = 'https://afkhambpms.ir/api1/personnels/save_leaving_request';
    var period = '';
    switch (leavePeriod) {
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
    print(leaveType);
    switch (leaveType) {
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
        type = '';
    }
    List<String> validTypes = ['deserved', 'sickness', 'without_salary'];

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if(period=='hourly'){
        final leavingBox = Hive.box<Leaving>('leavingBox');
      if (dateController.text.trim().length > 0 &&
          leaveType.trim().length > 1 &&
          validTypes.contains(type) &&
          startTimeController.text.trim().length > 0 &&
          endTimeController.text.trim().length > 0 &&
          reasonController.text.trim().length > 0 &&
          leavePeriod.trim().length > 0 ) {
      try {
        Leaving leaving = Leaving(
            jalali_request_date: dateController.text.trim(),
            period: leavePeriod,
            status: 'recorded',
            level: 'درخواست',
            type: leaveType,
            start: StandardNumberCreator.convert(
                startTimeController.text.trim()),
            end: StandardNumberCreator.convert(endTimeController.text.trim()),
            reason: reasonController.text.trim(),
            description: null,
            synced: false);
        leavingBox.add(leaving);
        print(leavingBox.length);
        setState(() {
          isLoading = false;
        });
        CustomNotification.show(context, 'موفقیت آمیز',
            'درخواست مرخصی با موفقیت ثبت شد.', '/leave-request');
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        CustomNotification.show(context, 'خطا',
            'در ثبت درخواست مشکلی وجود دارد.', '/');
      }
    }else {
        setState(() {
          isLoading = false;
        });
        CustomNotification.show(context, 'خطا',
            'لطفا اطلاعات را به صورت کامل وارد کنید.', '');
      }
    }else if(period=='daily'){
        final leavingBox = Hive.box<Leaving>('leavingBox');
        if (dateController.text.trim().length > 0 &&
            leaveType.trim().length > 1 &&
            validTypes.contains(type) &&
            startDateController.text.trim().length > 0 &&
            endDateController.text.trim().length > 0 &&
            reasonController.text.trim().length > 0 &&
            leavePeriod.trim().length > 0 ) {
          try {
            Leaving leaving = Leaving(
                jalali_request_date: dateController.text.trim(),
                period: leavePeriod,
                status: 'recorded',
                level: 'درخواست',
                type: leaveType,
                start: startDateController.text.trim(),
                end: endDateController.text.trim(),
                reason: reasonController.text.trim(),
                description: null,
                synced: false);
            leavingBox.add(leaving);
            print(leavingBox.length);
            setState(() {
              isLoading = false;
            });
            CustomNotification.show(context, 'موفقیت آمیز', 'درخواست مرخصی با موفقیت ثبت شد.', '/leave-request');
          } catch (e) {
            setState(() {
              isLoading = false;
            });
            CustomNotification.show(context, 'خطا', 'در ثبت درخواست مشکلی وجود دارد.', '/');
          }
        } else {
          setState(() {
            isLoading = false;
          });
          CustomNotification.show(context, 'خطا', 'لطفا اطلاعات را به صورت کامل وارد کنید.', '');
        }
      }else{
        setState(() {
          isLoading = false;
        });
        CustomNotification.show(context, 'خطا', 'لطفا اطلاعات را به صورت کامل وارد کنید.', '');
      }}else{
      SaveLeaveRequestService saveLeaveRequestService =
      SaveLeaveRequestService(apiUrl);
      try {
        final response = await saveLeaveRequestService.saveLeaveRequest(
            dateController.text.trim(),
            startDateController.text.trim(),
            endDateController.text.trim(),
            StandardNumberCreator.convert(startTimeController.text.trim()),
            StandardNumberCreator.convert(endTimeController.text.trim()),
            reasonController.text.trim(),
            period,
            type);
        if (response['status'] == 'successful') {
            final leavingBox = Hive.box<Leaving>('leavingBox');

            Leaving leaving=Leaving(
                jalali_request_date: dateController.text.trim(),
                period: period,
                status: 'recorded',
                level: response['leaving']['level'],
                type: type,
                start: StandardNumberCreator.convert(startTimeController.text.trim()),
                end: StandardNumberCreator.convert(endTimeController.text.trim()),
                reason: reasonController.text.trim(),
                description: null,
                synced: true);
            leavingBox.add(leaving);
print(response['leaving']['level']);

          CustomNotification.show(context, 'موفقیت آمیز',
              'درخواست مرخصی با موفقیت ثبت شد.', '/leave-request');
        } else if (response['status'] == 'imperfect_data') {
          CustomNotification.show(
              context, 'خطا', 'لطفا اطلاعات را به صورت کامل وارد کنید.', '');
        } else {
          print(response);
          CustomNotification.show(
              context, 'ناموفق', 'در ثبت درخواست مشکلی وجود دارد.', '');
        }
      } catch (e) {
        CustomNotification.show(context, 'ناموفق',
            'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.', '');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
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
            iconTheme: IconThemeData(color: CustomColor.drawerBackgroundColor),
            title:
                Text('مرخصی', style: TextStyle(color: CustomColor.textColor)),
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'درخواست مرخصی',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              SizedBox(height: 16.0),
                              _buildDateTextField(),
                              SizedBox(height: 16.0),
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 75,
                                      child: Text(
                                        'دوره مرخصی :',
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
                                                color: CustomColor.textColor,
                                                width: 4.0)),
                                      ),
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: EdgeInsets.only(
                                              right: 8, left: 8),
                                          isDense: true,
                                          border: InputBorder.none,
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: leavePeriod,
                                            onChanged: (newValue) {
                                              setState(() {
                                                leavePeriod = newValue!;
                                                clearHourFields();
                                              });
                                            },
                                            iconEnabledColor: CustomColor
                                                .drawerBackgroundColor,
                                            items: leavePeriods.map((period) {
                                              return DropdownMenuItem<String>(
                                                value: period,
                                                child: Container(
                                                  width: double.infinity,
                                                  padding: EdgeInsets.only(
                                                      right: 8, left: 8),
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
                                            icon: Icon(Icons.arrow_drop_down),
                                            elevation: 3,
                                          ),
                                        ),
                                      ),
                                    ))
                                  ]),
                              SizedBox(height: 16.0),
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 75,
                                      child: Text(
                                        'نوع مرخصی :',
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
                                                contentPadding: EdgeInsets.only(
                                                    right: 8, left: 8),
                                                isDense: true,
                                                border: InputBorder.none,
                                              ),
                                              child:
                                                  DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value: leaveType,
                                                  onChanged: (newValue) {
                                                    setState(() {
                                                      leaveType = newValue!;
                                                    });
                                                  },
                                                  iconEnabledColor: CustomColor
                                                      .drawerBackgroundColor,
                                                  items: leaveTypes.map((type) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: type,
                                                      child: Container(
                                                        width: double.infinity,
                                                        padding:
                                                            EdgeInsets.only(
                                                                right: 1,
                                                                left: 1),
                                                        child: Text(type,
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
                                              ),
                                            )))
                                  ]),
                              (leavePeriod != 'انتخاب دوره مرخصی')
                                  ? (leavePeriod == 'روزانه'
                                      ? buildDateFields()
                                      : buildHourFields())
                                  : removeFields(),
                              SizedBox(height: 16.0),
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 75,
                                      child: Text(
                                        'علت :',
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
                                              controller: reasonController,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.white,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        vertical: 8),
                                                isDense: true,
                                                border: InputBorder.none,
                                              ),
                                              maxLines: 3,
                                              style: TextStyle(
                                                fontFamily: 'irs',
                                              ),
                                            )))
                                  ]),
                              SizedBox(height: 24.0),
                              ElevatedButton(
                                onPressed:
                                    isLoading ? null : submitLeaveRequest,
                                child: isLoading
                                    ? CircularProgressIndicator()
                                    : Text(
                                        'ثبت',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        10.0),
                                  ),
                                  minimumSize: const Size(double.infinity, 48),
                                  primary: CustomColor.buttonColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: AllLeaves(),
  ));
}
