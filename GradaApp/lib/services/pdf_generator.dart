import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:barcode/barcode.dart';

class PDFGenerator {
  Future<void> generateAndPrint({
    required String kodeSoal,
    required String namaSoal,
    required int jumlahSoal,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // CORNER MARKERS - Titik hitam di 4 pojok untuk alignment
              pw.Positioned(
                top: 5,
                left: 5,
                child: _buildCornerMarker(),
              ),
              pw.Positioned(
                top: 5,
                right: 5,
                child: _buildCornerMarker(),
              ),
              pw.Positioned(
                bottom: 5,
                left: 5,
                child: _buildCornerMarker(),
              ),
              pw.Positioned(
                bottom: 5,
                right: 5,
                child: _buildCornerMarker(),
              ),

              // KONTEN UTAMA
              pw.Padding(
                padding: const pw.EdgeInsets.all(30),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'LEMBAR JAWABAN UJIAN',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Container(
                            width: 200,
                            height: 2,
                            color: PdfColors.black,
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 15),

                    // INFO SOAL
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Kode Soal: $kodeSoal',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'Mata Pelajaran: $namaSoal',
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'Jumlah Soal: $jumlahSoal',
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        // BARCODE untuk identifikasi
                        _buildBarcode(kodeSoal),
                      ],
                    ),
                    pw.SizedBox(height: 15),

                    // INFO SISWA
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1.5),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Row(
                            children: [
                              pw.Expanded(
                                flex: 2,
                                child: pw.Row(
                                  children: [
                                    pw.Text('Nama: ',
                                        style: const pw.TextStyle(fontSize: 11)),
                                    pw.Expanded(
                                      child: pw.Container(
                                        height: 20,
                                        decoration: const pw.BoxDecoration(
                                          border: pw.Border(
                                            bottom: pw.BorderSide(width: 1),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              pw.SizedBox(width: 20),
                              pw.Expanded(
                                child: pw.Row(
                                  children: [
                                    pw.Text('Kelas: ',
                                        style: const pw.TextStyle(fontSize: 11)),
                                    pw.Expanded(
                                      child: pw.Container(
                                        height: 20,
                                        decoration: const pw.BoxDecoration(
                                          border: pw.Border(
                                            bottom: pw.BorderSide(width: 1),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 12),

                    // PETUNJUK
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey300,
                        border: pw.Border.all(width: 1),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PETUNJUK PENGISIAN:',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            '• Gunakan pensil 2B untuk menghitamkan bulatan jawaban',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            '• Hitamkan dengan sempurna, jangan sampai keluar dari bulatan',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            '• Jangan mencoret, melipat, atau mengotori lembar jawaban',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            '• Pastikan 4 titik hitam di pojok tidak tertutup atau rusak',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 15),

                    // GRID JAWABAN
                    pw.Text(
                      'JAWABAN:',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),

                    // Generate grid dalam 2 kolom
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Kolom 1
                        pw.Expanded(
                          child: _buildAnswerColumn(
                            1,
                            (jumlahSoal / 2).ceil(),
                          ),
                        ),
                        pw.SizedBox(width: 15),
                        // Kolom 2
                        pw.Expanded(
                          child: _buildAnswerColumn(
                            (jumlahSoal / 2).ceil() + 1,
                            jumlahSoal,
                          ),
                        ),
                      ],
                    ),

                    pw.Spacer(),

                    // FOOTER
                    pw.Center(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.only(top: 5),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            top: pw.BorderSide(width: 1),
                          ),
                        ),
                        child: pw.Text(
                          'Scan lembar jawaban menggunakan aplikasi untuk penilaian otomatis',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey700,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Print PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Titik marker hitam di pojok untuk deteksi kamera
  pw.Widget _buildCornerMarker() {
    return pw.Container(
      width: 15,
      height: 15,
      decoration: const pw.BoxDecoration(
        color: PdfColors.black,
        shape: pw.BoxShape.circle,
      ),
    );
  }

  // Widget QR Code untuk kode soal
  pw.Widget _buildBarcode(String kodeSoal) {
    return pw.Container(
      width: 70,
      height: 70,
      child: pw.Column(
        children: [
          pw.Expanded(
            child: pw.BarcodeWidget(
              data: kodeSoal,
              barcode: Barcode.qrCode(),
              drawText: false,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            kodeSoal,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Kolom jawaban dengan bubble A-E
  pw.Widget _buildAnswerColumn(int start, int end) {
    final options = ['A', 'B', 'C', 'D', 'E'];

    return pw.Column(
      children: List.generate(end - start + 1, (index) {
        final nomor = start + index;
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            children: [
              // Nomor soal
              pw.Container(
                width: 25,
                child: pw.Text(
                  '$nomor.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              // Opsi A-E dengan bubble
              pw.Expanded(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: options.map((option) {
                    return pw.Column(
                      children: [
                        pw.Text(
                          option,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          width: 12,
                          height: 12,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(width: 1.5),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}