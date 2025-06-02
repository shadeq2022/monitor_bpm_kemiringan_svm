import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';

class BLEService {
  BLEService._privateConstructor();

  static final BLEService _instance = BLEService._privateConstructor();

  factory BLEService() {
    return _instance;
  }

  final String targetDeviceName = "ESP32";
  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;

  final ValueNotifier<String> bpm = ValueNotifier<String>("0");
  final ValueNotifier<String> kemiringan = ValueNotifier<String>("0");

  Future<void> connectToDevice() async {
    print("Mulai scan device...");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) async {
      print("Scan results updated: ${results.length} devices ditemukan");
      for (ScanResult r in results) {
        print("Ketemu device: ${r.device.name}");
        if (r.device.name == targetDeviceName) {
          print("Target device ditemukan! Berhenti scan dan coba connect...");
          FlutterBluePlus.stopScan();
          _device = r.device;
          try {
            await _device!.connect();
            print("Berhasil connect ke device: ${_device!.name}");
          } catch (e) {
            print("Gagal connect ke device: $e");
            return;
          }

          var services = await _device!.discoverServices();
          print("Jumlah service ditemukan: ${services.length}");

          for (var service in services) {
            print("Service UUID: ${service.uuid}");
            for (var char in service.characteristics) {
              print("Characteristic UUID: ${char.uuid}, notify: ${char.properties.notify}");
              if (char.properties.notify) {
                _characteristic = char;
                await char.setNotifyValue(true);
                print("Set notify true pada characteristic: ${char.uuid}");
                char.lastValueStream.listen((value) {
                  final data = String.fromCharCodes(value);
                  print("Data diterima dari characteristic: $data");
                  final parts = data.split(',');
                  if (parts.length == 2) {
                    bpm.value = parts[0];
                    kemiringan.value = parts[1];
                  }
                });
                break;
              }
            }
          }
          break;  // keluar dari for setelah connect ke device target
        }
      }
    });
  }

  void disconnect() {
    if (_device != null) {
      print("Disconnect dari device: ${_device!.name}");
      _device!.disconnect();
    } else {
      print("Tidak ada device untuk disconnect");
    }
  }
}
