import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart' as ble;

import 'bluetooth.dart';

final flutterReactiveBle = ble.FlutterReactiveBle();

class BluetoothLEReactive extends Bluetooth {
  bool _scanning = true;

  @override
  Future<List<BluetoothDevice>> scanForDevice([void Function(String status)? onStatusChange]) async {
    /// A map of device address and their le counterpart
    final Map<String, BluetoothLEReactiveDevice> deviceMap = {};

    final status = await flutterReactiveBle.statusStream.timeout(const Duration(seconds: 4)).firstWhere((status) => status == ble.BleStatus.ready);

    onStatusChange?.call("BleStatus: $status");

    if (status != ble.BleStatus.ready) {
      onStatusChange?.call("Scanning failed");

      return [];
    }

    onStatusChange?.call("Bluetooth is on");
    onStatusChange?.call("Scanning for devices...");

    final deviceStream = flutterReactiveBle.scanForDevices(withServices: [], scanMode: ble.ScanMode.lowLatency).listen((event) => deviceMap.putIfAbsent(event.id, () => BluetoothLEReactiveDevice(address: event.id, name: event.name)));

    await Future.delayed(const Duration(seconds: 4), () => deviceStream.cancel());

    onStatusChange?.call("Scanning Complete");

    _scanning = false;

    return deviceMap.values.toList();
  }

  @override
  bool get isScanning => _scanning;
}

class BluetoothLEReactiveDevice extends BluetoothDevice {
  BluetoothLEReactiveDevice({required super.name, required super.address});

  ble.DeviceConnectionState _connectionState = ble.DeviceConnectionState.disconnected;
  late StreamSubscription<ble.ConnectionStateUpdate> connectionSubscription;

  static final serviceId = ble.Uuid.parse('FFF0');
  static final readCharacteristicId = ble.Uuid.parse('FFF1');
  static final writeCharacteristicId = ble.Uuid.parse('FFF2');

  late final ble.QualifiedCharacteristic readCharacteristic;
  late final ble.QualifiedCharacteristic writeCharacteristic;

  late final Stream<List<int>> _readStream;

  bool initalised = false;

  @override
  Future<bool> connect() async {
    final Completer connectionCompleter = Completer<bool>();

    connectionSubscription = flutterReactiveBle.connectToDevice(id: address, connectionTimeout: const Duration(seconds: 10)).listen(
      (connectionState) {
        _connectionState = connectionState.connectionState;

        if (_connectionState == ble.DeviceConnectionState.connected && !initalised) {
          readCharacteristic = ble.QualifiedCharacteristic(serviceId: serviceId, characteristicId: readCharacteristicId, deviceId: address);
          writeCharacteristic = ble.QualifiedCharacteristic(serviceId: serviceId, characteristicId: writeCharacteristicId, deviceId: address);
          _readStream = flutterReactiveBle.subscribeToCharacteristic(readCharacteristic).asBroadcastStream();
        }

        if (_connectionState == ble.DeviceConnectionState.connected) connectionCompleter.complete(true);
      },
      cancelOnError: true,
      onError: (e) => connectionCompleter.complete(false),
    );

    return connectionCompleter.future as Future<bool>;
  }

  @override
  Future<bool> disconnect() async {
    connectionSubscription.cancel();

    return true;
  }

  @override
  bool get isConnected => _connectionState == ble.DeviceConnectionState.connected;

  @override
  Stream<List<int>>? listenToData() {
    return _readStream;
  }

  @override
  Future<List<int>?> readData() async {
    final response = await flutterReactiveBle.readCharacteristic(readCharacteristic);

    return response;
  }

  @override
  Future<void> sendData(List<int> data) async {
    await flutterReactiveBle.writeCharacteristicWithResponse(writeCharacteristic, value: data);
  }

  @override
  ConnectionStatus get connectionStatus => ConnectionStatus.values.asNameMap()[_connectionState.name]!;
}
