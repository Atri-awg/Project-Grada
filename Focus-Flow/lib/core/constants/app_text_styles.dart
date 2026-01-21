import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Style untuk judul besar (Dashboard/Auth)
  static TextStyle heading = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
  );

  // Style untuk sub-judul atau label
  static TextStyle subHeading = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Style khusus angka Timer (Monospace agar angka tidak bergeser)
  static TextStyle timerDisplay = GoogleFonts.jetBrainsMono(
    fontSize: 44,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
  );

  // Style untuk isi list atau body text
  static TextStyle body = GoogleFonts.poppins(
    fontSize: 14,
    color: AppColors.textMain,
  );

  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
}
