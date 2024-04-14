import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:otp_autofill/otp_autofill.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import '../utils/custom_notification.dart';
import '../utils/custom_color.dart';

class VerifyMobileScreen extends StatefulWidget {
  @override
  _VerifyMobileScreenState createState() => _VerifyMobileScreenState();
}

class _VerifyMobileScreenState extends State<VerifyMobileScreen> {
  final AuthService authService = AuthService('https://afkhambpms.ir/api1');
  final UpdateService updateService =
      UpdateService('https://afkhambpms.ir/api1/update');
  TextEditingController mobileController = TextEditingController();
  late OTPTextEditController verifyCodeController;
  TextEditingController passwordController = TextEditingController();
  TextEditingController passwordRepeatController = TextEditingController();
  final FocusNode myFocusNode = FocusNode();
  File? _imageFile;
  late OTPInteractor _otpInteractor;

  bool isLoading = false;
  bool showPasswordFields = false;
  bool showVerifyCodeField = false;

  int minutes = 0;
  int seconds = 0;
  late Timer timer;

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

  void startTimer() {
    const oneSecond = Duration(seconds: 1);
    timer = Timer.periodic(oneSecond, (timer) {
      setState(() {
        if (minutes == 0 && seconds == 0) {
          setState(() {
            showVerifyCodeField = false;
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

  void checkMobile() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response =
          await authService.checkMobile(mobileController.text.trim());
      if (response['status'] == 'successful') {
        setState(() {
          minutes = 2;
          showVerifyCodeField = true;
          isLoading = false;
        });
        FocusScope.of(context).requestFocus(myFocusNode);
        startTimer();
      } else {
        CustomNotification.show(
            context, 'خطا', 'کاربری با این شماره موبایل یافت نشد.', '');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      CustomNotification.show(
          context,
          'ناموفق',
          'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.',
          'verify-mobile');
    }finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void checkCode() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await authService.checkCode(
          mobileController.text.trim(), verifyCodeController.text.trim());
      if (response['status'] == 'successful') {
        setState(() {
          showPasswordFields = true;
          isLoading = false;
        });
        if (response.containsKey('access_token')) {
          authService.saveToken(response['access_token']);
          authService.saveInfo(response['user'], response['code']);
          _fetchImageFromServer(response['code']);
        }
      } else if (response['status'] == 'wrong_code') {
        CustomNotification.show(
            context, 'ناموفق', 'کد وارد شده اشتباه است.', '');
        setState(() {
          isLoading = false;
        });
      } else {
        CustomNotification.show(
            context, 'ناموفق', 'کاربری با این شماره موبایل وجود ندارد.', '');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      CustomNotification.show(
          context,
          'ناموفق',
          'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.',
          'verify-mobile');
    }finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void changePassword() async {
    if (passwordRepeatController.text.trim() ==
        passwordController.text.trim()) {
      setState(() {
        isLoading = true;
      });
      try {
        final response =
            await authService.changePassword(passwordController.text.trim());
        if (response['status'] == 'successful') {
          CustomNotification.show(context, 'موفقیت آمیز',
              'عملیات تغییر رمز با موفقیت انجام شد.', '/main');
          setState(() {
            isLoading = false;
          });
        } else if (response['status'] == 'unsuccessful') {
          CustomNotification.show(context, 'ناموفق', 'عملیات انجام نشد.', '');
          setState(() {
            isLoading = false;
          });
        } else {
          CustomNotification.show(context, 'ناموفق', 'عملیات انجام نشد.', '');
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        CustomNotification.show(
            context,
            'ناموفق',
            'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.',
            'verify-mobile');
      }finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      CustomNotification.show(
          context, 'خطا', 'رمز عبور و تکرار آن یکسان نیستند!', '');
    }
  }

  @override
  void dispose() {
    verifyCodeController.stopListen();
    super.dispose();
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

  Future<void> _fetchImageFromServer(String code) async {
    final imageBytes = await authService.fetchImageFromServer();
    if (imageBytes != null) {
      _saveImageLocally(imageBytes, code);
    }
  }

  Widget createNewPasswordField() {
    return Column(children: [
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
                    left: BorderSide(color: CustomColor.textColor, width: 4.0)),
              ),
              child: TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 7),
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
              'تکرار کلمه عبور :',
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
                    left: BorderSide(color: CustomColor.textColor, width: 4.0)),
              ),
              child: TextField(
                controller: passwordRepeatController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 7),
                  isDense: true,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: 16.0),
    ]);
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
                    borderRadius: BorderRadius.circular(
                        2.0), // Adjust the radius as needed
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
                              'تغییر کلمه عبور',
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
                                'موبایل :',
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
                                  readOnly: showVerifyCodeField,
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
                        (showVerifyCodeField)
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
                                      readOnly: showPasswordFields,
                                      focusNode: myFocusNode,
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
                        (showPasswordFields) ? createNewPasswordField() : Row(),
                        (!showVerifyCodeField)
                            ? ElevatedButton(
                                onPressed: isLoading ? null : checkMobile,
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
                            : Row(),
                        (!showPasswordFields && showVerifyCodeField)
                            ? ElevatedButton(
                                onPressed: isLoading ? null : checkCode,
                                child: isLoading
                                    ? CircularProgressIndicator()
                                    : Text(
                                        'بررسی',
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
                            : Row(),
                        (showPasswordFields && showVerifyCodeField)
                            ? ElevatedButton(
                                onPressed: isLoading ? null : changePassword,
                                child: isLoading
                                    ? CircularProgressIndicator()
                                    : Text(
                                        'تغییر کلمه عبور',
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
                            : Row(),
                        (showVerifyCodeField && !showPasswordFields)
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
