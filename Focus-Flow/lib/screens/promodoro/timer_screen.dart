import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/timer_provider.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Kita panggil provider agar UI mendengarkan perubahan detik
    final timer = Provider.of<TimerProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Memberikan sedikit gradien agar layar tidak kaku
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.primary.withOpacity(0.05)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Focus Session",
              style: AppTextStyles.heading.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 10),
            Text(
              "Tetap fokus, Alfi. Kamu pasti bisa!",
              style: AppTextStyles.subHeading,
            ),
            const SizedBox(height: 60),

            // Indikator Lingkaran Pomodoro
            CircularPercentIndicator(
              radius: 140.0,
              lineWidth: 18.0,
              // Mengambil data persen dari provider
              percent: timer.percent,
              animation: true,
              animateFromLastPercent: true,
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timer.timeString,
                    style: AppTextStyles.timerDisplay.copyWith(fontSize: 54),
                  ),
                  Text("menit", style: AppTextStyles.bodySmall),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // Tombol Kontrol
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tombol Reset
                _buildActionButton(
                  onTap: () => timer.resetTimer(),
                  icon: Icons.refresh_rounded,
                  label: "Reset",
                  color: Colors.white24,
                ),
                const SizedBox(width: 30),

                // Tombol Start/Pause
                _buildActionButton(
                  onTap: () =>
                      timer.isRunning ? timer.stopTimer() : timer.startTimer(),
                  icon: timer.isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  label: timer.isRunning ? "Pause" : "Start",
                  color: AppColors.primary,
                  isLarge: true,
                ),
                const SizedBox(width: 30),

                // Tombol Stop (sama dengan reset untuk saat ini)
                _buildActionButton(
                  onTap: () => timer.stopTimer(),
                  icon: Icons.stop_rounded,
                  label: "Stop",
                  color: Colors.white24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk membuat tombol yang konsisten
  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
    bool isLarge = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(isLarge ? 20 : 15),
            decoration: BoxDecoration(
              color: isLarge ? color : AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: isLarge
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              size: isLarge ? 40 : 25,
              color: isLarge ? Colors.black : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
