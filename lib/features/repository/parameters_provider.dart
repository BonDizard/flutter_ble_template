import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/parameters_model.dart';
import '../repository/bluetooth_provider.dart';

class UuidState {
  final String selectedWriteUuid;
  final String selectedReadUuid;

  UuidState({
    required this.selectedWriteUuid,
    required this.selectedReadUuid,
  });

  UuidState copyWith({
    String? selectedWriteUuid,
    String? selectedReadUuid,
  }) {
    return UuidState(
      selectedWriteUuid: selectedWriteUuid ?? this.selectedWriteUuid,
      selectedReadUuid: selectedReadUuid ?? this.selectedReadUuid,
    );
  }
}

class UuidNotifier extends StateNotifier<UuidState> {
  UuidNotifier()
      : super(UuidState(selectedWriteUuid: '', selectedReadUuid: ''));

  void updateWriteUuid(String writeUuid) {
    state = state.copyWith(selectedWriteUuid: writeUuid);
  }

  void updateReadUuid(String readUuid) {
    state = state.copyWith(selectedReadUuid: readUuid);
  }
}

final uuidProvider = StateNotifierProvider<UuidNotifier, UuidState>((ref) {
  return UuidNotifier();
});

class ParametersModelNotifier extends StateNotifier<List<ParametersModel>> {
  final BluetoothNotifier bluetoothNotifier;

  ParametersModelNotifier(this.bluetoothNotifier) : super([]);

  Future<void> fetchParameters(List<BluetoothDevice> devices) async {
    List<ParametersModel> tempParameterModels = [];
    for (var device in devices) {
      tempParameterModels.add(
        await bluetoothNotifier.convertBluetoothDeviceToParameterModel(device),
      );
    }
    state = tempParameterModels;
  }

  void updateUuids(int index, String? readUuid, String? writeUuid) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index)
          state[i].copyWith(
            readUuid: readUuid,
            writeUuid: writeUuid,
          )
        else
          state[i]
    ];
  }
}

final parametersModelProvider =
    StateNotifierProvider<ParametersModelNotifier, List<ParametersModel>>(
        (ref) {
  final bluetoothNotifier = ref.watch(bluetoothProvider.notifier);
  return ParametersModelNotifier(bluetoothNotifier);
});
