import 'dart:math';

class ETVehicle {
  final String? vin;
  final String make;
  final String model;
  final String imageUrl;
  final String? linkedUserUid;
  final String? linkedOBDDeviceId;

  ETVehicle({
    this.vin,
    required this.make,
    required this.model,
    required this.imageUrl,
    this.linkedUserUid,
    required this.linkedOBDDeviceId,
  });

  Map<String, dynamic> exportAsFirebaseVehicle() {
    return {
      "vin": vin,
      "make": make,
      "model": model,
      "imageUrl": imageUrl,
      "linkedUserUid": linkedUserUid,
      "linkedOBD2DeviceId": linkedOBDDeviceId,
    };
  }

  factory ETVehicle.fromFirebase(Map<String, dynamic> vehicle) {
    return ETVehicle(
      vin: vehicle["vin"],
      make: vehicle["make"] ?? "DeLorean Motor Company",
      model: vehicle["model"] ?? "DMC12",
      imageUrl: vehicle["imageUrl"] ?? "gs://m-engineering-app.appspot.com/vehicles/delorean.png",
      linkedUserUid: vehicle["linkedUserUid"],
      linkedOBDDeviceId: vehicle["linkedOBD2DeviceId"],
    );
  }

  factory ETVehicle.test() {
    return ETVehicle(
      vin: "",
      make: "DeLorean Motor Company",
      model: "DMC12",
      imageUrl: "gs://m-engineering-app.appspot.com/vehicles/delorean.png",
      linkedUserUid: "",
      linkedOBDDeviceId: "",
    );
  }
}

class ETVehicleLiveData {
  ETVehicleLiveData({
    required this.rpm,
    required this.speed,
    required this.coolantTemp,
    required this.boostPressure,
    required this.voltage,
    required this.egt,
  });

  final int rpm;
  final int speed;
  final double coolantTemp;
  final double boostPressure;
  final double voltage;

  /// Exhaust gas temperature
  final double egt;

  factory ETVehicleLiveData.random() {
    return ETVehicleLiveData(
      boostPressure: (Random().nextInt(6000) - 1000) / 100,
      coolantTemp: (Random().nextInt(1000) + 100) / 10,
      egt: (Random().nextInt(1000) + 100) / 10,
      rpm: Random().nextInt(10000),
      speed: Random().nextInt(200),
      voltage: (Random().nextInt(30) + 100) / 10,
    );
  }
}

class ErrorCode {
  ErrorCode(this.code, this.message);

  final int code;
  final String message;
}
