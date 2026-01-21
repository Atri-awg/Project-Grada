import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/pdf_generator.dart';

class ExamListScreen extends StatefulWidget {
  const ExamListScreen({super.key});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  List<Map<String, dynamic>> _listSoal = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSoal();
  }

  Future<void> _loadSoal() async {
    setState(() => _isLoading = true);
    _listSoal = await FirebaseService().getAllSoal();
    setState(() => _isLoading = false);
  }

  Future<void> _downloadPDF(Map<String, dynamic> soal) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Fixed: Use proper instance of PDFGenerator
      final pdfGenerator = PDFGenerator();
      await pdfGenerator.generateAndPrint(
        kodeSoal: soal['kode_soal'],
        namaSoal: soal['nama_soal'],
        jumlahSoal: soal['jumlah_soal'],
      );
      
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ PDF Lembar Jawaban siap dicetak!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _hapusSoal(String kodeSoal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Hapus soal "$kodeSoal"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool sukses = await FirebaseService().hapusSoal(kodeSoal);
      if (sukses) {
        _loadSoal();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Soal berhasil dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Soal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSoal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listSoal.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada soal.\nBuat soal baru terlebih dahulu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _listSoal.length,
                  itemBuilder: (context, index) {
                    final soal = _listSoal[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            soal['kode_soal'].substring(0, 1),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          soal['kode_soal'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(soal['nama_soal']),
                            const SizedBox(height: 4),
                            Text(
                              '${soal['jumlah_soal']} Soal',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // TOMBOL DOWNLOAD PDF
                            IconButton(
                              icon: const Icon(Icons.print, color: Colors.green),
                              onPressed: () => _downloadPDF(soal),
                              tooltip: 'Cetak Lembar Jawaban',
                            ),
                            // TOMBOL HAPUS
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _hapusSoal(soal['kode_soal']),
                              tooltip: 'Hapus Soal',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}