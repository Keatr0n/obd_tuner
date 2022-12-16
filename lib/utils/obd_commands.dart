import 'dart:async';
import 'dart:convert';

import 'package:obd_tuner/utils/bluetooth.dart';
import 'package:obd_tuner/vehicle.dart';

/// # ObdCommands
///
/// This handles advanced communication with the OBD-II reader.
class ObdCommands {
  ObdCommands(this.device);
  static const int commandTerminator = 0x0D; // equal to "\r"

  final BluetoothDevice device;

  Future<String?> _awaitData(Pattern pattern, [bool asHex = false]) async {
    if (asHex) {
      return ascii.decode(await device.listenToData()?.firstWhere((el) => el.map((e) => e.toRadixString(16)).toList().join(" ").contains(pattern), orElse: () => [0]) ?? [0]);
    }
    return ascii.decode(await device.listenToData()?.firstWhere((el) => ascii.decode(el).contains(pattern), orElse: () => [0]) ?? [0]);
  }

  /// This will handle the command terminator. So just send the command as a string and it will do the rest.
  ///
  /// By default expectedResponse will match the value as a hex string, like "41 0D".
  ///
  /// if ignorePromptCharacter is true, we will not wait for the prompt character before returning.
  Future<void> _send(
    String data, {
    Pattern? expectedResponse,
    bool matchAsHex = true,
    int? delay,
    bool ignorePromptCharacter = false,
    bool unsafelySendWithoutDelay = false,
  }) async {
    await device.sendData(data.codeUnits + [commandTerminator]);

    if (unsafelySendWithoutDelay) return;

    if (!ignorePromptCharacter) {
      await _awaitData(">");
      return;
    }

    if (expectedResponse != null) {
      await _awaitData(expectedResponse, matchAsHex);
      return;
    }

    // this should allow enough time for the reader to process the command
    await Future.delayed(Duration(milliseconds: delay ?? 100));

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
      // onEvent?.call(ascii.decode(data));
    });
    try {
      await _send("AT Z");
      await _send("AT AL");
      await _send("AT SP6");
      await _send("AT CAF0");
      await _send("AT CEA");
      await _send("AT BI");
      await _send("AT V0");
    } catch (e, s) {
      onEvent?.call("Error: $e\n$s");
      await sub?.cancel();
      return false;
    }
    await sub?.cancel();
    return true;
  }

  Stream<ETVehicleLiveData> liveDataStream() {
    late StreamController<ETVehicleLiveData> controller;
    bool isRunning = false;
    // https://en.wikipedia.org/wiki/OBD-II_PIDs#Service_01_PID_78
    // need to check if it's actually supported, if not just leave it 0
    // bool isEgtSupported = true;

    void cancelStream() {
      isRunning = false;
      controller.close();
    }

    void dataFetcher() async {
      // switch to Auto mode which will allow us to read the live data
      await _send("AT SP 0", expectedResponse: "OK");
      // confirm that it is in auto mode
      await _send("AT DP", expectedResponse: "AUTO");

      while (isRunning && !controller.isClosed) {
        // a lot of this is pulled from here https://www.obdsol.com/knowledgebase/obd-software-development/reading-real-time-data/
        // but basically, 010C is the command to access the RPM, the ECU will respond with 41 0C XX XX where XX XX is the RPM
        _send("010C");

        // this utter mess is extracting the RPM from the response, making it base 10, dividing it by 4, then returning it as a string
        final int rpm = (int.tryParse("0x${(await _awaitData("41 0C"))?.replaceFirst("41 0C ", "").replaceAll(" ", "")}") ?? 0 ~/ 4);

        // this is the same as above, but for the speed
        _send("010D");

        final int speed = int.tryParse("0x${(await _awaitData("41 0D"))?.replaceFirst("41 0D ", "").replaceAll(" ", "")}") ?? 0;

        // this is the same as above, but for the coolant temperature
        _send("0105");

        final double coolantTemp = (double.tryParse("0x${(await _awaitData("41 05"))?.replaceFirst("41 05 ", "").replaceAll(" ", "")}") ?? 0 - 40);

        // now for voltage
        _send("AT RV");

        final double voltage = double.tryParse(await _awaitData(RegExp(r"[0-9]")) ?? "0") ?? 0 / 10;

        if (isRunning && !controller.isClosed) {
          controller.add(ETVehicleLiveData(
            rpm: rpm,
            speed: speed,
            coolantTemp: coolantTemp,
            voltage: voltage,
            // https://mechanics.stackexchange.com/questions/45239/calculate-boost-from-map-sensor-via-obd-ii
            // this might help for boost pressure
            boostPressure: 0,
            egt: 0,
          ));
        }
      }

      return;
    }

    void runDataFetcher() {
      isRunning = true;
      dataFetcher();
    }

    controller = StreamController<ETVehicleLiveData>.broadcast(
      onListen: runDataFetcher,
      onCancel: cancelStream,
    );

    return controller.stream;
  }

  Future<bool> runBeginCommands([void Function(String)? onEvent]) async {
    // final sub = device.listenToData()?.listen((data) {
    //   onEvent?.call(ascii.decode(data));
    // });

    await _send("AT R0"); // turns off responses
    await _send("AT SH 750", ignorePromptCharacter: true);
    await _send("5F 02 27 51", ignorePromptCharacter: true);
    await _send("AT R1"); // turns on responses
    await _send("02 09 04");
    await _send("AT SH 721");

    // I need to fetch the response here, so I'm gonna await the response rather than the command
    _send("02 27 01", ignorePromptCharacter: true);

    List<String>? authData;

    await Future.wait([
      _awaitData(">"),
      _awaitData(RegExp(r"06 67 01(\s[0-9a-fA-F]{2}){4} 00")).then((value) {
        authData = RegExp(r"06 67 01(\s[0-9a-fA-F]{2}){4} 00").stringMatch(value ?? "")?.split(" ");
      }),
    ]);

    if (authData == null || (authData?.length ?? 0) < 8) return false;

    try {
      authData![0] = "06";
      authData![1] = "27";
      authData![2] = "02";
      authData![4] = (int.parse("0x${authData![4]}") ^ 0x60).toRadixString(16);
      authData![5] = (int.parse("0x${authData![5]}") ^ 0x60).toRadixString(16);

      if (authData![4].length == 1) authData![4] = "0${authData![4]}";
      if (authData![5].length == 1) authData![5] = "0${authData![5]}";
    } catch (e) {
      print(e);
      return false;
    }

    String authComplete = authData!.join(" ");

    if (!RegExp(r"06 27 02(\s[0-9a-fA-F]{2}){4} 00").hasMatch(authComplete)) {
      onEvent?.call("Error: Auth data did not match expected format\n$authComplete");
    }

    onEvent?.call("Sending: $authComplete");

    await _send(authComplete, expectedResponse: "02 67 02");

    await _send("AT SH 7E0");

    _send("02 27 01", ignorePromptCharacter: true);

    await Future.wait([
      _awaitData(">"),
      _awaitData(RegExp(r"06 67 01(\s[0-9a-fA-F]{2}){4} 00")).then((value) {
        authData = RegExp(r"06 67 01(\s[0-9a-fA-F]{2}){4} 00").stringMatch(value ?? "")?.split(" ");
      }),
    ]);

    if (authData == null || (authData?.length ?? 0) < 8) return false;

    try {
      authData![0] = "06";
      authData![1] = "27";
      authData![2] = "02";
      authData![4] = (int.parse("0x${authData![4]}") ^ 0x60).toRadixString(16);
      authData![5] = (int.parse("0x${authData![5]}") ^ 0x60).toRadixString(16);

      if (authData![4].length == 1) authData![4] = "0${authData![4]}";
      if (authData![5].length == 1) authData![5] = "0${authData![5]}";
    } catch (e) {
      print(e);
      return false;
    }

    authComplete = authData!.join(" ");

    if (!RegExp(r"06 27 02(\s[0-9a-fA-F]{2}){4} 00").hasMatch(authComplete)) {
      onEvent?.call("Error: Auth data did not match expected format\n$authComplete");
    }

    onEvent?.call("Sending: $authComplete");

    await _send(authComplete);

    await _send("AT R0");
    await _send("AT SH 720", ignorePromptCharacter: true);
    await _send("02 A0 27", ignorePromptCharacter: true);
    await _send("02 A0 27", ignorePromptCharacter: true);
    await _send("02 A0 27", ignorePromptCharacter: true);

    await _send("AT R1");
    await _send("AT SH 721");
    await _send("02 10 02", expectedResponse: "01 50");

    await _send("AT SH 7E0");
    await _send("02 10 02", expectedResponse: "01 50");

    await _send("AT R0");
    await _send("AT SH 001", ignorePromptCharacter: true);
    await _send("01", unsafelySendWithoutDelay: true);
    await _send("01", unsafelySendWithoutDelay: true);
    await _send("06 20 07 01 00 02", unsafelySendWithoutDelay: true);
    await _send("02 07", unsafelySendWithoutDelay: true);
    // await _send("AT R1");
    await _send("04 64 0A A5 51", ignorePromptCharacter: true, delay: 10); // expectedResponse: "01 3C");

    return true;
  }
}
