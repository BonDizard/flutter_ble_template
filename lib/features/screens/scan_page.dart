import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../core/common/loading.dart';
import '../../core/common/reusable_button.dart';
import '../../core/constants/color_constant.dart';
import '../repository/bluetooth_provider.dart';
import 'main_page.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  late BluetoothNotifier bluetoothNotifier;

  @override
  void initState() {
    super.initState();
    bluetoothNotifier = ref.read(bluetoothProvider.notifier);
  }

  @override
  void dispose() {
    // Use the notifier directly instead of ref in the dispose method
    bluetoothNotifier.disconnectAllDevices();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bluetoothState = ref.watch(bluetoothProvider);
    final bluetoothNotifier = ref.read(bluetoothProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'STARTER-KIT',
          style: TextStyle(
            fontFamily: 'Alatsi',
            color: ColorConstants.darkColor,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    if (bluetoothState.isLoading)
                      const Loader()
                    else
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Available Devices',
                                style: TextStyle(
                                  fontFamily: 'Alatsi',
                                  fontSize: 18,
                                  color: ColorConstants.darkColor,
                                ),
                              ),
                              Text(
                                '[${bluetoothState.scanResults.length} device(s) available]',
                                style: TextStyle(
                                  fontFamily: 'Alatsi',
                                  color: ColorConstants.darkColor.withAlpha(
                                    (255 * 0.5).round(),
                                  ),
                                ),
                              ),
                              ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: bluetoothState.scanResults.length,
                                itemBuilder: (context, index) {
                                  final device =
                                      bluetoothState.scanResults[index].device;
                                  return buildConnectedDeviceTile(
                                      device, false);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ReusableButton(
                      onPressed: () {
                        print('scan button pressed');
                        bluetoothNotifier.startScan();
                        bluetoothNotifier.fetchConnectedDevices();
                      },
                      buttonText: 'Scan',
                    ),
                    const SizedBox(
                        height: 8), // Add space between button and divider
                  ],
                ),
              ),
              const VerticalDivider(
                color: ColorConstants.darkColor,
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Connected Devices:',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Alatsi',
                        color: ColorConstants.darkColor,
                      ),
                    ),
                    Text(
                      '[${bluetoothState.connectedDevices.length} device(s) connected]',
                      style: TextStyle(
                        fontFamily: 'Alatsi',
                        color: ColorConstants.darkColor.withAlpha(
                          (255 * 0.5).round(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: bluetoothState.connectedDevices.length,
                        itemBuilder: (context, index) {
                          final device = bluetoothState.connectedDevices[index];
                          return buildConnectedDeviceTile(device, true);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(right: width * 0.07, bottom: width * 0.07),
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15)),
            gradient: LinearGradient(
              colors: [
                ColorConstants.onColorOne,
                ColorConstants.onColorTwo,
                ColorConstants.onColorThree,
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: FloatingActionButton(
            elevation: 0,
            backgroundColor: Colors.transparent,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainPage(),
                ),
              );
            },
            child: const Icon(
              Icons.keyboard_arrow_right_sharp,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildConnectedDeviceTile(BluetoothDevice device, bool connected) {
    final width = MediaQuery.of(context).size.width;
    final connectionStatus = ref.watch(connectionStateProvider(device));
    final bluetoothNotifier = ref.read(bluetoothProvider.notifier);

    Logger logger = Logger();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Container(
        width: width * 0.8,
        decoration: connected
            ? const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorConstants.onColorOne,
                    ColorConstants.onColorTwo,
                    ColorConstants.onColorThree,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(35),
                  bottomLeft: Radius.circular(17),
                  topRight: Radius.circular(17),
                  topLeft: Radius.circular(35),
                ))
            : BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color:
                        const Color(0xFF747D8C).withAlpha((255 * 0.5).round()),
                    blurRadius: 16,
                    offset: const Offset(8, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withAlpha((255 * 0.5).round()),
                    blurRadius: 16,
                    offset: const Offset(-8, -8),
                  ),
                ],
                gradient: const LinearGradient(
                  colors: [
                    ColorConstants.backgroundColorOne,
                    ColorConstants.backgroundColorTwo,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(35),
                  bottomLeft: Radius.circular(17),
                  topRight: Radius.circular(17),
                  topLeft: Radius.circular(35),
                ),
              ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Text(
            device.platformName.isEmpty ? 'N/A' : device.platformName,
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: Text(device.remoteId.toString()),
          trailing: connectionStatus.when(
            data: (isConnected) =>
                isConnected == BluetoothConnectionState.connected
                    ? FutureBuilder<int>(
                        future: device.readRssi(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data == null) {
                            if (kDebugMode) {
                              print('No RSSI data available');
                            }
                            return const Icon(Icons.error);
                          } else {
                            final rssi = snapshot.data ?? -100;
                            return getRangeIcon(rssi);
                          }
                        },
                      )
                    : const SizedBox(),
            error: (error, stackTrace) => const SizedBox(),
            loading: () => const CircularProgressIndicator(),
          ),
          leading: Icon(Icons.bluetooth,
              color: connected ? Colors.white : Colors.blue),
          onTap: () {
            bluetoothNotifier.connectToDevice(device: device, context: context);
            logger.i('Connecting to ${device.platformName}');
          },
        ),
      ),
    );
  }

  Widget getRangeIcon(int rssi) {
    if (rssi > -60) {
      return const Icon(
        Icons.signal_cellular_alt_rounded,
        color: ColorConstants.darkColor,
      );
    } else if (rssi > -70) {
      return const Icon(
        Icons.signal_cellular_alt_2_bar_sharp,
        color: ColorConstants.darkColor,
      );
    } else if (rssi > -80) {
      return const Icon(
        Icons.signal_cellular_alt_1_bar,
        color: ColorConstants.darkColor,
      );
    } else {
      return const Icon(
        Icons.signal_cellular_connected_no_internet_0_bar,
        color: ColorConstants.darkColor,
      );
    }
  }
}
