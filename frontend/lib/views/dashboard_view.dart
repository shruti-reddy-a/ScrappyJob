import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/config_tab.dart';
import 'tabs/jobs_tab.dart';
import 'tabs/settings_tab.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0;
  
  @override
  void didUpdateWidget(covariant DashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentIndex >= 4) {
      _currentIndex = 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= 4) {
      _currentIndex = 3;
    }
    
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    final bodyContent = IndexedStack(
      index: _currentIndex,
      children: [
        DashboardTab(onNavigateToSearches: () => setState(() => _currentIndex = 2)),
        const JobsTab(),
        ConfigTab(onRunStarted: () => setState(() => _currentIndex = 1)),
        const SettingsTab(),
      ],
    );

    final hasActiveTask = context.watch<FirebaseService>().activeProgress != null && 
                          context.watch<FirebaseService>().activeProgress!.status == 'RUNNING';

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            _buildSidebar(hasActiveTask),
            Expanded(
              child: Column(
                children: [
                  _buildDesktopTopBar(hasActiveTask),
                  Expanded(child: bodyContent),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (hasActiveTask)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderColor, height: 1),
        ),
      ),
      body: bodyContent,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderColor, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMobileNavItem(Icons.home_outlined, 'Home', 0),
                _buildMobileNavItem(Icons.work_outline, 'Jobs', 1),
                _buildMobileNavItem(Icons.search, 'Searches', 2, showDot: hasActiveTask),
                _buildMobileNavItem(Icons.settings_outlined, 'Settings', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTopBar(bool hasActiveTask) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (hasActiveTask)
            const Row(
              children: [
                SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                SizedBox(width: 8),
                Text('Task running...', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                SizedBox(width: 16),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool hasActiveTask) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.borderColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
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
          ),
          const SizedBox(height: 16),
          _buildSidebarItem(Icons.home_outlined, 'Home', 0),
          _buildSidebarItem(Icons.work_outline, 'Jobs', 1),
          _buildSidebarItem(Icons.search, 'Searches', 2, showDot: hasActiveTask),
          _buildSidebarItem(Icons.settings_outlined, 'Settings', 3),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, int index, {bool showDot = false}) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.onSurfaceVariant;
    final bgColor = isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 20),
                  if (showDot)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavItem(IconData icon, String label, int index, {bool showDot = false}) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.outline;
    
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (showDot)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
