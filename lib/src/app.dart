import 'package:flutter/material.dart';
import 'package:comtrol_temperatura/src/pages/bluetooth.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BluetoothApp(),
    );
  }
}
