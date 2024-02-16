import 'package:and/services/update_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../utils/custom_color.dart';
import 'dart:io';

class AppDrawer extends StatefulWidget {
  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String storedValue = 'نامشخص';
  String storedCode = '0';
  String version = '0';
  final prefs = SharedPreferences.getInstance();
  String profileAddress = '';

  void initState() {
    super.initState();
    loadProfile();
    loadUserName();
    loadVersion();
  }

  final AuthService authService = AuthService('https://afkhambpms.ir/api1');
  final UpdateService updateService =
      UpdateService('https://afkhambpms.ir/api1');

  Future<void> loadUserName() async {
    var savedValue = await authService.getInfo();
    print(savedValue['code']);
    setState(() {
      storedValue = savedValue['name'];
      storedCode = savedValue['code'];
    });
  }

  Future<void> loadVersion() async {
    var value = await updateService.getVersion();
    setState(() {
      version = value;
    });
  }

  Future<void> loadProfile() async {
    String profile = await authService.loadImageFromPreferences();
    setState(() {
      profileAddress = profile;
    });
    print(profileAddress);
  }

  void _secondLogout(BuildContext context) async {
    await authService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        backgroundColor: CustomColor.backgroundColor,
        child: Container(
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero,
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                height: 300.0, // Set your desired height
                child: DrawerHeader(
                    decoration: BoxDecoration(
                      color: CustomColor.drawerBackgroundColor,
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'سامانه یکپارچه مدیریتی صنایع غذائی افخم',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: CustomColor.cardColor,
                                  fontWeight: FontWeight.bold),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                //Spacer(),
                                Text(
                                  ' نسخه ${version}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: CustomColor.cardColor),
                                ),
                                SizedBox(
                                  width: 24,
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.yellow,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.green,
                                        width: 3.0,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.file(
                                        File(profileAddress),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(storedValue,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(' کد ملی : ${storedCode}',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal)),
                              ],
                            )
                          ],
                        ),
                      ),
                    )),
              ),
              Column(
                children: [
                  ListTile(
                    title: Text('خانه',
                        style: TextStyle(
                            color: CustomColor.drawerBackgroundColor)),
                    leading: Icon(
                      Icons.home,
                      color: CustomColor.drawerBackgroundColor,
                    ),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/main');
                    },
                  ),
                  ExpansionTile(
                    expandedAlignment: Alignment.center,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1.0),
                    ),
                    title: Text('خدمات پرسنلی',
                        style: TextStyle(
                            color: CustomColor.drawerBackgroundColor)),
                    backgroundColor: CustomColor.cardColor,
                    leading: Icon(
                      Icons.folder,
                      color: CustomColor.drawerBackgroundColor,
                    ),
                    children: [
                      _buildListTile('مرخصی', onTap: () {
                        Navigator.pushReplacementNamed(
                            context, '/leave-request');
                      }),
                      _buildListTile('ماموریت', onTap: () {
                        Navigator.pushReplacementNamed(
                            context, '/mission-request');
                      }),
                      _buildListTile('مساعده', onTap: () {
                        Navigator.pushReplacementNamed(context, '/assistance');
                      }),
                      _buildListTile('وام', onTap: () {
                        Navigator.pushReplacementNamed(context, '/loan');
                      }),
                      _buildListTile('فیش حقوقی', onTap: () {
                        Navigator.pushReplacementNamed(context, '/payslip');
                      }),
                      _buildListTile('ثبت ورود و خروج', onTap: () {
                        Navigator.pushReplacementNamed(context, '/loc');
                      }),
                    ],
                  ),
                  _buildListTile('خروج', icon: Icons.logout, onTap: () {
                    _secondLogout(context);
                    Navigator.pushReplacementNamed(context, '/login');
                  })
                ],
              ),
            ],
          ),
        ));
  }

  Widget _buildListTile(String title, {IconData? icon, VoidCallback? onTap}) {
    return ListTile(
      title: Text(title,
          style: TextStyle(color: CustomColor.drawerBackgroundColor)),
      leading: icon != null
          ? Icon(icon, color: CustomColor.drawerBackgroundColor)
          : null,
      onTap: onTap,
    );
  }
}
