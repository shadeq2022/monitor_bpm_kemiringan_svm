import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'svm_http_client.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final CollectionReference _historyCollection =
      FirebaseFirestore.instance.collection('history');

  final SVMHttpClient svmClient = SVMHttpClient();

  bool _hasNavigatedToWarning = false;
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        title: const Text(
          "Riwayat Pengguna",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFFC8E6C9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          key: ValueKey(_refreshKey),
          stream: _historyCollection.orderBy('tanggal', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Terjadi kesalahan: ${snapshot.error}'),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            if (data.docs.isEmpty) {
              return const Center(
                child: Text(
                  "Belum ada data riwayat.",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            // Cek data terbaru untuk klasifikasi SVM dan navigasi warning
            final latestDoc = data.docs.first;
            final bpm = double.tryParse(latestDoc['bpm']) ?? 0.0;
            final angle = double.tryParse(latestDoc['kemiringan']) ?? 0.0;

            // Panggil classify dan navigasi jika perlu
            svmClient.classify(bpm, angle).then((label) {
              if (!_hasNavigatedToWarning && label != "Normal" && label != "Ngantuk Sedang" && label != "Ngantuk Berat") {
                _hasNavigatedToWarning = true;
                Navigator.pushNamed(context, '/warning');
              }
            });

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 700,
                child: Column(
                  children: [
                    const Text(
                      "RIWAYAT KONDISI PENGGUNA",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHeader("Hari/Tanggal"),
                        _buildHeader("Kemiringan"),
                        _buildHeader("Denyut Nadi"),
                        _buildHeader("Keterangan"),
                      ],
                    ),
                    const Divider(thickness: 1),
                    SizedBox(
                      height: 400,
                      child: RefreshIndicator(
                        onRefresh: () async {
                          setState(() {
                            _refreshKey++;
                          });
                        },
                        child: ListView.builder(
                          itemCount: data.docs.length,
                          itemBuilder: (context, index) {
                            final doc = data.docs[index];
                            final tanggal = DateTime.tryParse(doc['tanggal']) ?? DateTime.now();
                            final formattedTanggal = "${tanggal.year.toString().padLeft(4,'0')}-${tanggal.month.toString().padLeft(2,'0')}-${tanggal.day.toString().padLeft(2,'0')}";
                            String keterangan = doc['keterangan'].toString().toLowerCase();
                            // Normalisasi keterangan ke tiga kategori yang diizinkan
                            if (keterangan != "normal" && keterangan != "mengantuk sedang" && keterangan != "mengantuk berat") {
                              keterangan = "normal";
                            }
                            final kemiringan = doc['kemiringan'];
                            final bpm = doc['bpm'];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildCell(formattedTanggal),
                                  _buildCell("$kemiringan°"),
                                  _buildCell("$bpm BPM"),
                                  _buildCell(keterangan, isKeterangan: true),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                      ),
                      child: const Text("Exit",
                          style: TextStyle(color: Colors.green)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/warning');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                      ),
                      child: const Text("Lihat Warning",
                          style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildCell(String text, {bool isKeterangan = false}) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isKeterangan ? Colors.yellow : Colors.white,
          fontWeight: isKeterangan ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
