import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart'; // Import repository Anda

class AuthProvider with ChangeNotifier {
  // 1. Panggil Repository agar Provider tidak perlu akses Firebase langsung
  final AuthRepository _authRepository = AuthRepository();

  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Memantau perubahan status login secara real-time
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // 2. Perbaikan fungsi Register (Memanggil Repository)
  Future<void> register(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Panggil fungsi signUp yang sudah kita buat di AuthRepository
      await _authRepository.signUp(email, password, name);
    } on FirebaseAuthException catch (e) {
      // Melempar error spesifik Firebase agar bisa ditangkap SnackBar di UI
      rethrow;
    } catch (e) {
      throw "Terjadi kesalahan pendaftaran";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. Perbaikan fungsi Login
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authRepository.signIn(email, password);
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      throw "Gagal masuk, periksa koneksi Anda";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 4. Fungsi Logout
  Future<void> logout() async {
    try {
      await _authRepository.signOut();
    } catch (e) {
      print("Logout error: $e");
    }
  }
}
