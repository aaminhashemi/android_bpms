import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';
import '../services/auth_service.dart';
import '../utils/consts.dart';
import '../utils/custom_color.dart';
import '../utils/custom_notification.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<WelcomeScreen> {
  String version = '';
  final AuthService authService = AuthService('https://afkhambpms.ir/api1');
  final UpdateService updateService =
      UpdateService('https://afkhambpms.ir/api1/update');

  @override
  void initState() {
    super.initState();
    checkAccessToken();
    checkForAvailableUpdate();
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void checkAccessToken() async {
    final accessToken = await authService.getToken();
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      if (accessToken != null) {
        final validAccessToken =
            await authService.isAccessTokenValid(accessToken);
        await Future.delayed(Duration(seconds: 3));
        (validAccessToken)
            ? Navigator.pushReplacementNamed(context, '/main')
            : Navigator.pushReplacementNamed(context, '/login');
      } else {
        await Future.delayed(Duration(seconds: 3));
        Navigator.pushReplacementNamed(context, '/login');
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
    final versionNumber = await updateService.getVersion();
    setState(() {
      version = versionNumber;
    });
    try {
      final response = await updateService.check();
      if (response['status'] == 'successful') {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(Consts.update,
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.normal)),
              content: Text(Consts.updateIsAvailable,
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              actions: <Widget>[
                TextButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.green),
                  ),
                  onPressed: () {
                    _launchURL(response['url']);
                  },
                  child: Text(Consts.update),
                ),
                TextButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.red),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(Consts.cancel),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // CustomNotification.show(context, 'ناموفق',
      //     'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.', 'home');
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.backgroundColor,
      body: Stack(
        children: [
          // Logo at the center
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
