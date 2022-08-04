import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:obd_tuner/utils/bluetooth.dart';
import 'package:obd_tuner/utils/bluetooth_classic.dart';
import 'package:obd_tuner/utils/bluetooth_le.dart';

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

  final Map<String, dynamic> _terminalCommandContext = {};

  TerminalState({Key? key}) : super();

  StreamSubscription<String>? _commandSubscription;

  void onNewCommand(String cmd) {
    final String command = cmd.trim();

    if (command.isNotEmpty) {
      _data.add(_TerminalData(value: command, type: TerminalDataType.input));
    }

    if (command.split(" ").first == "send") {
      if (command.length < 6) {
        _data.add(_TerminalData(value: "Cannot send empty command\nUse \"send [obd command]\"", type: TerminalDataType.output));
      } else if (_terminalCommandContext["connectedDevice"] != null) {
        _data.add(_TerminalData(value: "Sending ${command.substring(5)}", type: TerminalDataType.output));
        // all messages to the ELM327 must be terminated with a carriage return character (hex '0D') before it will be acted upon
        // https://www.elmelectronics.com/wp-content/uploads/2016/07/ELM327DS.pdf
        var commandTeminator = 0x0D;
        _terminalCommandContext["connectedDevice"].sendData(command.substring(5).codeUnits + [commandTeminator]);
      } else {
        _data.add(_TerminalData(value: "Not connected\nRun \"scan\" to connect to a device", type: TerminalDataType.output));
      }
    } else if (command == "disconnect") {
      if (_terminalCommandContext["connectedDeviceStream"] != null) {
        _terminalCommandContext["connectedDeviceStream"]?.cancel();
      }
      if (_terminalCommandContext["connectedDevice"] != null) {
        _terminalCommandContext["connectedDevice"]?.disconnect();
      }
      _data.add(_TerminalData(value: "Disconnected from device", type: TerminalDataType.output));
    } else if (command == "scan classic") {
      BluetoothClassic().scanForDevice((status) {
        _data.add(_TerminalData(value: status, type: TerminalDataType.output));
        if (mounted) setState(() {});
      }).then((devices) {
        if (devices.isNotEmpty) {
          _terminalCommandContext["devices"] = devices;
          var i = -1;
          _data.add(_TerminalData(
            value: devices.map((e) {
              i++;
              return "$i: ${e.address} ${e.name != "" ? "(${e.name})" : ""}\n";
            }).reduce((value, element) => "$value$element"),
            type: TerminalDataType.output,
          ));
          _data.add(_TerminalData(value: "Type \"connect [number]\" to connect to a device", type: TerminalDataType.output));
        } else {
          _data.add(_TerminalData(value: "No devices found!", type: TerminalDataType.output));
        }
        if (mounted) setState(() {});
      });
    } else if (command == "scan le") {
      BluetoothLE().scanForDevice((status) {
        _data.add(_TerminalData(value: status, type: TerminalDataType.output));
        if (mounted) setState(() {});
      }).then((devices) {
        if (devices.isNotEmpty) {
          _terminalCommandContext["devices"] = devices;
          var i = -1;
          _data.add(_TerminalData(
            value: devices.map((e) {
              i++;
              return "$i: ${e.address} ${e.name != "" ? "(${e.name})" : ""}\n";
            }).reduce((value, element) => "$value$element"),
            type: TerminalDataType.output,
          ));
          _data.add(_TerminalData(value: "Type \"connect [number]\" to connect to a device", type: TerminalDataType.output));
          _data.add(_TerminalData(value: "If a device you're looking for isn't here,\ntry pairing with it in your phones settings first", type: TerminalDataType.output));
        } else {
          _data.add(_TerminalData(value: "No devices found!", type: TerminalDataType.output));
        }
        if (mounted) setState(() {});
      });
    } else if (command.startsWith("scan")) {
      _data.add(_TerminalData(value: "Type \"scan le\"for bluetooth low energy,\nor \"scan classic\" for bluetooth classic", type: TerminalDataType.output));
    } else if (command.split(" ").first == "connect") {
      if (_terminalCommandContext["devices"] != null) {
        if (int.parse(command.split(" ").last) < _terminalCommandContext["devices"].length) {
          (_terminalCommandContext["devices"][int.parse(command.split(" ").last)] as BluetoothDevice).connect().then((value) {
            _terminalCommandContext["connectedDevice"] = _terminalCommandContext["devices"][int.parse(command.split(" ").last)];
            if (value) {
              _data.add(_TerminalData(value: "Connected to ${command.split(" ").last}", type: TerminalDataType.output));

              if (_terminalCommandContext["connectedDeviceStream"] != null) {
                _terminalCommandContext["connectedDeviceStream"]?.cancel();
              }

              _terminalCommandContext["connectedDeviceStream"] = (_terminalCommandContext["devices"][int.parse(command.split(" ").last)] as BluetoothDevice).listenToData()?.listen((data) {
                _data.add(_TerminalData(value: "Device response ${data.toString()}\n${ascii.decode(data)}", type: TerminalDataType.output));
                if (mounted) setState(() {});
              });
            } else {
              _data.add(_TerminalData(value: "Failed to connect to ${command.split(" ").last}", type: TerminalDataType.output));
            }
            if (mounted) setState(() {});
          });
        } else {
          _data.add(_TerminalData(value: "Invalid device number", type: TerminalDataType.output));
        }
      } else {
        _data.add(_TerminalData(value: "No devices found!\nType \"scan\" to search for devices", type: TerminalDataType.output));
      }
    } else {
      //_data.add(_TerminalData(value: "Sent $command", type: TerminalDataType.output));
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // this ensures everything else has been loaded first
    Future.microtask(() {
      _commandSubscription = widget.commandStream?.listen(onNewCommand);
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
                      onNewCommand(text.trim());
                      _textController.clear();
                    }
                  },
                  onSubmitted: (value) {
                    onNewCommand(value);
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
