import 'dart:async';

import 'package:flutter/material.dart';

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
  State<Terminal> createState() => _TerminalState();
}

class _TerminalState extends State<Terminal> {
  final _textController = TextEditingController();
  final List<_TerminalData> _data = [];
  StreamSubscription<String>? _commandSubscription;

  void onNewCommand(String command) {
    if (command.isNotEmpty) {
      _data.add(_TerminalData(value: command, type: TerminalDataType.input));
      _data.add(_TerminalData(value: "Received $command", type: TerminalDataType.output));
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
          ListView(
            shrinkWrap: true,
            reverse: true,
            children: [
              for (var i = _data.length - 1; i >= 0; i--) _data[i].buildText(),
            ],
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
