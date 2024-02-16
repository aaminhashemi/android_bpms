import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_linear_datepicker/flutter_datepicker.dart';
import 'package:shamsi_date/shamsi_date.dart';
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
    setInitialDate();
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
        TextField(
          controller: startDateController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: Consts.startDate,
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12.0),
          ),
          onTap: () {
            showStartDateDialog(context, startDateController);
          },
        ),
        SizedBox(height: 16.0),
        TextField(
          controller: endDateController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: Consts.endDate,
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12.0),
          ),
          onTap: () {
            showEndDateDialog(context, endDateController);
          },
        ),
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
                initialDate: "1397/05/05",
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
                endDate: "1398/01/14",
                initialDate: "1397/05/05",
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
      print(response);
      if (response['status'] == 'successful') {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Consts.missionRequest,style: TextStyle(color: CustomColor.textColor)),
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
                                      10.0), // Adjust the radius as needed
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

  @override
  void initState() {
    super.initState();
    fetchData(context);
  }

  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          Navigator.pushReplacementNamed(context, '/main');
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(Consts.missionsList,style: TextStyle(color: CustomColor.textColor)),
          ),
          drawer: AppDrawer(),
          body: SingleChildScrollView(
            child: Column(
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
                (isLoading)
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : (allMissionsList.isEmpty)
                        ? Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Center(
                              child: Card(
                                elevation: 5,
                                margin: EdgeInsets.all(16),
                                child: Container(
                                  color: Colors.white10,
                                  padding: EdgeInsets.all(16),
                                  width: double.infinity,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/box.png',
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        Consts.noMissionsFound,
                                        style: TextStyle(
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ))
                        : Padding(
                            padding: EdgeInsets.only(bottom: 16.0),
                            // Adjust the value as needed
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
                                  color: CustomColor.cardColor,
                                  margin: EdgeInsets.only(
                                      left: 16, right: 16, top: 12),
                                  child: ExpansionTile(
                                    onExpansionChanged: (isExpanded) {
                                      setState(() {
                                        _isExpandedList[index] = isExpanded;
                                      });
                                    },
                                    leading: _isExpandedList[index]
                                        ? Icon(Icons.keyboard_arrow_up)
                                        : Icon(Icons.keyboard_arrow_down),
                                    shape: LinearBorder.none,
                                    title: Text(
                                      '${Consts.requestDate} : ${mission['jalali_request_date']} ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.0,
                                          color: CustomColor.textColor),
                                    ),
                                    subtitle: RichText(
                                      text: TextSpan(children: <TextSpan>[
                                        TextSpan(
                                          text: '${Consts.missionType}  :',
                                          style: TextStyle(
                                              fontFamily: 'irs',
                                              fontWeight: FontWeight.bold,
                                              color: CustomColor.textColor),
                                        ),
                                        TextSpan(
                                          text: ' ${mission['type']}  ',
                                          style: TextStyle(
                                              fontFamily: 'irs',
                                              fontWeight: FontWeight.normal,
                                              color: CustomColor.textColor),
                                        ),
                                      ]),
                                    ),
                                    trailing: InkWell(
                                      child: (mission['status'] == 'recorded')
                                          ? Container(
                                              padding: EdgeInsets.all(8.0),
                                              decoration: BoxDecoration(
                                                color: CustomColor.cardColor,
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              child: Text(
                                                '${mission['level']}',
                                                style: TextStyle(
                                                    color:
                                                        CustomColor.textColor),
                                              ),
                                            )
                                          : (mission['status'] == 'accepted')
                                              ? Container(
                                                  padding: EdgeInsets.all(8.0),
                                                  decoration: BoxDecoration(
                                                    color: CustomColor
                                                        .successColor,
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
                                              : Container(
                                                  padding: EdgeInsets.all(8.0),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        CustomColor.dangerColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.0),
                                                  ),
                                                  child: Text(
                                                      '${mission['level']}',
                                                      style: TextStyle(
                                                          color: CustomColor
                                                              .textColor)),
                                                ),
                                    ),
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
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
                                                              fontFamily: 'irs',
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
                                                              fontFamily: 'irs',
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
                                                              fontFamily: 'irs',
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
                                                              fontFamily: 'irs',
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
                                            if (mission['description'] != null)
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
              ],
            ),
          ),
        ));
  }

  Future<void> fetchData(BuildContext context) async {
    final AuthService authService = AuthService('https://afkhambpms.ir/api1');
    final token = await authService.getToken();
    setState(() {
      isLoading = true;
    });
    final response = await http.get(
        Uri.parse('https://afkhambpms.ir/api1/personnels/get-mission'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        });

    if (response.statusCode == 200) {
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
  }
}

void main() {
  runApp(MaterialApp(
    home: AllMissions(),
  ));
}
