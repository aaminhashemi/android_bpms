import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';
import '../services/auth_service.dart';
import '../utils/consts.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<WelcomeScreen> {
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
    if (accessToken != null) {
      final validAccessToken =
          await authService.isAccessTokenValid(accessToken);
      await Future.delayed(Duration(seconds: 3));
      (validAccessToken)
          ? Navigator.pushReplacementNamed(context, '/personnel')
          : Navigator.pushReplacementNamed(context, '/login');
    } else {
      await Future.delayed(Duration(seconds: 3));
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void checkForAvailableUpdate() async {
    final response = await updateService.check();
    if (response['status'] == 'successful') {
      print('hi');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(Consts.update,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.normal)),
            content: Text(Consts.updateIsAvailable,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
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
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
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
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage:
                  AssetImage('assets/images/logo.png') as ImageProvider,
              radius: 60.0,
            ),
            SizedBox(height: 16),
            Text(Consts.applicationTitle, style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
