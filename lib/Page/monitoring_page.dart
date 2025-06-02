import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../services/history_service.dart';
import '../ble_service.dart';
import 'svm_http_client.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({Key? key}) : super(key: key);

  @override
  _MonitoringPageState createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  String bpm = "0";
  String angle = "0";
  String result = 'Menunggu data...';
  bool _isLoading = false;

  final HistoryService historyService = HistoryService();
  final BLEService bleService = BLEService();
  final SVMHttpClient svmClient = SVMHttpClient();

  Timer? _debounceTimer;
  Timer? _debounceSVM;

  @override
  void initState() {
    super.initState();
    void updateMonitoringData() {
      setState(() {
        bpm = bleService.bpm.value;
        angle = bleService.kemiringan.value;
      });
      print('Update data dari BLE: bpm=$bpm, angle=$angle');
      _debounceSaveHistory();
      _debounceKirimDataKePyroid();
    }

    bleService.bpm.addListener(updateMonitoringData);
    bleService.kemiringan.addListener(updateMonitoringData);
  }

  void _debounceKirimDataKePyroid() {
    if (_debounceSVM?.isActive ?? false) _debounceSVM!.cancel();
    _debounceSVM = Timer(const Duration(seconds: 1), () {
      if (bpm != "0" && angle != "0") {
        _kirimDataKePyroid();
      }
    });
  }

  void _kirimDataKePyroid() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      print('Mengirim data ke Pyroid: bpm=$bpm, angle=$angle');
      final res = await svmClient.classify(double.parse(bpm), double.parse(angle));
      print('Response dari Pyroid: $res');
      
      if (mounted) {
        setState(() {
          result = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          result = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _debounceSaveHistory() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _saveHistory();
    });
  }

  void _saveHistory() {
    if (bpm != "0" && angle != "0") {
      final String tanggal = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      historyService.addHistory(
        tanggal: tanggal,
        bpm: bpm,
        kemiringan: angle,
        keterangan: result,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Page'),
        backgroundColor: const Color(0xFF6FCF97),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFFC8E6C9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'KONDISI TUBUH',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40),
            _buildInfoField('Denyut Nadi (BPM)', Icons.favorite, Colors.red, bpm),
            const SizedBox(height: 20),
            _buildInfoField('Kemiringan Tubuh', Icons.accessibility_new, Colors.blueGrey, angle),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF9E9E9E)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hasil Klasifikasi:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Text(
                          result,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/history');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Lihat Riwayat',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, IconData icon, Color iconColor, String value) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: iconColor),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Colors.black87),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _debounceSVM?.cancel();
    super.dispose();
  }
}
