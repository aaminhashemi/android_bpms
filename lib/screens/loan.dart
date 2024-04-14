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
        CustomNotification.show(
            context, 'موفقیت آمیز', 'درخواست وام با موفقیت ثبت شد.', '/loan');
      } else if (response['status'] == 'imperfect_data') {
        CustomNotification.show(
            context, 'خطا', 'لطفا اطلاعات را به صورت کامل وارد کنید.', '');
      } else {
        CustomNotification.show(
            context, 'ناموفق', 'در ثبت درخواست مشکلی وجود دارد.', '');
      }
    } catch (e) {
      CustomNotification.show(context, 'ناموفق',
          'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.', '');
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
        iconTheme: IconThemeData(color: CustomColor.drawerBackgroundColor),
        title: const Text(Consts.loanRequest,
            style: TextStyle(color: CustomColor.textColor)),
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
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 75,
        child: Text(
          'تاریخ درخواست :',
          style: TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      SizedBox(width: 8.0),
      Expanded(
          child: Container(
              decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(color: CustomColor.textColor, width: 4.0)),
              ),
              child: InputDecorator(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.only(right: 1, left: 1),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  child: TextField(
                    controller: dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                      border: InputBorder.none,
                    ),
                  ))))
    ]);
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
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 75,
        child: Text(
          'مبلغ (ریال) :',
          style: TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      SizedBox(width: 8.0),
      Expanded(
          child: Container(
              decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(color: CustomColor.textColor, width: 4.0)),
              ),
              child: TextField(
                controller: valueController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                  border: InputBorder.none,
                ),
              )))
    ]);
  }

  Widget _buildReasonTextField() {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 75,
        child: Text(
          'توضیحات :',
          style: TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      SizedBox(width: 8.0),
      Expanded(
          child: Container(
              decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(color: CustomColor.textColor, width: 4.0)),
              ),
              child: InputDecorator(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.only(right: 1, left: 1),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  child: TextField(
                    controller: reasonController,
                    keyboardType: TextInputType.text,
                    maxLines: 3,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                      border: InputBorder.none,
                    ),
                  ))))
    ]);
  }

  Widget _buildRepaymentCountTextField() {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 75,
        child: Text(
          'تعداد اقساط :',
          style: TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      SizedBox(width: 8.0),
      Expanded(
          child: Container(
              decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(color: CustomColor.textColor, width: 4.0)),
              ),
              child: InputDecorator(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.only(right: 1, left: 1),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  child: TextField(
                    controller: repaymentCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                      border: InputBorder.none,
                    ),
                  ))))
    ]);
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : save,
      child: isLoading
          ? CircularProgressIndicator() // Show loading indicator
          : Text(Consts.save, style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(10.0), // Adjust the radius as needed
        ),
        minimumSize: const Size(double.infinity, 48),
        primary: CustomColor.successColor,
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
        Navigator.pushReplacementNamed(context, '/main');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: CustomColor.drawerBackgroundColor),
          title: Text(Consts.loansList,
              style: TextStyle(color: CustomColor.textColor)),
        ),
        drawer: AppDrawer(),
        body: Column(children: [
          Container(
            color: CustomColor.backgroundColor,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  color: CustomColor.buttonColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  Consts.loanRequest,
                                  style: TextStyle(
                                      color: CustomColor.backgroundColor,
                                      fontWeight: FontWeight.bold),
                                ),
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
          ),
          (isLoading)
              ? Expanded(
                  child: Center(
                  child: CircularProgressIndicator(),
                ))
              : (allLoanlList.isEmpty)
                  ? Expanded(
                      child: Center(
                      child: Text(
                        'وام یافت نشد!',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ))
                  : Expanded(
                      child: SingleChildScrollView(
                          child: Padding(
                      padding: EdgeInsets.only(bottom: 15),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: allLoanlList.length,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          var loan = allLoanlList[index];
                          return Card(
                            color: CustomColor.backgroundColor,
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
                                  ? Icon(Icons.keyboard_arrow_up,
                                      color: CustomColor.drawerBackgroundColor)
                                  : Icon(Icons.keyboard_arrow_down,
                                      color: CustomColor.drawerBackgroundColor),
                              shape: LinearBorder.none,
                              title: RichText(
                                text: TextSpan(children: <TextSpan>[
                                  TextSpan(
                                    text: '${Consts.requestDate}  :',
                                    style: TextStyle(
                                        fontFamily: 'irs',
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.bold,
                                        color: CustomColor.textColor),
                                  ),
                                  TextSpan(
                                    text: ' ${loan['jalali_request_date']}  ',
                                    style: TextStyle(
                                        fontFamily: 'irs',
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.normal,
                                        color: CustomColor.textColor),
                                  ),
                                ]),
                              ),
                              subtitle: RichText(
                                text: TextSpan(children: <TextSpan>[
                                  TextSpan(
                                    text: '${Consts.requestedValue}  :',
                                    style: TextStyle(
                                        fontFamily: 'irs',
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.bold,
                                        color: CustomColor.textColor),
                                  ),
                                  TextSpan(
                                    text:
                                        ' ${loan['formatted_requested_value']} ${Consts.priceUnit}  ',
                                    style: TextStyle(
                                        fontFamily: 'irs',
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.normal,
                                        color: CustomColor.textColor),
                                  ),
                                ]),
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
                                Container(
                                  color: CustomColor.cardColor,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                style:
                                                    DefaultTextStyle.of(context)
                                                        .style,
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        '${Consts.repaymentCount} :',
                                                    style: TextStyle(
                                                        color: CustomColor
                                                            .textColor,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  (loan['repayment_count'] ==
                                                          null)
                                                      ? TextSpan(
                                                          text: '0',
                                                          style: TextStyle(
                                                              fontStyle:
                                                                  FontStyle
                                                                      .normal,
                                                              color: CustomColor
                                                                  .textColor),
                                                        )
                                                      : TextSpan(
                                                          text:
                                                              '${loan['repayment_count']} ',
                                                          style: TextStyle(
                                                              fontStyle:
                                                                  FontStyle
                                                                      .normal,
                                                              color: CustomColor
                                                                  .textColor),
                                                        ),
                                                ],
                                              ),
                                            ),
                                            Spacer(),
                                            RichText(
                                              text: TextSpan(
                                                style:
                                                    DefaultTextStyle.of(context)
                                                        .style,
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        '${Consts.repaymentValue} :',
                                                    style: TextStyle(
                                                        color: CustomColor
                                                            .textColor,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        '${loan['formatted_repayment_value']} ${Consts.priceUnit}',
                                                    style: TextStyle(
                                                        fontStyle:
                                                            FontStyle.normal,
                                                        color: CustomColor
                                                            .textColor),
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
                                                style:
                                                    DefaultTextStyle.of(context)
                                                        .style,
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        '${Consts.residueValue} :',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: CustomColor
                                                            .textColor),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        '${loan['formatted_residue_value']} ${Consts.priceUnit}',
                                                    style: TextStyle(
                                                        fontStyle:
                                                            FontStyle.normal,
                                                        color: CustomColor
                                                            .textColor),
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
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    )))
        ]),
      ),
    );
  }

  Future<void> fetchData(BuildContext context) async {
    final AuthService authService = AuthService('https://afkhambpms.ir/api1');
    final token = await authService.getToken();
    setState(() {
      isLoading = true;
    });
    try {
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
    } catch (e) {
      CustomNotification.show(context, 'ناموفق',
          'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.', 'loan');
    }finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
