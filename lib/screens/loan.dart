import 'dart:convert';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../models/loan.dart';
import '../services/action_service.dart';
import '../utils/consts.dart';
import '../utils/exception_consts.dart';
import '../services/loan_service.dart';
import '../utils/custom_color.dart';
import '../utils/custom_notification.dart';
import '../widgets/app_drawer.dart';
import '../services/auth_service.dart';

class LoanCreate extends StatefulWidget {
  @override
  _LoanCreateState createState() => _LoanCreateState();
}

class _LoanCreateState extends State<LoanCreate> {
  TextEditingController dateController = TextEditingController();
  TextEditingController valueController = TextEditingController();
  TextEditingController repaymentCountController = TextEditingController();
  TextEditingController reasonController = TextEditingController();
  bool isLoading = false;
  Box<Loan>? loanBox;

  @override
  void initState() {
    super.initState();
    setInitialDate();
    initBox();
    valueController.addListener(_formatValue);
  }
  Future<void> initBox()async{
    loanBox= await Hive.openBox('loanBox');
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
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      final loanBox = Hive.box<Loan>('loanBox');
      if(dateController.text.trim().length>0 && valueController.text.trim().length>1 && repaymentCountController.text.trim().length>0 && reasonController.text.trim().length>0){
      try{
        Loan loan=Loan(
            jalali_request_date: dateController.text.trim(),
            suggested_value: valueController.text.trim(),
            formatted_requested_value: null,
            level: 'درخواست',
            status: 'recorded',
            suggested_repayment_count: repaymentCountController.text.trim(),
            repayment_count: null,
            formatted_repayment_value: null,
            formatted_residue_value: null,
            description: reasonController.text.trim(),
            synced: false);
        loanBox.add(loan);
        print(loanBox.length);
        setState(() {
          isLoading = false;
        });
        CustomNotification.show(context, 'موفقیت آمیز',
            'درخواست وام با موفقیت ثبت شد.', '/loan');
      }catch(e){
        setState(() {
          isLoading = false;
        });
        CustomNotification.show(context, 'خطا',
            'در ثبت درخواست مشکلی وجود دارد.', '/');
      }
      }else{
        setState(() {
          isLoading = false;
        });
        CustomNotification.show(context, 'خطا',
            'لطفا اطلاعات را به صورت کامل وارد کنید.', '');
      }
    }
    else{
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

        final loanBox = Hive.box<Loan>('loanBox');

        Loan loan=Loan(
            jalali_request_date: dateController.text.trim(),
            suggested_value: valueController.text.trim(),
            formatted_requested_value: null,
            level: response['loan']['level'],
            status: 'recorded',
            suggested_repayment_count: repaymentCountController.text.trim(),
            repayment_count: null,
            formatted_repayment_value:null,
            formatted_residue_value: null,
            description: reasonController.text.trim(),
            synced: true);
        loanBox.add(loan);
        print(response['loan']['level']);

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
    }}
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
          ? CircularProgressIndicator()
          : Text(Consts.save, style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(10.0),
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
  Box<Loan>? loanBox;
  List<Loan>? results;
  bool isSynchronized = true;
  bool isSyncing = false;
  bool isConnected = false;
  double syncPercent = 0;
  Future<void> connectionChecker() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        isConnected = false;
      });
    } else {
      setState(() {
        isConnected = true;
      });
    }
    print(isConnected);
  }
  @override
  void initState() {
    super.initState();
    initBox();
    connectionChecker();
    fetchData(context);
  }
  void SendListToServer() async {
    setState(() {
      isSyncing = true;
    });
    const apiUrl = 'https://afkhambpms.ir/api1/personnels/save-loan';
    LoanService loanService = LoanService(apiUrl);
    final List<Loan>? results =
    loanBox?.values.where((data) => data.synced == false).toList();
    double percent = 0;
    if (results!.isNotEmpty) {
      percent = 1 / (results!.length);
    }
    if (results!.isNotEmpty) {
      for (var result in results) {
        try {
          final response = await loanService.save(
            result.jalali_request_date,
            result.suggested_value,
            result.suggested_repayment_count??'',
            result.description,
          );
          print(response['status']);
          print("response['status']");
          if (response['status'] == 'successful') {
            Loan loan = Loan(
              jalali_request_date: result.jalali_request_date,
              suggested_value: result.suggested_value,
              level: response['loan']['level'],
              status: response['loan']['level'],
              formatted_repayment_value: result.formatted_repayment_value,
              suggested_repayment_count: result.suggested_repayment_count,
              repayment_count: result.repayment_count,
              description: result.description,
              synced: true,
            );
            loanBox?.put(result.key, loan);
            setState(() {
              syncPercent = syncPercent + percent;
            });
          }else if(response['status']=='existed'){
            print('hazf');
            await loanBox?.delete(result.key);
            print('dddd');
            setState(() {
              syncPercent = syncPercent + percent;
            });
          }

        } catch (e) {
          CustomNotification.show(context, 'ناموفق', e.toString(), '');
        }finally{
          allLoanlList=[];
          print(loanBox);
          for (var res in loanBox!.values.toList()) {
            var loan = {
              'jalali_request_date': res.jalali_request_date,
              'formatted_requested_value': res.suggested_value,
              'level': res.level,
              'status': res.status,
              'repayment_count': res.suggested_repayment_count,
              'formatted_repayment_value': res.formatted_repayment_value,
              'formatted_residue_value': res.formatted_residue_value,
              'description': res.description,
            };
            allLoanlList.add(loan);
          }
        }
      }
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        isSyncing = false;
        isSynchronized = true;
      });
    }
  }

  Future<void> initBox() async {
    loanBox = await Hive.openBox('loanBox');
    final List<Loan>? results =
    loanBox?.values.where((data) => data.synced == false).toList();
    if (results!.length > 0) {
      setState(() {
        isSynchronized = false;
      });
    }
    setState(() {});
    print(isSynchronized);
    print('object');
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
        body: (isSyncing)?
        Center(
          child:  Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ' در حال به روز رسانی %${(syncPercent * 100).toInt()}',
                              style: TextStyle(
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: syncPercent,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
            :Column(children: [
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
                                builder: (context) => LoanCreate(),
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
          (!isSynchronized && isConnected)
              ? ElevatedButton(
            style: ButtonStyle(
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("به روز رسانی"),
                SizedBox(width: 8),
                Icon(Icons.update),
              ],
            ),
            onPressed: () {
              SendListToServer();
            },
          )
              : Row(),
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
                                                          text: 'نامشخص',
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
                                                  (loan['formatted_repayment_value'] == null)?
                                                  TextSpan(
                                                    text:
                                                        'نامشخص',
                                                    style: TextStyle(
                                                        fontStyle:
                                                            FontStyle.normal,
                                                        color: CustomColor
                                                            .textColor),
                                                  ):TextSpan(
                                                    text:
                                                    '${loan['formatted_repayment_value']} ${Consts.priceUnit}',
                                                    style: TextStyle(
                                                        fontStyle:
                                                        FontStyle.normal,
                                                        color: CustomColor
                                                            .textColor),
                                                  )
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
                                                  (loan['formatted_residue_value'] == null)?
                                                  TextSpan(
                                                    text:
                                                        'نامشخص',
                                                    style: TextStyle(
                                                        fontStyle:
                                                            FontStyle.normal,
                                                        color: CustomColor
                                                            .textColor),
                                                  ):
                                                  TextSpan(
                                                    text:
                                                    '${loan['formatted_residue_value']} ${Consts.priceUnit}',
                                                    style: TextStyle(
                                                        fontStyle:
                                                        FontStyle.normal,
                                                        color: CustomColor
                                                            .textColor),
                                                  )
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
    loanBox = await Hive.openBox('loanBox');
    var connectivityResult = await Connectivity().checkConnectivity();
    final box = Hive.box<Loan>('loanBox');
    if (connectivityResult != ConnectivityResult.none) {
      results = await loanBox?.values
          .where((data) => data.synced == false)
          .toList();
      if (results?.length == 0) {
        await box.clear();
        try {
          final response = await http.get(
              Uri.parse('https://afkhambpms.ir/api1/personnels/get-loan'),
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
                'Content-Type': 'application/x-www-form-urlencoded',
              });

          if (response.statusCode == 200) {
            var temp = json.decode(response.body);
            var check = await box.values.toList();
            if (check.length == 0) {
              for (var item in temp) {
                print(item);
                Loan loan = Loan(
                  jalali_request_date: item['jalali_request_date'],
                  suggested_value: item['formatted_requested_value'],
                  formatted_requested_value: item['formatted_requested_value'],
                  level: item['level'],
                  status: item['status'],
                  suggested_repayment_count: item['repayment_count'],
                  repayment_count: item['repayment_count'],
                  formatted_repayment_value: item['formatted_repayment_value'],
                  formatted_residue_value: item['formatted_residue_value'],
                  description: item['description'],
                  synced: true,
                );
                box.add(loan);
                print('payslipBox.length');
                print(box.length);
              }
            }
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
              e.toString()/*'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.'*/,
              'loan');
        } finally {
          setState(() {
            isLoading = false;
          });
        }
      }else {
        print(box);
        for (var res in box.values.toList()
          ..sort((a, b) => b.key.compareTo(a.key))) {
          var loan = {
            'jalali_request_date': res.jalali_request_date,
            'formatted_requested_value': res.suggested_value,
            'level': res.level,
            'status': res.status,
            'repayment_count': res.suggested_repayment_count,
            'formatted_repayment_value': res.formatted_repayment_value,
            'formatted_residue_value': res.formatted_residue_value,
            'description': res.description,
          };
          allLoanlList.add(loan);
          print(res.status);
        }
        setState(() {
          isLoading = false;
        });

      }
    }else {
      print(box);
      for (var res in box.values.toList()
        ..sort((a, b) => b.key.compareTo(a.key))) {
        var loan = {
          'jalali_request_date': res.jalali_request_date,
          'formatted_requested_value': res.suggested_value,
          'level': res.level,
          'status': res.status,
          'suggested_repayment_count': res.suggested_repayment_count,
          'formatted_repayment_value': res.formatted_repayment_value,
          'formatted_residue_value': res.formatted_residue_value,
          'repayment_count': res.repayment_count,
          'description': res.description,
        };
        allLoanlList.add(loan);
        print(res.status);
      }
      setState(() {
        isLoading = false;
      });
    }
  }
}
