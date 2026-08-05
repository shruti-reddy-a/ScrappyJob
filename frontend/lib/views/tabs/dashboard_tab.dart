import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../pages/active_configurations_view.dart';
import '../pages/execution_history_view.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FirebaseService>();
    final activeJobs = service.jobs.where((j) => j.isActive).toList();
    final activeJobsCount = activeJobs.length;
    final totalScraped = service.jobRuns.fold<int>(0, (sum, run) => sum + run.totalFound);
    final totalRuns = service.jobRuns.length;
    
    // We can just define the number of platforms statically for now based on settings.py
    const totalPlatforms = 7; 

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Overview', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Active Configurations', 
                  activeJobsCount.toString(), 
                  Icons.tune,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveConfigurationsView())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Jobs Discovered', 
                  totalScraped.toString(), 
                  Icons.find_in_page,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExecutionHistoryView())),
                )
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Execution History', 
                  totalRuns.toString(), 
                  Icons.history,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExecutionHistoryView())),
                )
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Active Platforms', 
                  totalPlatforms.toString(), 
                  Icons.language
                )
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, {VoidCallback? onTap}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        highlightColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600, 
                        color: Theme.of(context).colorScheme.onSurfaceVariant, 
                        letterSpacing: 0.5
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ]
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).colorScheme.onSurface
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
