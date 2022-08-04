import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';

FlutterBlue flutterBlue = FlutterBlue.instance;

/// # Bluetooth
///
/// This makes the whole connecting, sending, receiving, and disconnecting a lot easier.
class Bluetooth {
  Bluetooth();

  Future<List<BluetoothDevice>> searchForDevices([void Function(String)? onStatusChange]) async {
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

      // for (var datum in data) {
      //   print("----------------------------------");
      //   print(datum.device.id.id);
      //   print(datum.advertisementData.connectable);
      //   print(datum.advertisementData.manufacturerData);
      //   print(datum.advertisementData.localName);
      //   print(datum.device.name);
      //   print(datum.device.type);
      //   print("----------------------------------");
      // }

      return data.map((e) => e.device).toList();
    }
    return [];
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
