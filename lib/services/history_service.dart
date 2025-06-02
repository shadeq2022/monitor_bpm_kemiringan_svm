import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryService {
  final CollectionReference _historyCollection =
      FirebaseFirestore.instance.collection('history');

  Future<void> addHistory({
    required String tanggal,
    required String kemiringan,
    required String bpm,
    required String keterangan,
  }) async {
    try {
      await _historyCollection.add({
        'tanggal': tanggal,
        'kemiringan': kemiringan,
        'bpm': bpm,
        'keterangan': keterangan,
      });
    } catch (e) {
      print('Gagal menambahkan data history: $e');
      rethrow;
    }
  }
}
