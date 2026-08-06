import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../constants/app_colors.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _useCustomCrawler = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  void _loadSettings() {
    final firebaseService = context.read<FirebaseService>();
    final settings = firebaseService.userSettings;
    setState(() {
      _useCustomCrawler = settings['use_custom_crawler'] ?? false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final firebaseService = context.read<FirebaseService>();
    await firebaseService.saveUserSettings({
      'use_custom_crawler': _useCustomCrawler,
    });
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<FirebaseService>().user;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon: _isSaving 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
                label: const Text('Save Settings'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Card(
            elevation: 0,
            color: AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Account Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person, color: AppColors.outline),
                    title: const Text('User ID', style: TextStyle(color: AppColors.onSurface)),
                    subtitle: Text(user?.uid ?? 'Not signed in', style: const TextStyle(color: AppColors.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Card(
            elevation: 0,
            color: AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scraper Engine Configurations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Use Custom Crawler (Playwright + Gemini)', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('If disabled, the scraper will fall back to using Firecrawl SDK.'),
                    value: _useCustomCrawler,
                    onChanged: (val) {
                      setState(() {
                        _useCustomCrawler = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  if (_useCustomCrawler) ...[
                    const SizedBox(height: 8),
                    const Text('Gemini API Key is securely loaded from the backend .env file.', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}