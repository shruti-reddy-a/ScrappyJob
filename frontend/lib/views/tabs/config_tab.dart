import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../services/firebase_service.dart';
import '../../models/job_config.dart';
import '../../constants/app_colors.dart';
import '../widgets/config_modal.dart';

class ConfigTab extends StatelessWidget {
  final VoidCallback onRunStarted;
  const ConfigTab({super.key, required this.onRunStarted});

  void _showConfigModal(BuildContext context, {JobConfig? job}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => ConfigModal(job: job),
    );
  }

  Future<void> _runAgent(BuildContext context, JobConfig job) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Triggering Job: ${job.jobTitles.join(', ')}...'))
      );
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/run'),
        headers: {'Content-Type': 'application/json'},
        body: '{"job_id": "${job.id}"}'
      );
      if (context.mounted) {
        if (response.statusCode == 200) {
          context.read<FirebaseService>().setActiveJobId(job.id);
          onRunStarted();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start agent: ${response.statusCode}'))
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Could not connect to the backend. Make sure you run `python server.py` first!'),
            backgroundColor: AppColors.secondary,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FirebaseService>();
    final jobs = service.jobs;

    // "Give the form by default." -> If no jobs, we can still show the Schedule button,
    // and if we want it to open by default, we could do it in a PostFrameCallback.
    // For now, the empty state will just display the schedule button prominently.

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Expanded(
            child: jobs.isEmpty
                ? const Center(
                    child: Text(
                      "No jobs scheduled yet.",
                      style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 16, bottom: 24),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return JobCard(
                        job: job,
                        onEdit: () => _showConfigModal(context, job: job),
                        onRun: () => _runAgent(context, job),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showConfigModal(context),
                icon: const Icon(Icons.add_task, color: AppColors.onSecondary),
                label: const Text('Schedule New Job', style: TextStyle(color: AppColors.onSecondary, fontSize: 16, fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  elevation: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final JobConfig job;
  final VoidCallback onEdit;
  final VoidCallback onRun;

  const JobCard({super.key, required this.job, required this.onEdit, required this.onRun});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune, color: AppColors.outline, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Configuration Parameters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill, color: AppColors.secondary, size: 28),
                      onPressed: onRun,
                      tooltip: 'Run Job Now',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1, color: Color(0x33C2C6D4)), // outlineVariant with 0.2 opacity
            ),
            _buildParamRow('TARGET JOB TITLES', job.jobTitles.join(', ')),
            const SizedBox(height: 24),
            _buildParamRow('LOCATIONS', job.locations.join(', ')),
            const SizedBox(height: 24),
            _buildParamRow('SCRAPE FREQUENCY', job.scrapeFrequency),
            const SizedBox(height: 24),
            _buildParamRow('TIMEFRAME', job.timeframe),
            const SizedBox(height: 24),
            const Text(
              'TARGET ATS PLATFORMS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: job.targetAts.map((ats) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.secondaryContainer.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    ats,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: AppColors.onSecondaryContainer,
                      letterSpacing: 0.05,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParamRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.onSurface,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}