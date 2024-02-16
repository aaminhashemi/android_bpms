import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../utils/custom_color.dart';
import '../widgets/app_drawer.dart';
import '../utils/consts.dart';
import '../utils/exception_consts.dart';
import '../services/auth_service.dart';

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
  bool isLoading = true;
  List<dynamic> payslipList = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
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
    print(response);
    if (response.statusCode == 200) {
      setState(() {
        payslipList = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception(Exception_consts.dataFetchError);
    }
  }

  void _logout(BuildContext context) async {
    await authService.logout();
    Navigator.pushReplacementNamed(context, '/login');
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
          title: Text(Consts.payslip,
              style: TextStyle(color: CustomColor.textColor)),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
          ],
        ),
        drawer: AppDrawer(),
        body: (isLoading)
            ? Center(
                child: CircularProgressIndicator(),
              )
            : (payslipList.isEmpty)
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
                                'تاکنون فیش حقوقی برای شما ثبت نشده است.',
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
                    itemCount: payslipList.length,
                    itemBuilder: (context, index) {
                      var payslip = payslipList[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        color: CustomColor.cardColor,
                        elevation: 4.0,
                        margin: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            ' ${Consts.period}: ${payslip['payment_period']} ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ' ${Consts.value} :  ${payslip['price']}  ${Consts.priceUnit} ',
                                style: TextStyle(
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                ' ${Consts.status} : ${payslip['level']} ',
                                style: TextStyle(
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                ' ${Consts.paymentDate} ${payslip['payment_date']} ',
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
      ),
    );
  }
}

class PayslipDetails extends StatelessWidget {
  final dynamic payslip;

  PayslipDetails(this.payslip);

  _launchURL() async {
    final url = 'https://afkhambpms.ir/api1/files/show/${payslip['license']}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.backgroundColor,
      appBar: AppBar(
        title: Text(' ${Consts.payslip} ${payslip['payment_period']} ',
            style: TextStyle(color: CustomColor.textColor)),
      ),
      body: Container(
        child: Column(
          children: [
            Expanded(
                child: Container(
              child: SfPdfViewer.network(
                  'https://afkhambpms.ir/api1/files/show/${payslip['license']}'),
            )),
            ElevatedButton(
              onPressed: _launchURL,
              child: Text(Consts.download),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      10.0), // Adjust the radius as needed
                ),
                primary: CustomColor.successColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
