import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SpeedScreen(),
    );
  }
}

class SpeedScreen extends StatefulWidget {
  @override
  _SpeedScreenState createState() => _SpeedScreenState();
}

class _SpeedScreenState extends State<SpeedScreen> {
  double _speed = 0.0;
  late StreamSubscription<Position> _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  void _requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    _startListening();
  }

  void _startListening() {
    _positionStreamSubscription = Geolocator.getPositionStream(
            locationSettings: LocationSettings(
                accuracy: LocationAccuracy.high, distanceFilter: 10))
        .listen((Position position) {
      setState(() {
        _speed = position.speed;
      });
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Current Speed'),
      ),
      body: Center(
        child: Text(
          'Speed: ${(_speed * 3.6).toStringAsFixed(2)} km/h', // Convert from m/s to km/h
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
