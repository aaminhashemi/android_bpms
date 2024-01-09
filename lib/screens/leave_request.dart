import '../services/save_leave_request_service.dart';
import '../utils/custom_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linear_datepicker/flutter_datepicker.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../utils/custom_notification.dart';
import '../utils/standard_number_creator.dart';
import '../widgets/app_drawer.dart';

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

  bool isLoading=false;
  TextEditingController dateController = TextEditingController();
  TextEditingController startDateController = TextEditingController();
  TextEditingController typeController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  TextEditingController startTimeController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  TextEditingController reasonController = TextEditingController();

  String leaveType = 'انتخاب نوع مرخصی';
  List<String> leaveTypes = ['انتخاب نوع مرخصی', 'روزانه', 'ساعتی'];

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
    String selected = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('انتخاب تاریخ شروع', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
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
    String selected = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('انتخاب تاریخ پایان', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
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
    var type = '';
    switch (leaveType) {
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
    SaveLeaveRequestService saveLeaveRequestService = SaveLeaveRequestService(apiUrl);
    try {
      final response = await saveLeaveRequestService.saveLeaveRequest(
          dateController.text.trim(),
          startDateController.text.trim(),
          endDateController.text.trim(),
          StandardNumberCreator.convert(startTimeController.text.trim()),
          StandardNumberCreator.convert(endTimeController.text.trim()),
          reasonController.text.trim(),
          type);
      print(response);
      if (response['status'] == 'successful') {
        CustomNotification.showCustomSuccess(
          context,
          'درخواست مرخصی با موفقیت ثبت شد.',
        );
      } else {
        CustomNotification.showCustomWarning(
          context,
          'اطلاعات را به صورت کامل وارد کنید.',
        );
      }
    } catch (e) {
      CustomNotification.showCustomDanger(context,'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.');
    }finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              child: Card(
                color: CustomColor.primaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'درخواست مرخصی',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: 16.0),
                      _buildDateTextField(),
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
                                clearHourFields();
                              });
                            },
                            items: leaveTypes.map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 12.0),
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
                      (leaveType != 'انتخاب نوع مرخصی')
                          ? (leaveType == 'روزانه'
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
                          fontFamily:
                          'irs',
                        ),
                      ),
                      SizedBox(height: 24.0),
                      ElevatedButton(
                        onPressed: isLoading ? null : submitLeaveRequest,
                        child: isLoading
                            ? CircularProgressIndicator()
                            : Text(
                          'ثبت',
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          primary:
                          CustomColor.buttonColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: LeaveRequest(),
  ));
}
