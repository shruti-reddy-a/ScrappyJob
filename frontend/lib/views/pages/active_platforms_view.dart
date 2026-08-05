import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../models/ats_platform.dart';
import '../../constants/app_colors.dart';

class ActivePlatformsView extends StatefulWidget {
  const ActivePlatformsView({super.key});

  @override
  State<ActivePlatformsView> createState() => _ActivePlatformsViewState();
}

class _ActivePlatformsViewState extends State<ActivePlatformsView> {
  void _showAddPlatformDialog(BuildContext context, {AtsPlatform? existingPlatform}) {
    final nameCtrl = TextEditingController(text: existingPlatform?.name ?? '');
    final domainCtrl = TextEditingController(text: existingPlatform?.domain ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingPlatform == null ? 'Add ATS Platform' : 'Edit ATS Platform'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Platform Name (e.g. Greenhouse)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: domainCtrl,
                decoration: const InputDecoration(labelText: 'Domain (e.g. boards.greenhouse.io)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final service = context.read<FirebaseService>();
                final plat = AtsPlatform(
                  id: existingPlatform?.id ?? '',
                  userId: service.user?.uid ?? '',
                  name: nameCtrl.text.trim(),
                  domain: domainCtrl.text.trim(),
                  isEnabled: existingPlatform?.isEnabled ?? true,
                );
                await service.saveAtsPlatform(plat);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FirebaseService>();
    final platforms = service.atsPlatforms;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Platforms'),
        backgroundColor: AppColors.surface,
      ),
      body: platforms.isEmpty
          ? const Center(child: Text('No platforms found.'))
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: platforms.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final plat = platforms[index];
                return Card(
                  elevation: 0,
                  color: AppColors.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    title: Text(plat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(plat.domain, style: const TextStyle(color: AppColors.outline)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: plat.isEnabled,
                          onChanged: (val) {
                            service.toggleAtsPlatform(plat.id, val);
                          },
                          activeTrackColor: AppColors.secondary,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.outline),
                          onPressed: () => _showAddPlatformDialog(context, existingPlatform: plat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => service.deleteAtsPlatform(plat.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPlatformDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Platform'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
      ),
    );
  }
}
