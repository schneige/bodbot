import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:sensors_plus/sensors_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// LocationSettings _locationSettings = AndroidSettings(
//     accuracy: LocationAccuracy.high,
//     distanceFilter: 0,
//     forceLocationManager: true,
//     intervalDuration: const Duration(seconds: 1),
//     //(Optional) Set foreground notification config to keep the app alive
//     //when going to the background
//     foregroundNotificationConfig: const ForegroundNotificationConfig(
//       notificationText:
//           "Example app will continue to receive your location even when you aren't using it",
//       notificationTitle: "Running in Background",
//       enableWakeLock: true,
//     ));

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
  bool _started = false;
  double _speed = 0.0;
  late StreamSubscription<Position> _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        _writeToFile("accel", event.toString());
      },
      onError: (error) {
        // Logic to handle error
        // Needed for Android in case sensor is not available
      },
      cancelOnError: true,
    );

    gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        _writeToFile("gyro", event.toString());
      },
      onError: (error) {
        // Logic to handle error
        // Needed for Android in case sensor is not available
      },
      cancelOnError: true,
    );

    magnetometerEventStream().listen(
      (MagnetometerEvent event) {
        _writeToFile("magnet", event.toString());
      },
      onError: (error) {
        // Logic to handle error
        // Needed for Android in case sensor is not available
      },
      cancelOnError: true,
    );
  }

  Future<void> _writeToFile(String filename, String data) async {
    final directory = await getExternalStorageDirectory();
    final path = directory?.path;
    final file = File('$path/$filename.txt');
    await file.writeAsString('${DateTime.now().millisecondsSinceEpoch},$data\n',
        mode: FileMode.append);
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
            //  _locationSettings)
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high, distanceFilter: 0))
        .listen((Position position) {
      _writeToFile("position", position.toString());
      _writeToFile("speed", position.speed.toString());
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
          child: Column(
        children: [
          Text(
            'Speed: ${(_speed * 3.6).toStringAsFixed(2)} km/h', // Convert from m/s to km/h
            style: TextStyle(fontSize: 24),
          ),
          TextButton(
              onPressed: () {
                setState(() {
                  _started = !_started;
                });
              },
              child: _started
                  ? const Text("Recording")
                  : const Text("Start Recording"))
        ],
      )),
    );
  }
}
