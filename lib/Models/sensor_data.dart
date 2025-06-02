class SensorData {
  final double value;
  final double angle;

  SensorData({required this.value, required this.angle});

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      value: (json['bpm'] as num).toDouble(),
      angle: (json['angle'] as num).toDouble(),
    );
  }
}
