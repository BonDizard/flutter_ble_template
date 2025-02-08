import 'dart:async';
import 'package:ble_framework/features/screens/scan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/bluetooth_adapter_state_observer.dart';
import 'features/screens/bluetooth_off_screen.dart';

Future<void> main() async {
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    const ProviderScope(
      child: FlutterBlueApp(),
    ),
  );
}

class FlutterBlueApp extends StatefulWidget {
  const FlutterBlueApp({Key? key}) : super(key: key);

  @override
  State<FlutterBlueApp> createState() => _FlutterBlueAppState();
}

class _FlutterBlueAppState extends State<FlutterBlueApp> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  @override
  void initState() {
    super.initState();
    _adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;

      if (mounted) {
        setState(() {});
      }
      if (!mounted) return;
    });
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget screen;
    if (_adapterState == BluetoothAdapterState.on ||
        _adapterState == BluetoothAdapterState.turningOn ||
        _adapterState == BluetoothAdapterState.unknown) {
      screen = const ScanPage();
    } else {
      screen = BluetoothOffScreen(
        bluetoothAdapterState: _adapterState,
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: screen,
      navigatorObservers: [BluetoothAdapterStateObserver()],
    );
  }
}
