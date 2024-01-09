import '../services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../utils/custom_color.dart';
import '../widgets/app_drawer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personnel List App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PayslipList(),
    );
  }
}

class PayslipList extends StatefulWidget {
  @override
  _PayslipListState createState() => _PayslipListState();
}

class _PayslipListState extends State<PayslipList> {
  final AuthService authService = AuthService('https://afkhambpms.ir/api1');

  List<dynamic> payslipList = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final accessToken = await authService.getToken();
    if (accessToken != null) {
      final validAccessToken =
          await authService.isAccessTokenValid(accessToken);
      if (validAccessToken) {
      } else {
        authService.logout();
      }
    } else {
      authService.logout();
    }

    final response = await http
        .get(Uri.parse('https://afkhambpms.ir/api1/get-user'), headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/x-www-form-urlencoded',
    });

    if (response.statusCode == 200) {
      setState(() {
        payslipList = json.decode(response.body);
      });
    } else {
      throw Exception('فیش های حقوقی پرسنل دریافت نشد.');
    }
  }

  void _logout(BuildContext context) async {
    await authService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('فیش حقوقی'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: payslipList.isEmpty
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: payslipList.length,
              itemBuilder: (context, index) {
                var payslip = payslipList[index];
                return Card(
                  color: CustomColor.primaryColor,
                  elevation: 4.0,
                  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    title: Text(
                      ' دوره: ${payslip['payment_period']} ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مبلغ : ' +
                              NumberFormat.currency(locale: 'en_US', symbol: '')
                                  .format(payslip['value']) +
                              ' ریال',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'وضعیت : ${payslip['level']} ',
                          style: TextStyle(
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          ' تاریخ پرداخت ${payslip['payment_date']} ',
                          style: TextStyle(
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PayslipDetails(payslip),
                        ),
                      );
                      },
                  ),
                );
              },
            ),
    );
  }
}

class PayslipDetails extends StatelessWidget {
  final dynamic payslip;

  PayslipDetails(this.payslip);

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(' فیش حقوقی ${payslip['payment_period']} '),
      ),
      body: Container(
        child: SfPdfViewer.network('https://afkhambpms.ir/api1/files/show/${payslip['license']}'),
      )
    );
  }
}
