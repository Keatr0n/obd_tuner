import 'dart:convert';

import 'package:obd_tuner/utils/bluetooth.dart';

/// # ObdCommands
///
/// This handles advanced communication with the OBD-II reader.
class ObdCommands {
  static const int commandTerminator = 0x0D; // equal to "\r"

  static Future<void> _listenFor(BluetoothDevice device, String data) async {
    await device.listenToData()?.firstWhere((el) => ascii.decode(el).contains(data));
    return;
  }

  static Future<bool> runDemoCommand(BluetoothDevice device, [void Function(String)? onEvent]) async {
    final sub = device.listenToData()?.listen((data) {
      onEvent?.call(ascii.decode(data));
    });

    await device.sendData("AT Z\r".codeUnits);
    await device.sendData("AT SP6\r".codeUnits);
    await device.sendData("AT CAF0\r".codeUnits);
    await device.sendData("AT CEA\r".codeUnits);
    await device.sendData("AT SH 721\r".codeUnits);
    await device.sendData("02 27 01\r".codeUnits);

    // I think this is the reply we need, not sure though
    await _listenFor(device, "729 8");

    // and so on.
    // hopefully this illustrates how this is to write.

    return false;
  }
}
