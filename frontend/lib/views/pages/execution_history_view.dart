import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ExecutionHistoryView extends StatelessWidget {
  const ExecutionHistoryView({super.key});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FirebaseService>();
    final jobRuns = service.jobRuns;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Execution History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
      ),
      body: jobRuns.isEmpty
          ? Center(
              child: Text(
                'No execution history.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24.0),
              itemCount: jobRuns.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final run = jobRuns[index];
                final dateStr = run.createdAt != null 
                    ? DateFormat.yMMMMEEEEd().add_jm().format(run.createdAt!) 
                    : 'Unknown Date';
                
                final isSuccess = run.status == 'SUCCESS';
                final isRunning = run.status == 'IN_PROGRESS';
                final isCancelled = run.status == 'CANCELLED';

                Color statusColor;
                if (isSuccess) {
                  statusColor = Colors.green.shade700;
                } else if (isRunning) statusColor = Colors.blue.shade700;
                else if (isCancelled) statusColor = Colors.orange.shade700;
                else statusColor = Colors.red.shade700;

                return Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.all(20.0),
                      childrenPadding: const EdgeInsets.only(bottom: 20.0),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(isSuccess ? Icons.check_circle : (isRunning ? Icons.play_circle : Icons.error), color: statusColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  run.jobTitles.join(', '),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  run.status,
                                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.event, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Text(dateStr, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.find_in_page, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Text('Found ${run.totalFound} jobs', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                      children: [
                        if (run.jobs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("No detailed jobs saved for this run."),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Company', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Time Posted', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Apply Link', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Applied', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: List.generate(run.jobs.length, (jobIndex) {
                                  final job = run.jobs[jobIndex];
                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                                      if (job.isApplied) return Colors.green.withValues(alpha: 0.1);
                                      return null;
                                    }),
                                    cells: [
                                      DataCell(Text('${jobIndex + 1}')),
                                      DataCell(SizedBox(width: 200, child: Text(job.jobTitle))),
                                      DataCell(Text(job.company)),
                                      DataCell(Text(job.location)),
                                      DataCell(Text(job.postingTime)),
                                      DataCell(
                                        job.applicationLink.startsWith('http') 
                                        ? TextButton.icon(
                                            onPressed: () => _launchURL(job.applicationLink),
                                            icon: const Icon(Icons.open_in_new, size: 16),
                                            label: const Text('Apply'),
                                          )
                                        : const Text('N/A')
                                      ),
                                      DataCell(
                                        Switch(
                                          value: job.isApplied,
                                          activeThumbColor: Colors.green,
                                          onChanged: (val) {
                                            service.toggleJobApplied(run.id, run.jobs, jobIndex, val);
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
