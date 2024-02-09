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
  int max_value=0;
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
      print(json.decode(response.body));
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
        CustomNotification.showCustomSuccess(
          context,
          'درخواست مساعده با موفقیت ثبت شد.',
        );
        Navigator.pushReplacementNamed(context, '/assistance');
      } else if (response['status'] == 'existed') {
        CustomNotification.showCustomWarning(
          context,
          'درخواست مساعده قبلا ثبت شده است.',
        );
      } else {
        print(response['status']);
        CustomNotification.showCustomWarning(
          context,
          'اطلاعات را به صورت کامل وارد کنید.',
        );
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
    return  Scaffold(
        backgroundColor: CustomColor.backgroundColor,
        appBar: AppBar(
          title: const Text('درخواست مساعده'),
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
    return TextField(
      controller: dateController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'تاریخ',
        border: OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(12.0),
      ),
    );
  }


  Widget _buildValueTextField() {
    return TextField(
      controller: valueController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: 'مبلغ (ریال)',
        border: OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(12.0),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : save,
      child: isLoading
          ? CircularProgressIndicator()
          : Text('ثبت'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        primary: CustomColor.buttonColor,
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
      Navigator.pushReplacementNamed(context, '/personnel');
      return false;
    },
    child:
    Scaffold(
      backgroundColor: CustomColor.backgroundColor,
      appBar: AppBar(
        title: Text('لیست درخواست های مساعده'),
      ),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        child: Column(children: [
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
                        'درخواست مساعده',
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
                              builder: (context) => Assistance(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: CustomColor.warningColor,
                            borderRadius: BorderRadius.circular(
                                10.0),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'ایجاد',
                                style: TextStyle(
                                    ),
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
        (isLoading)
            ? Center(
          child: CircularProgressIndicator(),
        )
            : (allAssistancelList.isEmpty)
            ? Padding(
            padding: const EdgeInsets.all(6.0),
            child:
            Center(
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
            )
        )
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
              color: CustomColor.cardColor,
              margin:
              EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ExpansionTile(
                shape: LinearBorder.none,
                leading: Icon(Icons.keyboard_arrow_down),
                title: Text(
                  ' دوره : ${assistance['payment_period']} ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                subtitle: Text(
                  'مبلغ  : ${assistance['price']} ریال ',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                  ),
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
                      style: TextStyle(),
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
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (assistance['deposit_date'] != null)
                          Text(
                            ' تاریخ پرداخت : ${assistance['payment_date']}  ',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          Text(
                            ' تاریخ پرداخت : نامشخص  ',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        )

        ]
        ),
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
      print(json.decode(response.body));
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
