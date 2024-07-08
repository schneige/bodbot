// import 'dart:io';
// import 'dart:async';

// import 'package:path_provider/path_provider.dart';

// class StreamToFileWriter {
//   final Map<String, IOSink> _sinks = {};

//   Future<void> writeToFile(String data, String filePath) async {
//     if (!_sinks.containsKey(filePath)) {
//       final directory = await getExternalStorageDirectory();
//       final path = directory?.path;
//       final file = File('$path/$filePath.txt');
//       _sinks[filePath] = file.openWrite(mode: FileMode.writeOnlyAppend);
//     }
//     IOSink sink = _sinks[filePath]!;
//     final timestamp = DateTime.now().millisecondsSinceEpoch;
//     sink.writeln('$timestamp,$data');
//   }

//   Future<void> closeAll() async {
//     for (var sink in _sinks.values) {
//       await sink.flush();
//       await sink.close();
//     }
//     _sinks.clear();
//   }
// }
