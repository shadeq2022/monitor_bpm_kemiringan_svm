class SensorData {
  final int bpm;       // misalnya BPM (denyut nadi)
  final double angle;    // misalnya sudut kemiringan tubuh

  SensorData({
    required this.bpm,
    required this.angle,
  });

  // Optional: buat parsing dari JSON, kalau pakai data dari API atau Bluetooth
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      bpm: json['bpm'],
      angle: json['angle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bpm': bpm,
      'angle': angle,
    };
  }
}
