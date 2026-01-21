import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  String? get currentUserId => _auth.currentUser?.uid;

  Future<UserCredential?> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // KUNCI UTAMA: Sign out dulu jika ada user untuk clear cache
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('⚠️ User masih login, sign out dulu...');
        await _auth.signOut();
        // Delay untuk memastikan sign out selesai
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      print('🔐 Melakukan login...');
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Login berhasil: ${userCredential.user?.email}');
      return userCredential;
      
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Unexpected Error: $e');
      // Jika error bukan FirebaseAuthException, coba force sign out dan retry
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('type') ||
          e.toString().contains('cast')) {
        print('🔄 Cache error detected, clearing and retrying...');
        try {
          await _auth.signOut();
          await Future.delayed(Duration(seconds: 1));
          
          // Retry login
          UserCredential userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          print('✅ Login retry berhasil');
          return userCredential;
        } catch (retryError) {
          print('❌ Retry gagal: $retryError');
          throw 'Login gagal. Silakan coba lagi.';
        }
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      print('🚪 Melakukan logout...');
      await _auth.signOut();
      // Delay untuk memastikan logout complete
      await Future.delayed(Duration(milliseconds: 500));
      print('✅ Logout berhasil');
    } catch (e) {
      print('❌ Error logout: $e');
      // Force sign out
      try {
        await _auth.signOut();
      } catch (_) {}
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter.';
      case 'email-already-in-use':
        return 'Email sudah digunakan. Silakan login atau gunakan email lain.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
        return 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.';
      case 'wrong-password':
        return 'Password salah. Silakan coba lagi.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan.';
      default:
        return 'Terjadi kesalahan: ${e.message}';
    }
  }

  CollectionReference getUserCollection(String collectionName) {
    if (currentUserId == null) {
      throw Exception('User belum login');
    }
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection(collectionName);
  }
}