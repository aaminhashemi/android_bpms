import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../utils/consts.dart';
import '../utils/custom_color.dart';
import '../utils/custom_notification.dart';
import '../utils/exception_consts.dart';
import '../widgets/app_drawer.dart';
import '../services/action_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController descriptionController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  bool isLoading = false;
  bool isInRange = false;
  String type = 'انتخاب';
  List<String> typeList = ['انتخاب', 'ورود', 'خروج', 'مرخصی', 'ماموریت'];
  List<dynamic> targetLatitudes = [];
  List<dynamic> targetLongitudes = [];
  late double distanceThreshold;
  late double distance;

  void setInitialDate() {
    DateTime dt = DateTime.now();
    Jalali j = dt.toJalali();
    final f = j.formatter;
    dateController.text = '${f.yyyy}/${f.mm}/${f.dd}';
  }

  @override
  void initState() {
    super.initState();
    setInitialDate();
    fetchCoordinates(context);
  }

  Future<void> fetchCoordinates(BuildContext context) async {
    final AuthService authService = AuthService('https://afkhambpms.ir/api1');
    final token = await authService.getToken();
    setState(() {
      isLoading = true;
    });
    final response = await http.get(
        Uri.parse('https://afkhambpms.ir/api1/personnels/get-points'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        });
    if (response.statusCode == 200) {
      var res = json.decode(response.body);
      print(json.decode(response.body));
      setState(() {
        targetLatitudes = res['latitudes'];
        targetLongitudes = res['longitudes'];
        distanceThreshold = double.parse(res['distance']);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('خطا در دریافت داده ها');
    }
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
              )))
    ]);
  }

  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/main');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('ثبت ورود و خروج',style: TextStyle(color: CustomColor.textColor)),
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
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      for (int i = 0; i < targetLatitudes.length; i++) {
        distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          double.parse(targetLatitudes[i]),
          double.parse(targetLongitudes[i]),
        );

        if (distance <= distanceThreshold && !isInRange) {
          setState(() {
            isInRange = true;
          });
        }
      }
      if (isInRange) {
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
          final actionResponse = await actionService.save(
            dateController.text.trim(),
            actionType,
            descriptionController.text.trim(),
          );

          if (actionResponse['status'] == 'successful') {
            CustomNotification.show(context, 'موفقیت آمیز', 'درخواست با موفقیت ثبت شد.', '/main');
          } else if (actionResponse['status'] == 'imperfect_data') {
            CustomNotification.show(context, 'خطا', 'لطفا اطلاعات را به صورت کامل وارد کنید.', '');
          } else {
            CustomNotification.show(context, 'ناموفق', 'در ثبت درخواست مشکلی وجود دارد.', '');
          }
        } catch (e) {
          setState(() {
            isLoading = false;
          });
          CustomNotification.show(context, 'ناموفق', 'در ثبت درخواست مشکلی وجود دارد.', '');

        } finally {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        CustomNotification.show(context, 'خطا', 'درخواست غیر مجاز، شما در محدوده ی تعیین شده قرار ندارید!', '');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      CustomNotification.show(context, 'ناموفق', 'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.', '');
      setState(() {
        isLoading = false;
      });
    }
  }
}
