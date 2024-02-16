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

    static void show(BuildContext context,String title,String message,String route){
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            title: Text(title,style: TextStyle(fontSize: 16)),
            content: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                (route=='')? '' :
                Navigator.pushReplacementNamed(context, route);
                ;
              },

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Spacer(),
                      (route=='')?
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          primary: CustomColor.successColor,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('باشه'),
                      ):
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          primary: CustomColor.successColor,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushReplacementNamed(context, route);
                        },
                        child: Text('باشه'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      );
    }
}