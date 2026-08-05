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
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))
        ),
        child: ConfigModal(
          job: job,
          onRun: job != null ? () {
            Navigator.pop(ctx);
            _runAgent(context, job);
          } : null,
        ),
      ),
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
                        onDelete: () => context.read<FirebaseService>().deleteJob(job.id),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showConfigModal(context),
                icon: const Icon(Icons.add_task, color: AppColors.onSecondary),
                label: const Text('Schedule New Job', style: TextStyle(color: AppColors.onSecondary, fontSize: 16, fontWeight: FontWeight.w500)),
                style: FilledButton.styleFrom(
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
  final VoidCallback onDelete;

  const JobCard({super.key, required this.job, required this.onEdit, required this.onRun, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none), // removes inner borders when expanded
        title: Row(
          children: [
            Expanded(
              child: Text(
                job.jobLabel,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_circle_fill, color: AppColors.secondary),
                  onPressed: onRun,
                  tooltip: 'Run Job Now',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.outline),
                  onPressed: onEdit,
                  tooltip: 'Edit Job',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: onDelete,
                  tooltip: 'Delete Job',
                ),
              ],
            ),
          ],
        ),
        leading: const Icon(Icons.tune, color: AppColors.outline),
        childrenPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0x33C2C6D4)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildParamRow('TARGET JOB TITLES', job.jobTitles.join(', '))),
              const SizedBox(width: 16),
              Expanded(child: _buildParamRow('LOCATIONS', job.locations.join(', '))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildParamRow('SCRAPE FREQUENCY', job.scrapeFrequency)),
              const SizedBox(width: 16),
              Expanded(child: _buildParamRow('TIMEFRAME', job.timeframe)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'TARGET ATS PLATFORMS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondaryContainer.withValues(alpha: 0.5)),
                ),
                child: Text(
                  ats,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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
            fontWeight: FontWeight.w600,
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