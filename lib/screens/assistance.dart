import 'package:android_bpms1/services/save_assistance_service.dart';
import 'package:android_bpms1/utils/custom_color.dart';
import 'package:android_bpms1/utils/custom_notification.dart';
import 'package:android_bpms1/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

class Assistance extends StatefulWidget {
  @override
  _AssistanceState createState() => _AssistanceState();
}

class _AssistanceState extends State<Assistance> {
  TextEditingController dateController = TextEditingController();
  TextEditingController valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    setInitialDate();
  }

  void setInitialDate() {
    DateTime dt = DateTime.now();
    Jalali j = dt.toJalali();
    final f = j.formatter;
    dateController.text = '${f.yyyy}/${f.mm}/${f.dd}';
  }

  Future<void> save() async {
    const apiUrl = 'https://afkhambpms.ir/api1/personnels/save-assistance';
    SaveAssistanceService saveAssistanceService = SaveAssistanceService(apiUrl);

    try {
      final response = await saveAssistanceService.saveAssistance(
        dateController.text.trim(),
        valueController.text.trim(),
      );
      print(response);
      if (response['status'] == 'successful') {
        CustomNotification.showCustomSuccess(
          context,
          'درخواست مساعده با موفقیت ثبت شد.',
        );
      } else {
        CustomNotification.showCustomWarning(
          context,
          'اطلاعات را به صورت کامل وارد کنید.',
        );
      }
    } catch (e) {
      CustomNotification.showCustomDanger(context,'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت درخواست مساعده'),
      ),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                color: CustomColor.primaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'درخواست مساعده',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: 16.0),
                      _buildDateTextField(),
                      SizedBox(height: 16.0),
                      _buildValueTextField(),
                      SizedBox(height: 24.0),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTextField() {
    return TextField(
      controller: dateController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'تاریخ',
        border: OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(12.0),
      ),
    );
  }

  Widget _buildValueTextField() {
    return TextField(
      controller: valueController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'مبلغ',
        border: OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(12.0),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: save,
      child: const Text('ثبت'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        primary: CustomColor.buttonColor,
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Assistance(),
  ));
}
