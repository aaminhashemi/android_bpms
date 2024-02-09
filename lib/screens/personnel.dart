import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
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
  }

  void _logout(BuildContext context) async {
    await authService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.backgroundColor,
      appBar: AppBar(
        title: Text(Consts.personnelList),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: 4.0,
                  color: (personnel['is_verified']) ? CustomColor.cardColor : CustomColor.emptyListColor,
                  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 50.0,
                      child: ClipOval(
                        child: personnel['image_id'] != null
                            ? Image.network(
                                'https://afkhambpms.ir/api1/files/show/${personnel['image_id']}',
                                width: 50,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/images/default.png',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    title: Text(
                      '${personnel['prefix_name']} ${personnel['first_name']} ${personnel['last_name']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                    subtitle: Text(
                      ' ${Consts.personnelCode} : ${personnel['full_code']}',
                      style: TextStyle(
                        fontStyle: FontStyle.normal,
                        fontSize: 12.0,
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
      backgroundColor: CustomColor.backgroundColor,
      appBar: AppBar(
        title: Text(personnel['fullname']),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4.0,
              color: (personnel['is_verified']) ? CustomColor.cardColor : CustomColor.emptyListColor,
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
