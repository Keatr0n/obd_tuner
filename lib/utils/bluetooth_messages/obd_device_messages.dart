import 'package:obd_tuner/utils/bluetooth_messages/obd_message_interface.dart';

enum OBDDeviceMessages implements IOBDMessage {
  /// This should return the voltage that the obd device is receiving
  readVoltage('AT RV'),

  /// Gets the current mode of the device
  getDeviceMode('AT DP'),

  /// Confirm that it is in auto mode
  confirmAutomaticMode('AT DP', 'auto'),

  /// switch to Auto mode which will allow us to read the live data
  switchToAutomaticMode("AT SP 0", 'OK');

  const OBDDeviceMessages(this.payload, [this.expectedResponse]);

  @override
  final String payload;
  @override
  final Pattern? expectedResponse;

  @override
  Future<dynamic> parseResponse(DataAwaiter awaitData) async {
    switch (this) {
      case OBDDeviceMessages.readVoltage:
        return double.tryParse(await awaitData(RegExp(r"[0-9]")) ?? "0") ?? 0 / 10;
      default:
        return 0;
    }
  }

  // @override
  // Future<num> parseResponse(String response) async {
  //   switch (this) {
  //     case OBDDeviceMessages.readVoltage:
  //       return double.tryParse(response) ?? 0 / 10;
  //     default:
  //       return 0;
  //   }
  // }
}
