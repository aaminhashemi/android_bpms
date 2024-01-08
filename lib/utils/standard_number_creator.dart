import 'package:intl/intl.dart';

class StandardNumberCreator{

  static String convert(String inputTime) {
    if (inputTime=='') {
      return '';
    }
    inputTime = inputTime.replaceAllMapped(RegExp(r'[۰-۹]'), (match) {
      return String.fromCharCode(match.group(0)!.codeUnitAt(0) - 1728);
    });
    DateTime dateTime = DateFormat.Hm().parse(inputTime);
    String standardTime = DateFormat.Hm().format(dateTime);
    return standardTime;
  }

}