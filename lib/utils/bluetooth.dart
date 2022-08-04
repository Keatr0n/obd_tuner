abstract class Bluetooth {
  Future<List<BluetoothDevice>> scanForDevice([void Function(String)? onStatusChange]);
}

abstract class BluetoothDevice {
  BluetoothDevice(this.name, this.address);

  final String name;
  final String address;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<bool> connect();

  Future<bool> disconnect();

  Future<void> sendData(List<int> data);
  Future<List<int>?> readData();
}
