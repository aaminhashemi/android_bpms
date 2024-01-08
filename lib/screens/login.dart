import 'package:android_bpms1/utils/custom_color.dart';
import 'package:android_bpms1/utils/custom_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_install_apk_silently/flutter_install_apk_silently.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService authService = AuthService('https://afkhambpms.ir/api1');
  final UpdateService updateService = UpdateService('https://afkhambpms.ir/api1/update');
  TextEditingController mobileController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkAccessToken();
  }

  void checkAccessToken() async {
    final accessToken = await authService.getToken();
    if (accessToken != null) {
      final validAccessToken =
          await authService.isAccessTokenValid(accessToken);
      if (validAccessToken) {
        Navigator.pushReplacementNamed(context, '/personnel');
      }
    }
  }

  void checkForAvailableUpdate() async {
    final response = await updateService.check();
    if(response['status']=='successful'){
      _downloadAndInstall(response['address']);
    }
  }
  Future<void> _downloadAndInstall(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final file = File('path/to/your/download/folder/newer_app.apk');
      await file.writeAsBytes(response.bodyBytes);
     // _installApk(file);
    } catch (error) {
      print('Error downloading: $error');
    }
  }
  Future<void> _installApk(File apkFile) async {
    try {
     // await FlutterInstallApkSilently.installApkSilently(apkFile.path);
    } catch (error) {
      print('Error installing APK: $error');
    }
  }
  void _login() async {
    setState(() {
      isLoading = true;
    });
    try {
      final loginResponse = await authService.login(
        mobileController.text.trim(),
        passwordController.text,
      );

      if (loginResponse.containsKey('access_token')) {
        authService.saveToken(loginResponse['access_token']);
        Navigator.pushReplacementNamed(context, '/personnel');
      } else {
        CustomNotification.showCustomWarning(
            context, 'اطلاعات وارد شده با داده های ما همخوانی ندارد!');
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
        title: Text('ورود به سامانه'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 8,
              color: CustomColor.primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          AssetImage('assets/images/logo.png') as ImageProvider,
                      radius: 60.0,
                    ),
                    SizedBox(height: 16.0),
                    TextField(
                      controller: mobileController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'نام کاربری',
                        border: OutlineInputBorder(),
                        contentPadding: const EdgeInsets.all(12.0),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'کلمه عبور',
                        border: OutlineInputBorder(),
                        contentPadding: const EdgeInsets.all(12.0),
                      ),
                    ),
                    SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: _login,
                      child: isLoading
                          ? CircularProgressIndicator() // Show loading indicator
                          : Text(
                              'ورود',
                            ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                        primary: CustomColor.buttonColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
