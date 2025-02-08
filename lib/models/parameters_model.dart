import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ParametersModel {
  final BluetoothDevice device;
  final List<BluetoothService> services;
  final String readUuid;
  final String writeUuid;

  ParametersModel({
    required this.device,
    required this.services,
    required this.readUuid,
    required this.writeUuid,
  });

  ParametersModel copyWith({
    String? readUuid,
    String? writeUuid,
  }) {
    return ParametersModel(
      device: device,
      services: services,
      readUuid: readUuid ?? this.readUuid,
      writeUuid: writeUuid ?? this.writeUuid,
    );
  }
}
