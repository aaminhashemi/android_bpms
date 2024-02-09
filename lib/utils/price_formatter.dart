import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class PriceFormatter{
  static void formatValue(TextEditingController controller) {
    final numValue = int.tryParse(controller.text.replaceAll(',', ''));

    if (numValue != null) {
      final limitedValue = numValue.clamp(0, 1000000000);

      final formattedValue = NumberFormat("#,###").format(limitedValue);
      controller.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.fromPosition(
          TextPosition(offset: formattedValue.length),
        ),
      );
    }
  }
}