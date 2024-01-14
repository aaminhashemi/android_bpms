import 'dart:convert';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;

import '../services/save_assistance_service.dart';
import '../utils/custom_color.dart';
import '../utils/custom_notification.dart';
import '../widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

class Assistance extends StatefulWidget {
  @override
  _AssistanceState createState() => _AssistanceState();
}

class _AssistanceState extends State<Assistance> {
  TextEditingController dateController = TextEditingController();
  TextEditingController valueController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    setInitialDate();
  }

  void setInitialDate() {
    DateTime dt = DateTime.now();
    Jalali j = dt.toJalali();
    final f = j.formatter;
    dateController.text = '${f.yyyy}/${f.mm}/${f.dd}';
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
      print(response);
      if (response['status'] == 'successful') {
        CustomNotification.showCustomSuccess(
          context,
          'درخواست مساعده با موفقیت ثبت شد.',
        );
      } else {
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
    return Scaffold(
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
                color: CustomColor.primaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text(
                        'لیست درخواست ها',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(width: 140),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AllAssistances(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: CustomColor.warningColor, // Set your desired background color
                            borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                          ),
                          child: Text(
                            'مشاهده',
                            style: TextStyle(
                              // Add text styles here if needed
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Card(
                color: CustomColor.primaryColor,
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
      decoration: InputDecoration(
        labelText: 'مبلغ',
        border: OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(12.0),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : save,
      child: isLoading
          ? CircularProgressIndicator() // Show loading indicator
          : Text(
              'ثبت',
            ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        primary: CustomColor.buttonColor,
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Assistance(),
  ));
}

class AllAssistances extends StatefulWidget {
  @override
  _AllAssistanceListState createState() => _AllAssistanceListState();

}

class _AllAssistanceListState extends State<AllAssistances> {

  List<dynamic> allAssistancelList = [];

  @override
  void initState() {
    super.initState();
    fetchData(context);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لیست درخواست های مساعده'),
      ),
      body: allAssistancelList.isEmpty
          ? Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        itemCount: allAssistancelList.length,
        itemBuilder: (context, index) {
          var assistance = allAssistancelList[index];
          return Card(
            elevation: 4.0,
            color: CustomColor.primaryColor,
            margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ExpansionTile(
              shape: LinearBorder.none,
              leading: Icon(Icons.keyboard_arrow_down),
              title: Text(
                ' تاریخ درخواست : ${assistance['jalali_date']} ',
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
                    color: CustomColor.primaryColor,
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
                  child: Text(
                    'Additional Information: ${assistance['additionalInfo']}',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> fetchData(BuildContext context) async {
    final AuthService authService = AuthService('https://afkhambpms.ir/api1');
    final token = await authService.getToken();

    final response = await http.get(Uri.parse('https://afkhambpms.ir/api1/personnels/get-assistance'),
        headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
        });

    if (response.statusCode == 200) {
      setState(() {
        allAssistancelList = json.decode(response.body);
      });
    } else {
      throw Exception('خطا در دریافت داده ها');
    }
  }

}
