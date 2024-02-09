import 'dart:convert';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_linear_datepicker/flutter_datepicker.dart';
import '../utils/custom_notification.dart';
import '../utils/standard_number_creator.dart';
import '../widgets/app_drawer.dart';
import '../services/auth_service.dart';
import '../services/save_leave_request_service.dart';
import '../utils/custom_color.dart';

class AllLeaves extends StatefulWidget {
  @override
  _AllLeaveListState createState() => _AllLeaveListState();
}

class _AllLeaveListState extends State<AllLeaves> {
  List<dynamic> allLeavelList = [];
  bool isLoading = true;
  late List<bool> _isExpandedList =
      List.generate(allLeavelList.length, (index) => false);

  @override
  void initState() {
    super.initState();
    fetchData(context);
  }

  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          Navigator.pushReplacementNamed(context, '/personnel');
          return false;
        },
        child: Scaffold(
          backgroundColor: CustomColor.backgroundColor,
          appBar: AppBar(
            title: Text('لیست درخواست های مرخصی'),
          ),
          drawer: AppDrawer(),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    width: double.infinity,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      color: CustomColor.cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Text(
                              'درخواست مرخصی',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            Spacer(),
                            InkWell(
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
                                  color: CustomColor.warningColor,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'ایجاد',
                                      style: TextStyle(),
                                    ),
                                    SizedBox(width: 8.0),
                                    Icon(Icons.arrow_circle_left),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                        child: Column(children: [
                      (isLoading)
                          ? Center(
                              child: CircularProgressIndicator(),
                            )
                          : (allLeavelList.isEmpty)
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                              'تاکنون درخواست مرخصی ثبت نکرده اید!',
                                              style: TextStyle(
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ))
                              : Text(
                                  'لیست مرخصی ها',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(),
                                ),
                      ListView.builder(
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
                            color: CustomColor.cardColor,
                            margin: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
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
                                ' تاریخ درخواست : ${leave['jalali_request_date']} ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                ),
                              ),
                              subtitle: Text(
                                'دوره  : ${leave['period']}  ',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              trailing: InkWell(
                                child: (leave['status'] == 'recorded')
                                    ? Container(
                                        padding: EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: CustomColor.cardColor,
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        child: Text(
                                          '${leave['level']}',
                                        ),
                                      )
                                    : (leave['status'] == 'accepted')
                                        ? Container(
                                            padding: EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              color: CustomColor.successColor,
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            child: Text(
                                              '${leave['level']}',
                                            ),
                                          )
                                        : Container(
                                            padding: EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              color: CustomColor.dangerColor,
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            child: Text(
                                              '${leave['level']}',
                                            ),
                                          ),
                              ),
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'نوع  : ${leave['type']}  ',
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                          Spacer()
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'شروع  : ${leave['start']}  ',
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                          Spacer(),
                                          Text(
                                            'پایان  : ${leave['end']}  ',
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'توضیحات  : ${leave['reason']}  ',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (leave['description'] != null)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'توضیحات سرپرست: ${leave['description']}',
                                                style: TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                ),
                                                overflow: TextOverflow.visible,
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
                    ])))
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
        Uri.parse('https://afkhambpms.ir/api1/personnels/get-leave'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        });

    if (response.statusCode == 200) {
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
        TextField(
          controller: startDateController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'تاریخ شروع',
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
            labelText: 'تاریخ پایان',
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
    return TextField(
      controller: dateController,
      readOnly: true,
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
        TextField(
          controller: startTimeController,
          readOnly: true,
          onTap: () async {
            TimeOfDay? pickedTime = await showTimePicker(
              context: context,
              initialTime: startTime ?? TimeOfDay.now(),
            );
            setState(() {
              startTime = pickedTime;
              startTimeController.text = MaterialLocalizations.of(context)
                  .formatTimeOfDay(pickedTime!);
            });
          },
          decoration: InputDecoration(
            labelText: 'ساعت شروع',
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12.0),
          ),
        ),
        SizedBox(height: 16.0),
        TextField(
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
                    context, 'زمان پایان نمی تواند زودتر از زمان شروع باشد.');
                endTimeController.text = '';
              } else {
                endTimeController.text = MaterialLocalizations.of(context)
                    .formatTimeOfDay(pickedTime!);
              }
            });
          },
          decoration: InputDecoration(
            labelText: 'ساعت پایان',
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12.0),
          ),
        )
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
        type = 'choose_type';
    }
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
      print(response);
      if (response['status'] == 'successful') {
        CustomNotification.showCustomSuccess(
            context, 'درخواست مرخصی با موفقیت ثبت شد.');
        Navigator.pushReplacementNamed(context, '/leave-request');
      } else {
        CustomNotification.showCustomWarning(
            context, 'اطلاعات را به صورت کامل وارد کنید.');
      }
    } catch (e) {
      CustomNotification.showCustomDanger(
          context, 'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/personnel');
        return false;
      },
      child: Scaffold(
          backgroundColor: CustomColor.backgroundColor,
          appBar: AppBar(
            title: Text('درخواست مرخصی'),
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
                              InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'دوره مرخصی',
                                  border: OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.all(12.0),
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
                                    items: leavePeriods.map((period) {
                                      return DropdownMenuItem<String>(
                                        value: period,
                                        child: Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16.0, vertical: 12.0),
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
                              SizedBox(height: 16.0),
                              InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'نوع مرخصی',
                                  border: OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.all(12.0),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: leaveType,
                                    onChanged: (newValue) {
                                      setState(() {
                                        leaveType = newValue!;
                                      });
                                    },
                                    items: leaveTypes.map((type) {
                                      return DropdownMenuItem<String>(
                                        value: type,
                                        child: Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16.0, vertical: 12.0),
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
                                    icon: Icon(Icons.arrow_drop_down),
                                    elevation: 3,
                                  ),
                                ),
                              ),
                              (leavePeriod != 'انتخاب دوره مرخصی')
                                  ? (leavePeriod == 'روزانه'
                                      ? buildDateFields()
                                      : buildHourFields())
                                  : removeFields(),
                              SizedBox(height: 16.0),
                              TextField(
                                controller: reasonController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'علت',
                                  border: OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.all(12.0),
                                ),
                                style: TextStyle(
                                  fontFamily: 'irs',
                                ),
                              ),
                              SizedBox(height: 24.0),
                              ElevatedButton(
                                onPressed:
                                    isLoading ? null : submitLeaveRequest,
                                child: isLoading
                                    ? CircularProgressIndicator()
                                    : Text(
                                        'ثبت',
                                      ),
                                style: ElevatedButton.styleFrom(
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
