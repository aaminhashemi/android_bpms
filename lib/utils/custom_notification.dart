import 'package:flutter/material.dart';

import 'custom_color.dart';

class CustomNotification{

    static void showCustomDanger(BuildContext context, String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: CustomColor.textColor),
          ),
          backgroundColor: CustomColor.dangerColor,
        ),
      );
    }

    static void showCustomWarning(BuildContext context, String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: CustomColor.textColor),
          ),
          backgroundColor: CustomColor.warningColor,
        ),
      );
    }

    static void showCustomSuccess(BuildContext context, String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: CustomColor.textColor),
          ),
          backgroundColor: CustomColor.successColor,
        ),
      );
    }
}