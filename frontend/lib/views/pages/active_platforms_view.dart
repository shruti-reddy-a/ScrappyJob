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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage ATS Platforms', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Platforms',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Enable or disable platforms to control where the AI scraper searches for jobs.',
                            style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: () => _showAddPlatformDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Custom Platform'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: platforms.isEmpty
                    ? const Center(
                        child: Text('No platforms found. Add one to get started!',
                            style: TextStyle(color: AppColors.outline, fontSize: 16)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        itemCount: platforms.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final plat = platforms[index];
                          final isEnabled = plat.isEnabled;
                          final initial = plat.name.isNotEmpty ? plat.name[0].toUpperCase() : '?';

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: isEnabled ? AppColors.surfaceContainerLowest : AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isEnabled ? AppColors.primary.withValues(alpha: 0.2) : AppColors.outlineVariant.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                              boxShadow: isEnabled
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => service.toggleAtsPlatform(plat.id, !isEnabled),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isEnabled ? AppColors.secondaryContainer : AppColors.outlineVariant,
                                        foregroundColor: isEnabled ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                                        radius: 24,
                                        child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              plat.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: isEnabled ? AppColors.onSurface : AppColors.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              plat.domain,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isEnabled ? AppColors.onSurfaceVariant : AppColors.outline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isEnabled ? AppColors.secondaryContainer.withValues(alpha: 0.5) : AppColors.surfaceContainerHigh,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          isEnabled ? 'Active' : 'Disabled',
                                          style: TextStyle(
                                            color: isEnabled ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Switch(
                                        value: isEnabled,
                                        onChanged: (val) {
                                          service.toggleAtsPlatform(plat.id, val);
                                        },
                                        activeThumbColor: AppColors.onPrimary,
                                        activeTrackColor: AppColors.primary,
                                        inactiveThumbColor: AppColors.outline,
                                        inactiveTrackColor: AppColors.surfaceContainerHigh,
                                      ),
                                      const SizedBox(width: 12),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: AppColors.outline),
                                        tooltip: 'Platform Options',
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _showAddPlatformDialog(context, existingPlatform: plat);
                                          } else if (value == 'delete') {
                                            service.deleteAtsPlatform(plat.id);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 20, color: AppColors.onSurfaceVariant),
                                                SizedBox(width: 12),
                                                Text('Edit Platform'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, size: 20, color: Colors.redAccent),
                                                SizedBox(width: 12),
                                                Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
