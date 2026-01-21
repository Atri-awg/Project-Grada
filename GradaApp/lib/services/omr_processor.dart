import 'package:image/image.dart' as img;

class OMRProcessor {
  
  // Fungsi Utama Proses LJK
  Future<Map<String, dynamic>> prosesLJK(
    img.Image image, 
    List<String> kunciJawaban,
    int jumlahSoal,
  ) async {
    
    // 1. DETEKSI 4 MARKER POINTS (pojok kertas)
    List<Point>? markers = _detectMarkers(image);
    if (markers == null || markers.length != 4) {
      throw Exception("Tidak dapat mendeteksi 4 marker pojok kertas");
    }

    // 2. PERSPECTIVE CORRECTION (luruskan kertas)
    img.Image correctedImage = _perspectiveTransform(image, markers);

    // 3. DETEKSI JAWABAN SISWA
    List<String> jawabanSiswa = _detectAnswers(correctedImage, jumlahSoal);

    // 4. KOREKSI
    return _koreksi(jawabanSiswa, kunciJawaban);
  }

  // --- STEP 1: DETEKSI 4 MARKER POJOK ---
  List<Point>? _detectMarkers(img.Image image) {
    // Convert ke grayscale
    img.Image gray = img.grayscale(image);
    
    // Threshold untuk deteksi hitam
    img.Image binary = img.Image(width: gray.width, height: gray.height);
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        var pixel = gray.getPixel(x, y);
        int brightness = pixel.r.toInt();
        int colorValue = brightness < 100 ? 0 : 255;
        // setPixelRgba sekarang butuh 6 parameter: x, y, r, g, b, a
        binary.setPixelRgba(x, y, colorValue, colorValue, colorValue, 255);
      }
    }

    // Cari 4 titik hitam terbesar di pojok
    List<Point> candidates = [];
    
    // Scan area pojok (dibagi jadi 4 kuadran)
    int w = binary.width;
    int h = binary.height;
    
    // Kiri Atas
    candidates.add(_findDarkestPoint(binary, 0, 0, w ~/ 3, h ~/ 3));
    // Kanan Atas
    candidates.add(_findDarkestPoint(binary, w * 2 ~/ 3, 0, w, h ~/ 3));
    // Kiri Bawah
    candidates.add(_findDarkestPoint(binary, 0, h * 2 ~/ 3, w ~/ 3, h));
    // Kanan Bawah
    candidates.add(_findDarkestPoint(binary, w * 2 ~/ 3, h * 2 ~/ 3, w, h));

    return candidates;
  }

  Point _findDarkestPoint(img.Image image, int x1, int y1, int x2, int y2) {
    int darkestX = x1;
    int darkestY = y1;
    int minBrightness = 255;

    for (int y = y1; y < y2; y++) {
      for (int x = x1; x < x2; x++) {
        var pixel = image.getPixel(x, y);
        int brightness = pixel.r.toInt();
        if (brightness < minBrightness) {
          minBrightness = brightness;
          darkestX = x;
          darkestY = y;
        }
      }
    }
    return Point(darkestX.toDouble(), darkestY.toDouble());
  }

  // --- STEP 2: PERSPECTIVE TRANSFORM (Luruskan) ---
  img.Image _perspectiveTransform(img.Image image, List<Point> markers) {
    // Urutkan marker: [TopLeft, TopRight, BottomLeft, BottomRight]
    markers.sort((a, b) {
      if ((a.y - b.y).abs() < 50) {
        return a.x.compareTo(b.x);
      }
      return a.y.compareTo(b.y);
    });

    Point topLeft = markers[0];
    Point topRight = markers[1];
    Point bottomLeft = markers[2];
    Point bottomRight = markers[3];

    // Transform sederhana (bisa pakai library opencv_dart untuk lebih akurat)
    // Untuk MVP, kita crop saja berdasarkan bounding box marker
    int minX = [topLeft.x, topRight.x, bottomLeft.x, bottomRight.x].reduce((a, b) => a < b ? a : b).toInt();
    int maxX = [topLeft.x, topRight.x, bottomLeft.x, bottomRight.x].reduce((a, b) => a > b ? a : b).toInt();
    int minY = [topLeft.y, topRight.y, bottomLeft.y, bottomRight.y].reduce((a, b) => a < b ? a : b).toInt();
    int maxY = [topLeft.y, topRight.y, bottomLeft.y, bottomRight.y].reduce((a, b) => a > b ? a : b).toInt();

    return img.copyCrop(image, 
      x: minX, 
      y: minY, 
      width: maxX - minX, 
      height: maxY - minY
    );
  }

  // --- STEP 3: DETEKSI JAWABAN ---
  List<String> _detectAnswers(img.Image image, int jumlahSoal) {
    List<String> hasil = [];
    
    // Convert ke grayscale
    img.Image gray = img.grayscale(image);
    
    // Asumsi layout: 2 kolom, 5 opsi (A-E)
    int soalPerKolom = (jumlahSoal / 2).ceil();
    double startY = image.height * 0.3; // Skip header (30%)
    double endY = image.height * 0.9;
    double rowHeight = (endY - startY) / soalPerKolom;
    
    // Kolom 1 (kiri)
    double col1X = image.width * 0.15;
    // Kolom 2 (kanan)
    double col2X = image.width * 0.65;
    
    double opsiWidth = image.width * 0.05; // Jarak antar opsi
    
    for (int i = 0; i < jumlahSoal; i++) {
      int kolom = i < soalPerKolom ? 0 : 1;
      int row = i < soalPerKolom ? i : i - soalPerKolom;
      
      double baseX = kolom == 0 ? col1X : col2X;
      double baseY = startY + (row * rowHeight);
      
      // Check setiap opsi A-E
      List<int> brightness = [];
      for (int opt = 0; opt < 5; opt++) {
        int checkX = (baseX + (opt * opsiWidth)).toInt();
        int checkY = baseY.toInt();
        
        // Sample area bulatan (15x15 pixel)
        int totalBrightness = 0;
        int count = 0;
        for (int dy = -7; dy <= 7; dy++) {
          for (int dx = -7; dx <= 7; dx++) {
            int px = checkX + dx;
            int py = checkY + dy;
            if (px >= 0 && px < gray.width && py >= 0 && py < gray.height) {
              var pixel = gray.getPixel(px, py);
              totalBrightness += pixel.r.toInt();
              count++;
            }
          }
        }
        brightness.add(totalBrightness ~/ count);
      }
      
      // Cari yang paling gelap (dihitamkan)
      int minIndex = 0;
      int minValue = brightness[0];
      for (int j = 1; j < brightness.length; j++) {
        if (brightness[j] < minValue) {
          minValue = brightness[j];
          minIndex = j;
        }
      }
      
      // Threshold: jika brightness < 150, berarti dihitamkan
      if (minValue < 150) {
        hasil.add(['A', 'B', 'C', 'D', 'E'][minIndex]);
      } else {
        hasil.add(''); // Tidak dijawab
      }
    }
    
    return hasil;
  }

  // --- STEP 4: KOREKSI ---
  Map<String, dynamic> _koreksi(List<String> jawabanSiswa, List<String> kunciJawaban) {
    int benar = 0;
    int salah = 0;
    List<Map<String, dynamic>> detail = [];

    for (int i = 0; i < kunciJawaban.length; i++) {
      String kunci = kunciJawaban[i];
      String jawaban = i < jawabanSiswa.length ? jawabanSiswa[i] : '';
      bool isBenar = jawaban == kunci;
      
      if (isBenar) benar++;
      if (!isBenar && jawaban.isNotEmpty) salah++;

      detail.add({
        'nomor': i + 1,
        'kunci': kunci,
        'jawaban': jawaban.isEmpty ? 'Kosong' : jawaban,
        'benar': isBenar,
      });
    }

    return {
      'benar': benar,
      'salah': salah,
      'total': kunciJawaban.length,
      'detail': detail,
    };
  }
}

// Helper class untuk koordinat
class Point {
  final double x;
  final double y;
  Point(this.x, this.y);
}