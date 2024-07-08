import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'writer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensors Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0x9f4376f8),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.title});

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const String userAccelorometer_data = 'user_accelerometer_data';
  static const String accelorometer_data = 'accelerometer_data';
  static const String magnetometer_data = 'magnetometer_data';
  static const String gyroscope_data = 'gyroscope_data';
  static const String position_data = 'position_data';
  static const String speed_data = 'speed_data';

  IOSink? user_accelerometer_data_sink;
  IOSink? accelerometer_data_sink;
  IOSink? gyroscope_data_sink;
  IOSink? magnetometer_data_sink;
  IOSink? speed_data_sink;
  IOSink? position_data_sink;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  Duration sensorInterval = SensorInterval.normalInterval;
  final int bufferSize = 100;
  final Map<String, List<String>> _buffers = {};

  bool recording = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensors Plus Example'),
        elevation: 4,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                  onPressed: () async {
                    if (mounted) {
                      setState(() {
                        recording = !recording;
                      });
                      setRecording();
                    }
                    print(recording);
                  },
                  child: const Text("Button"))
            ],
          )
        ],
      ),
    );
  }

  void setRecording() {
    if (!recording) {
      sense();
    } else {
      dispose();
    }
  }

  @override
  void dispose() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // When the app starts requestpermission is triggered to get location permission from the phone
    _requestPermission();
    openFiles();
    sense();
  }

  Future<void> openFiles() async {
    final user_accelerometer_data_file =
        File(await _getFilePath(userAccelorometer_data));
    user_accelerometer_data_sink =
        user_accelerometer_data_file.openWrite(mode: FileMode.writeOnlyAppend);

    final accelerometer_data_file =
        File(await _getFilePath(accelorometer_data));
    accelerometer_data_sink =
        accelerometer_data_file.openWrite(mode: FileMode.writeOnlyAppend);

    final magnetometer_data_file = File(await _getFilePath(magnetometer_data));
    magnetometer_data_sink =
        magnetometer_data_file.openWrite(mode: FileMode.writeOnlyAppend);

    final gyroscope_data_file = File(await _getFilePath(gyroscope_data));
    gyroscope_data_sink =
        gyroscope_data_file.openWrite(mode: FileMode.writeOnlyAppend);

    final speed_data_file = File(await _getFilePath(speed_data));
    speed_data_sink = speed_data_file.openWrite(mode: FileMode.writeOnlyAppend);

    final position_data_file = File(await _getFilePath(position_data));
    position_data_sink =
        position_data_file.openWrite(mode: FileMode.writeOnlyAppend);
  }

  void closeFiles() async {
    await user_accelerometer_data_sink?.flush();
    await user_accelerometer_data_sink?.close();
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
  }

  void _handleSensorEvent(String data, String filePath) async {
    // print(filePath);
    if (!_buffers.containsKey(filePath)) {
      _buffers[filePath] = [];
    }

    _buffers[filePath]!.add(data);

    if (_buffers[filePath]!.length >= bufferSize) {
      final path = await _getFilePath(filePath);
      await _writeToFile(filePath, path, _buffers[filePath]!);
      _buffers[filePath]!.clear();
    }
  }

  Future<String> _getFilePath(String fileName) async {
    final directory = await getExternalStorageDirectory();
    return '${directory?.path}/$fileName';
  }

  Future<void> _writeToFile(
      String filename, String filePath, List<String> buffer) async {
    // print(filename);
    for (var data in buffer) {
      switch (filename) {
        case "user_accelerometer_data":
          user_accelerometer_data_sink?.writeln(data);
          break;
        case "accelerometer_data":
          accelerometer_data_sink?.writeln(data);
          break;
        case "magnetometer_data":
          magnetometer_data_sink?.writeln(data);
          break;
        case "gyroscope_data":
          gyroscope_data_sink?.writeln(data);
          break;
        case "position_data":
          position_data_sink?.writeln(data);
          break;
        case "speed_data":
          speed_data_sink?.writeln(data);
          break;

        default:
        // throw Exception("no file found");
      }
    }
  }

  // 5 sensor Subscriptions are added to a list so we can dispose of them later if we need
  void sense() {
    _streamSubscriptions.add(
      userAccelerometerEventStream(samplingPeriod: sensorInterval).listen(
        (UserAccelerometerEvent event) {
          final now = DateTime.now().millisecondsSinceEpoch;
          // setState(() {
          //   _userAccelerometerEvent = event;
          //   if (_userAccelerometerUpdateTime != null) {
          //     final interval = now.difference(_userAccelerometerUpdateTime!);
          //     if (interval > _ignoreDuration) {
          //       _userAccelerometerLastInterval = interval.inMilliseconds;
          //     }
          //   }
          // });
          // _userAccelerometerUpdateTime = now;
          _handleSensorEvent(
            '$now,${event.x},${event.y},${event.z}',
            userAccelorometer_data,
          );
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support User Accelerometer Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      accelerometerEventStream(samplingPeriod: sensorInterval).listen(
        (AccelerometerEvent event) {
          final now = DateTime.now().millisecondsSinceEpoch;
          // setState(() {
          //   _accelerometerEvent = event;
          //   if (_accelerometerUpdateTime != null) {
          //     final interval = now.difference(_accelerometerUpdateTime!);
          //     if (interval > _ignoreDuration) {
          //       _accelerometerLastInterval = interval.inMilliseconds;
          //     }
          //   }
          // });
          // _accelerometerUpdateTime = now;
          _handleSensorEvent(
            '$now,${event.x},${event.y},${event.z}',
            accelorometer_data,
          );
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support Accelerometer Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      gyroscopeEventStream(samplingPeriod: sensorInterval).listen(
        (GyroscopeEvent event) {
          final now = DateTime.now().millisecondsSinceEpoch;
          // print("what");
          // setState(() {
          //   _gyroscopeEvent = event;
          //   if (_gyroscopeUpdateTime != null) {
          //     final interval = now.difference(_gyroscopeUpdateTime!);
          //     if (interval > _ignoreDuration) {
          //       _gyroscopeLastInterval = interval.inMilliseconds;
          //     }
          //   }
          // });
          // _gyroscopeUpdateTime = now;
          _handleSensorEvent(
            '$now,${event.x},${event.y},${event.z}',
            gyroscope_data,
          );
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support Gyroscope Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      magnetometerEventStream(samplingPeriod: sensorInterval).listen(
        (MagnetometerEvent event) {
          final now = DateTime.now().millisecondsSinceEpoch;
          // setState(() {
          //   _magnetometerEvent = event;
          //   if (_magnetometerUpdateTime != null) {
          //     final interval = now.difference(_magnetometerUpdateTime!);
          //     if (interval > _ignoreDuration) {
          //       _magnetometerLastInterval = interval.inMilliseconds;
          //     }
          //   }
          // });
          // _magnetometerUpdateTime = now;
          _handleSensorEvent(
            '$now,${event.x},${event.y},${event.z}',
            magnetometer_data,
          );
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support Magnetometer Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high, distanceFilter: 1))
        .listen((Position position) {
      final now = DateTime.now().millisecondsSinceEpoch;
      // setState(() {
      //   _position = position;
      //   if (_gpsUpdateTime != null) {
      //     final interval = now.difference(_gpsUpdateTime!);
      //     if (interval > _ignoreDuration) {
      //       _gyroscopeLastInterval = interval.inMilliseconds;
      //     }
      //   }
      // });
      // _gpsUpdateTime = now;
      _handleSensorEvent(
        '$now,${position.speed.toString()}',
        speed_data,
      );
      _handleSensorEvent(
        '$now,${position.toString()}',
        position_data,
      );
    }));
  }
}
