import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/app_drawer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyPathPage(),
    );
  }
}

class MyPathPage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyPathPage> {
  double totalDistance = 0;
  Position? lastPosition;
  bool isTracking = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/personnel');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('محاسبه مسافت'),
        ),
        drawer: AppDrawer(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                ' مسافت کلی : ${totalDistance.toStringAsFixed(2)} متر ',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _toggleTracking();
                },
                child: Text(isTracking ? 'شروع' : 'پایان'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleTracking() {
    setState(() {
      if (isTracking) {
        isTracking = false;
        lastPosition = null;
      } else {
        isTracking = true;
        lastPosition = null;

        Geolocator.getPositionStream(
          desiredAccuracy: LocationAccuracy.best,
          distanceFilter: 1,
        ).listen((Position position) {
          if (lastPosition != null) {
            double newDistance = Geolocator.distanceBetween(
              lastPosition!.latitude,
              lastPosition!.longitude,
              position.latitude,
              position.longitude,
            );

            setState(() {
              totalDistance += newDistance;
            });
          }
          lastPosition = position;
        });
      }
    });
  }
}
