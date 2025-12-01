import 'package:battery_plus/battery_plus.dart';

class BatteryService {
  final Battery _battery = Battery();

  Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      print('Error getting battery level: $e');
      return 0;
    }
  }

  Stream<BatteryState> get batteryStateStream => _battery.onBatteryStateChanged;

  Future<BatteryState> getBatteryState() async {
    try {
      return await _battery.batteryState;
    } catch (e) {
      print('Error getting battery state: $e');
      return BatteryState.unknown;
    }
  }
}
