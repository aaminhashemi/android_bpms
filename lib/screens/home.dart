import 'package:and/services/home_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../utils/custom_notification.dart';
import '../widgets/app_drawer.dart';
import '../utils/consts.dart';
import '../utils/custom_color.dart';
import '../utils/exception_consts.dart';

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
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService authService = AuthService('https://afkhambpms.ir/api1');
  final HomeService homeService = HomeService('https://afkhambpms.ir/api1');
  bool isLoading = false;
  late int assistanceCount;
  late int payslipCount;
  late int loanCount;
  late int missionCount;
  late int leavingCount;

  late String lastAssistance;
  late String lastPayslip;
  late String lastLoan;
  late String lastMission;
  late String lastLeaving;
  late String lastAction;

  List<dynamic> personnelList = [];

  @override
  void initState() {
    super.initState();
    statistics();
  }

  void statistics() async {
    setState(() {
      isLoading = true;
    });
    try {
      final homeResponse = await homeService.getStatistics();
      print(homeResponse);
      if (homeResponse['status'] == 'successful') {
        setState(() {
          assistanceCount = homeResponse['assistance'];
          payslipCount = homeResponse['payslip'];
          loanCount = homeResponse['loan'];
          missionCount = homeResponse['mission'];
          leavingCount = homeResponse['leaving'];

          lastAction = homeResponse['action'];
          lastAssistance = homeResponse['last_assistance'];
          lastPayslip = homeResponse['last_payslip'];
          lastLoan = homeResponse['last_loan'];
          lastMission = homeResponse['last_mission'];
          lastLeaving = homeResponse['last_leaving'];
          isLoading = false;
        });
      } else {
        CustomNotification.show(
            context, 'ناموفق', Exception_consts.incorrectCredentials, '');
        setState(() {
          assistanceCount = 0;
          payslipCount = 0;
          loanCount = 0;
          missionCount = 0;
          leavingCount = 0;
          lastAssistance = 'نامشخص';
          lastPayslip = 'نامشخص';
          lastAction = 'نامشخص';
          lastLoan = 'نامشخص';
          lastMission = 'نامشخص';
          lastLeaving = 'نامشخص';
          isLoading = false;
        });
      }
    } catch (e) {
      CustomNotification.show(context, 'ناموفق',
          'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.', '');
      setState(() {
        assistanceCount = 0;
        payslipCount = 0;
        loanCount = 0;
        missionCount = 0;
        leavingCount = 0;
        lastAssistance = 'نامشخص';
        lastPayslip = 'نامشخص';
        lastLoan = 'نامشخص';
        lastAction = 'نامشخص';
        lastMission = 'نامشخص';
        lastLeaving = 'نامشخص';
        isLoading = false;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

/*  Future<void> fetchData() async {
    final response = await http
        .get(Uri.parse('https://afkhambpms.ir/api1/personnels'), headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
    });

    if (response.statusCode == 200) {
      setState(() {
        personnelList = json.decode(response.body);
      });
    } else {
      throw Exception(Exception_consts.dataFetchError);
    }
  }*/

  void _logout(BuildContext context) async {
    await authService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('خانه', style: TextStyle(color: CustomColor.textColor)),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
          ],
        ),
        drawer: AppDrawer(),
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Card(
                            color: CustomColor.cardColor,
                            elevation: 2,
                            margin: EdgeInsets.only(bottom: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'آخرین رویداد',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,color: CustomColor.textColor
                                        ),
                                      ),
                                      Spacer(),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pushReplacementNamed(
                                              context, '/loc');
                                        },
                                        child: Text('ثبت'),
                                        style: ElevatedButton.styleFrom(
                                        primary: Colors.teal, // Background color of the button
                                        onPrimary: Colors.white, // Text color on the button
                                        elevation: 5, // Elevation of the button
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.0), // Rounded corners
                                        ),
                                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Button padding
                                      ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 5),
                                      Text(
                                        ' ${lastAction}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: CustomColor.textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ]))),
                        _buildCard('تعداد مرخصی', 'leave-request', leavingCount,
                            lastLeaving),
                        _buildCard('تعداد ماموریت', 'mission-request',
                            missionCount, lastMission),
                        _buildCard('تعداد مساعده', 'assistance',
                            assistanceCount, lastAssistance),
                        _buildCard('تعداد وام', 'loan', loanCount, lastLoan),
                        _buildCard('تعداد فیش حقوقی', 'payslip', payslipCount,
                            lastPayslip),
                      ],
                    ))));
  }

  Widget _buildCard(String title, String route, int count, String last) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 20),
      color: CustomColor.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,color: CustomColor.textColor
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  ': $count',
                  style: TextStyle(
                    fontSize: 16,
                    color: CustomColor.textColor
                  ),
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/${route}');
                  },
                  child: Text('مشاهده'),style: ElevatedButton.styleFrom(
                  primary: Colors.teal, // Background color of the button
                  onPrimary: Colors.white, // Text color on the button
                  elevation: 5, // Elevation of the button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // Rounded corners
                  ),
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Button padding
                ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'آخرین :',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,color: CustomColor.textColor
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  ' $last',
                  style: TextStyle(
                    fontSize: 16,
                      color: CustomColor.textColor
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class PersonnelDetails extends StatelessWidget {
  final dynamic personnel;

  PersonnelDetails(this.personnel);

  _launchPhoneDialer(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(personnel['fullname'],
            style: TextStyle(color: CustomColor.textColor)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4.0,
              color: (personnel['is_verified'])
                  ? CustomColor.cardColor
                  : CustomColor.emptyListColor,
              margin: EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundImage: personnel['image_id'] != null
                          ? NetworkImage(
                                  'https://afkhambpms.ir/api1/files/show/${personnel['image_id']}')
                              as ImageProvider
                          : AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                      radius: 60.0,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      '${personnel['prefix_name']} ${personnel['first_name']} ${personnel['last_name']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0,
                      ),
                    ),
                    SizedBox(height: 8.0),
                  ],
                ),
              ),
            ),
            ListTile(
              title: Text(Consts.personnelEmail),
              subtitle: Text((personnel['email'] != null)
                  ? personnel['email']
                  : 'ثبت نشده'),
              leading: Icon(Icons.email),
            ),
            ListTile(
              title: Text(Consts.personnelPhone),
              subtitle: Text(personnel['phone']),
              leading: Icon(Icons.phone),
              onTap: () {
                _launchPhoneDialer(personnel['mobile']);
              },
            ),
            ListTile(
              title: Text(Consts.personnelMobile),
              subtitle: Text(personnel['mobile']),
              leading: Icon(Icons.phone_android),
              onTap: () {
                _launchPhoneDialer(personnel['mobile']);
              },
            ),
            ListTile(
              title: Text(Consts.personnelEmergencyPhone),
              subtitle: Text(personnel['emergency_phone']),
              leading: Icon(Icons.local_hospital),
              onTap: () {
                _launchPhoneDialer(personnel['mobile']);
              },
            ),
            Divider(),
            ListTile(
              title: Text(Consts.personnelBirthDate),
              subtitle: Text(personnel['birth_date']),
              leading: Icon(Icons.cake),
            ),
            ListTile(
              title: Text(Consts.personnelAddress),
              subtitle: Text(personnel['address']),
              leading: Icon(Icons.home),
            ),
            ListTile(
              title: Text(Consts.personnelEducationalDegree),
              subtitle: Text(personnel['education_degree']),
              leading: Icon(Icons.school),
            ),
            ListTile(
              title: Text(Consts.personnelMaritalStatus),
              subtitle:
                  Text(personnel['marital_status'] == "0" ? 'مجرد' : 'متاهل'),
              leading: Icon(Icons.favorite),
            ),
            ListTile(
              title: Text(Consts.personnelChildren),
              subtitle: Text(personnel['children']),
              leading: Icon(Icons.child_care),
            ),
          ],
        ),
      ),
    );
  }
}
