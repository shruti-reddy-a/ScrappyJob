import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/config_tab.dart';
import 'tabs/jobs_tab.dart';
import 'tabs/settings_tab.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'ScrappyJob',
              style: GoogleFonts.lora(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const DashboardTab(),
          const JobsTab(),
          ConfigTab(onRunStarted: () => setState(() => _currentIndex = 1)),
          const SettingsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: AppColors.onSurface,
          unselectedItemColor: AppColors.onSurfaceVariant,
          backgroundColor: AppColors.surfaceContainerLowest,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          items: [
            _buildNavItem(Icons.home_outlined, 'Home', 0),
            _buildNavItem(Icons.work_outline, 'Jobs', 1),
            _buildNavItem(Icons.search, 'Searches', 2),
            _buildNavItem(Icons.settings_outlined, 'Settings', 3),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
        ),
      ),
      label: label,
    );
  }
}
