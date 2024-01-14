import 'package:android_bpms/screens/loan.dart';

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
        backgroundColor: CustomColor.primaryColor, // Set your desired background color for app bars
      ),
    ),
      supportedLocales: const [
        Locale("fa", "IR"),
      ],
      locale: const Locale("fa", "IR"),
      title: 'Flutter Demo',
      home: LoginScreen(),
      routes:{
        '/login':(context)=>LoginScreen(),
        '/personnel':(context)=>PersonnelList(),
        '/payslip':(context)=>PayslipList(),
        '/assistance':(context)=>Assistance(),
        '/loan':(context)=>Loan(),
        '/leave-request':(context)=>LeaveRequest(),
        '/mission-request':(context)=>MissionRequest(),
      },
    );
  }
}
