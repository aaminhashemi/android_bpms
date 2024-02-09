import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../utils/consts.dart';
import '../utils/exception_consts.dart';
import '../services/loan_service.dart';
import '../utils/custom_color.dart';
import '../utils/custom_notification.dart';
import '../widgets/app_drawer.dart';
import '../services/auth_service.dart';

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

      if (response['status'] == 'successful') {
        CustomNotification.showCustomSuccess(
          context,
          'درخواست وام با موفقیت ثبت شد.',
        );
        Navigator.pushReplacementNamed(context, '/loan');
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
      backgroundColor: CustomColor.backgroundColor,
      appBar: AppBar(
        title: const Text(Consts.loanRequest),
      ),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                color: CustomColor.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        Consts.saveLoanRequest,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.normal),
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
        labelText: Consts.requestDate,
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
        labelText: '${Consts.value} (${Consts.priceUnit})',
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
        labelText: Consts.description,
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
        labelText: Consts.requestedRepaymentCount,
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
          : Text(Consts.save),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        primary: CustomColor.buttonColor,
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: AllLoans(),
  ));
}

class AllLoans extends StatefulWidget {
  @override
  _AllLoanListState createState() => _AllLoanListState();
}

class _AllLoanListState extends State<AllLoans> {
  List<dynamic> allLoanlList = [];
  late List<bool> _isExpandedList =
      List.generate(allLoanlList.length, (index) => false);
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData(context);
  }

  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/personnel');
        return false;
      },
      child: Scaffold(
        backgroundColor: CustomColor.backgroundColor,
        appBar: AppBar(
          title: Text(Consts.loansList),
        ),
        drawer: AppDrawer(),
        body: SingleChildScrollView(
            child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                color: CustomColor.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text(
                        'درخواست وام',
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
                              builder: (context) => Loan(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: CustomColor.warningColor,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Row(
                            children: [
                              Text(
                                Consts.create,
                                style: TextStyle(),
                              ),
                              SizedBox(width: 8.0),
                              Icon(Icons.arrow_circle_left),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          (isLoading)
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : (allLoanlList.isEmpty)
                  ? Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Center(
                        child: Card(
                          elevation: 5,
                          margin: EdgeInsets.all(16),
                          child: Container(
                            color: Colors.white10,
                            padding: EdgeInsets.all(16),
                            width: double.infinity,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/box.png',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  Consts.noLoansFound,
                                  style: TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: allLoanlList.length,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        var loan = allLoanlList[index];
                        return Card(
                          color: CustomColor.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          elevation: 4.0,
                          margin: EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: ExpansionTile(
                            onExpansionChanged: (isExpanded) {
                              setState(() {
                                _isExpandedList[index] = isExpanded;
                              });
                            },
                            leading: _isExpandedList[index]
                                ? Icon(Icons.keyboard_arrow_up)
                                : Icon(Icons.keyboard_arrow_down),
                            shape: LinearBorder.none,
                            title: Text(
                              '${Consts.requestDate} : ${loan['jalali_request_date']} ',
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 13.0,
                              ),
                            ),
                            subtitle: Text(
                              '${Consts.requestedValue} : ${loan['formatted_requested_value']} ${Consts.priceUnit} ',
                              style: TextStyle(
                                fontStyle: FontStyle.normal,
                                fontSize: 13.0,
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
                                    Row(
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            style: DefaultTextStyle.of(context)
                                                .style,
                                            children: [
                                              TextSpan(
                                                text:
                                                    '${Consts.repaymentCount}',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              (loan['repayment_count'] == null)
                                                  ? TextSpan(
                                                      text: '0',
                                                      style: TextStyle(
                                                        fontStyle:
                                                            FontStyle.normal,
                                                      ),
                                                    )
                                                  : TextSpan(
                                                      text:
                                                          '${loan['repayment_count']} ',
                                                      style: TextStyle(
                                                        fontStyle:
                                                            FontStyle.normal,
                                                      ),
                                                    ),
                                            ],
                                          ),
                                        ),
                                        Spacer(),
                                        RichText(
                                          text: TextSpan(
                                            style: DefaultTextStyle.of(context)
                                                .style,
                                            children: [
                                              TextSpan(
                                                text:
                                                    '${Consts.repaymentValue}',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              TextSpan(
                                                text:
                                                    '${loan['formatted_repayment_value']} ${Consts.priceUnit}',
                                                style: TextStyle(
                                                  fontStyle: FontStyle.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            style: DefaultTextStyle.of(context)
                                                .style,
                                            children: [
                                              TextSpan(
                                                text: '${Consts.residueValue}',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              TextSpan(
                                                text:
                                                    '${loan['formatted_residue_value']} ${Consts.priceUnit}',
                                                style: TextStyle(
                                                  fontStyle: FontStyle.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Spacer()
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ])),
      ),
    );
  }

  Future<void> fetchData(BuildContext context) async {
    final AuthService authService = AuthService('https://afkhambpms.ir/api1');
    final token = await authService.getToken();
    setState(() {
      isLoading = true;
    });
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
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception(Exception_consts.dataFetchError);
    }
  }
}
