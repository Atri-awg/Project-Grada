import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({super.key});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _kodeSoalController = TextEditingController();
  final TextEditingController _namaSoalController = TextEditingController();
  int _jumlahSoal = 20;
  List<String> _kunciJawaban = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initKunciJawaban();
  }

  void _initKunciJawaban() {
    _kunciJawaban = List.filled(_jumlahSoal, 'A');
  }

  void _updateJumlahSoal(int jumlah) {
    setState(() {
      _jumlahSoal = jumlah;
      if (_kunciJawaban.length < jumlah) {
        _kunciJawaban.addAll(List.filled(jumlah - _kunciJawaban.length, 'A'));
      } else {
        _kunciJawaban = _kunciJawaban.sublist(0, jumlah);
      }
    });
  }

  Future<void> _simpanKunciJawaban() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    bool sukses = await FirebaseService().simpanKunciJawaban(
      kodeSoal: _kodeSoalController.text.toUpperCase(),
      namaSoal: _namaSoalController.text,
      kunciJawaban: _kunciJawaban,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (sukses) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Kunci jawaban berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Gagal menyimpan kunci jawaban'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Kunci Jawaban'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // KODE SOAL
                  TextFormField(
                    controller: _kodeSoalController,
                    decoration: const InputDecoration(
                      labelText: 'Kode Soal',
                      hintText: 'Contoh: MATH001',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kode soal tidak boleh kosong';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // NAMA SOAL
                  TextFormField(
                    controller: _namaSoalController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Soal',
                      hintText: 'Contoh: Matematika Kelas 10',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama soal tidak boleh kosong';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // JUMLAH SOAL
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Jumlah Soal:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      DropdownButton<int>(
                        value: _jumlahSoal,
                        items: [10, 15, 20, 25, 30, 40, 50]
                            .map((e) => DropdownMenuItem(value: e, child: Text('$e Soal')))
                            .toList(),
                        onChanged: (value) => _updateJumlahSoal(value!),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const Text(
                    'Input Kunci Jawaban:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // GRID KUNCI JAWABAN
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _jumlahSoal,
                    itemBuilder: (context, index) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _kunciJawaban[index],
                              isExpanded: true,
                              items: ['A', 'B', 'C', 'D', 'E']
                                  .map((e) => DropdownMenuItem(value: e, child: Center(child: Text(e))))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _kunciJawaban[index] = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // TOMBOL SIMPAN
                  ElevatedButton(
                    onPressed: _simpanKunciJawaban,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'SIMPAN KUNCI JAWABAN',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _kodeSoalController.dispose();
    _namaSoalController.dispose();
    super.dispose();
  }
}