import 'package:flutter_blue/flutter_blue.dart' as fb;
import 'package:flutter_blue/gen/flutterblue.pb.dart' as pb;
import 'package:permission_handler/permission_handler.dart';

import 'bluetooth.dart';

fb.FlutterBlue flutterBlue = fb.FlutterBlue.instance;

/// # Bluetooth
///
/// This makes the whole connecting, sending, receiving, and disconnecting a lot easier.
class BluetoothLE implements Bluetooth {
  BluetoothLE();

  @override
  Future<List<BluetoothDevice>> scanForDevice([void Function(String)? onStatusChange]) async {
    onStatusChange?.call("Checking permissions...");
    await Permission.bluetooth.request();
    await Permission.bluetoothAdvertise.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    onStatusChange?.call("Permissions granted\nChecking bluetooth...");

    if (await flutterBlue.isOn) {
      onStatusChange?.call("Bluetooth is on");
      onStatusChange?.call("Scanning for devices...");
      final data = await flutterBlue.scan(timeout: const Duration(seconds: 5)).toList();
      onStatusChange?.call("Scanning done\nFound ${data.length} devices");

      return data.map((e) => BluetoothLEDevice(e.device)).toList();
    }
    return [];
  }
}

class BluetoothLEDevice implements BluetoothDevice {
  BluetoothLEDevice(this.device);

  final fb.BluetoothDevice device;

  bool _isConnected = false;

  @override
  String get address => device.id.id;
  @override
  String get name => device.name;
  @override
  bool get isConnected => _isConnected;

  fb.BluetoothCharacteristic? _readCharacteristic = fb.BluetoothCharacteristic.fromProto(pb.BluetoothCharacteristic(uuid: "0000FFF1-0000-1000-8000-008055F9b34fb", serviceUuid: "0000FFF0-0000-1000-8000-008055F9b34fb"));
  fb.BluetoothCharacteristic? _writeCharacteristic = fb.BluetoothCharacteristic.fromProto(pb.BluetoothCharacteristic(uuid: "0000FFF2-0000-1000-8000-008055F9b34fb", serviceUuid: "0000FFF0-0000-1000-8000-008055F9b34fb"));

  @override
  Future<bool> connect() async {
    return device.connect().then((_) {
      _isConnected = true;
      return true;
    }, onError: (e) {
      print(e);
      return false;
    });
  }

  @override
  Future<bool> disconnect() async {
    return device.disconnect().then((_) {
      _isConnected = false;
      return true;
    }, onError: (e) {
      print(e);
      return false;
    });
  }

  @override
  Future<void> sendData(List<int> data) async {
    if (!_isConnected) return;

    if (_writeCharacteristic == null) {
      var services = await device.services.first;

      for (var service in services) {
        if (service.characteristics.isNotEmpty) {
          for (var characteristic in service.characteristics) {
            if (characteristic.properties.write) {
              _writeCharacteristic = characteristic;
              break;
            }
          }
        }
      }
    }

    if (_writeCharacteristic == null) return;

    return _writeCharacteristic?.write(data);
  }

  @override
  Future<List<int>?> readData() async {
    if (!_isConnected) return [];

    if (_readCharacteristic == null) {
      var services = await device.services.first;

      for (var service in services) {
        if (service.characteristics.isNotEmpty) {
          for (var characteristic in service.characteristics) {
            if (characteristic.properties.read) {
              _readCharacteristic = characteristic;
              break;
            }
          }
        }
      }
    }

    if (_readCharacteristic == null) return [];

    return _readCharacteristic?.read();
  }

  void setToHardCodedDefault() {
    _readCharacteristic = fb.BluetoothCharacteristic.fromProto(pb.BluetoothCharacteristic(uuid: "0000FFF1-0000-1000-8000-008055F9b34fb", serviceUuid: "0000FFF0-0000-1000-8000-008055F9b34fb"));
    _writeCharacteristic = fb.BluetoothCharacteristic.fromProto(pb.BluetoothCharacteristic(uuid: "0000FFF2-0000-1000-8000-008055F9b34fb", serviceUuid: "0000FFF0-0000-1000-8000-008055F9b34fb"));
  }

  @override
  Stream<List<int>>? listenToData() {
    if (!_isConnected) return null;

    return _readCharacteristic?.value;
  }
}
