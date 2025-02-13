import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../core/constants/ble_constants.dart';
import '../../models/parameters_model.dart';
import '../repository/bluetooth_provider.dart';
import '../repository/parameters_provider.dart';

class DeviceScreen extends ConsumerStatefulWidget {
  final ParametersModel device;
  final int index;

  const DeviceScreen({
    super.key,
    required this.index,
    required this.device,
  });
  @override
  ConsumerState createState() => MainPageState();
}

class MainPageState extends ConsumerState<DeviceScreen> {
  String receivedData = '';
  final Logger logger = Logger();

  Future<void> readDataFromDevice(BluetoothDevice device) async {
    final bluetoothNotifier = ref.read(bluetoothProvider.notifier);
    var data = await bluetoothNotifier.readTheDataFromDevice(
      device: widget.device.device,
    );
    if (mounted) {
      setState(() {
        receivedData = data;
        print('recieved data: $receivedData');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final updatedDevice = ref.watch(parametersModelProvider)[widget.index];
    logger.d('readUuid: ${updatedDevice.readUuid}');
    logger.d('writeUuid: ${updatedDevice.writeUuid}');

    readDataFromDevice(updatedDevice.device);
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.pink[50],
      body: Padding(
        padding: EdgeInsets.all(width * 0.02),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      child: GridWidget(
                          value: BLEConstants.ph.toString(), parameter: 'pH')),
                  SizedBox(width: width * 0.02),
                  Expanded(
                      child: GridWidget(
                          value: BLEConstants.inp.toString(),
                          parameter: 'INP')),
                ],
              ),
            ),
            SizedBox(height: height * 0.02),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      child: GridWidget(
                          value: BLEConstants.totalSuspendedSolids.toString(),
                          parameter: 'TSS')),
                  SizedBox(width: width * 0.02),
                  Expanded(
                      child: GridWidget(
                          value: BLEConstants.dissolvedOxygen.toString(),
                          parameter: 'DO')),
                ],
              ),
            ),
            SizedBox(height: height * 0.02),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: Colors.pink[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'MENU',
                style: TextStyle(
                  fontSize: height * 0.03,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridWidget extends StatelessWidget {
  final String value;
  final String parameter;

  GridWidget({required this.value, required this.parameter});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Container(
      decoration: BoxDecoration(
        color: Colors.pink[100],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black,
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  parameter,
                  style: TextStyle(
                    fontSize: height * 0.08,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: height * 0.005),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: height * 0.15,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
