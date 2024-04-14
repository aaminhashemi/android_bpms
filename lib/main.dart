import 'package:afkham/models/payslip.dart';
import 'package:afkham/models/rollcal.dart';
import 'package:hive_flutter/adapters.dart';
import '../screens/otp_login.dart';
import '../screens/payslip.dart';
import '../screens/verify_mobile.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../screens/location.dart';
import '../screens/welcome.dart';
import '../screens/loan.dart';
import '../screens/assistance.dart';
import '../screens/leave_request.dart';
import '../screens/login.dart';
import '../screens/mission_request.dart';
import '../screens/home.dart';
import '../utils/custom_color.dart';
import 'models/coordinate.dart';


Future<void> main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(RollcalAdapter());
  Hive.registerAdapter(CoordinateAdapter());
  Hive.registerAdapter(PayslipAdapter());
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
          backgroundColor: CustomColor.backgroundColor,
        ),
      ),
      supportedLocales: const [
        Locale("fa", "IR"),
      ],
      routes: {
        '/home': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/login-otp': (context) => OtpLoginScreen(),
        '/main': (context) => Home(),
        '/assistance': (context) => AllAssistances(),
        '/loan': (context) => AllLoans(),
        '/leave-request': (context) => AllLeaves(),
        '/mission-request': (context) => AllMissions(),
        '/verify-mobile': (context) => VerifyMobileScreen(),
        '/loc': (context) => AllList(),
        '/payslip': (context) => PayslipList(),
      },
      locale: const Locale("fa", "IR"),
      title: 'افخم',
      home: WelcomeScreen(),
    );
  }
}
