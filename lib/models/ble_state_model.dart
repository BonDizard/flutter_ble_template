import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothStateModel {
  BluetoothStateModel({
    required this.bluetoothEnabled,
    required this.isLoading,
    required this.connectedDevices,
    required this.scanResults,
  });
  final bool bluetoothEnabled;
  final bool isLoading;
  final List<BluetoothDevice> connectedDevices;
  final List<ScanResult> scanResults;

  BluetoothStateModel copyWith({
    bool? bluetoothEnabled,
    bool? isLoading,
    List<BluetoothDevice>? connectedDevices,
    List<ScanResult>? scanResults,
  }) {
    return BluetoothStateModel(
      bluetoothEnabled: bluetoothEnabled ?? this.bluetoothEnabled,
      isLoading: isLoading ?? this.isLoading,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      scanResults: scanResults ?? this.scanResults,
    );
  }
}
