import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firebase_service.dart';
import '../../models/job_config.dart';
import '../../constants/app_colors.dart';

class LogsTab extends StatelessWidget {
  const LogsTab({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  void _showLogsModal(BuildContext context, JobRun run) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2F3133),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Agent Execution Logs',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: run.logs.isEmpty
                          ? const Center(child: Text("No detailed logs found for this run.", style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: run.logs.length,
                              itemBuilder: (context, index) {
                                final log = run.logs[index];
                                final timeStr = log['timestamp']?.toString().split('T').last.split('.').first ?? '';
                                final msg = log['message'] ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    '[$timeStr] $msg',
                                    style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 12),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final runs = context.watch<FirebaseService>().jobRuns;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Execution Logs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
          const SizedBox(height: 24),
          Expanded(
            child: runs.isEmpty
                ? const Center(child: Text("No runs recorded yet.", style: TextStyle(color: AppColors.onSurfaceVariant)))
                : Card(
                    elevation: 0,
                    color: AppColors.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
                              columns: const [
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Total Found')),
                                DataColumn(label: Text('Execution Time (ms)')),
                                DataColumn(label: Text('Action')),
                              ],
                              rows: runs.map((run) {
                                return DataRow(cells: [
                                  DataCell(Text(run.createdAt != null
                                      ? DateFormat('MMM dd, yyyy HH:mm').format(run.createdAt!)
                                      : run.runDate)),
                                  DataCell(Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: run.status == 'SUCCESS' ? Colors.green.shade50 : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(run.status,
                                        style: TextStyle(
                                            color: run.status == 'SUCCESS' ? Colors.green.shade800 : Colors.orange.shade800,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                  )),
                                  DataCell(Text(run.totalFound.toString())),
                                  DataCell(Text(run.executionTimeMs.toString())),
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.terminal, size: 20, color: AppColors.onSurfaceVariant),
                                        tooltip: 'View Logs',
                                        onPressed: () => _showLogsModal(context, run),
                                      ),
                                      if (run.excelFileUrl.isNotEmpty)
                                        TextButton.icon(
                                          icon: const Icon(Icons.table_chart, size: 16, color: AppColors.secondary),
                                          label: const Text('Sheet', style: TextStyle(color: AppColors.secondary)),
                                          onPressed: () => _launchUrl(context, run.excelFileUrl),
                                        )
                                    ],
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        );
                      }
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}