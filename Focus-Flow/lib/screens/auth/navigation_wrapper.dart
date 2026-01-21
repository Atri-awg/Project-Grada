import 'package:flutter/material.dart';
import 'package:focus_flow_app/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:focus_flow_app/providers/auth_provider.dart';
import 'package:focus_flow_app/screens/auth/register_screen.dart';
import 'package:focus_flow_app/screens/home/main_navigation.dart';

class NavigationWrapper extends StatelessWidget {
  const NavigationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Jika sedang dalam proses cek status login (Loading)
    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // Jika sudah login ke Home, jika belum ke Register
    return auth.isAuthenticated ? const MainNavigation() : const RegisterScreen();
  }
}