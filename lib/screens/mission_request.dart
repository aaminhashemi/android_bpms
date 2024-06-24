import 'dart:convert';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_linear_datepicker/flutter_datepicker.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../models/mission.dart';
import '../services/action_service.dart';
import '../services/save_mission_request_service.dart';
import '../utils/custom_notification.dart';
import '../utils/standard_number_creator.dart';
import '../widgets/app_drawer.dart';
import '../utils/consts.dart';
import '../utils/exception_consts.dart';
import '../services/auth_service.dart';
import '../utils/custom_color.dart';

class MissionRequest extends StatefulWidget {
  @override
  _MissionRequestState createState() => _MissionRequestState();
}

class _MissionRequestState extends State<MissionRequest> {
  @override
  void initState() {
    super.initState();
    initBox();
    setInitialDate();
  }
  Future<void> initBox()async{
    missionBox= await Hive.openBox('missionBox');
  }
  DateTime convertTimeOfDayToDateTime(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    return DateTime(
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
  }

  bool isLoading = false;
  TextEditingController dateController = TextEditingController();
  TextEditingController originController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  TextEditingController startDateController = TextEditingController();
  TextEditingController typeController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  TextEditingController startTimeController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  TextEditingController reasonController = TextEditingController();
  Box<Mission>? missionBox;
  String leaveType = Consts.selectMissionType;
  List<String> leaveTypes = [
    Consts.selectMissionType,
    Consts.daily,
    Consts.hourly
  ];

  void clearHourFields() {
    startTime = null;
    endTime = null;
  }

  Widget buildDateFields() {
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
          ],
        )
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
        title: Text(Consts.selectStartDate),
        content: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearDatePicker(
                startDate: "1396/12/12",
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
                yearText: Consts.year,
                monthText: Consts.month,
                dayText: Consts.day,
                showLabels: true,
                columnWidth: 90,
                showMonthName: true,
                isJalaali: true,
              ),
              ElevatedButton(
                child: Text(Consts.select),
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
        title: Text(Consts.selectEndDate),
        content: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearDatePicker(
                startDate: startDateController.text,
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
                yearText: Consts.year,
                monthText: Consts.month,
                dayText: Consts.day,
                showLabels: true,
                columnWidth: 90,
                showMonthName: true,
                isJalaali: true,
              ),
              ElevatedButton(
                child: Text(Consts.select),
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
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
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
              )))
    ]);
  }

  Widget _buildOriginTextField() {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 75,
        child: Text(
          'مبدا :',
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
            controller: originController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              isDense: true,
              border: InputBorder.none,
            ),
          ),
        ),
      )
    ]);
  }

  Widget _buildDestinationTextField() {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 75,
        child: Text(
          'مقصد :',
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
          controller: destinationController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
            isDense: true,
            border: InputBorder.none,
          ),
        ),
      ))
    ]);
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
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
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
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
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
                          CustomNotification.showCustomWarning(
                              context, Consts.endTimeCantBeLessThanStartTime);
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

  Future<void> submitMissionRequest() async {
    setState(() {
      isLoading = true;
    });
    final apiUrl = 'https://afkhambpms.ir/api1/personnels/save_mission_request';
    var type = '';
    switch (leaveType) {
      case Consts.daily:
        type = 'daily';
        break;
      case Consts.hourly:
        type = 'hourly';
        break;
      default:
        type = 'choose_type';
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if(type=='hourly'){
      final missionBox = Hive.box<Mission>('missionBox');
      if (dateController.text
          .trim()
          .length > 0 && leaveType
          .trim()
          .length > 1 && startTimeController.text
          .trim()
          .length > 0 && endTimeController.text
          .trim()
          .length > 0 && reasonController.text
          .trim()
          .length > 0 && originController.text
          .trim()
          .length > 0 && destinationController.text
          .trim()
          .length > 0) {
        try {
          Mission mission = Mission(
              jalali_request_date: dateController.text.trim(),
              type: leaveType,
              level: 'درخواست',
              status: 'recorded',
              start: StandardNumberCreator.convert(
                  startTimeController.text.trim()),
              end: StandardNumberCreator.convert(endTimeController.text.trim()),
              reason: reasonController.text.trim(),
              origin: originController.text.trim(),
              destination: destinationController.text.trim(),
              description: null,
              synced: false);
          missionBox.add(mission);
          print(missionBox.length);
          setState(() {
            isLoading = false;
          });
          CustomNotification.show(context, 'موفقیت آمیز',
              'درخواست ماموریت با موفقیت ثبت شد.', '/mission-request');
        } catch (e) {
          setState(() {
            isLoading = false;
          });
          CustomNotification.show(context, 'خطا',
              'در ثبت درخواست مشکلی وجود دارد.', '/');
        }
      } else {
        setState(() {
          isLoading = false;
        });
        CustomNotification.show(context, 'خطا',
            'لطفا اطلاعات را به صورت کامل وارد کنید.', '');
      }
    }else if(type=='daily'){
        final missionBox = Hive.box<Mission>('missionBox');
        if (dateController.text
            .trim()
            .length > 0 && leaveType
            .trim()
            .length > 1 && startDateController.text
            .trim()
            .length > 0 && endDateController.text
            .trim()
            .length > 0 && reasonController.text
            .trim()
            .length > 0 && originController.text
            .trim()
            .length > 0 && destinationController.text
            .trim()
            .length > 0) {
          try {
            Mission mission = Mission(
                jalali_request_date: dateController.text.trim(),
                type: leaveType,
                level: 'درخواست',
                status: 'recorded',
                start: startDateController.text.trim(),
                end: endDateController.text.trim(),
                reason: reasonController.text.trim(),
                origin: originController.text.trim(),
                destination: destinationController.text.trim(),
                description: null,
                synced: false);
            missionBox.add(mission);
            print(missionBox.length);
            setState(() {
              isLoading = false;
            });
            CustomNotification.show(context, 'موفقیت آمیز',
                'درخواست ماموریت با موفقیت ثبت شد.', '/mission-request');
          } catch (e) {
            setState(() {
              isLoading = false;
            });
            CustomNotification.show(context, 'خطا',
                'در ثبت درخواست مشکلی وجود دارد.', '/');
          }
        } else {
          setState(() {
            isLoading = false;
          });
          CustomNotification.show(context, 'خطا',
              'لطفا اطلاعات را به صورت کامل وارد کنید.', '');
        }
      }else{
        setState(() {
          isLoading = false;
        });
        CustomNotification.show(context, 'خطا',
            'لطفا اطلاعات را به صورت کامل وارد کنید.', '');
      }
      }
    else{
    SaveMissionRequestService saveMissionRequestService =
    SaveMissionRequestService(apiUrl);
    try {
      final response = await saveMissionRequestService.saveMissionRequest(
          dateController.text.trim(),
          startDateController.text.trim(),
          endDateController.text.trim(),
          StandardNumberCreator.convert(startTimeController.text.trim()),
          StandardNumberCreator.convert(endTimeController.text.trim()),
          originController.text.trim(),
          destinationController.text.trim(),
          reasonController.text.trim(),
          type);

      if (response['status'] == 'successful') {
        final missionBox = Hive.box<Mission>('missionBox');

        Mission mission=Mission(
            jalali_request_date: dateController.text.trim(),
            type: type,
            level: response['mission']['level'],
            status: 'recorded',
            start: StandardNumberCreator.convert(startTimeController.text.trim()),
            end: StandardNumberCreator.convert(endTimeController.text.trim()),
            reason: reasonController.text.trim(),
            origin: originController.text.trim(),
            destination: destinationController.text.trim(),
            description: null,
            synced: true);
        missionBox.add(mission);
        print(response['mission']['level']);
        CustomNotification.show(context, 'موفقیت آمیز',
            'درخواست ماموریت با موفقیت ثبت شد.', '/mission-request');
      } else if (response['status'] == 'imperfect_data') {
        CustomNotification.show(
            context, 'خطا', 'لطفا اطلاعات را به صورت کامل وارد کنید.', '');
      } else {
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
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: CustomColor.drawerBackgroundColor),
        title: Text(Consts.missionRequest,
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
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(
                              Consts.missionRequest,
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
                                      'نوع ماموریت :',
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
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: leaveType,
                                                onChanged: (newValue) {
                                                  setState(() {
                                                    leaveType = newValue!;
                                                    clearHourFields();
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
                                                          EdgeInsets.symmetric(
                                                              horizontal: 16.0,
                                                              vertical: 12.0),
                                                      child: Text(
                                                        type,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                ),
                                                isExpanded: true,
                                                icon:
                                                    Icon(Icons.arrow_drop_down),
                                                elevation: 3,
                                                underline: Container(
                                                  height: 0,
                                                  color: Colors.transparent,
                                                ),
                                              ),
                                            ),
                                          )))
                                ]),
                            (leaveType != Consts.selectMissionType)
                                ? (leaveType == Consts.daily
                                    ? buildDateFields()
                                    : buildHourFields())
                                : removeFields(),
                            SizedBox(height: 16.0),
                            _buildOriginTextField(),
                            SizedBox(height: 16.0),
                            _buildDestinationTextField(),
                            SizedBox(height: 16.0),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                              ))))
                                ]),
                            SizedBox(height: 24.0),
                            ElevatedButton(
                              onPressed:
                                  isLoading ? null : submitMissionRequest,
                              child: isLoading
                                  ? CircularProgressIndicator()
                                  : Text(Consts.save,
                                      style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      10.0),
                                ),
                                minimumSize: const Size(double.infinity, 48),
                                primary: CustomColor.successColor,
                              ),
                            ),
                          ])))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AllMissions extends StatefulWidget {
  @override
  _AllMissionsListState createState() => _AllMissionsListState();
}

class _AllMissionsListState extends State<AllMissions> {
  List<dynamic> allMissionsList = [];
  bool isLoading = true;
  late List<bool> _isExpandedList =
      List.generate(allMissionsList.length, (index) => false);
  Box<Mission>? missionBox;
  List<Mission>? results;
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
  void SendListToServer() async {
    setState(() {
      isSyncing = true;
    });
    const apiUrl = 'https://afkhambpms.ir/api1/personnels/save_mission_request';
    SaveMissionRequestService saveMissionRequestService = SaveMissionRequestService(apiUrl);
    final List<Mission>? results =
    missionBox?.values.where((data) => data.synced == false).toList();
    double percent = 0;
    if (results!.isNotEmpty) {
      percent = 1 / (results!.length);
    }
    if (results.isNotEmpty) {
      for (var result in results) {
        print(result.key);
        print(missionBox!.get(result.key));
        print('result.type');
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
          print(type);
          print(result.origin);
          print(result.destination);
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
          print(response['status']);
          print("response['status']");
          if (response['status'] == 'successful') {
            
            try{
              Mission mission = Mission(
                jalali_request_date: result.jalali_request_date,
                type:result.type,
                level:response['mission']['level'],
                status:response['mission']['status'],
                start:result.start,
                end:result.end,
                origin:result.origin,
                destination:result.destination,
                reason:result.reason,
                description:null,
                synced:true,
              );
              missionBox?.put(result.key, mission);
            }catch(e){
              print('err');
              print(e.toString());
            }
            setState(() {
              syncPercent = syncPercent + percent;
            });
          }

        } catch (e) {
          CustomNotification.show(context, 'ناموفق', e.toString(), '');
        }finally{
          allMissionsList=[];
          print(missionBox);
          for (var res in missionBox!.values.toList()) {
            var mission = {
              'jalali_request_date': res.jalali_request_date,
              'type':res.type,
              'level':res.level,
              'status':res.status,
              'start':res.start,
              'end':res.end,
              'origin':res.origin,
              'destination':res.end,
              'reason':res.reason,
              'description':res.description,
            };
            allMissionsList.add(mission);
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

  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          Navigator.pushReplacementNamed(context, '/main');
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: CustomColor.drawerBackgroundColor),
            title: Text(Consts.missionsList,
                style: TextStyle(color: CustomColor.textColor)),
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
              :Column(
            children: [
              Container(
                color: CustomColor.backgroundColor,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    width: double.infinity,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      color: CustomColor.buttonColor,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MissionRequest(),
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
                                  Consts.missionRequest,
                                  style: TextStyle(
                                      color: CustomColor.backgroundColor,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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
                  : (allMissionsList.isEmpty)
                      ? Expanded(
                          child: Center(
                          child: Text(
                            'ماموریت یافت نشد!',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ))
                      : Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 15),
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 16.0),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: allMissionsList.length,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    var mission = allMissionsList[index];
                                    return Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      elevation: 4.0,
                                      color: CustomColor.backgroundColor,
                                      margin: EdgeInsets.only(
                                          left: 16, right: 16, top: 12),
                                      child: ExpansionTile(
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
                                              text: '${Consts.requestDate}  :',
                                              style: TextStyle(
                                                  fontFamily: 'irs',
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: CustomColor.textColor),
                                            ),
                                            TextSpan(
                                              text:
                                                  ' ${mission['jalali_request_date']}  ',
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
                                              text: '${Consts.missionType}  :',
                                              style: TextStyle(
                                                  fontFamily: 'irs',
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: CustomColor.textColor),
                                            ),
                                            TextSpan(
                                              text: ' ${mission['type']}  ',
                                              style: TextStyle(
                                                  fontFamily: 'irs',
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.normal,
                                                  color: CustomColor.textColor),
                                            ),
                                          ]),
                                        ),
                                        trailing: InkWell(
                                          child: (mission['status'] ==
                                                  'recorded')
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
                                                    '${mission['level']}',
                                                    style: TextStyle(
                                                        color: CustomColor
                                                            .textColor),
                                                  ),
                                                )
                                              : (mission['status'] ==
                                                      'accepted')
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
                                                        '${mission['level']}',
                                                        style: TextStyle(
                                                            color: CustomColor
                                                                .textColor),
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
                                                          '${mission['level']}',
                                                          style: TextStyle(
                                                              color: CustomColor
                                                                  .textColor)),
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
                                                              text:
                                                                  '${Consts.start}  :',
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
                                                                  ' ${mission['start']}  ',
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
                                                          ]),
                                                    ),
                                                    Spacer(),
                                                    RichText(
                                                      text: TextSpan(
                                                          children: <TextSpan>[
                                                            TextSpan(
                                                              text:
                                                                  '${Consts.end}  :',
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
                                                                  ' ${mission['end']}  ',
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
                                                          ]),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    RichText(
                                                      text: TextSpan(
                                                          children: <TextSpan>[
                                                            TextSpan(
                                                              text:
                                                                  'مبدا  :',
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
                                                                  ' ${mission['origin']}  ',
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
                                                          ]),
                                                    ),
                                                    Spacer(),
                                                    RichText(
                                                      text: TextSpan(
                                                          children: <TextSpan>[
                                                            TextSpan(
                                                              text:
                                                                  'مقصد  :',
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
                                                                  ' ${mission['destination']}  ',
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
                                                          ]),
                                                    ),
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
                                                                text:
                                                                    '${Consts.description}  :',
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
                                                                    ' ${mission['reason']}  ',
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
                                                            ]),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (mission['description'] !=
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
                                                                      '${Consts.SuperiorDescription}  :',
                                                                  style: TextStyle(
                                                                      fontFamily:
                                                                          'irs',
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: CustomColor
                                                                          .textColor),
                                                                ),
                                                                TextSpan(
                                                                  text:
                                                                      ' ${mission['description']}  ',
                                                                  style: TextStyle(
                                                                      fontFamily:
                                                                          'irs',
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      color: CustomColor
                                                                          .textColor),
                                                                ),
                                                              ]),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
            ],
          ),
        ));
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

  Future<void> initBox() async {
    missionBox = await Hive.openBox('missionBox');
    final List<Mission>? results =
        missionBox?.values.where((data) => data.synced == false).toList();
    if (results!.length > 0) {
      setState(() {
        isSynchronized = false;
      });
    }
    setState(() {});
  }

  Future<void> fetchData(BuildContext context) async {
    final AuthService authService = AuthService('https://afkhambpms.ir/api1');
    final token = await authService.getToken();
    setState(() {
      isLoading = true;
    });
    missionBox = await Hive.openBox('missionBox');
    var connectivityResult = await Connectivity().checkConnectivity();
    final box = Hive.box<Mission>('missionBox');
    if (connectivityResult != ConnectivityResult.none) {
      results = await missionBox?.values
          .where((data) => data.synced == false)
          .toList();
      if (results?.length == 0) {
        await box.clear();
        try {
          final response = await http.get(
              Uri.parse('https://afkhambpms.ir/api1/personnels/get-mission'),
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
                Mission mission = Mission(
                  jalali_request_date: leving['jalali_request_date'],
                  type: leving['type'],
                  level: leving['level'],
                  status: leving['status'],
                  start: leving['start'],
                  end: leving['end'],
                  reason: leving['reason'],
                  origin: leving['origin'],
                  destination: leving['destination'],
                  description: leving['description'],
                  synced: true,
                );
                box.add(mission);
                print('payslipBox.length');
                print(box.length);
              }
            }
            setState(() {
              allMissionsList = json.decode(response.body);
              isLoading = false;
            });

          } else {
            setState(() {
              isLoading = false;
            });
            throw Exception(Exception_consts.dataFetchError);
          }
        } catch (e) {
          CustomNotification.show(
              context,
              'ناموفق',
              'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.',
              'mission-request');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        for (var res in box.values.toList()
          ..sort((a, b) => b.key.compareTo(a.key))) {
          var mission = {
            'jalali_request_date': res.jalali_request_date,
            'type': res.type,
            'level': res.level,
            'status': res.status,
            'start': res.start,
            'end': res.end,
            'origin': res.origin,
            'destination': res.destination,
            'reason': res.reason,
            'description': res.description,
          };
          allMissionsList.add(mission);
        }
        setState(() {
          isLoading = false;
        });
      }
    } else {
      for (var res in box.values.toList()
        ..sort((a, b) => b.key.compareTo(a.key))) {
        var mission = {
          'jalali_request_date': res.jalali_request_date,
          'type': res.type,
          'level': res.level,
          'status': res.status,
          'start': res.start,
          'end': res.end,
          'origin': res.origin,
          'destination': res.destination,
          'reason': res.reason,
          'description': res.description,
        };
        allMissionsList.add(mission);
      }
      setState(() {
        isLoading = false;
      });
    }
  }
}

void main() {
  runApp(MaterialApp(
    home: AllMissions(),
  ));
}
