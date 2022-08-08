import 'dart:async';

import 'package:flutter/material.dart';
import 'package:obd_tuner/widgets/preset_commands_menu.dart';
import 'package:obd_tuner/widgets/terminal.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OBD Tuner',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamController<String> commandStreamController = StreamController<String>();

  @override
  void dispose() {
    commandStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: PresetCommandsMenu((command) => commandStreamController.add(command)),
      appBar: AppBar(title: const Text('CoCreations OBDII Terminal')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 40,
            ),
            Terminal(
              commandStream: commandStreamController.stream,
              height: MediaQuery.of(context).size.width * 0.7,
              width: 300, // MediaQuery.of(context).size.width - 50,
            ),
            const Spacer()
          ],
        ),
      ),
    );
  }
}
