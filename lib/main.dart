import 'package:android_bpms1/screens/assistance.dart';
import 'package:android_bpms1/screens/leave_request.dart';
import 'package:android_bpms1/screens/login.dart';
import 'package:android_bpms1/screens/mission_request.dart';
import 'package:android_bpms1/screens/personnel.dart';
import 'package:android_bpms1/screens/payslip.dart';
import 'package:android_bpms1/utils/custom_color.dart';
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
        '/leave-request':(context)=>LeaveRequest(),
        '/mission-request':(context)=>MissionRequest(),
      },
    );
  }
}
