import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_input.dart';
import '../../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Text(
              "Daftar Akun",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            CustomInput(
              hint: "Nama Lengkap",
              icon: Icons.person,
              controller: _name,
            ),
            const SizedBox(height: 16),
            CustomInput(hint: "Email", icon: Icons.email, controller: _email),
            const SizedBox(height: 16),
            CustomInput(
              hint: "Password",
              icon: Icons.lock,
              controller: _pass,
              isPassword: true,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: auth.isLoading
                    ? null
                    : () => auth.register(_email.text, _pass.text, _name.text),
                child: auth.isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Daftar"),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text("Sudah punya akun? Masuk"),
            ),
          ],
        ),
      ),
    );
  }
}
