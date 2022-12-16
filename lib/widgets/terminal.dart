import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:obd_tuner/utils/bluetooth.dart';
import 'package:obd_tuner/utils/bluetooth_classic.dart';
import 'package:obd_tuner/utils/bluetooth_le.dart';
import 'package:obd_tuner/utils/obd_commands.dart';

enum TerminalDataType {
  input,
  output,
}

class _TerminalData {
  _TerminalData({
    required this.value,
    required this.type,
  });
  final String value;
  final TerminalDataType type;

  Widget buildText() {
    switch (type) {
      case TerminalDataType.input:
        return Text(
          ">$value",
          style: const TextStyle(
            color: Colors.green,
          ),
        );
      case TerminalDataType.output:
        return Text(
          value,
          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
        );
    }
  }
}

class _TerminalCommandHandler {
  _TerminalCommandHandler(this.onUpdate);
  final void Function(_TerminalData) onUpdate;

  final Map<String, dynamic> _terminalCommandContext = {};

  void _addInput(String input) {
    onUpdate(_TerminalData(value: input, type: TerminalDataType.input));
  }

  void _addOutput(String input) {
    onUpdate(_TerminalData(value: input, type: TerminalDataType.output));
  }

  void _testCommand() {
    ObdCommands(_terminalCommandContext["connectedDevice"]).runTestCommand(_addOutput);
  }

  void _advancedCommand(String arg) async {
    if (_terminalCommandContext["connectedDevice"] == null) {
      _addOutput("No device connected");
      _addOutput("Run 'scan classic' or 'scan le' to connect to a device");
      return;
    }

    switch (arg) {
      case "setup device":
        _addOutput("Setting up device...");
        var res = await ObdCommands(_terminalCommandContext["connectedDevice"]).setupDevice(_addOutput);
        if (res) {
          _addOutput("Device setup complete");
        } else {
          _addOutput("Device setup failed");
        }
        break;
      case "begin commands":
        _addOutput("Beginning commands...");
        var res = await ObdCommands(_terminalCommandContext["connectedDevice"]).runBeginCommands(_addOutput);
        if (res) {
          _addOutput("Ran commands successfully");
        } else {
          _addOutput("Failed to run commands");
        }
        break;
      default:
        _addOutput("Unknown command: $arg");
        _addOutput("known options are 'setup device' and 'begin commands'");
    }
  }

  void _scanLE() {
    _addOutput("Scanning for devices...");
    BluetoothLE().scanForDevice(_addOutput).then((devices) {
      if (devices.isNotEmpty) {
        _terminalCommandContext["devices"] = devices;

        var i = -1;
        _addOutput(devices.map((e) {
          i++;
          return "$i: ${e.address} ${e.name != "" ? "(${e.name})" : ""}\n";
        }).reduce((value, element) => "$value$element"));

        _addOutput("Type \"connect [number]\" to connect to a device");
        _addOutput("If a device you're looking for isn't here,\ntry \"scan classic\" instead");
      } else {
        _addOutput("No devices found");
      }
    });
  }

  void _scanClassic() {
    _addOutput("Scanning for devices...");
    BluetoothClassic().scanForDevice(_addOutput).then((devices) {
      if (devices.isNotEmpty) {
        _terminalCommandContext["devices"] = devices;

        var i = -1;
        _addOutput(devices.map((e) {
          i++;
          return "$i: ${e.address} ${e.name != "" ? "(${e.name})" : ""}\n";
        }).reduce((value, element) => "$value$element"));

        _addOutput("Type \"connect [number]\" to connect to a device");
        _addOutput("If a device you're looking for isn't here,\ntry pairing with it in your phones settings first");
      } else {
        _addOutput("No devices found");
      }
    });
  }

  void _connect(String args) {
    _addOutput("Connecting to device...");
    if (_terminalCommandContext["devices"] == null) {
      _addOutput("First run \"scan [le||classic]\" to scan for devices");
      return;
    }

    int? deviceId = int.tryParse(args);
    if (deviceId == null || deviceId < 0 || deviceId >= _terminalCommandContext["devices"].length) {
      _addOutput("Invalid device");
      return;
    }

    (_terminalCommandContext["devices"][deviceId] as BluetoothDevice).connect().then((value) {
      _terminalCommandContext["connectedDevice"] = _terminalCommandContext["devices"][deviceId];
      if (!value) {
        _addOutput("Failed to connect to $deviceId");
        return;
      }

      _addOutput("Connected to $deviceId");

      if (_terminalCommandContext["connectedDeviceStream"] != null) {
        _terminalCommandContext["connectedDeviceStream"]?.cancel();
      }

      _terminalCommandContext["connectedDeviceStream"] = (_terminalCommandContext["devices"][deviceId] as BluetoothDevice).listenToData()?.listen((data) {
        _addOutput("Device response ${data.toString()}\n${ascii.decode(data)}");
      });
    });
  }

  void _send(String args) {
    if (args.isEmpty) {
      _addOutput("Cannot send empty command\nUse \"send [obd command]\"");
      return;
    }

    if (_terminalCommandContext["connectedDevice"] != null) {
      _addOutput("Sending $args");

      (_terminalCommandContext["connectedDevice"] as BluetoothDevice).sendData(args.codeUnits + [ObdCommands.commandTerminator]);
      return;
    }

    _addOutput("Not connected\nRun \"scan\" to connect to a device");
  }

  void _disconnect() {
    if (_terminalCommandContext["connectedDeviceStream"] != null) {
      _terminalCommandContext["connectedDeviceStream"]?.cancel();
    }
    if (_terminalCommandContext["connectedDevice"] != null) {
      _terminalCommandContext["connectedDevice"]?.disconnect();
    }
    _addOutput("Disconnected from device");
  }

  void runCommand(String cmd) {
    final String fullCommand = cmd.trim();
    final String command = fullCommand.split(" ").first.toLowerCase();
    final String args = fullCommand.contains(" ") ? fullCommand.split(" ").sublist(1).join(" ").trim() : "";

    if (fullCommand.isNotEmpty) _addInput(fullCommand);

    switch (command) {
      case 'help':
        _addOutput(
          """
          help - show this help
          scan [le||classic] - scan for devices
          connect [device number] - connect to device
          send [command] - send command to device
          advanced [command] - run advanced command
          disconnect - disconnect from the device
          """,
        );
        break;
      case 'scan':
        if (args == "le") {
          _scanLE();
        } else if (args == "classic") {
          _scanClassic();
        } else {
          _addOutput("Type \"scan le\"for bluetooth low energy,\nor \"scan classic\" for bluetooth classic");
        }

        break;
      case 'connect':
        _connect(args);
        break;

      case 'read':
        (_terminalCommandContext["connectedDevice"] as BluetoothDevice).readData().then((value) => print(value));
        break;

      case 'test':
        _testCommand();
        break;

      case 'send':
        _send(args);
        break;

      case 'advanced':
        _advancedCommand(args);
        break;

      case 'disconnect':
        _disconnect();
        break;
      default:
        _addOutput('Unknown command: $command');
    }
  }
}

class Terminal extends StatefulWidget {
  const Terminal({this.width, this.height, this.commandStream, Key? key}) : super(key: key);

  final double? width;
  final double? height;
  final Stream<String>? commandStream;

  @override
  State<Terminal> createState() => TerminalState();
}

class TerminalState extends State<Terminal> {
  final _textController = TextEditingController();
  final List<_TerminalData> _data = [];

  TerminalState({Key? key}) : super();

  StreamSubscription<String>? _commandSubscription;

  late _TerminalCommandHandler _commandHandler;

  @override
  void initState() {
    super.initState();
    // this ensures everything else has been loaded first
    Future.microtask(() {
      _commandHandler = _TerminalCommandHandler((commandData) {
        if (mounted) setState(() => _data.add(commandData));
      });

      _commandSubscription = widget.commandStream?.listen(_commandHandler.runCommand);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _commandSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: widget.height != null ? widget.height! - 50 : null,
            child: ListView(
              reverse: true,
              children: [
                for (var i = _data.length - 1; i >= 0; i--) _data[i].buildText(),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(">", style: TextStyle(color: Colors.green)),
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.green),
                  decoration: const InputDecoration(
                    hintText: "Enter command",
                    hintStyle: TextStyle(color: Colors.green),
                    border: InputBorder.none,
                  ),
                  controller: _textController,
                  onChanged: (text) {
                    if (text.endsWith("\n")) {
                      _commandHandler.runCommand(text.trim());
                      _textController.clear();
                    }
                  },
                  onSubmitted: (value) {
                    _commandHandler.runCommand(value);
                    _textController.clear();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
