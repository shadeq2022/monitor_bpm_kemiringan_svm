import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestBluetoothPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
  }
}
