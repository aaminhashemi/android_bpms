import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/custom_color.dart';

class AppDrawer extends StatelessWidget {

  final AuthService authService = AuthService('https://afkhambpms.ir/api1');

  void _secondLogout(BuildContext context) async {
    await authService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: CustomColor.buttonColor,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/logo.png') as ImageProvider,
                  radius: 40.0,
                ),
                SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'صنایع غذایی افخم',
                      style: TextStyle(
                        color: CustomColor.textColor,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            title: Text('خانه'),
            leading: Icon(Icons.home),
            onTap: () {
            Navigator.pushReplacementNamed(context, '/personnel');
            },
          ),
          ExpansionTile(
            title: Text('خدمات پرسنلی'),
            leading: Icon(Icons.folder),
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
              _buildListTile('مشاهده فیش حقوقی', onTap: () {
                Navigator.pushReplacementNamed(context, '/payslip');
              }),
            ],
          ),
          _buildListTile('خروج', icon: Icons.logout, onTap: () {
            _secondLogout(context);
            Navigator.pushReplacementNamed(context, '/login');
          }),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, {IconData? icon, VoidCallback? onTap}) {
    return ListTile(
      title: Text(title),
      leading: icon != null ? Icon(icon) : null,
      onTap: onTap,
    );
  }
}
