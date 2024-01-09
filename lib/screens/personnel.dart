import '../utils/custom_color.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
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
      home: PersonnelList(),
    );
  }
}

class PersonnelList extends StatefulWidget {
  @override
  _PersonnelListState createState() => _PersonnelListState();
}

class _PersonnelListState extends State<PersonnelList> {
  final AuthService authService = AuthService('https://afkhambpms.ir/api1');

  List<dynamic> personnelList = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('https://afkhambpms.ir/api1/personnels'),headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/x-www-form-urlencoded',
    });

    if (response.statusCode == 200) {
      setState(() {
        personnelList = json.decode(response.body);
      });
    } else {
      throw Exception('داده های پرسنل دریافت نشد.');
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
        title: Text('لیست پرسنل'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: personnelList.isEmpty
          ? Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        itemCount: personnelList.length,
        itemBuilder: (context, index) {
          var personnel = personnelList[index];
          return Card(
            elevation: 4.0,
            color: CustomColor.primaryColor,
            margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: personnel['image_id'] != null
                    ? NetworkImage('https://afkhambpms.ir/api1/files/show/${personnel['image_id']}') as ImageProvider
                    : AssetImage('assets/default_avatar.png') as ImageProvider,
                radius: 50.0,
              ),
              title: Text(
                '${personnel['prefix_name']} ${personnel['first_name']} ${personnel['last_name']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              subtitle: Text(
                'کد پرسنلی : ${personnel['full_code']}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                ),
              ),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PersonnelDetails(personnel),
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
        title: Text(personnel['fullname']),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4.0,
              color: CustomColor.primaryColor,
              margin: EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundImage: personnel['image_id'] != null
                          ? NetworkImage('https://afkhambpms.ir/api1/files/show/${personnel['image_id']}') as ImageProvider
                          : AssetImage('assets/default_avatar.png') as ImageProvider,
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
              title: Text('ایمیل'),
              subtitle: Text((personnel['email']!=null) ? personnel['email'] : 'ثبت نشده'),
              leading: Icon(Icons.email),
            ),
            ListTile(
              title: Text('شماره تلفن'),
              subtitle: Text(personnel['phone']),
              leading: Icon(Icons.phone),
              onTap: () {
                _launchPhoneDialer(personnel['mobile']);
              },
            ),
            ListTile(
              title: Text('شماره موبایل'),
              subtitle: Text(personnel['mobile']),
              leading: Icon(Icons.phone_android),
              onTap: () {
                _launchPhoneDialer(personnel['mobile']);
              },
            ),
            ListTile(
              title: Text('شماره تلفن اضطراری'),
              subtitle: Text(personnel['emergency_phone']),
              leading: Icon(Icons.local_hospital),
              onTap: () {
                _launchPhoneDialer(personnel['mobile']);
              },
            ),
            Divider(),
            ListTile(
              title: Text('تاریخ تولد'),
              subtitle: Text(personnel['birth_date']),
              leading: Icon(Icons.cake),
            ),
            ListTile(
              title: Text('آدرس'),
              subtitle: Text(personnel['address']),
              leading: Icon(Icons.home),
            ),
            ListTile(
              title: Text('مدرک تحصیلی'),
              subtitle: Text(personnel['education_degree']),
              leading: Icon(Icons.school),
            ),
            ListTile(
              title: Text('وضعیت تاهل'),
              subtitle: Text(personnel['marital_status'] == "0" ? 'مجرد' : 'متاهل'),
              leading: Icon(Icons.favorite),
            ),
            ListTile(
              title: Text('تعداد فرزند'),
              subtitle: Text(personnel['children']),
              leading: Icon(Icons.child_care),
            ),
          ],
        ),
      ),
    );
  }
}
