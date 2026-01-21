import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../services/omr_processor.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> dataSoal;

  const ResultScreen({
    super.key, 
    required this.imagePath, 
    required this.dataSoal
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isProcessing = true;
  Map<String, dynamic>? _hasilKoreksi;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _prosesGambar();
  }

  Future<void> _prosesGambar() async {
    try {
      // Load image
      File imageFile = File(widget.imagePath);
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception("Gagal decode image");
      }

      // Proses OMR
      OMRProcessor processor = OMRProcessor();
      Map<String, dynamic> hasil = await processor.prosesLJK(
        image, 
        widget.dataSoal['kunci_jawaban'] as List<String>,
        widget.dataSoal['jumlah_soal'] as int,
      );

      setState(() {
        _hasilKoreksi = hasil;
        _isProcessing = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hasil Koreksi")),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Memproses LJK..."),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 80, color: Colors.red),
                        const SizedBox(height: 20),
                        Text("Error: $_errorMessage"),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Coba Lagi"),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildHasilView(),
    );
  }

  Widget _buildHasilView() {
    int benar = _hasilKoreksi!['benar'];
    int salah = _hasilKoreksi!['salah'];
    int total = _hasilKoreksi!['total'];
    double nilai = (benar / total) * 100;
    List<Map<String, dynamic>> detail = _hasilKoreksi!['detail'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Kartu Nilai
          Card(
            color: nilai >= 75 ? Colors.green[50] : Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text("NILAI", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  const SizedBox(height: 10),
                  Text(
                    nilai.toStringAsFixed(1), 
                    style: TextStyle(
                      fontSize: 60, 
                      fontWeight: FontWeight.bold,
                      color: nilai >= 75 ? Colors.green : Colors.red,
                    )
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat("Benar", benar, Colors.green),
                      _buildStat("Salah", salah, Colors.red),
                      _buildStat("Total", total, Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text("Detail Jawaban:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          // Tabel Detail
          ...detail.map((item) {
            int nomor = item['nomor'];
            String kunci = item['kunci'];
            String jawaban = item['jawaban'];
            bool benar = item['benar'];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: benar ? Colors.green[50] : Colors.red[50],
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: benar ? Colors.green : Colors.red,
                  child: Text("$nomor", style: const TextStyle(color: Colors.white)),
                ),
                title: Text("Jawaban: $jawaban"),
                subtitle: Text("Kunci: $kunci"),
                trailing: Icon(
                  benar ? Icons.check_circle : Icons.cancel,
                  color: benar ? Colors.green : Colors.red,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 5),
        Text("$value", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}