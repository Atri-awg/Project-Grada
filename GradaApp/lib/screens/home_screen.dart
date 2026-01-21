import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_exam_screen.dart';
import 'scanner_screen.dart';
import 'exam_list_screen.dart';
import '../services/auth_service.dart';
import '../services/migration_helper.dart'; // Import migration helper
import 'auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isMigrating = false;

  @override
  void initState() {
    super.initState();
    _checkAndMigrate();
  }

  // Cek dan migrasi data lama jika ada
  Future<void> _checkAndMigrate() async {
    setState(() => _isMigrating = true);
    
    try {
      final migrationHelper = MigrationHelper();
      
      // Cek struktur data
      await migrationHelper.checkDataStructure();
      
      // Migrasi data lama jika ada
      await migrationHelper.migrateOldDataToUser();
      
    } catch (e) {
      print('Error saat migrasi: $e');
    } finally {
      if (mounted) {
        setState(() => _isMigrating = false);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      try {
        await AuthService().signOut();
        
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getInitial(User? user) {
    if (user == null) return 'U';
    
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!.substring(0, 1).toUpperCase();
    }
    
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.substring(0, 1).toUpperCase();
    }
    
    return 'U';
  }

  String _getDisplayName(User? user) {
    if (user == null) return 'User';
    
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@')[0];
    }
    
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Tampilkan loading saat migrasi
    if (_isMigrating) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Menyiapkan data...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Aplikasi Koreksi Ujian"),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Info User
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        _getInitial(user),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDisplayName(user),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                "Menu Guru",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const Divider(),
              const SizedBox(height: 10),

              _tombolMenu(
                context,
                "Buat Kunci Jawaban",
                Icons.edit_note,
                Colors.blue,
                const CreateExamScreen(),
              ),

              const SizedBox(height: 15),

              _tombolMenu(
                context,
                "Bank Soal & Download PDF",
                Icons.file_download,
                Colors.orange,
                const ExamListScreen(),
              ),

              const SizedBox(height: 40),

              const Text(
                "Menu Koreksi",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const Divider(),
              const SizedBox(height: 10),

              _tombolMenu(
                context,
                "Mulai Scan LJK",
                Icons.qr_code_scanner,
                Colors.green,
                const ScannerPage(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tombolMenu(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
      ),
    );
  }
}