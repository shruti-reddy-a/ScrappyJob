import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../constants/app_colors.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FirebaseService>();
    final activeJobs = service.jobs.where((j) => j.isActive).toList();
    final activeJobsCount = activeJobs.length;
    final totalScraped = service.jobRuns.fold<int>(0, (sum, run) => sum + run.totalFound);
    final totalRuns = service.jobRuns.length;
    final successRuns = service.jobRuns.where((r) => r.status == 'SUCCESS').length;
    final successRate = totalRuns == 0 ? 0 : (successRuns / totalRuns * 100).round();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Active Jobs', 
                  activeJobsCount.toString(), 
                  Icons.tune,
                  onTap: () => _showActiveJobsDialog(context, activeJobs),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('Total Scraped', totalScraped.toString(), Icons.find_in_page)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Runs', totalRuns.toString(), Icons.history)),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('Success Rate', '$successRate%', Icons.check_circle_outline)),
            ],
          ),
        ],
      ),
    );
  }

  void _showActiveJobsDialog(BuildContext context, List<dynamic> activeJobs) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          title: const Text('Active Jobs', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: activeJobs.isEmpty
                ? const Text('No active jobs.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: activeJobs.length,
                    itemBuilder: (context, index) {
                      final job = activeJobs[index];
                      return ListTile(
                        leading: const Icon(Icons.work, color: AppColors.primary),
                        title: Text(job.jobTitles.join(', ')),
                        subtitle: Text('Frequency: ${job.scrapeFrequency}\nLocations: ${job.locations.join(', ')}'),
                        isThreeLine: true,
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, {VoidCallback? onTap}) {
    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant, letterSpacing: 0.5),
              ),
              if (onTap != null) ...[
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.onSurfaceVariant),
              ]
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.onSurface),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      );
    }
    return card;
  }
}
