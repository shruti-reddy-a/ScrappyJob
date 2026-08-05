import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../constants/app_colors.dart';

class AgentTab extends StatefulWidget {
  final void Function(String jobRunId)? onViewLog;

  const AgentTab({super.key, this.onViewLog});

  @override
  State<AgentTab> createState() => _AgentTabState();
}

class _AgentTabState extends State<AgentTab> {
  Timer? _timer;
  Duration _executionTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final service = context.read<FirebaseService>();
      final progress = service.activeProgress;
      if (progress != null && progress.startTime != null) {
        if (progress.status == 'RUNNING') {
          setState(() {
            _executionTime = DateTime.now().difference(progress.startTime!);
          });
        } else if (progress.updatedAt != null) {
          setState(() {
            _executionTime = progress.updatedAt!.difference(progress.startTime!);
          });
        }
      } else {
        setState(() {
          _executionTime = Duration.zero;
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

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
                      'No active job running.\nTrigger a job from the Config tab.',
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
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildProgressRow('Current Target', progress.currentAts.isEmpty ? 'Initializing...' : progress.currentAts, Icons.radar)),
                            Expanded(child: _buildProgressRow('Execution Time', _formatDuration(_executionTime), Icons.timer)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildProgressRow('Jobs Found', progress.jobsFoundSoFar.toString(), Icons.work_outline)),
                            Expanded(child: _buildProgressRow('ATS Completed', '${progress.atsCompleted} / ${progress.totalAts}', Icons.checklist)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (progress.jobsPerAts.isNotEmpty) ...[
                          const Text('JOBS PER ATS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant, letterSpacing: 0.5)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: progress.jobsPerAts.entries.map((e) {
                              return Chip(
                                label: Text('${e.key}: ${e.value}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                backgroundColor: AppColors.surface,
                                side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                              );
                            }).toList(),
                          ),
                        ],
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
                          const Center(child: Text('Stopping agent gracefully...', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)))
                        else if (progress.status == 'COMPLETED' && progress.jobRunId != null && widget.onViewLog != null)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => widget.onViewLog!(progress.jobRunId!),
                              icon: const Icon(Icons.receipt_long, color: Colors.white),
                              label: const Text('View Log', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                              ),
                            ),
                          ),
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.onSurface), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}