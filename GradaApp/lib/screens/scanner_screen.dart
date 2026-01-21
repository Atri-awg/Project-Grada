import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../services/firebase_service.dart';
import 'result_screen.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  MobileScannerController qrController = MobileScannerController();
  bool _isProcessing = false;
  String? _detectedCode;
  Map<String, dynamic>? _dataSoal;

  void _onQRDetected(String code) async {
    if (_isProcessing || _detectedCode == code) return;
    
    setState(() {
      _isProcessing = true;
      _detectedCode = code;
    });
    
    await qrController.stop();

    var dataSoal = await FirebaseService().cekKodeSoal(code);

    if (dataSoal != null) {
      _dataSoal = dataSoal;
      if (mounted) _showInstructions();
    } else {
      _showError("Kode Soal tidak ditemukan!");
    }
  }

  Future<void> _showInstructions() async {
    bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.blue),
            SizedBox(width: 8),
            Text('📸 Petunjuk Foto LJK'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pastikan saat mengambil foto:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInstructionRow('✓', '4 titik hitam pojok terlihat semua'),
            _buildInstructionRow('✓', 'Foto dari atas (tegak lurus)'),
            _buildInstructionRow('✓', 'Pencahayaan cukup, tidak ada bayangan'),
            _buildInstructionRow('✓', 'Seluruh lembar masuk frame'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_camera, color: Colors.green, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Posisikan kertas dalam zona hijau',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kamera akan otomatis mendeteksi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Mulai Scan'),
          ),
        ],
      ),
    );

    if (proceed == true) {
      _openCameraWithOverlay();
    } else {
      setState(() {
        _isProcessing = false;
        _detectedCode = null;
      });
      if (mounted) {
        await qrController.start();
      }
    }
  }

  Future<void> _openCameraWithOverlay() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      _showError("Kamera tidak tersedia");
      return;
    }

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutoScannerScreen(
          camera: cameras.first,
          dataSoal: _dataSoal!,
        ),
      ),
    );

    if (result == true) {
      // Sukses scan, kembali ke home
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _detectedCode = null;
          _dataSoal = null;
        });
      }
    } else {
      setState(() {
        _isProcessing = false;
        _detectedCode = null;
      });
      if (mounted) await qrController.start();
    }
  }

  Widget _buildInstructionRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(msg),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code Soal"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: qrController,
            onDetect: (capture) {
              if (_isProcessing) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _onQRDetected(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  "Arahkan ke QR Code",
                  style: TextStyle(
                    color: Colors.white,
                    backgroundColor: Colors.black54,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Memproses...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    qrController.dispose();
    super.dispose();
  }
}

// Screen auto scanner dengan deteksi otomatis
class AutoScannerScreen extends StatefulWidget {
  final CameraDescription camera;
  final Map<String, dynamic> dataSoal;

  const AutoScannerScreen({
    super.key,
    required this.camera,
    required this.dataSoal,
  });

  @override
  State<AutoScannerScreen> createState() => _AutoScannerScreenState();
}

class _AutoScannerScreenState extends State<AutoScannerScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  Timer? _detectionTimer;
  bool _isProcessing = false;
  bool _cornersDetected = false;
  int _detectionCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      _startAutoDetection();
    });
  }

  void _startAutoDetection() {
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isProcessing && mounted) {
        _checkCorners();
      }
    });
  }

  Future<void> _checkCorners() async {
    if (_isProcessing) return;

    try {
      final image = await _controller.takePicture();
      final bool detected = await _detectCorners(image.path);

      if (mounted) {
        setState(() {
          _cornersDetected = detected;
        });

        if (detected) {
          _detectionCount++;
          if (_detectionCount >= 2) {
            // Deteksi stabil selama 2 kali berturut-turut
            _detectionTimer?.cancel();
            await _processImage(image.path);
          }
        } else {
          _detectionCount = 0;
        }
      }

      // Hapus file sementara jika tidak terdeteksi
      if (!detected) {
        await File(image.path).delete();
      }
    } catch (e) {
      debugPrint('Error checking corners: $e');
    }
  }

  Future<bool> _detectCorners(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) return false;

      img.Image gray = img.grayscale(image);
      img.Image binary = img.Image(width: gray.width, height: gray.height);
      
      for (int y = 0; y < gray.height; y++) {
        for (int x = 0; x < gray.width; x++) {
          var pixel = gray.getPixel(x, y);
          int r = pixel.r.toInt();
          
          if (r < 50) {
            binary.setPixelRgba(x, y, 0, 0, 0, 255);
          } else {
            binary.setPixelRgba(x, y, 255, 255, 255, 255);
          }
        }
      }

      int cornerSize = (image.width * 0.15).toInt();
      
      bool topLeft = _hasBlackBlob(binary, 0, 0, cornerSize, cornerSize);
      bool topRight = _hasBlackBlob(binary, image.width - cornerSize, 0, cornerSize, cornerSize);
      bool bottomLeft = _hasBlackBlob(binary, 0, image.height - cornerSize, cornerSize, cornerSize);
      bool bottomRight = _hasBlackBlob(binary, image.width - cornerSize, image.height - cornerSize, cornerSize, cornerSize);

      return topLeft && topRight && bottomLeft && bottomRight;
      
    } catch (e) {
      debugPrint('Error detecting corners: $e');
      return false;
    }
  }

  bool _hasBlackBlob(img.Image image, int startX, int startY, int width, int height) {
    int blackPixelCount = 0;
    int totalPixels = width * height;
    
    for (int y = startY; y < startY + height && y < image.height; y++) {
      for (int x = startX; x < startX + width && x < image.width; x++) {
        var pixel = image.getPixel(x, y);
        int r = pixel.r.toInt();
        if (r < 128) blackPixelCount++;
      }
    }
    
    double ratio = blackPixelCount / totalPixels;
    return ratio > 0.05;
  }

  Future<void> _processImage(String imagePath) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    // Tampilkan loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('✓ 4 titik terdeteksi!\nMemproses...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    Navigator.pop(context); // Tutup loading dialog

    // Navigate ke result screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          imagePath: imagePath,
          dataSoal: widget.dataSoal,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("SCANNING"),
        backgroundColor: _cornersDetected ? Colors.green : Colors.orange,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // Camera Preview
                Center(
                  child: CameraPreview(_controller),
                ),
                
                // Overlay zona deteksi
                CustomPaint(
                  painter: ScannerOverlayPainter(
                    cornersDetected: _cornersDetected,
                  ),
                  child: Container(),
                ),
                
                // Status indicator
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _cornersDetected 
                            ? Colors.green.withOpacity(0.9)
                            : Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _cornersDetected ? Icons.check_circle : Icons.search,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _cornersDetected 
                                ? '✓ 4 Titik Terdeteksi'
                                : 'Posisikan dalam zona hijau',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

// Custom Painter untuk zona deteksi scanner
class ScannerOverlayPainter extends CustomPainter {
  final bool cornersDetected;

  ScannerOverlayPainter({this.cornersDetected = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Margin zona deteksi
    final horizontalMargin = size.width * 0.08;
    final verticalMargin = size.height * 0.12;
    
    final lineLength = 50.0;
    final cornerRadius = 8.0;

    // Warna berubah saat terdeteksi
    final color = cornersDetected ? Colors.green : Colors.white;
    
    // Paint untuk garis sudut
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Zona deteksi (kotak)
    final zoneRect = Rect.fromLTRB(
      horizontalMargin,
      verticalMargin,
      size.width - horizontalMargin,
      size.height - verticalMargin,
    );

    // Gambar garis sudut di 4 pojok
    // Top-Left
    canvas.drawLine(
      Offset(zoneRect.left, zoneRect.top + cornerRadius),
      Offset(zoneRect.left, zoneRect.top + lineLength),
      linePaint,
    );
    canvas.drawLine(
      Offset(zoneRect.left + cornerRadius, zoneRect.top),
      Offset(zoneRect.left + lineLength, zoneRect.top),
      linePaint,
    );

    // Top-Right
    canvas.drawLine(
      Offset(zoneRect.right, zoneRect.top + cornerRadius),
      Offset(zoneRect.right, zoneRect.top + lineLength),
      linePaint,
    );
    canvas.drawLine(
      Offset(zoneRect.right - cornerRadius, zoneRect.top),
      Offset(zoneRect.right - lineLength, zoneRect.top),
      linePaint,
    );

    // Bottom-Left
    canvas.drawLine(
      Offset(zoneRect.left, zoneRect.bottom - cornerRadius),
      Offset(zoneRect.left, zoneRect.bottom - lineLength),
      linePaint,
    );
    canvas.drawLine(
      Offset(zoneRect.left + cornerRadius, zoneRect.bottom),
      Offset(zoneRect.left + lineLength, zoneRect.bottom),
      linePaint,
    );

    // Bottom-Right
    canvas.drawLine(
      Offset(zoneRect.right, zoneRect.bottom - cornerRadius),
      Offset(zoneRect.right, zoneRect.bottom - lineLength),
      linePaint,
    );
    canvas.drawLine(
      Offset(zoneRect.right - cornerRadius, zoneRect.bottom),
      Offset(zoneRect.right - lineLength, zoneRect.bottom),
      linePaint,
    );

    // Kotak outline zona (opsional, bisa dihilangkan)
    final zonePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRect(zoneRect, zonePaint);

    // Area gelap di luar zona
    final darkPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);

    // Top
    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, zoneRect.top),
      darkPaint,
    );
    // Bottom
    canvas.drawRect(
      Rect.fromLTRB(0, zoneRect.bottom, size.width, size.height),
      darkPaint,
    );
    // Left
    canvas.drawRect(
      Rect.fromLTRB(0, zoneRect.top, zoneRect.left, zoneRect.bottom),
      darkPaint,
    );
    // Right
    canvas.drawRect(
      Rect.fromLTRB(zoneRect.right, zoneRect.top, size.width, zoneRect.bottom),
      darkPaint,
    );

    // Teks petunjuk di bawah
    final textSpan = TextSpan(
      text: 'Posisikan 4 titik hitam di dalam zona',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    final textBgRect = Rect.fromCenter(
      center: Offset(size.width / 2, zoneRect.bottom + 40),
      width: textPainter.width + 30,
      height: textPainter.height + 16,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(textBgRect, const Radius.circular(10)),
      Paint()..color = Colors.black.withOpacity(0.75),
    );
    
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        zoneRect.bottom + 32,
      ),
    );
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter oldDelegate) {
    return oldDelegate.cornersDetected != cornersDetected;
  }
}