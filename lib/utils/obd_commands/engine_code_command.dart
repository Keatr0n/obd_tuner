import 'package:obd_tuner/utils/bluetooth_messages/obdii_messages.dart';
import 'package:obd_tuner/utils/obd_command.dart';

import 'dart:convert';

class EngineCodeCommand extends OBDCommand<ETEngineCode> {
  String intTo8bitString(int number, {bool prefix = false}) => prefix ? '0x${number.toRadixString(2).padLeft(8, '0')}' : '${number.toRadixString(2).padLeft(8, '0')}';

  final _pattern = RegExp(r'(?:0x)?(\d+)');

  int binaryStringToInt(String binaryString) => int.parse(_pattern.firstMatch(binaryString)!.group(1)!, radix: 2);

  @override
  Future<ETEngineCode> run() async {
    start();
    send(OBDIIMessages.getStoredDTC);

    int bitIndex = 0;

    while (isRunning) {
      final data = await device.listenToData()?.first;

      if (data?.contains(">") ?? false) complete();
    }

    return ETEngineCode.completelyFucked;
  }
}

enum ETEngineCode { completelyFucked }
