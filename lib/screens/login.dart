import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import '../utils/custom_notification.dart';
import '../utils/consts.dart';
import '../utils/exception_consts.dart';
import '../utils/custom_color.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService authService = AuthService('https://afkhambpms.ir/api1');
  final UpdateService updateService =
      UpdateService('https://afkhambpms.ir/api1/update');
  TextEditingController mobileController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
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
        authService.saveInfo(loginResponse['user']);
        _fetchImageFromServer();
        Navigator.pushReplacementNamed(context, '/personnel');
      } else {
        CustomNotification.showCustomDanger(
            context, Exception_consts.incorrectCredentials);
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

  Future<void> _fetchImageFromServer() async {
    final imageBytes = await authService.fetchImageFromServer();
    if (imageBytes != null) {
      _saveImageLocally(imageBytes);
    }
  }

  Future<void> _saveImageLocally(Uint8List imageBytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/user_profile_picture.jpg';

      // Save the image bytes to the specified path
      await File(imagePath).writeAsBytes(imageBytes);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_picture_path', imagePath);

      setState(() {
        _imageFile = File(imagePath);
      });
    } catch (e) {
      print('Error saving image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.backgroundColor,
      appBar: AppBar(
        //title: Text(Consts.loginToApplication),
        backgroundColor: CustomColor.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(children: [
              CircleAvatar(
                backgroundImage:
                    AssetImage('assets/images/logo.png') as ImageProvider,
                radius: 60.0,
              ),
              SizedBox(height: 32.0),
            ]),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(2.0), // Adjust the radius as needed
              ),
              //elevation: 8,
              color: CustomColor.cardColor,

              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'اطلاعات ورود',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'نام کاربری :',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8.0),
                        Expanded(
                          child: TextField(
                            controller: mobileController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              // Set your desired background color
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'کلمه عبور :',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8.0),
                        Expanded(
                          child: TextField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              // Set your desired background color
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: isLoading ? null : _login,
                      child: isLoading
                          ? CircularProgressIndicator()
                          : Text(
                              'ورود',
                              style: TextStyle(color: Colors.white),
                            ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              10.0), // Adjust the radius as needed
                        ),
                        minimumSize: const Size(double.infinity, 48),
                        primary: CustomColor.successColor,
                      ),
                    )
                  ],
                ),
              ),
            ),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(
                        children: [
                          RichText(
                            text: TextSpan(
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'در صورت فراموشی کلمه عبور ',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black),
                                ),
                                TextSpan(
                                  text: 'اینجا تپ ',
                                  style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      fontSize: 14,
                                      color: Colors.red),
                                ),
                                TextSpan(
                                  text: 'کنید.',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ))
                ]),
          ],
        ),
      ),
    );
  }
}
