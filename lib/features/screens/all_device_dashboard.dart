import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/common/loading.dart';
import '../repository/bluetooth_provider.dart';
import '../repository/parameters_provider.dart';
import 'device_screen.dart';

class AllDevicePages extends ConsumerStatefulWidget {
  const AllDevicePages({super.key});

  @override
  ConsumerState createState() => _AllDevicePagesState();
}

class _AllDevicePagesState extends ConsumerState<AllDevicePages> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchParameters();
  }

  Future<void> _fetchParameters() async {
    final bluetoothState = ref.read(bluetoothProvider);
    final devices = bluetoothState.connectedDevices;
    await ref.read(parametersModelProvider.notifier).fetchParameters(devices);
  }

  @override
  Widget build(BuildContext context) {
    final parameterModels = ref.watch(parametersModelProvider);
    final bluetoothState = ref.watch(bluetoothProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: bluetoothState.isLoading
          ? const Loader()
          : parameterModels.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Loader(),
                    Center(
                      child: Text(
                        'No Connected Devices',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                  ],
                )
              : IndexedStack(
                  index: _selectedIndex,
                  children: List.generate(
                    parameterModels.length,
                    (index) => DeviceScreen(
                      device: parameterModels[index],
                      index: index,
                    ),
                  ),
                ),
      bottomNavigationBar: parameterModels.length > 1
          ? BottomNavigationBar(
              items: List.generate(
                parameterModels.length,
                (index) => BottomNavigationBarItem(
                  backgroundColor: Colors.orange,
                  icon: Icon(
                    Icons.devices,
                    color: Colors.orange,
                  ),
                  label: 'Device ${index + 1}',
                ),
              ),
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.amber[800],
              onTap: _onItemTapped,
            )
          : null,
    );
  }
}
