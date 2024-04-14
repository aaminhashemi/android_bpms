import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import '../utils/custom_notification.dart';
import '../utils/custom_color.dart';
import 'package:otp_autofill/otp_autofill.dart';

class OtpLoginScreen extends StatefulWidget {
  @override
  _OtpLoginScreenState createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final AuthService authService = AuthService('https://afkhambpms.ir/api1');
  final UpdateService updateService =
      UpdateService('https://afkhambpms.ir/api1/update');
  TextEditingController mobileController = TextEditingController();
  late OTPTextEditController verifyCodeController;
  bool isLoading = false;
  bool canReceiveNewCode = true;
  int minutes = 0;
  int seconds = 0;
  File? _imageFile;
  late Timer timer;
  late OTPInteractor _otpInteractor;

  @override
  void initState() {
    super.initState();
    _initInteractor();
    verifyCodeController = OTPTextEditController(
      codeLength: 5,
      onCodeReceive: (code) => print('Your Application receive code - $code'),
      otpInteractor: _otpInteractor,
    )..startListenUserConsent(
        (code) {
          final exp = RegExp(r'(\d{5})');
          return exp.stringMatch(code ?? '') ?? '';
        },
        strategies: [],
      );
  }

  Future<void> _initInteractor() async {
    _otpInteractor = OTPInteractor();
    final appSignature = await _otpInteractor.getAppSignature();
    if (kDebugMode) {
      print('Your app signature: $appSignature');
    }
  }

  @override
  void dispose() {
    verifyCodeController.stopListen();
    super.dispose();
  }

  void requestNewCode() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response =
          await authService.otpCheckMobile(mobileController.text.trim());
      if (response['status'] == 'successful') {
        setState(() {
          minutes = 2;
          canReceiveNewCode = false;
          isLoading = false;
        });
        startTimer();
      } else {
        CustomNotification.show(
            context, 'خطا', 'کاربری با این شماره موبایل یافت نشد.', '');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      CustomNotification.show(context, 'ناموفق',
          'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.', 'home');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void startTimer() {
    const oneSecond = Duration(seconds: 1);
    timer = Timer.periodic(oneSecond, (timer) {
      setState(() {
        if (minutes == 0 && seconds == 0) {
          setState(() {
            canReceiveNewCode = true;
          });
          timer.cancel();
        } else if (seconds == 0) {
          minutes--;
          seconds = 59;
        } else {
          seconds--;
        }
      });
    });
  }

  void _login() async {
    setState(() {
      isLoading = true;
    });
    try {
      final loginResponse = await authService.otpCheckCode(
        mobileController.text.trim(),
        verifyCodeController.text,
      );
      print(loginResponse);
      if (loginResponse.containsKey('access_token')) {
        authService.saveToken(loginResponse['access_token']);
        authService.saveInfo(loginResponse['user'], loginResponse['code']);
        _fetchImageFromServer(loginResponse['code']);
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        CustomNotification.show(
            context, 'ناموفق', 'کد وارد شده اشتباه است.', '');
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
      setState(() {
        _imageFile = File(imagePath);
      });
    } catch (e) {
      print('Error saving image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/login');
        return false;
      },
      child: Scaffold(
        backgroundColor: CustomColor.backgroundColor,
        appBar: AppBar(
          //title: Text(Consts.loginToApplication),
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
                  borderRadius: BorderRadius.circular(2.0),
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
                                readOnly: !canReceiveNewCode,
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
                      (!canReceiveNewCode)
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 75,
                                  child: Text(
                                    'کد تایید :',
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
                                    controller: verifyCodeController,
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
                            )
                          : Row(),
                      SizedBox(height: 16.0),
                      (canReceiveNewCode)
                          ? ElevatedButton(
                              onPressed: isLoading ? null : requestNewCode,
                              child: isLoading
                                  ? CircularProgressIndicator()
                                  : Text(
                                      'درخواست کد تایید',
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
                          : ElevatedButton(
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
                            ),
                      (!canReceiveNewCode)
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 15),
                                    child: Text(
                                        '${minutes}:${seconds} تا درخواست مجدد کد تایید '),
                                  )
                                ])
                          : Row(),
                      Row(
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 15),
                            child: RichText(
                              text: TextSpan(
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'ورود با نام کاربری و کلمه عبور',
                                    style: TextStyle(
                                        fontFamily: 'irs',
                                        fontSize: 14,
                                        color: Colors.blue),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.pushReplacementNamed(
                                            context, '/login');
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
            ],
          )),
        ),
      ),
    );
  }
}
