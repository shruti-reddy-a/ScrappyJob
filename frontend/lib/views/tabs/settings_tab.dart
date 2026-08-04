import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../constants/app_colors.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<FirebaseService>().user;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.person, color: AppColors.outline),
              title: const Text('User ID', style: TextStyle(color: AppColors.onSurface)),
              subtitle: Text(user?.uid ?? 'Not signed in', style: const TextStyle(color: AppColors.onSurfaceVariant)),
            ),
          )
        ],
      ),
    );
  }
}