import 'dart:convert';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/loan_service.dart';
import '../utils/custom_color.dart';
import '../utils/custom_notification.dart';
import '../widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

class Loan extends StatefulWidget {
  @override
  _LoanState createState() => _LoanState();
}

class _LoanState extends State<Loan> {
  TextEditingController dateController = TextEditingController();
  TextEditingController valueController = TextEditingController();
  TextEditingController repaymentCountController = TextEditingController();
  TextEditingController reasonController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    setInitialDate();
    valueController.addListener(_formatValue);
  }

  @override
  void dispose() {
    valueController.removeListener(_formatValue);
    valueController.dispose();
    super.dispose();
  }

  void setInitialDate() {
    DateTime dt = DateTime.now();
    Jalali j = dt.toJalali();
    final f = j.formatter;
    dateController.text = '${f.yyyy}/${f.mm}/${f.dd}';
  }

  Future<void> save() async {
    setState(() {
      isLoading = true;
    });
    const apiUrl = 'https://afkhambpms.ir/api1/personnels/save-loan';
    LoanService loanService = LoanService(apiUrl);
    try {
      final response = await loanService.save(
        dateController.text.trim(),
        valueController.text.trim(),
        repaymentCountController.text.trim(),
        reasonController.text.trim(),
      );
      print(response);
      if (response['status'] == 'successful') {
        CustomNotification.showCustomSuccess(
          context,
          'درخواست وام با موفقیت ثبت شد.',
        );
      } else {
        CustomNotification.showCustomWarning(
          context,
          'اطلاعات را به صورت کامل وارد کنید.',
        );
      }
    } catch (e) {
      CustomNotification.showCustomDanger(
          context, 'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('درخواست وام'),
      ),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Card(
                color: CustomColor.primaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text(
                        'لیست درخواست ها',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      Spacer(),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AllLoans(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: CustomColor.warningColor,
                            // Set your desired background color
                            borderRadius: BorderRadius.circular(
                                10.0), // Adjust the radius as needed
                          ),
                          child: Text(
                            'مشاهده',
                            style: TextStyle(
                                // Add text styles here if needed
                                ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Card(
                color: CustomColor.primaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'ثبت درخواست وام',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: 16.0),
                      _buildDateTextField(),
                      SizedBox(height: 16.0),
                      _buildValueTextField(),
                      SizedBox(height: 16.0),
                      _buildRepaymentCountTextField(),
                      SizedBox(height: 24.0),
                      _buildReasonTextField(),
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

  void _formatValue() {
    final numValue = int.tryParse(valueController.text.replaceAll(',', ''));

    if (numValue != null) {
      final limitedValue = numValue.clamp(0, 1000000000);

      final formattedValue = NumberFormat("#,###").format(limitedValue);
      valueController.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.fromPosition(
          TextPosition(offset: formattedValue.length),
        ),
      );
    }
  }

  Widget _buildValueTextField() {
    return TextField(
      controller: valueController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: 'مبلغ (ریال)',
        border: OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(12.0),
      ),
    );
  }

  Widget _buildReasonTextField() {
    return TextField(
      controller: reasonController,
      keyboardType: TextInputType.text,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'توضیحات',
        border: OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(12.0),
      ),
    );
  }

  Widget _buildRepaymentCountTextField() {
    return TextField(
      controller: repaymentCountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'تعداد اقساط پیشنهادی',
        border: OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(12.0),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : save,
      child: isLoading
          ? CircularProgressIndicator() // Show loading indicator
          : Text(
              'ثبت',
            ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        primary: CustomColor.buttonColor,
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Loan(),
  ));
}

class AllLoans extends StatefulWidget {
  @override
  _AllLoanListState createState() => _AllLoanListState();
}

class _AllLoanListState extends State<AllLoans> {
  List<dynamic> allLoanlList = [];

  @override
  void initState() {
    super.initState();
    fetchData(context);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لیست درخواست های وام'),
      ),
      body: allLoanlList.isEmpty
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: allLoanlList.length,
              itemBuilder: (context, index) {
                var loan = allLoanlList[index];
                return Card(
                  elevation: 4.0,
                  color: CustomColor.primaryColor,
                  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ExpansionTile(
                    shape: LinearBorder.none,
                    leading: Icon(Icons.keyboard_arrow_down),
                    title: Text(
                      ' تاریخ درخواست : ${loan['jalali_request_date']} ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    subtitle: Text(
                      'مبلغ درخواستی  : ${loan['formatted_requested_value']} ریال ',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    trailing: InkWell(
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: CustomColor.primaryColor,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Text(
                          '${loan['level']}',
                          style: TextStyle(),
                        ),
                      ),
                    ),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'تعداد اقساط  : ${loan['repayment_count']}  ',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Text(
                              'مبلغ هر قسط  : ${loan['formatted_repayment_value']} ریال ',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Text(
                              'مبلغ باقیمانده  : ${loan['formatted_residue_value']} ریال ',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> fetchData(BuildContext context) async {
    final AuthService authService = AuthService('https://afkhambpms.ir/api1');
    final token = await authService.getToken();

    final response = await http.get(
        Uri.parse('https://afkhambpms.ir/api1/personnels/get-loan'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        });

    if (response.statusCode == 200) {
      setState(() {
        allLoanlList = json.decode(response.body);
      });
    } else {
      throw Exception('خطا در دریافت داده ها');
    }
  }
}
