import 'package:obd_tuner/utils/obd_command.dart';

abstract class Bluetooth {
  bool get isScanning;

  Future<List<BluetoothDevice>> scanForDevice([void Function(String)? onStatusChange]);
}

enum ConnectionStatus {
  connected,
  disconnected,
  connecting,
  disconnecting,
  error,
}

abstract class BluetoothDevice {
  BluetoothDevice({required this.name, required this.address});

  final String name;
  final String address;

  OBDCommand? obdCommand;

  ConnectionStatus get connectionStatus;

  bool get isConnected;

  Future<T> runCommand<T>(OBDCommand<T> command) {
    if (obdCommand == null || !(obdCommand?.isRunning ?? false)) {
      command.registerWithDevice(this);
      obdCommand = command;
      obdCommand?.addListener(() {
        if (!(obdCommand?.isRunning ?? false)) obdCommand = null;
      });
      return command.run();
    } else {
      return Future.error(Exception('Command Already Running'));
    }
  }

  Future<bool> connect();

  Future<bool> disconnect();

  Future<void> sendData(List<int> data);
  Future<List<int>?> readData();

  Stream<List<int>>? listenToData();
}
