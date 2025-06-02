import 'dart:async'; // Digunakan untuk Timer (mengatur interval getar)
import 'package:flutter/material.dart'; // Paket utama Flutter untuk UI
import 'package:audioplayers/audioplayers.dart'; // Plugin untuk memainkan audio alarm
import 'package:vibration/vibration.dart'; // Plugin untuk mengakses fitur getar perangkat

// Halaman WarningPage adalah StatefulWidget karena butuh state (alarm & getar)
class WarningPage extends StatefulWidget {
  @override
  State<WarningPage> createState() => _WarningPageState();
}

// State dari WarningPage, termasuk kontrol alarm & getaran
class _WarningPageState extends State<WarningPage> with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer(); // Objek player untuk memutar audio
  bool _shouldPlayAlarm = true; // Flag apakah alarm boleh diputar
  bool _isNavigating = false; // Mencegah user menavigasi lebih dari 1x

  Timer? _vibrationTimer; // Timer untuk mengatur getar berulang

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Mengamati lifecycle aplikasi
    _startWarningEffects(); // Memulai efek peringatan (alarm & getar)
  }

  // Fungsi utama untuk memulai efek peringatan
  void _startWarningEffects() {
    _playAlarmLoop(); // Putar alarm
    _startVibrationLoop(); // Mulai getaran
  }

  // Fungsi untuk memulai getar berulang setiap 1.5 detik
  void _startVibrationLoop() async {
    if (await Vibration.hasVibrator() ?? false) {
      _vibrateStrong(); // Getar pertama langsung
      _vibrationTimer = Timer.periodic(
        Duration(milliseconds: 1500), // Interval total pattern
        (_) {
          _vibrateStrong(); // Getar lagi setiap interval
        },
      );
    }
  }

  // Fungsi yang mendefinisikan pola getar kuat
  void _vibrateStrong() {
    Vibration.vibrate(
      pattern: [0, 500, 200, 500, 200, 500], // Jeda & getar (total 1500ms)
      intensities: [255, 255, 255], // Intensitas maksimal
      amplitude: 255, // Fallback intensitas maksimal (untuk perangkat support)
      repeat: -1, // Jangan diulang otomatis, karena kita pakai Timer
    );
  }

  // Fungsi untuk memutar audio alarm dalam mode loop
  Future<void> _playAlarmLoop() async {
    if (!_shouldPlayAlarm) return; // Jika tidak diizinkan, keluar
    await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Mode loop
    await _audioPlayer.play(AssetSource('mixkit_emergency_alert.mp3')); // Putar alarm
  }

  // Fungsi dipanggil saat widget dihapus dari tree
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Hapus observer lifecycle
    _audioPlayer.stop(); // Hentikan audio
    _audioPlayer.dispose(); // Bebaskan resource audio
    _stopVibration(); // Hentikan getar
    super.dispose(); // Panggil dispose bawaan
  }

  // Fungsi untuk menghentikan getaran dan timer-nya
  void _stopVibration() {
    _vibrationTimer?.cancel(); // Hentikan timer jika ada
    _vibrationTimer = null; // Hapus referensinya
    Vibration.cancel(); // Hentikan getar aktif
  }

  // Fungsi ketika tombol "MATIKAN ALARM" ditekan
  void _stopAlarmAndNavigate() async {
    if (_isNavigating) return; // Cegah lebih dari satu aksi navigasi
    _isNavigating = true; // Tandai sedang navigasi

    _shouldPlayAlarm = false; // Matikan flag alarm

    await _audioPlayer.stop(); // Hentikan alarm
    _stopVibration(); // Hentikan getaran

    if (!mounted) return; // Cek apakah widget masih aktif
    Navigator.pushReplacementNamed(context, '/monitoring'); // Pindah ke halaman monitoring
  }

  // Widget UI utama
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900, // Latar belakang merah gelap
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24), // Padding di sekeliling konten
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Tengah vertikal
            children: [
              Icon(
                Icons.warning_amber_rounded, // Ikon peringatan
                color: Colors.white,
                size: 120,
              ),
              const SizedBox(height: 20), // Spasi
              const Text(
                "PERINGATAN!!!", // Judul utama
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20), // Spasi
              const Text(
                "Anda terdeteksi dalam kondisi mengantuk atau kelelahan. Segera berhenti!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40), // Spasi
              ElevatedButton.icon(
                onPressed: _stopAlarmAndNavigate, // Fungsi saat tombol ditekan
                icon: const Icon(Icons.power_settings_new, color: Colors.white),
                label: const Text(
                  "MATIKAN ALARM",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700, // Warna tombol
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Sudut membulat
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
