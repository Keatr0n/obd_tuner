import 'package:obd_tuner/utils/bluetooth_messages/obd_message_interface.dart';

/// This is a enum which stores messages to be sent to the ecu.
enum OBDIIMessages implements IOBDMessage {
  /// This gets the speed from the ecu
  getCoolantTemperature('0105'),

  /// This gets the speed from the ecu
  getStoredDTC('03'),

  /// This gets the speed from the ecu
  getSpeed('010D'),

  /// A lot of this is pulled from here https://www.obdsol.com/knowledgebase/obd-software-development/reading-real-time-data/
  /// but basically, 010C is the command to access the RPM, the ECU will respond with 41 0C XX XX where XX XX is the RPM
  getRPM('010C');

  const OBDIIMessages(this.payload, {this.expectedResponse});

  @override
  final String payload;
  @override
  final Pattern? expectedResponse;

  @override
  Future<dynamic> parseResponse(DataAwaiter awaitData) async {
    switch (this) {
      case OBDIIMessages.getCoolantTemperature:
        return (double.tryParse("0x${(await awaitData("41 05"))?.replaceFirst("41 05 ", "").replaceAll(" ", "")}") ?? 0 - 40);
      case OBDIIMessages.getSpeed:
        return int.tryParse("0x${(await awaitData("41 0D"))?.replaceFirst("41 0D ", "").replaceAll(" ", "")}") ?? 0;
      case OBDIIMessages.getStoredDTC:
        final data = await awaitData('');
        return;
      case OBDIIMessages.getRPM:
        return (int.tryParse("0x${(await awaitData("41 0C"))?.replaceFirst("41 0C ", "").replaceAll(" ", "")}") ?? 0 ~/ 4);
      default:
        return 0;
    }
  }
}
