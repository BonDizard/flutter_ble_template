import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/common/custom_toast.dart';

class BluetoothOffScreen extends StatelessWidget {
  final BluetoothAdapterState bluetoothAdapterState;

  const BluetoothOffScreen({super.key, required this.bluetoothAdapterState});

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;
    Color iconColor;

    switch (bluetoothAdapterState) {
      case BluetoothAdapterState.unknown:
        message = 'Bluetooth Status Unknown';
        icon = Icons.help_outline;
        iconColor = Colors.amber;
        break;
      case BluetoothAdapterState.off:
        message = 'Bluetooth is Disabled';
        icon = Icons.bluetooth_disabled;
        iconColor = Colors.white;
        break;
      case BluetoothAdapterState.on:
        // This shouldn't reach this screen, you can navigate elsewhere.
        Future.microtask(() => Navigator.of(context).pop()); // Delay the pop
        return Container(); // Empty container to prevent rendering issues
      default:
        message = 'Unexpected State';
        icon = Icons.error_outline;
        iconColor = Colors.red;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.error,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72.0,
              color: iconColor,
            ),
            const Padding(padding: EdgeInsets.all(16.0)),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Alatsi',
                color: Colors.white,
                fontSize: 30,
              ),
            ),
            const Padding(padding: EdgeInsets.all(8.0)),
            const Text(
              'Please enable Bluetooth to connect to devices.',
              style: TextStyle(),
            ),
            const Padding(padding: EdgeInsets.all(16.0)),
            ElevatedButton(
              onPressed: () async {
                await requestBluetoothPermission();
              },
              child: Text('Turn on Bluetooth'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> requestBluetoothPermission() async {
    try {
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      }
    } catch (e) {
      CustomToast.showToast("Error Turning On: $e");
    }
  }
}
