import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../constants/app_colors.dart';

class AgentTab extends StatelessWidget {
  const AgentTab({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FirebaseService>();
    final progress = service.activeProgress;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Agent Progress', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
          const SizedBox(height: 24),
          Expanded(
            child: progress == null
                ? const Center(
                    child: Text(
                      'No active job running.\\nTrigger a job from the Config tab.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: progress.status == 'RUNNING' ? Colors.blue.shade50 : (progress.status == 'COMPLETED' ? Colors.green.shade50 : Colors.red.shade50),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                progress.status,
                                style: TextStyle(
                                  color: progress.status == 'RUNNING' ? Colors.blue.shade800 : (progress.status == 'COMPLETED' ? Colors.green.shade800 : Colors.red.shade800),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (progress.status == 'RUNNING')
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                              ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildProgressRow('Current Target', progress.currentAts.isEmpty ? 'Initializing...' : progress.currentAts, Icons.radar),
                        const SizedBox(height: 24),
                        _buildProgressRow('Jobs Found', progress.jobsFoundSoFar.toString(), Icons.work_outline),
                        const SizedBox(height: 24),
                        _buildProgressRow('ATS Completed', '${progress.atsCompleted} / ${progress.totalAts}', Icons.checklist),
                        const Spacer(),
                        if (progress.status == 'RUNNING' && progress.command != 'STOP')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => service.stopAgentRun(progress.id),
                              icon: const Icon(Icons.stop_circle, color: Colors.white),
                              label: const Text('Stop Agent Run', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                              ),
                            ),
                          )
                        else if (progress.command == 'STOP' && progress.status == 'RUNNING')
                          const Center(child: Text('Stopping agent gracefully...', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.outline, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.onSurface)),
          ],
        ),
      ],
    );
  }
}