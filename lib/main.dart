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
  @override
  Widget build(BuildContext context) {

    GlobalKey<TerminalState> termKey = GlobalKey<TerminalState>();

    Terminal term = Terminal(
      key: termKey,
      height: MediaQuery.of(context).size.width * 0.8,
      width: MediaQuery.of(context).size.width - 50,
    );



    return Scaffold(
      drawer: PresetCommandsMenu( (command) => termKey.currentState!.onNewCommand(command) ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // add some sort of bluetooth setup here with a status indicator
            term,
            // put a list of preset commands here
          ],
        ),
      ),
    );
  }
}
