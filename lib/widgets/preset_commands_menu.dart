
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
          ListTile(
            leading: const Icon(Icons.bluetooth_searching),
            title: const Text('Scan'),
            onTap: () => closeMenuAndCallback('scan'),
          ),
          ListTile(
            leading: const Icon(Icons.bluetooth_drive),
            title: const Text('Connect 0\n(if device 0 is OBDII)'),
            onTap: () => closeMenuAndCallback('connect 0'),
          ),

          ...commandsList.map((c) => 
            ListTile(
              title: Text(c),
              onTap: () => closeMenuAndCallback(c)
            ),
          ),
          
        ],
      ),
    );
  }
}
