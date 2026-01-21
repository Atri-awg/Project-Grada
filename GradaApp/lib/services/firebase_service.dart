import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  // Database URL Anda
  static const String databaseURL = 'https://koreksi-ujian-app-default-rtdb.asia-southeast1.firebasedatabase.app';
  
  // Gunakan default Firebase instance
  final DatabaseReference _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: databaseURL,
  ).ref();

  // Fungsi helper untuk mendapatkan user ID
  String? _getUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  // 1. SIMPAN KUNCI JAWABAN BARU (per user)
  Future<bool> simpanKunciJawaban({
    required String kodeSoal,
    required String namaSoal,
    required List<String> kunciJawaban,
  }) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Error: User tidak login');
        return false;
      }

      // Simpan di path: users/{userId}/soal/{kodeSoal}
      await _db.child('users').child(userId).child('soal').child(kodeSoal).set({
        'nama_soal': namaSoal,
        'jumlah_soal': kunciJawaban.length,
        'kunci_jawaban': kunciJawaban,
        'tanggal_dibuat': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error simpan kunci: $e');
      return false;
    }
  }

  // 2. AMBIL KUNCI JAWABAN BERDASARKAN KODE QR (per user)
  Future<Map<String, dynamic>?> cekKodeSoal(String kodeSoal) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Error: User tidak login');
        return null;
      }

      final snapshot = await _db
          .child('users')
          .child(userId)
          .child('soal')
          .child(kodeSoal)
          .get();
      
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        
        if (data is Map) {
          // Ambil kunci_jawaban dengan safe handling
          List<String> kunciJawaban = [];
          if (data['kunci_jawaban'] != null) {
            if (data['kunci_jawaban'] is List) {
              kunciJawaban = List<String>.from(
                (data['kunci_jawaban'] as List).map((e) => e.toString())
              );
            }
          }
          
          return {
            'kode_soal': kodeSoal,
            'nama_soal': data['nama_soal']?.toString() ?? 'Tanpa Nama',
            'jumlah_soal': data['jumlah_soal'] ?? kunciJawaban.length,
            'kunci_jawaban': kunciJawaban,
          };
        }
      }
      return null;
    } catch (e) {
      print('Error cek kode: $e');
      return null;
    }
  }

  // 3. AMBIL SEMUA SOAL (untuk halaman daftar soal per user)
  Future<List<Map<String, dynamic>>> getAllSoal() async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Error: User tidak login');
        return [];
      }

      final snapshot = await _db
          .child('users')
          .child(userId)
          .child('soal')
          .get();
      
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        
        // Handle jika data adalah Map
        if (data is Map) {
          List<Map<String, dynamic>> listSoal = [];
          
          data.forEach((key, value) {
            if (value is Map) {
              listSoal.add({
                'kode_soal': key.toString(),
                'nama_soal': value['nama_soal']?.toString() ?? 'Tanpa Nama',
                'jumlah_soal': value['jumlah_soal'] ?? 0,
                'tanggal_dibuat': value['tanggal_dibuat']?.toString() ?? DateTime.now().toIso8601String(),
              });
            }
          });
          
          // Urutkan berdasarkan tanggal terbaru
          listSoal.sort((a, b) {
            try {
              final dateA = DateTime.parse(a['tanggal_dibuat']);
              final dateB = DateTime.parse(b['tanggal_dibuat']);
              return dateB.compareTo(dateA);
            } catch (e) {
              return 0;
            }
          });
          
          return listSoal;
        }
      }
      return [];
    } catch (e) {
      print('Error get all soal: $e');
      return [];
    }
  }

  // 4. HAPUS SOAL (per user)
  Future<bool> hapusSoal(String kodeSoal) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Error: User tidak login');
        return false;
      }

      await _db
          .child('users')
          .child(userId)
          .child('soal')
          .child(kodeSoal)
          .remove();
      return true;
    } catch (e) {
      print('Error hapus soal: $e');
      return false;
    }
  }

  // 5. SIMPAN HASIL KOREKSI (per user)
  Future<bool> simpanHasilKoreksi({
    required String kodeSoal,
    required String namaLJK,
    required List<String> jawabanSiswa,
    required int skor,
    required int jumlahBenar,
    required int jumlahSalah,
  }) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Error: User tidak login');
        return false;
      }

      final hasilId = DateTime.now().millisecondsSinceEpoch.toString();
      
      await _db
          .child('users')
          .child(userId)
          .child('hasil_koreksi')
          .child(hasilId)
          .set({
        'kode_soal': kodeSoal,
        'nama_ljk': namaLJK,
        'jawaban_siswa': jawabanSiswa,
        'skor': skor,
        'jumlah_benar': jumlahBenar,
        'jumlah_salah': jumlahSalah,
        'tanggal_koreksi': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      print('Error simpan hasil: $e');
      return false;
    }
  }

  // 6. AMBIL SEMUA HASIL KOREKSI (per user)
  Future<List<Map<String, dynamic>>> getAllHasilKoreksi() async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Error: User tidak login');
        return [];
      }

      final snapshot = await _db
          .child('users')
          .child(userId)
          .child('hasil_koreksi')
          .get();
      
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        
        if (data is Map) {
          List<Map<String, dynamic>> listHasil = [];
          
          data.forEach((key, value) {
            if (value is Map) {
              listHasil.add({
                'id': key.toString(),
                'kode_soal': value['kode_soal']?.toString() ?? '',
                'nama_ljk': value['nama_ljk']?.toString() ?? 'Tanpa Nama',
                'skor': value['skor'] ?? 0,
                'jumlah_benar': value['jumlah_benar'] ?? 0,
                'jumlah_salah': value['jumlah_salah'] ?? 0,
                'tanggal_koreksi': value['tanggal_koreksi']?.toString() ?? DateTime.now().toIso8601String(),
              });
            }
          });
          
          // Urutkan berdasarkan tanggal terbaru
          listHasil.sort((a, b) {
            try {
              final dateA = DateTime.parse(a['tanggal_koreksi']);
              final dateB = DateTime.parse(b['tanggal_koreksi']);
              return dateB.compareTo(dateA);
            } catch (e) {
              return 0;
            }
          });
          
          return listHasil;
        }
      }
      return [];
    } catch (e) {
      print('Error get hasil koreksi: $e');
      return [];
    }
  }
}