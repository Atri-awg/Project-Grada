import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MigrationHelper {
  static const String databaseURL = 'https://koreksi-ujian-app-default-rtdb.asia-southeast1.firebasedatabase.app';
  
  final DatabaseReference _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: databaseURL,
  ).ref();

  // Fungsi untuk migrasi data lama ke struktur baru
  Future<bool> migrateOldDataToUser() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('Error: User tidak login');
        return false;
      }

      print('Memulai migrasi data...');

      // 1. Cek apakah ada data lama di root 'soal'
      final oldSoalSnapshot = await _db.child('soal').get();
      
      if (oldSoalSnapshot.exists && oldSoalSnapshot.value != null) {
        final oldData = oldSoalSnapshot.value;
        
        if (oldData is Map) {
          print('Ditemukan ${oldData.length} soal lama');
          
          // Copy data ke struktur baru
          for (var entry in oldData.entries) {
            final kodeSoal = entry.key.toString();
            final value = entry.value;
            
            if (value is Map) {
              print('Migrasi soal: $kodeSoal');
              
              // Ambil kunci jawaban dengan safe handling
              List<String> kunciJawaban = [];
              if (value['kunci_jawaban'] != null) {
                if (value['kunci_jawaban'] is List) {
                  kunciJawaban = List<String>.from(
                    (value['kunci_jawaban'] as List).map((e) => e.toString())
                  );
                }
              }
              
              // Simpan ke struktur baru
              await _db
                  .child('users')
                  .child(userId)
                  .child('soal')
                  .child(kodeSoal)
                  .set({
                'nama_soal': value['nama_soal']?.toString() ?? 'Tanpa Nama',
                'jumlah_soal': value['jumlah_soal'] ?? kunciJawaban.length,
                'kunci_jawaban': kunciJawaban,
                'tanggal_dibuat': value['tanggal_dibuat']?.toString() ?? DateTime.now().toIso8601String(),
              });
            }
          }
          
          print('Migrasi selesai!');
        }
      } else {
        print('Tidak ada data lama yang perlu dimigrasi');
      }
      
      return true;
    } catch (e) {
      print('Error migrasi: $e');
      return false;
    }
  }

  // Fungsi untuk membersihkan data lama (HATI-HATI!)
  Future<bool> cleanOldData() async {
    try {
      print('Membersihkan data lama...');
      
      // Hapus data lama di root 'soal'
      await _db.child('soal').remove();
      
      print('Data lama berhasil dihapus');
      return true;
    } catch (e) {
      print('Error hapus data lama: $e');
      return false;
    }
  }

  // Fungsi untuk cek struktur data
  Future<void> checkDataStructure() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('User tidak login');
        return;
      }

      print('\n=== CEK STRUKTUR DATA ===');
      
      // Cek data lama
      final oldSnapshot = await _db.child('soal').get();
      if (oldSnapshot.exists) {
        print('❌ Data lama ditemukan di root/soal');
      } else {
        print('✅ Tidak ada data lama di root/soal');
      }
      
      // Cek data baru
      final newSnapshot = await _db.child('users').child(userId).child('soal').get();
      if (newSnapshot.exists && newSnapshot.value != null) {
        final data = newSnapshot.value;
        if (data is Map) {
          print('✅ Data baru ditemukan: ${data.length} soal');
        }
      } else {
        print('ℹ️  Belum ada data di users/$userId/soal');
      }
      
      print('=========================\n');
    } catch (e) {
      print('Error cek struktur: $e');
    }
  }
}