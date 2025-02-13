import 'package:ble_framework/models/parameters_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../core/common/custom_toast.dart';
import '../../core/constants/ble_constants.dart';
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
                processReceivedData(
                  receivedString: receivedData,
                );
                break; // Assuming you want to stop listening after the first received data
              }
            }
          }
        }
      }
    } catch (e) {
      CustomToast.showToast('Error while reading: $e');
    }
    return receivedData;
  }

  void processReceivedData({required String receivedString}) {
    decodeDWINCommand(receivedString);
    try {
      // RegExp wRegex = RegExp(r'w:([\d.]+)', caseSensitive: false);
      // RegExp xRegex = RegExp(r'x:([\d.]+)', caseSensitive: false);
      // RegExp yRegex = RegExp(r'y:([\d.]+)', caseSensitive: false);
      // RegExp zRegex = RegExp(r'z:([\d.]+)', caseSensitive: false);
      //
      // RegExpMatch? wRegexMatch = wRegex.firstMatch(receivedString);
      // double w = wRegexMatch != null
      //     ? double.tryParse(wRegexMatch.group(1)!) ?? 0.0
      //     : 0.0;
      //
      // RegExpMatch? xRegexMatch = xRegex.firstMatch(receivedString);
      // double x = xRegexMatch != null
      //     ? double.tryParse(xRegexMatch.group(1)!) ?? 0.0
      //     : 0.0;
      //
      // RegExpMatch? yRegexMatch = yRegex.firstMatch(receivedString);
      // double y = yRegexMatch != null
      //     ? double.tryParse(yRegexMatch.group(1)!) ?? 0.0
      //     : 0.0;
      // RegExpMatch? zRegexMatch = zRegex.firstMatch(receivedString);
      // double z = zRegexMatch != null
      //     ? double.tryParse(zRegexMatch.group(1)!) ?? 0.0
      //     : 0.0;
      //
      // BLEConstants.w = w.toInt();
      // BLEConstants.x = x.toInt();
      // BLEConstants.y = y.toInt();
      // BLEConstants.z = z.toInt();
    } catch (e) {
      logger.i('Error processing received data: $e');
      CustomToast.showToast(
        'Error processing received data',
      );
    }
  }

  void decodeDWINCommand(String hexString) {
    try {
      // Normalize input: remove spaces, split into hex bytes
      List<String> hexBytes = hexString
          .trim()
          .split(' ')
          .where((byte) => byte.isNotEmpty) // Remove empty entries
          .map((byte) => byte.toUpperCase()) // Normalize case
          .toList();

      print("hexBytes: $hexBytes");

      // Validate DWIN command header
      if (hexBytes.length < 6 || hexBytes[0] != "5A" || hexBytes[1] != "A5") {
        print("Invalid DWIN command");
        return;
      }

      List<String> extractedData = [];
      int index = 0;
      String vpAddress = ""; // Variable to store VP address

      // Parse multiple DWIN packets in the input
      while (index < hexBytes.length - 6) {
        if (hexBytes[index] == "5A" && hexBytes[index + 1] == "A5") {
          // Header found, get the data length
          int dataLength;
          try {
            dataLength = int.parse(hexBytes[index + 2], radix: 16);
          } catch (e) {
            print("Invalid data length");
            return;
          }

          // Extract VP Address
          vpAddress = hexBytes[index + 4] + hexBytes[index + 5];

          // Extract the data section
          int startIndex =
              index + 6; // Data starts after header, length, cmd, VP
          int endIndex = startIndex + dataLength - 4; // Adjust for fixed bytes

          if (endIndex <= hexBytes.length) {
            extractedData.addAll(hexBytes.sublist(startIndex, endIndex));
          }
        }
        index++;
      }

      // Convert hex to ASCII and remove unwanted spaces
      String decodedString = extractedData
          .map((hex) {
            try {
              return String.fromCharCode(int.parse(hex, radix: 16));
            } catch (e) {
              return ''; // Ignore invalid hex characters
            }
          })
          .join()
          .trim();

      if (decodedString.isNotEmpty) {
        print("Decoded Data: $decodedString");
        int vpAddressInt = int.parse(vpAddress);
        switch (vpAddressInt) {
          case 1200:
          case 1100:
            BLEConstants.ph = double.parse(decodedString);
            break;
          case 1400:
          case 1500:
            BLEConstants.inp = double.parse(decodedString);
            break;
          case 1700:
          case 1800:
            BLEConstants.dissolvedOxygen = double.parse(decodedString);
            break;
          case 2000:
          case 2100:
            BLEConstants.totalSuspendedSolids = double.parse(decodedString);
            break;
          default:
            logger.i('VP address not found');
            CustomToast.showToast(
              'VP address not found: $vpAddressInt',
            );
        }
      } else {
        logger.i("No valid data found: $decodedString");
        CustomToast.showToast("No valid data found: $decodedString");
      }
    } catch (e) {
      logger.i('Error processing received data: $e');
      CustomToast.showToast('Error processing received data: $e');
    }
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
