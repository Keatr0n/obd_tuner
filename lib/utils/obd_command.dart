import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:obd_tuner/utils/bluetooth_messages/obd_message_interface.dart';

import 'bluetooth.dart';

abstract class OBDCommand<T> extends ChangeNotifier {
  static const int commandTerminator = 0x0D; // equal to "\r"

  OBDCommand();

  late final BluetoothDevice device;
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  @protected
  Future<String?> awaitData(Pattern pattern, [bool asHex = false]) async {
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
  @protected
  Future<void> sendString(
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
      await awaitData(">");
      return;
    }

    if (expectedResponse != null) {
      await awaitData(expectedResponse, matchAsHex);
      return;
    }

    // this should allow enough time for the reader to process the command
    await Future.delayed(Duration(milliseconds: delay ?? 100));

    return;
  }

  /// This is effectively a wrapper around [sendString], that makes it a little more safe and blazingly fast... just the first one.
  Future<void> send(
    IOBDMessage obdMessage, {
    bool matchAsHex = true,
    int? delay,
    bool ignorePromptCharacter = false,
    bool unsafelySendWithoutDelay = false,
  }) {
    return sendString(
      obdMessage.payload,
      expectedResponse: obdMessage.expectedResponse,
      unsafelySendWithoutDelay: unsafelySendWithoutDelay,
      ignorePromptCharacter: ignorePromptCharacter,
      delay: delay,
      matchAsHex: matchAsHex,
    );
  }

  Future<dynamic> sendAndRespond(IOBDMessage obdMessage) {
    send(obdMessage);
    return obdMessage.parseResponse(awaitData);
  }

  /// Starts the main loop or command.
  Future<T> run();

  /// Starts the command, and must be called in the inheritor
  void start() {
    _isRunning = true;

    notifyListeners();
  }

  /// Marks the command as complete
  void complete() {
    _isRunning = false;

    notifyListeners();
  }

  /// Basically a fancy late-init function
  void registerWithDevice(BluetoothDevice device) => this.device = device;
}
