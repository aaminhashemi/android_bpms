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
  final prefs = SharedPreferences.getInstance();
  String profileAddress = '';

  void initState() {
    super.initState();
    loadProfile();
    loadUserName();
  }

  final AuthService authService = AuthService('https://afkhambpms.ir/api1');

  Future<void> loadUserName() async {
    String savedValue = await authService.getInfo() ?? 'Default Value';
    setState(() {
      storedValue = savedValue;
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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
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
                            fontSize: 12, color: CustomColor.cardColor),
                      ),
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
                                // Set your desired border color
                                width: 2.0, // Set your desired border width
                              ),
                            ),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.green,
                                  // Set your desired border color
                                  width: 2.0, // Set your desired border width
                                ),
                              ),
                              child: ClipOval(
                                child: Image.file(
                                  File(profileAddress),
                                  width: 100, // Set your desired width
                                  height: 100, // Set your desired height
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                      )
                    ],
                  ),
                ),
              )),
          Column(
            children: [
              ListTile(
                title: Text('خانه',
                    style: TextStyle(color: CustomColor.drawerBackgroundColor)),
                leading: Icon(
                  Icons.home,
                  color: CustomColor.drawerBackgroundColor,
                ),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/personnel');
                },
              ),
              ExpansionTile(
                title: Text('خدمات پرسنلی',
                    style: TextStyle(color: CustomColor.drawerBackgroundColor)),
                backgroundColor: CustomColor.cardColor,
                leading: Icon(
                  Icons.folder,
                  color: CustomColor.drawerBackgroundColor,
                ),
                children: [
                  _buildListTile('ثبت مرخصی', onTap: () {
                    Navigator.pushReplacementNamed(context, '/leave-request');
                  }),
                  _buildListTile('ثبت ماموریت', onTap: () {
                    Navigator.pushReplacementNamed(context, '/mission-request');
                  }),
                  _buildListTile('درخواست مساعده', onTap: () {
                    Navigator.pushReplacementNamed(context, '/assistance');
                  }),
                  _buildListTile('درخواست وام', onTap: () {
                    Navigator.pushReplacementNamed(context, '/loan');
                  }),
                  _buildListTile('مشاهده فیش حقوقی', onTap: () {
                    Navigator.pushReplacementNamed(context, '/payslip');
                  }),
                  _buildListTile('ثبت ورود و خروج', onTap: () {
                    Navigator.pushReplacementNamed(context, '/loc');
                  }),
                  /*_buildListTile('مسیر', onTap: () {
                Navigator.pushReplacementNamed(context, '/path');
              })*/
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
    );
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
