// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';

// import 'package:async/async.dart';
// import 'package:flutter_blue/flutter_blue.dart' as fb;
// import 'package:permission_handler/permission_handler.dart';

// import 'bluetooth.dart';

// fb.FlutterBlue flutterBlue = fb.FlutterBlue.instance;

// /// # Bluetooth
// ///
// /// This makes the whole connecting, sending, receiving, and disconnecting a lot easier.
// class BluetoothLE implements Bluetooth {
//   BluetoothLE();

//   @override
//   Future<List<BluetoothDevice>> scanForDevice([void Function(String)? onStatusChange]) async {
//     onStatusChange?.call("Checking permissions...");
//     await Permission.bluetooth.request();
//     await Permission.bluetoothAdvertise.request();
//     await Permission.bluetoothConnect.request();
//     await Permission.bluetoothScan.request();
//     onStatusChange?.call("Permissions granted\nChecking bluetooth...");

//     if (await flutterBlue.isOn) {
//       onStatusChange?.call("Bluetooth is on");
//       onStatusChange?.call("Scanning for devices...");
//       final data = await flutterBlue.scan(timeout: const Duration(seconds: 5)).toList();
//       onStatusChange?.call("Scanning done\nFound ${data.length} devices");

//       return data.map((e) => BluetoothLEDevice(e.device)).toList();
//     }
//     return [];
//   }
// }

// class BluetoothLEDevice implements BluetoothDevice {
//   BluetoothLEDevice(this.device);

//   final fb.BluetoothDevice device;

//   bool _isConnected = false;

//   @override
//   String get address => device.id.id;
//   @override
//   String get name => device.name;
//   @override
//   bool get isConnected => _isConnected;

//   Stream<List<int>>? _stream;

//   List<fb.BluetoothCharacteristic> readCharacteristics = [];
//   List<fb.BluetoothCharacteristic> writeCharacteristics = [];

//   // Future<void> loadReadCharacteristics() {}

//   // Future<void> loadWriteCharacteristics() {}

//   // Future<void> loadCharacteristics() {}

//   @override
//   Future<bool> connect() async {
//     return device.connect().then((_) {
//       _isConnected = true;
//       readData();

//       return true;
//     }, onError: (e) {
//       print(e);
//       return false;
//     });
//   }

//   @override
//   Future<bool> disconnect() async {
//     return device.disconnect().then((_) {
//       _isConnected = false;
//       return true;
//     }, onError: (e) {
//       print(e);
//       return false;
//     });
//   }

//   @override
//   Future<void> sendData(List<int> data) async {
//     if (!_isConnected) return;

//     // if (_writeCharacteristic == null) {
//     var services = await device.discoverServices();

//     if (services.isEmpty) log("No services found when trying to write data");

//     for (var service in services) {
//       if (service.characteristics.isNotEmpty) {
//         for (var characteristic in service.characteristics) {
//           if (characteristic.properties.write) {
//             await characteristic.setNotifyValue(true);
//             writeCharacteristics.add(characteristic);
//           }
//         }
//       }
//     }
//     // }

//     for (final characteristic in writeCharacteristics) {
//       (await characteristic.write(data));
//     }
//   }

//   @override
//   Future<List<int>?> readData() async {
//     if (!_isConnected) return [];

//     // if (_readCharacteristic == null) {
//     var services = await device.discoverServices();

//     if (services.isEmpty) log("No services found when trying to read data");

//     if (readCharacteristics.isEmpty) {
//       for (var service in services) {
//         if (service.characteristics.isNotEmpty) {
//           for (var characteristic in service.characteristics) {
//             if (characteristic.properties.read) {
//               await characteristic.setNotifyValue(true);
//               readCharacteristics.add(characteristic);
//               // _readCharacteristic = characteristic;
//             }
//           }
//         }
//       }
//     }

//     // if (_readCharacteristic == null) return [];

//     final controller = StreamGroup<List<int>>.broadcast();
//     final List<Stream> streams = [];

//     List<int> result = [];

//     for (final readCharacteristic in readCharacteristics) {
//       controller.add(readCharacteristic.value);
//       final r = await readCharacteristic.read();
//       if (r.isEmpty) {
//         print('Did not return data ${readCharacteristic.uuid}');
//       }

//       print('${readCharacteristic.uuid} produced =>' + ascii.decode(r));
//       result += r;
//     }

//     _stream = controller.stream;
//     _stream?.listen((event) {
//       print(ascii.decode(event));
//     });

//     return result;
//   }

//   @override
//   Stream<List<int>>? listenToData() => _stream;
// }
