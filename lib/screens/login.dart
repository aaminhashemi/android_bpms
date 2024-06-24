import 'dart:typed_data';
import 'dart:io';
import 'package:afkham/services/action_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import '../utils/custom_notification.dart';
import '../utils/exception_consts.dart';
import '../utils/custom_color.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService authService = AuthService('https://afkhambpms.ir/api1');
  final ActionService actionService = ActionService('https://afkhambpms.ir/api1');
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
      print(loginResponse);
      if (loginResponse.containsKey('access_token')) {
        authService.saveToken(loginResponse['access_token']);
        authService.saveMaxAssistanceValue(loginResponse['max_assistance_value']);
        actionService.saveThresholdDistance(loginResponse['distance']);
        actionService.saveLastActionDescription(loginResponse['last_action_description']);
        actionService.saveLastActionType(loginResponse['last_action_type']);
        authService.saveInfo(loginResponse['user'], loginResponse['code']);
        authService.getPersonnelShift(loginResponse['access_token']);
        _fetchImageFromServer(loginResponse['code']);
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        CustomNotification.show(
            context, 'ناموفق', Exception_consts.incorrectCredentials, '');
      }
    } catch (e) {
      CustomNotification.show(context, 'ناموفق',
          'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.', '');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchImageFromServer(String code) async {
    final imageBytes = await authService.fetchImageFromServer();
    if (imageBytes != null) {
      _saveImageLocally(imageBytes, code);
    }
  }

  Future<void> _saveImageLocally(Uint8List imageBytes, String imageName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/${imageName}.jpg';
      await File(imagePath).writeAsBytes(imageBytes);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_picture_path', imagePath);
      if (mounted) {
        setState(() {
          _imageFile = File(imagePath);
        });
      }
    } catch (e) {
      print('Error saving image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: CustomColor.backgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: CustomColor.backgroundColor,
        ),
        body: Center(
            child: SingleChildScrollView(
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
                      BorderRadius.circular(2.0),
                ),
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
                                color: CustomColor.textColor),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 75,
                            child: Text(
                              'نام کاربری :',
                              style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.normal,
                                  color: CustomColor.textColor),
                            ),
                          ),
                          SizedBox(width: 8.0),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                    left: BorderSide(
                                        color: CustomColor.textColor,
                                        width: 4.0)),
                              ),
                              child: TextField(
                                controller: mobileController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 7),
                                  isDense: true,
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 75,
                            child: Text(
                              'کلمه عبور :',
                              style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.normal,
                                  color: CustomColor.textColor),
                            ),
                          ),
                          SizedBox(width: 8.0),
                          Expanded(
                              child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                  left: BorderSide(
                                      color: CustomColor.textColor,
                                      width: 4.0)),
                            ),
                            child: TextField(
                              obscureText: true,
                              controller: passwordController,
                              style: TextStyle(),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 7),
                                isDense: true,
                                border: InputBorder.none,
                              ),
                            ),
                          )),
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
                                10.0),
                          ),
                          minimumSize: const Size(double.infinity, 48),
                          primary: CustomColor.successColor,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 15),
                            child: RichText(
                              text: TextSpan(
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'ورود با کد تایید',
                                    style: TextStyle(
                                        fontFamily: 'irs',
                                        fontSize: 14,
                                        color: Colors.blue),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.pushReplacementNamed(
                                            context, '/login-otp');
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                                        fontFamily: 'irs',
                                        fontSize: 14,
                                        color: CustomColor.textColor),
                                  ),
                                  TextSpan(
                                    text: 'اینجا تپ ',
                                    style: TextStyle(
                                        fontFamily: 'irs',
                                        decoration: TextDecoration.underline,
                                        fontSize: 14,
                                        color: Colors.red),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.pushReplacementNamed(
                                            context, '/verify-mobile');
                                      },
                                  ),
                                  TextSpan(
                                    text: 'کنید.',
                                    style: TextStyle(
                                        fontFamily: 'irs',
                                        fontSize: 14,
                                        color: CustomColor.textColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ))
                  ]),
            ],
          ),
        )));
  }
}
