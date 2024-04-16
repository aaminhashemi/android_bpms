import 'dart:convert';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/action_service.dart';
import '../services/save_assistance_service.dart';
import '../utils/custom_color.dart';
import '../utils/custom_notification.dart';
import '../widgets/app_drawer.dart';
import '../services/auth_service.dart';
import 'package:hive/hive.dart';
import '../models/assistance.dart';

class AssistanceCreate extends StatefulWidget {
  @override
  _AssistanceCreateState createState() => _AssistanceCreateState();
}

class _AssistanceCreateState extends State<AssistanceCreate> {
  TextEditingController dateController = TextEditingController();
  TextEditingController valueController = TextEditingController();
  bool isLoading = false;
  int max_value = 0;
  final AuthService authService = AuthService('https://afkhambpms.ir/api1');

  @override
  void initState() {
    super.initState();
    setInitialDate();
    valueController.addListener(_formatValue);
    fetchMaxAssistanceValue(context);
  }

  Future<void> fetchMaxAssistanceValue(BuildContext context) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      final AuthService authService = AuthService('https://afkhambpms.ir/api1');
      final token = await authService.getToken();
      final response = await http.get(
          Uri.parse('https://afkhambpms.ir/api1/personnels/get-max-assistance'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/x-www-form-urlencoded',
          });

      if (response.statusCode == 200) {
        setState(() {
          max_value = int.parse(json.decode(response.body));
        });
      } else {
        throw Exception('خطا در دریافت داده ها');
      }
    } else {
      var savedValue = await authService.getMaxAssistanceValue();
      setState(() {
        max_value = int.parse(savedValue);
      });
    }
  }

  @override
  void dispose() {
    valueController.removeListener(_formatValue);
    valueController.dispose();
    super.dispose();
  }

  void _formatValue() {
    final numValue = int.tryParse(valueController.text.replaceAll(',', ''));

    if (numValue != null) {
      final limitedValue = numValue.clamp(0, max_value);

      final formattedValue = NumberFormat("#,###").format(limitedValue);
      valueController.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.fromPosition(
          TextPosition(offset: formattedValue.length),
        ),
      );
    }
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
    const apiUrl = 'https://afkhambpms.ir/api1/personnels/save-assistance';
    SaveAssistanceService saveAssistanceService = SaveAssistanceService(apiUrl);
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      final assistanceBox = Hive.box<Assistance>('assistanceBox');
      List<String> parts = dateController.text.trim().split('/');
      String monthName = '';
      switch (parts[1]) {
        case '01':
          monthName = 'فروردین';
          break;
        case '02':
          monthName = 'اردیبهشت';
          break;
        case '03':
          monthName = 'خرداد';
          break;
        case '04':
          monthName = 'تیر';
          break;
        case '05':
          monthName = 'مرداد';
          break;
        case '06':
          monthName = 'شهریور';
          break;
        case '07':
          monthName = 'مهر';
          break;
        case '08':
          monthName = 'آبان';
          break;
        case '09':
          monthName = 'آذر';
          break;
        case '10':
          monthName = 'دی';
          break;
        case '11':
          monthName = 'بهمن';
          break;
        case '12':
          monthName = 'اسفند';
          break;
      }

      Assistance assistance = Assistance(
        level: 'درخواست',
        price: valueController.text.trim(),
        payment_period: '${monthName} ${parts[0]}',
        record_date: dateController.text.trim(),
        deposit_date: null,
        payment_date: null,
        synced: false,
      );
      assistanceBox.add(assistance);
      setState(() {
        isLoading = false;
      });
    } else {
      try {
        final response = await saveAssistanceService.saveAssistance(
          dateController.text.trim(),
          valueController.text.trim(),
        );
        if (response['status'] == 'successful') {
         // try {
            final assistanceBox = Hive.box<Assistance>('assistanceBox');

            Assistance assistance = Assistance(
              level: response['assistance']['level'],
              price: valueController.text.trim(),
              payment_period: response['assistance']['payment_period'],
              record_date: dateController.text.trim(),
              deposit_date: null,
              payment_date: null,
              synced: true,
            );
            assistanceBox.add(assistance);
         /* } catch (e) {
            CustomNotification.show(context, 'ناموفق', 'در ثبت درخواست مشکلی وجود دارد.', '');
            print(e.toString());
          }*/
          CustomNotification.show(context, 'موفقیت آمیز',
              'درخواست مساعده با موفقیت ثبت شد.', '/assistance');
        } else if (response['status'] == 'existed') {
          CustomNotification.show(context, 'خطا',
              'درخواست مساعده قبلا ثبت شده است.', '/assistance');
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: CustomColor.drawerBackgroundColor),
        title: const Text('درخواست مساعده',
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
                        'ثبت درخواست مساعده',
                        style: TextStyle(
                          fontSize: 16,
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
          ),
        ),
      ),
    ]);
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

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : save,
      child: isLoading
          ? CircularProgressIndicator()
          : Text(
              'ثبت',
              style: TextStyle(color: Colors.white),
            ),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        minimumSize: const Size(double.infinity, 48),
        primary: CustomColor.successColor,
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: AllAssistances(),
  ));
}

class AllAssistances extends StatefulWidget {
  @override
  _AllAssistanceListState createState() => _AllAssistanceListState();
}

class _AllAssistanceListState extends State<AllAssistances> {
  bool isLoading = true;
  List<dynamic> allAssistanceList = [];
  Box<Assistance>? assistanceBox;
  List<Assistance>? results;
  bool isSynchronized = true;
  bool isSyncing = false;
  bool isConnected = false;
  double syncPercent = 0;

  Future<void> initBox() async {
    assistanceBox = await Hive.openBox('assistanceBox');
    final List<Assistance>? results =
    assistanceBox?.values.where((data) => data.synced == false).toList();
    if (results!.length > 0) {
      setState(() {
        isSynchronized = false;
      });
    }
    setState(() {});
    print(isSynchronized);
    print('object');
  }
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
  void SendListToServer() async {
    setState(() {
      isSyncing = true;
    });
    ActionService actionService = ActionService('https://afkhambpms.ir/api1');
    const apiUrl = 'https://afkhambpms.ir/api1/personnels/save-assistance';
    SaveAssistanceService saveAssistanceService = SaveAssistanceService(apiUrl);
    final List<Assistance>? results =
    assistanceBox?.values.where((data) => data.synced == false).toList();
    double percent = 0;
    if (results!.isNotEmpty) {
      percent = 1 / (results!.length);
    }
    if (results!.isNotEmpty) {
      for (var result in results) {
        try {
          final response = await saveAssistanceService.saveAssistance(
            result.record_date,
            result.price,
          );
          print(response['status']);
          print("response['status']");
          if (response['status'] == 'successful') {
            Assistance assistance = Assistance(
              level: response['assistance']['level'],
              price: result.price,
              payment_period: response['assistance']['payment_period'],
              record_date: result.record_date,
              deposit_date: null,
              payment_date: null,
              synced: true,
            );
            assistanceBox?.put(result.key, assistance);
            setState(() {
              syncPercent = syncPercent + percent;
            });
          }else if(response['status']=='existed'){
            print('hazf');
            await assistanceBox?.delete(result.key);
            print('dddd');
            setState(() {
              syncPercent = syncPercent + percent;
            });
          }

        } catch (e) {
          CustomNotification.show(context, 'ناموفق', e.toString(), '');
        }finally{
          allAssistanceList=[];
          print(assistanceBox);
          for (var res in assistanceBox!.values.toList()) {
            var assistance = {
              'level': res.level,
              'price': res.price,
              'payment_period': res.payment_period,
              'record_date': res.record_date,
              'deposit_date': res.deposit_date,
              'payment_date': res.payment_date,
            };
            allAssistanceList.add(assistance);
            print(res.payment_period);
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

  late List<bool> _isExpandedList =
      List.generate(allAssistanceList.length, (index) => false);

  @override
  void initState() {
    super.initState();
    initBox();
    connectionChecker();
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
          title: Text('مساعده', style: TextStyle(color: CustomColor.textColor)),
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
              child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  color: CustomColor.buttonColor,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AssistanceCreate(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'درخواست مساعده جدید',
                              style: TextStyle(
                                  color: CustomColor.backgroundColor,
                                  fontWeight: FontWeight.bold),
                            ),
                            //SizedBox(width: 8.0),
                          ],
                        ),
                      ),
                    ),
                  )),
            ),
          ),
          SizedBox(height: 10),
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
                // Add some spacing between the icon and text
                Icon(Icons.update),
                // Add the desired icon
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
              : (allAssistanceList.isEmpty)
                  ? Expanded(
                      child: Center(
                      child: Text(
                        'مساعده یافت نشد!',
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
                                itemCount: allAssistanceList.length,
                                physics: NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  var assistance = allAssistanceList[index];
                                  return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    elevation: 4.0,
                                    color: CustomColor.backgroundColor,
                                    margin: EdgeInsets.only(
                                        left: 16, right: 16, top: 12),
                                    child: ExpansionTile(
                                      onExpansionChanged: (isExpanded) {
                                        setState(() {
                                          _isExpandedList[index] = isExpanded;
                                        });
                                      },
                                      leading: _isExpandedList[index]
                                          ? Icon(Icons.keyboard_arrow_up,
                                              color: CustomColor
                                                  .drawerBackgroundColor)
                                          : Icon(Icons.keyboard_arrow_down,
                                              color: CustomColor
                                                  .drawerBackgroundColor),
                                      shape: LinearBorder.none,
                                      title: RichText(
                                        text: TextSpan(children: <TextSpan>[
                                          TextSpan(
                                            text: 'دوره :',
                                            style: TextStyle(
                                                fontFamily: 'irs',
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.bold,
                                                color: CustomColor.textColor),
                                          ),
                                          TextSpan(
                                            text:
                                                ' ${assistance['payment_period']}',
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
                                            text: 'مبلغ :',
                                            style: TextStyle(
                                                fontFamily: 'irs',
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.bold,
                                                color: CustomColor.textColor),
                                          ),
                                          TextSpan(
                                            text:
                                                ' ${assistance['price']} ریال ',
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
                                            color: CustomColor.cardColor,
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          child: Text(
                                            '${assistance['level']}',
                                            style: TextStyle(
                                                color: CustomColor.textColor),
                                          ),
                                        ),
                                      ),
                                      children: <Widget>[
                                        Container(
                                          color: CustomColor.cardColor,
                                          padding: EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              RichText(
                                                text: TextSpan(
                                                    children: <TextSpan>[
                                                      TextSpan(
                                                        text: 'تاریخ ثبت :',
                                                        style: TextStyle(
                                                            fontFamily: 'irs',
                                                            fontSize: 12.0,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: CustomColor
                                                                .textColor),
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            ' ${assistance['record_date']}',
                                                        style: TextStyle(
                                                            fontFamily: 'irs',
                                                            fontSize: 12.0,
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            color: CustomColor
                                                                .textColor),
                                                      ),
                                                    ]),
                                              ),
                                              Spacer(),
                                              if (assistance['deposit_date'] !=
                                                  null)
                                                RichText(
                                                  text: TextSpan(
                                                      children: <TextSpan>[
                                                        TextSpan(
                                                          text:
                                                              'تاریخ پرداخت :',
                                                          style: TextStyle(
                                                              fontFamily: 'irs',
                                                              fontSize: 12.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: CustomColor
                                                                  .textColor),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              ' ${assistance['payment_date']}',
                                                          style: TextStyle(
                                                              fontFamily: 'irs',
                                                              fontSize: 12.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              color: CustomColor
                                                                  .textColor),
                                                        ),
                                                      ]),
                                                )
                                              else
                                                RichText(
                                                  text: TextSpan(
                                                      children: <TextSpan>[
                                                        TextSpan(
                                                          text:
                                                              'تاریخ پرداخت :',
                                                          style: TextStyle(
                                                              fontFamily: 'irs',
                                                              fontSize: 12.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: CustomColor
                                                                  .textColor),
                                                        ),
                                                        TextSpan(
                                                          text: ' نامشخص',
                                                          style: TextStyle(
                                                              fontFamily: 'irs',
                                                              fontSize: 12.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              color: CustomColor
                                                                  .textColor),
                                                        ),
                                                      ]),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ))))
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
    assistanceBox = await Hive.openBox('assistanceBox');
    var connectivityResult = await Connectivity().checkConnectivity();
    final box = Hive.box<Assistance>('assistanceBox');
    if (connectivityResult != ConnectivityResult.none) {
      results = await assistanceBox?.values
          .where((data) => data.synced == false)
          .toList();
      if (results?.length == 0) {
        await box.clear();
        try {
          final response = await http.get(
              Uri.parse('https://afkhambpms.ir/api1/personnels/get-assistance'),
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
                'Content-Type': 'application/x-www-form-urlencoded',
              });
          print('results?.length');

          if (response.statusCode == 200) {
            var temp = json.decode(response.body);
            var check = await box.values.toList();
            if (check.length == 0) {
              for (var ass in temp) {
                print(ass);

                Assistance assistance = Assistance(
                  level: ass['level'],
                  price: ass['price'],
                  payment_period: ass['payment_period'],
                  record_date: ass['record_date'],
                  deposit_date: ass['deposit_date'],
                  payment_date: ass['payment_date'],
                  synced: true,
                );
                box.add(assistance);
                print('payslipBox.length');
                print(box.length);
              }
            }
            setState(() {
              allAssistanceList = json.decode(response.body);
              isLoading = false;
            });
          } else {
            setState(() {
              isLoading = false;
            });
            throw Exception('خطا در دریافت داده ها');
          }
        } catch (e) {
          CustomNotification.show(
              context,
              'ناموفق',
              'خطا در برقراری ارتباط، اتصال به اینترنت را بررسی نمایید.',
              'assistance');
        } finally {
          setState(() {
            isLoading = false;
          });
        }
      } else {

        print(box);
        for (var res in box.values.toList()..sort((a, b) => b.key.compareTo(a.key))) {
          var assistance = {
            'level': res.level,
            'price': res.price,
            'payment_period': res.payment_period,
            'record_date': res.record_date,
            'deposit_date': res.deposit_date,
            'payment_date': res.payment_date,
          };
          allAssistanceList.add(assistance);
          print(res.payment_period);
        }
        setState(() {
          isLoading = false;
        });

      }
    } else {
      print(box);
      //final x=payslipBox?.values.toList();
      //print(payslipBox?.length);

      for (var res in box.values.toList()) {
        var assistance = {
          'level': res.level,
          'price': res.price,
          'payment_period': res.payment_period,
          'record_date': res.record_date,
          'deposit_date': res.deposit_date,
          'payment_date': res.payment_date,
        };
        allAssistanceList.add(assistance);
        print(res.payment_period);
      }
      setState(() {
        isLoading = false;
      });
    }
  }
}
