import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';
import '../services/auth_service.dart';
import '../utils/consts.dart';
import '../utils/custom_color.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:geocoding/geocoding.dart';

import '../utils/custom_notification.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<WelcomeScreen> {
  String version = '';
  bool readyToUpdate = false;
  bool isLogined = false;
  bool isDateTimeAutomaticallySet = false;
  final AuthService authService = AuthService('https://afkhambpms.ir/api1');
  final UpdateService updateService =
      UpdateService('https://afkhambpms.ir/api1/update');

  @override
  void initState() {
    super.initState();
    checkForAvailableUpdate();
    checkAccessToken();
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void startPageDetector() {
    (isLogined)
        ? Navigator.pushReplacementNamed(context, '/main')
        : Navigator.pushReplacementNamed(context, '/login');
  }

  void checkAccessToken() async {
    final accessToken = await authService.getToken();
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
        if (accessToken != null) {
          final validAccessToken =
          await authService.isAccessTokenValid(accessToken);
          (validAccessToken)
              ? setState(() {
            isLogined = true;
          })
              : setState(() {
            isLogined = false;
          });
          await Future.delayed(Duration(seconds: 3));
          (validAccessToken)
              ? (!readyToUpdate)
              ? Navigator.pushReplacementNamed(context, '/main')
              : null
              : Navigator.pushReplacementNamed(context, '/login');
        } else {
          await Future.delayed(Duration(seconds: 3));
          (!readyToUpdate)
              ? Navigator.pushReplacementNamed(context, '/login')
              : null;
        }
    } else {
        if (accessToken != null) {
          await Future.delayed(Duration(seconds: 3));
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          await Future.delayed(Duration(seconds: 3));
          Navigator.pushReplacementNamed(context, '/login');
        }

    }
  }

  void checkForAvailableUpdate() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    final versionNumber = await updateService.getVersion();
    setState(() {
      version = versionNumber;
    });
    if (connectivityResult != ConnectivityResult.none) {

      try {
        final response = await updateService.check();
        print(response);
        if (response['status'] == 'successful') {
          setState(() {
            readyToUpdate = true;
          });
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Center(
                    child: Text(Consts.update,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold))),
                content: (response['description']
                    .toString()
                    .length > 0)
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(Consts.updateIsAvailable),
                    SizedBox(height: 10),
                    Text('لیست تغییرات:'),
                    SizedBox(height: 5),
                    Text(response['description']),
                  ],
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(Consts.updateIsAvailable),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    style: ButtonStyle(
                      backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.green),
                      shape: MaterialStateProperty.all<OutlinedBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              7.0),
                        ),
                      ),
                    ),
                    onPressed: () {
                      _launchURL(response['url']);
                    },
                    child: Text(
                      Consts.update, style: TextStyle(color: Colors.white),),
                  ),
                  (response['is_necessary']==0)?
                  TextButton(
                    style: ButtonStyle(
                      backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.red),
                      shape: MaterialStateProperty.all<OutlinedBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              7.0),
                        ),
                      ),
                    ),
                    onPressed: () {
                      startPageDetector();
                    },
                    child: Text(
                        Consts.cancel, style: TextStyle(color: Colors.white)),
                  ):Row(),
                ],
              );
            },
          );
        }
      } catch (e) {
         CustomNotification.show(context, 'ناموفق',
             'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.', 'home');
      }
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.backgroundColor,
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/logo.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Text(
                    'سامانه BPMS',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ' نسخه ${version}',
                    style: TextStyle(fontSize: 18),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
