import 'package:ble_framework/models/parameters_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../core/common/custom_toast.dart';
import '../../models/ble_state_model.dart';

final connectionStateProvider =
    StreamProvider.family<BluetoothConnectionState, BluetoothDevice>(
        (ref, device) {
  final bleRepository = ref.watch(bluetoothProvider.notifier);
  return bleRepository.getConnectionState(device);
});

final bluetoothProvider =
    StateNotifierProvider<BluetoothNotifier, BluetoothStateModel>(
  (ref) => BluetoothNotifier(ref),
);

class BluetoothNotifier extends StateNotifier<BluetoothStateModel> {
  BluetoothNotifier(this.ref)
      : super(BluetoothStateModel(
          bluetoothEnabled: false,
          isLoading: false,
          connectedDevices: [],
          scanResults: [],
        )) {
    _initBluetooth();
  }
  final Ref ref;
  final Logger logger = Logger();

  void _initBluetooth() async {
    if (await FlutterBluePlus.isSupported == false) {
      logger.e('Bluetooth not supported by this device');
      return;
    }

    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      bool isBluetoothEnabled = (state == BluetoothAdapterState.on);
      if (isBluetoothEnabled) {
        startScan();
        fetchConnectedDevices();
      } else {
        stopScan();
      }
      this.state = this.state.copyWith(bluetoothEnabled: isBluetoothEnabled);
    });

    FlutterBluePlus.scanResults.listen((results) {
      state = this.state.copyWith(scanResults: results);
    });
  }

  void fetchConnectedDevices() async {
    List<BluetoothDevice> devices = await FlutterBluePlus.connectedDevices;
    state = this.state.copyWith(connectedDevices: devices);
  }

  void startScan() {
    print('start scan called');
    state = this.state.copyWith(isLoading: true);
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4)).then((_) {
      state = this.state.copyWith(isLoading: false);
      FlutterBluePlus.scanResults.listen((results) {
        print('results: $results');
        state = this.state.copyWith(scanResults: results);
      });
    }).catchError((e) {
      logger.e('Error starting scan: $e');
      CustomToast.showToast(
        'Error starting scan',
      );
    });
  }

  Stream<BluetoothConnectionState> getConnectionState(
    BluetoothDevice device,
  ) async* {
    // Listen for connection state changes
    await for (final event in device.connectionState) {
      yield event; // Emit the connection state event
    }
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    state = state.copyWith(scanResults: [], isLoading: false);
  }

  Future<void> connectToDevice({
    required BluetoothDevice device,
    required BuildContext context,
  }) async {
    try {
      await device.connect();

      state = this.state.copyWith(
            scanResults: this
                .state
                .scanResults
                .where((result) => result.device.remoteId != device.remoteId)
                .toList(),
          );

      fetchConnectedDevices();

      logger.e('Connected to ${device.platformName}');
      CustomToast.showToast(
        'Connected to ${device.platformName}',
      );
    } catch (e) {
      logger.e('Error connecting to device: $e');
      CustomToast.showToast(
        'Error connecting to device',
      );
    }
  }

  Future<ParametersModel> convertBluetoothDeviceToParameterModel(
      BluetoothDevice device) async {
    var services = await device.discoverServices();
    // Process services to find UUIDs
    String readUuid = '';
    String writeUuid = '';
    for (var service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        if (kDebugMode) {
          print(c.uuid);
        }
        if (c.properties.notify && readUuid.isEmpty) {
          readUuid = c.uuid.toString();
        }
        if (c.properties.writeWithoutResponse && writeUuid.isEmpty) {
          writeUuid = c.uuid.toString();
        }
      }
    }
    //create the model
    ParametersModel parametersModel = ParametersModel(
      device: device,
      services: services,
      readUuid: readUuid,
      writeUuid: writeUuid,
    );
    return parametersModel;
  }

  Future<void> disconnectAllDevices() async {
    for (var connectedDevice in state.connectedDevices) {
      await connectedDevice.disconnect();
    }
  }

  void disconnectFromDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      startScan();
      fetchConnectedDevices();
    } catch (e) {
      logger.e('Error disconnecting from device: $e');
      CustomToast.showToast(
        'Error disconnecting from device',
      );
    }
  }

  Future<String> readTheDataFromDevice({
    required BluetoothDevice device,
  }) async {
    String receivedData = '';
    ParametersModel parametersModel =
        await convertBluetoothDeviceToParameterModel(device);
    try {
      for (var service in parametersModel.services) {
        for (BluetoothCharacteristic c in service.characteristics) {
          if (c.uuid.toString() == parametersModel.readUuid) {
            if (c.properties.read || c.properties.notify) {
              await c.setNotifyValue(true);
              await for (var value in c.lastValueStream) {
                receivedData = String.fromCharCodes(value);

                // processReceivedData(
                //   receivedString: receivedData,
                // );
                break; // Assuming you want to stop listening after the first received data
              }
            }
          }
        }
      }
    } catch (e) {
      CustomToast.showToast('Error while reading: $e');
      if (kDebugMode) {
        print('Error while reading: $e');
      }
    }
    return receivedData;
  }

  Future<void> writeToDevice({
    required BluetoothDevice device,
    required String uuid,
    required String data,
    required List<BluetoothService> services,
  }) async {
    try {
      for (var service in services) {
        for (BluetoothCharacteristic character in service.characteristics) {
          if (character.uuid.toString() == uuid) {
            if (character.properties.writeWithoutResponse ||
                character.properties.write) {
              character.setNotifyValue(true);

              character.write(
                data.codeUnits,
                withoutResponse: true,
              );
              if (kDebugMode) {
                print('wrote the value: $data');
              }
            } else {
              if (kDebugMode) {
                print('Write property not supported by this characteristic');
              }
            }
          } else {
            if (kDebugMode) {
              print(
                  'no matching uuid c was ${character.uuid} and selected uid was ');
            }
          }
        }
      }
    } catch (e) {
      CustomToast.showToast('Error while writing');
    }
  }
}
