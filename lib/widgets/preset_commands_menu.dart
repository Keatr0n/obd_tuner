
import 'package:flutter/material.dart';

// The terminal interface is awesome - but who wants to type anything,
// so lets put the requested test commands into the side menu.
// NB : We would have a data file of all available OBCII commands in a real app,
//      I didn't find a good one to pull in, so this is all that we are doing in the PoC.
class PresetCommandsMenu extends StatelessWidget {

  final void Function(String) _callback;

  final List<String> commandsList = [
  'AT Z',
  'AT SP6',
  'AT CAF0',
  'AT CEA',
  'AT SH 721',
  '02 27 01',
  '-',
  '-',
  'AT SH 720',
  '02 A0 27',
  '-',
  'AT SH 7E0',
  '02 10 02',
  '-',
  ];

  PresetCommandsMenu(
    this._callback,
    {Key? key}
  ) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    void closeMenuAndCallback(String command) {
      Navigator.of(context).pop();
      _callback(command);
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const SizedBox(
            height: 80.0,
            child: DrawerHeader(
                      decoration: BoxDecoration(
                          color: Colors.green,
                      ),
                      child: Text(
                        'Preset Commands',
                        style: TextStyle(color: Colors.white, fontSize: 25),
                      ),
                    ),
          ),

          SizedBox(
            height: 40,
            child: ListTile(
              leading: const Icon(Icons.bluetooth_searching),
              title: const Text('Scan'),
              onTap: () => closeMenuAndCallback('scan classic'),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListTile(
              leading: const Icon(Icons.bluetooth_drive),
              title: const Text('Connect 0\n(if device 0 is OBDII)'),
              onTap: () => closeMenuAndCallback('connect 0'),
            ),
          ),

          ...commandsList.map((c) => 
            (c=='-') ? const SizedBox(height: 20) :
            SizedBox(height:30, child: ListTile(
              leading: const Icon(Icons.arrow_forward_ios),
              title: Text(c),
              onTap: () => closeMenuAndCallback('send $c')
            ),),
          ),

          SizedBox(
            height: 40,
            child: ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Terminal Help'),
              onTap: () => closeMenuAndCallback('help'),
            ),
          ),

        ],
      ),
    );
  }
}
