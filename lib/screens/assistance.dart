import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/save_assistance_service.dart';
import '../utils/custom_color.dart';
import '../utils/custom_notification.dart';
import '../widgets/app_drawer.dart';
import '../services/auth_service.dart';

class Assistance extends StatefulWidget {
  @override
  _AssistanceState createState() => _AssistanceState();
}

class _AssistanceState extends State<Assistance> {
  TextEditingController dateController = TextEditingController();
  TextEditingController valueController = TextEditingController();
  bool isLoading = false;
  int max_value = 0;

  @override
  void initState() {
    super.initState();
    setInitialDate();
    valueController.addListener(_formatValue);
    fetchMaxAssistanceValue(context);
  }

  Future<void> fetchMaxAssistanceValue(BuildContext context) async {
    final AuthService authService = AuthService('https://afkhambpms.ir/api1');
    final token = await authService.getToken();
    final response = await http.get(
        Uri.parse('https://afkhambpms.ir/api1/personnels/get-max-assistance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        });

    if (response.statusCode == 200) {
      setState(() {
        max_value = int.parse(json.decode(response.body));
      });
    } else {
      throw Exception('خطا در دریافت داده ها');
    }
  }

  @override
  void dispose() {
    valueController.removeListener(_formatValue);
    valueController.dispose();
    super.dispose();
  }

  void _formatValue() {
    final numValue = int.tryParse(valueController.text.replaceAll(',', ''));

    if (numValue != null) {
      final limitedValue = numValue.clamp(0, max_value);

      final formattedValue = NumberFormat("#,###").format(limitedValue);
      valueController.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.fromPosition(
          TextPosition(offset: formattedValue.length),
        ),
      );
    }
  }

  void setInitialDate() {
    DateTime dt = DateTime.now();
    Jalali j = dt.toJalali();
    final f = j.formatter;
    dateController.text = '1402/10/25';
  }

  Future<void> save() async {
    setState(() {
      isLoading = true;
    });
    const apiUrl = 'https://afkhambpms.ir/api1/personnels/save-assistance';
    SaveAssistanceService saveAssistanceService = SaveAssistanceService(apiUrl);

    try {
      final response = await saveAssistanceService.saveAssistance(
        dateController.text.trim(),
        valueController.text.trim(),
      );
      if (response['status'] == 'successful') {
        CustomNotification.show(context, 'موفقیت آمیز', 'درخواست مساعده با موفقیت ثبت شد.', '/assistance');
      } else if (response['status'] == 'existed') {
        CustomNotification.show(context, 'خطا', 'درخواست مساعده قبلا ثبت شده است.', '/assistance');

      } else if (response['status'] == 'imperfect_data'){
        CustomNotification.show(context, 'خطا', 'لطفا اطلاعات را به صورت کامل وارد کنید.', '');

      } else {
        CustomNotification.show(context,'ناموفق','در ثبت درخواست مشکلی وجود دارد.','');
      }
    } catch (e) {
      CustomNotification.show(context,'ناموفق','خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.','');
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
        title: const Text('درخواست مساعده',style: TextStyle(color: CustomColor.textColor)),
      ),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
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
                        'ثبت درخواست مساعده',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: 16.0),
                      _buildDateTextField(),
                      SizedBox(height: 16.0),
                      _buildValueTextField(),
                      SizedBox(height: 24.0),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          ),
        ),
      ),
    ]);
  }

  Widget _buildValueTextField() {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 75,
        child: Text(
          'مبلغ (ریال) :',
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
                controller: valueController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : save,
      child: isLoading ? CircularProgressIndicator() : Text('ثبت',style: TextStyle(color: Colors.white),),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              10.0), // Adjust the radius as needed
        ),
        minimumSize: const Size(double.infinity, 48),
        primary: CustomColor.successColor,
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: AllAssistances(),
  ));
}

class AllAssistances extends StatefulWidget {
  @override
  _AllAssistanceListState createState() => _AllAssistanceListState();
}

class _AllAssistanceListState extends State<AllAssistances> {
  bool isLoading = true;
  List<dynamic> allAssistancelList = [];

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
          title: Text('مساعده',style: TextStyle(color: CustomColor.textColor)),
        ),
        drawer: AppDrawer(),
        body: SingleChildScrollView(
          child: Column(children: [
            Container(
              color: CustomColor.backgroundColor,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    color: CustomColor.buttonColor,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Assistance(),
                            ),
                          );
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'درخواست مساعده جدید',
                              style: TextStyle(
                                  color: CustomColor.backgroundColor,
                                  fontWeight: FontWeight.bold),
                            ),
                            //SizedBox(width: 8.0),
                            //Icon(Icons.arrow_circle_left),
                          ],
                        ),
                      ),
                    )),
              ),
            ),
            (isLoading)
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : (allAssistancelList.isEmpty)
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/box.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'تاکنون درخواست مساعده ثبت نکرده اید!',
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: allAssistancelList.length,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          var assistance = allAssistancelList[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            elevation: 4.0,
                            color: CustomColor.backgroundColor,
                            margin:
                                EdgeInsets.only(left: 16, right: 16, top: 12),
                            child: ExpansionTile(
                              shape: LinearBorder.none,
                              leading: Icon(Icons.keyboard_arrow_down),
                              title: Text(
                                ' دوره :${assistance['payment_period']} ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                    color: CustomColor.textColor),
                              ),
                              subtitle: Text(
                                'مبلغ  : ${assistance['price']} ریال ',
                                style: TextStyle(
                                    fontStyle: FontStyle.normal,
                                    color: CustomColor.textColor),
                              ),
                              trailing: InkWell(
                                child: Container(
                                  padding: EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: CustomColor.cardColor,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Text(
                                    '${assistance['level']}',
                                    style:
                                        TextStyle(color: CustomColor.textColor),
                                  ),
                                ),
                              ),
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Text(
                                        ' تاریخ ثبت : ${assistance['record_date']}  ',
                                        style: TextStyle(
                                            fontStyle: FontStyle.normal,
                                            color: CustomColor.textColor),
                                      ),
                                      if (assistance['deposit_date'] != null)
                                        Text(
                                          ' تاریخ پرداخت : ${assistance['payment_date']}  ',
                                          style: TextStyle(
                                              fontStyle: FontStyle.normal,
                                              color: CustomColor.textColor),
                                        )
                                      else
                                        Text(
                                          ' تاریخ پرداخت : نامشخص  ',
                                          style: TextStyle(
                                              fontStyle: FontStyle.normal,
                                              color: CustomColor.textColor),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
          ]),
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
    final response = await http.get(
        Uri.parse('https://afkhambpms.ir/api1/personnels/get-assistance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        });

    if (response.statusCode == 200) {
      setState(() {
        allAssistancelList = json.decode(response.body);
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
