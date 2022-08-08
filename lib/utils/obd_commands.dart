import 'dart:convert';

import 'package:obd_tuner/utils/bluetooth.dart';

/// # ObdCommands
///
/// This handles advanced communication with the OBD-II reader.
class ObdCommands {
  ObdCommands(this.device);
  static const int commandTerminator = 0x0D; // equal to "\r"

  final BluetoothDevice device;

  Future<String?> _awaitData(Pattern pattern, [bool asHex = false]) async {
    if (asHex) {
      return ascii.decode(await device.listenToData()?.firstWhere((el) => el.map((e) => e.toRadixString(16)).toList().join(" ").contains(pattern), orElse: () => []) ?? []);
    }
    return ascii.decode(await device.listenToData()?.firstWhere((el) => ascii.decode(el).contains(pattern), orElse: () => []) ?? []);
  }

  /// This will handle the command terminator. So just send the command as a string and it will do the rest.
  ///
  /// By default it will match the value as a hex string, like "41 0D".
  Future<void> _send(String data, {Pattern? expectedResponse, bool matchAsHex = true}) async {
    await device.sendData(data.codeUnits + [commandTerminator]);

    if (expectedResponse != null) {
      await _awaitData(expectedResponse, matchAsHex);
    } else {
      // this should allow enough time for the reader to process the command
      await Future.delayed(const Duration(milliseconds: 90));
    }

    return;
  }

  Future<void> runTestCommand([void Function(String)? onEvent]) async {
    // onEvent?.call('Running AT Z');
    // await device.sendData("AT Z\r".codeUnits);

    await _send("AT Z");
    await _send("AT RV", expectedResponse: RegExp(r"[0-9]"), matchAsHex: false);
    await _send("AT DP");
  }

  Future<bool> setupDevice([void Function(String)? onEvent]) async {
    final sub = device.listenToData()?.listen((data) {
      onEvent?.call(ascii.decode(data));
    });
    try {
      await _send("AT Z");
      await _send("AT SP6");
      await _send("AT CAF0");
      await _send("AT CEA");
    } catch (e) {
      print(e);
      await sub?.cancel();
      return false;
    }
    await sub?.cancel();
    return true;
  }

  Future<bool> runBeginCommands([void Function(String)? onEvent]) async {
    final sub = device.listenToData()?.listen((data) {
      onEvent?.call(ascii.decode(data));
    });

    await _send("AT R0"); // turns off responses
    await _send("AT SH 750");
    await _send("5F 02 27 51");
    await _send("AT R1"); // turns on responses

    // I need to fetch the response here, so I'm gonna await the response rather than the command
    _send("AT SH 721", expectedResponse: RegExp(r"06 67 01(\s[0-9a-fA-F]{2}){4} 00"));

    final List<String>? authData = (await _awaitData(RegExp(r"06 67 01(\s[0-9a-fA-F]{2}){4} 00")))?.split(" ");

    if (authData == null) return false;

    try {
      authData[4] = (int.parse("0x${authData[4]}") ^ 0x60).toRadixString(16);
      authData[5] = (int.parse("0x${authData[5]}") ^ 0x60).toRadixString(16);
    } catch (e) {
      print(e);
      return false;
    }

    await _send(authData.join(" "), expectedResponse: "2 67 02");

    await _send("AT R0");
    await _send("AT SH 720");
    await _send("02 A0 27");
    await _send("02 A0 27");
    await _send("02 A0 27");

    await _send("AT R1");
    await _send("AT SH 721");
    await _send("02 10 02", expectedResponse: "01 50");

    await _send("AT SH 7E0");
    await _send("02 10 02", expectedResponse: "01 50");

    await _send("AT R0");
    await _send("AT SH 0001");
    await _send("01");
    await _send("01");
    await _send("06 20 07 01 00 02");
    await _send("02 07");
    await _send("AT R1");
    await _send("04 64 0A A5 51", expectedResponse: "01 3C");

    // I think this is the reply we need, not sure though
    // await _listenFor(device, "729 8");

    // and so on.
    // hopefully this illustrates how this is to write.

    return true;
  }
}
