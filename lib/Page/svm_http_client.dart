import 'package:http/http.dart' as http;
import 'dart:convert';

class SVMHttpClient {
  final String baseUrl;

  SVMHttpClient({this.baseUrl = 'http://192.168.1.8:8080'}); // Ganti IP jika Pyroid di HP

  Future<String> classify(double bpm, double angle) async {
  try {
    final url = '$baseUrl/predict';
    print('📡 Mengirim POST ke: $url');
    print('📤 Payload: bpm=$bpm, angle=$angle');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'bpm': bpm, 'angle': angle}),
    );

    print('📥 Status Code: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['label'];
    } else {
      return 'Gagal koneksi: ${response.statusCode}';
    }
  } catch (e) {
    print('❌ Exception saat HTTP: $e');
    return 'Error: $e';
  }
}
}