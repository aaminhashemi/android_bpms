import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/payslip.dart';
import '../utils/custom_color.dart';
import '../utils/custom_notification.dart';
import '../widgets/app_drawer.dart';
import '../utils/consts.dart';
import '../utils/exception_consts.dart';
import '../services/auth_service.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  Box<Payslip>? payslipBox;
  List<Payslip>? results=[];

  @override
  void initState() {
    super.initState();
    fetchData();
    initBox();
  }

  Future<void> initBox() async {
    payslipBox=await Hive.openBox('payslipBox');
    print(payslipBox?.length);
    setState(() {

    });
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    final accessToken = await authService.getToken();
    /*if (accessToken != null) {
      final validAccessToken =
          await authService.isAccessTokenValid(accessToken);
      if (validAccessToken) {
      } else {
        authService.logout();
      }
    } else {
      authService.logout();
    }*/
    payslipBox=await Hive.openBox('payslipBox');

    var connectivityResult = await Connectivity().checkConnectivity();
    final box = Hive.box<Payslip>('payslipBox');

    if (connectivityResult != ConnectivityResult.none) {
      try {
        final response = await http
            .get(Uri.parse('https://afkhambpms.ir/api1/get-user'), headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/x-www-form-urlencoded',
        });

        if (response.statusCode == 200) {

          //box.clear();
          var temp=json.decode(response.body);
          for(var pay in temp){
            var check=await box.values.where((data) => data.id == pay['id'].toInt()).toList();
            if(check.length==0){
              print(pay);
              //print(pay['yearly_period']);
              Payslip payslip=Payslip(
                id:pay['id'].toInt(),
                payment_period:pay['payment_period'],
                price:pay['price'],
                level:pay['level'],
                payment_date:pay['payment_date'],
              );
              box.add(payslip);
              print('payslipBox.length');
              print(box.length);
            }

          }
          setState(() {
            isLoading = false;
            payslipList = json.decode(response.body);
          });
        } else {
          setState(() {
            isLoading = false;
          });
          throw Exception(Exception_consts.dataFetchError);
        }
      } catch (e) {
        CustomNotification.show(context, 'ناموفق',
            e.toString(),
            'payslip');
      }
    }else{
      print(box);
      //final x=payslipBox?.values.toList();
      //print(payslipBox?.length);

      for(var res in box.values.toList()){
        var payslip= {
          'id': res.id.toInt(),
          'payment_period': res.payment_period,
          'price': res.price,
          'level': res.level,
          'payment_date': res.payment_date,
        };
        payslipList.add(payslip);
        print(res.payment_period);
      }
      setState(() {
        isLoading=false;
      });

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
          iconTheme: IconThemeData(color: CustomColor.drawerBackgroundColor),
          title: Text(Consts.payslip,
              style: TextStyle(color: CustomColor.textColor)),
          actions: [
            IconButton(
              icon: Icon(Icons.logout,color: CustomColor.drawerBackgroundColor),
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
                      child: Text(
                                'فیش حقوقی یافت نشد.',
                                style: TextStyle(
                                  fontSize: 18,
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
                          title:
                          RichText(
                            text: TextSpan(children: <TextSpan>[
                              TextSpan(
                                text: '${Consts.period}  :',
                                style: TextStyle(
                                    fontFamily: 'irs',
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: CustomColor.textColor),
                              ),
                              TextSpan(
                                text:
                                ' ${payslip['payment_period']} ',
                                style: TextStyle(
                                    fontFamily: 'irs',
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.normal,
                                    color: CustomColor.textColor),
                              ),
                            ]),
                          )
                          ,
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(children: <TextSpan>[
                                  TextSpan(
                                    text: '${Consts.value}  :',
                                    style: TextStyle(
                                        fontFamily: 'irs',
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: CustomColor.textColor),
                                  ),
                                  TextSpan(
                                    text:
                                    ' ${payslip['price']}  ${Consts.priceUnit} ',
                                    style: TextStyle(
                                        fontFamily: 'irs',
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.normal,
                                        color: CustomColor.textColor),
                                  ),
                                ]),
                              ),

                              SizedBox(height: 4),
                              RichText(
                                text: TextSpan(children: <TextSpan>[
                                  TextSpan(
                                    text: '${Consts.status}  :',
                                    style: TextStyle(
                                        fontFamily: 'irs',
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: CustomColor.textColor),
                                  ),
                                  TextSpan(
                                    text:
                                    ' ${payslip['level']}',
                                    style: TextStyle(
                                        fontFamily: 'irs',
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.normal,
                                        color: CustomColor.textColor),
                                  ),
                                ]),
                              ),

                              SizedBox(height: 4),
                              RichText(
                                text: TextSpan(children: <TextSpan>[
                                  TextSpan(
                                    text: '${Consts.paymentDate}  :',
                                    style: TextStyle(
                                        fontFamily: 'irs',
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: CustomColor.textColor),
                                  ),
                                  TextSpan(
                                    text:
                                    ' ${payslip['payment_date']}',
                                    style: TextStyle(
                                        fontFamily: 'irs',
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.normal,
                                        color: CustomColor.textColor),
                                  ),
                                ]),
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward,color: CustomColor.textColor,),
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
  Future<void> downloadFile() async {
    final url = 'https://afkhambpms.ir/api1/files/show/${payslip['license']}';
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: _handleNotificationClick);

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print('di');
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/${payslip["payment_period"]}.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        // Show success message or perform any other actions here
        await _showNotification(flutterLocalNotificationsPlugin, filePath);

      } else {
        throw 'Failed to download file: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Error downloading file: $e';
    }
  }
  Future<void> _handleNotificationClick(String? payload) async {
    if (payload != null) {
      await _openDownloadedFile(payload);;
      print('hi');

    }
  }
  Future<void> _showNotification(
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
      String filePath,
      ) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'downloaded_files_channel', // Change this to a unique channel ID
      'Downloaded Files',
      importance: Importance.high,
      priority: Priority.high,
    );
    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      0,
      'Download Complete',
      'File downloaded successfully',
      platformChannelSpecifics,
      payload: filePath, // Pass the file path as payload
    );
  }
  Future<void> _openDownloadedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerWidget(filePath: filePath),
          ),
        );
      }
    } catch (e) {
      print('Error opening file: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.backgroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: CustomColor.drawerBackgroundColor),
        title: Text(' ${Consts.payslip} ${payslip['payment_period']} ',
            style: TextStyle(color: CustomColor.textColor)),
      ),
      drawer: AppDrawer(),
      body: Container(
        child: Column(
          children: [
            Expanded(
                child: Container(
              child: SfPdfViewer.network(
                  'https://afkhambpms.ir/api1/files/show/${payslip['license']}'),
            )),
            ElevatedButton(
              onPressed: downloadFile,
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
