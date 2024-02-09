import 'package:afkham/screens/location.dart';
import 'package:afkham/screens/path.dart';
import 'package:afkham/screens/welcome.dart';
import '../screens/loan.dart';
import '../screens/assistance.dart';
import '../screens/leave_request.dart';
import '../screens/login.dart';
import '../screens/mission_request.dart';
import '../screens/personnel.dart';
import '../screens/payslip.dart';
import '../utils/custom_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: 'irs',
        appBarTheme: AppBarTheme(
          backgroundColor: CustomColor.test1,
        ),
      ),
      supportedLocales: const [
        Locale("fa", "IR"),
      ],
      routes: {
        '/home': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/personnel': (context) => PersonnelList(),
        '/payslip': (context) => PayslipList(),
        '/assistance': (context) => AllAssistances(),
        '/loan': (context) => AllLoans(),
        '/leave-request': (context) => AllLeaves(),
        '/mission-request': (context) => AllMissions(),
        '/loc': (context) => MyHomePage(),
        // '/path': (context) => MyPathPage(),
      },
      locale: const Locale("fa", "IR"),
      title: 'افخم',
      home: WelcomeScreen(),
    );
  }
}
