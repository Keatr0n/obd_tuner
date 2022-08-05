import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as bc;
import 'package:permission_handler/permission_handler.dart';

import 'bluetooth.dart';

bc.FlutterBluetoothSerial bluetoothClassic = bc.FlutterBluetoothSerial.instance;

class BluetoothClassic implements Bluetooth {
  @override
  Future<List<BluetoothClassicDevice>> scanForDevice([void Function(String p1)? onStatusChange]) async {
    onStatusChange?.call("Checking permissions...");
    await Permission.bluetooth.request();
    await Permission.bluetoothAdvertise.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    onStatusChange?.call("Permissions granted");

    onStatusChange?.call("Scanning for devices...");
    final data = await bluetoothClassic.getBondedDevices();
    onStatusChange?.call("Scanning done\nFound ${data.length} devices");

    return data.map((e) => BluetoothClassicDevice(e)).toList();
  }
}

class BluetoothClassicDevice implements BluetoothDevice {
  BluetoothClassicDevice(this.device);

  final bc.BluetoothDevice device;

  @override
  String get address => device.address;

  @override
  String get name => device.name ?? "";

  @override
  bool get isConnected => _connection != null;

  bc.BluetoothConnection? _connection;

  Stream<List<int>>? _stream;

  @override
  Future<bool> connect() async {
    try {
      _connection = await bc.BluetoothConnection.toAddress(device.address);
      _stream = _connection?.input?.asBroadcastStream();
      return _connection?.isConnected ?? false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  @override
  Future<bool> disconnect() async {
    if (isConnected) {
      await _connection?.finish();
      _connection = null;
      return true;
    }
    return false;
  }

  @override
  Future<List<int>?> readData() async {
    if (isConnected) {
      return _connection?.input?.first.then((value) => value.toList());
    }
    return null;
  }

  @override
  Future<void> sendData(List<int> data) async {
    if (isConnected) {
      return _connection?.output.add(Uint8List.fromList(data));
    }
  }

  @override
  Stream<List<int>>? listenToData() => _stream;
}
