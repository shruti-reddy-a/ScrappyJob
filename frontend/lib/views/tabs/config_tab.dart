import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';
import '../../models/job_config.dart';
import '../../constants/app_colors.dart';
import '../widgets/config_modal.dart';

class ConfigTab extends StatelessWidget {
  final VoidCallback onRunStarted;
  const ConfigTab({super.key, required this.onRunStarted});

  void _showConfigModal(BuildContext context, {JobConfig? job}) {
    showDialog(
      context: context,
      builder: (ctx) => ConfigModal(
        job: job,
        onRun: job != null ? () {
          Navigator.pop(ctx);
          _runAgent(context, job);
        } : null,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Searches',
                      style: GoogleFonts.lora(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Automated scrapers that hunt for roles on a schedule.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showConfigModal(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New search', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF165C53),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          if (jobs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: Text(
                  "No jobs scheduled yet.",
                  style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return SearchJobCard(
                  job: job,
                  service: service,
                  onEdit: () => _showConfigModal(context, job: job),
                  onRun: () => _runAgent(context, job),
                  onDelete: () => context.read<FirebaseService>().deleteJob(job.id),
                );
              },
            ),
        ],
      ),
    );
  }
}

class SearchJobCard extends StatefulWidget {
  final JobConfig job;
  final FirebaseService service;
  final VoidCallback onEdit;
  final VoidCallback onRun;
  final VoidCallback onDelete;

  const SearchJobCard({
    super.key, 
    required this.job, 
    required this.service,
    required this.onEdit, 
    required this.onRun, 
    required this.onDelete
  });

  @override
  State<SearchJobCard> createState() => _SearchJobCardState();
}

class _SearchJobCardState extends State<SearchJobCard> {
  bool _isExpanded = false;

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Unknown time';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final runs = widget.service.jobRuns.where((r) => r.configId == widget.job.id).toList();
    // Also check if this specific job is currently running
    final isCurrentlyRunning = widget.service.activeProgress != null && 
                               widget.service.activeProgress!.status == 'RUNNING' &&
                               widget.service.activeProgress!.id == widget.job.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          // Header Row
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: _isExpanded 
                ? const BorderRadius.vertical(top: Radius.circular(16)) 
                : BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                    color: AppColors.outline,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.job.jobLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrentlyRunning) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F6F4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF00C896),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Running',
                                      style: TextStyle(
                                        color: Color(0xFF165C53),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.job.locations.join(', ')} · ${widget.job.targetAts.length} platforms · ${widget.job.scrapeFrequency}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow_outlined, color: Color(0xFF00C896)),
                        onPressed: widget.onRun,
                        tooltip: 'Run Job Now',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.outline),
                        onPressed: widget.onEdit,
                        tooltip: 'Edit Job',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: widget.onDelete,
                        tooltip: 'Delete Job',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded Content
          if (_isExpanded) ...[
            Container(
              color: const Color(0xFFF9FAFA), // slightly grey background for history
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: AppColors.borderColor),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Text(
                      'RUN HISTORY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (runs.isEmpty && !isCurrentlyRunning)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Text('No runs yet.', style: TextStyle(color: AppColors.outline)),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DataTable(
                        headingTextStyle: const TextStyle(
                          color: AppColors.outline,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        dataTextStyle: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        dividerThickness: 1,
                        columnSpacing: 24,
                        horizontalMargin: 12,
                        columns: const [
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('DATE')),
                          DataColumn(label: Text('JOBS FOUND'), numeric: true),
                          DataColumn(label: Text('TIME TAKEN'), numeric: true),
                        ],
                        rows: [
                          if (isCurrentlyRunning)
                            DataRow(
                              cells: [
                                DataCell(_buildStatusBadge('Running', const Color(0xFF165C53), const Color(0xFFE8F6F4), hasDot: true, dotColor: const Color(0xFF00C896))),
                                const DataCell(Text('Just now')),
                                const DataCell(Text('running...', style: TextStyle(fontFamily: 'monospace'))),
                                const DataCell(Text('—')),
                              ],
                            ),
                          ...runs.map((r) {
                            return DataRow(
                              cells: [
                                DataCell(_buildStatusBadge('Success', const Color(0xFF007954), const Color(0xFFE6F6ED))),
                                DataCell(Text(_formatTime(r.createdAt))),
                                DataCell(Text(r.totalFound.toString(), style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600))),
                                DataCell(Text(r.executionTimeMs > 0 ? '${(r.executionTimeMs / 1000).toStringAsFixed(1)}s' : '—')),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color, Color bgColor, {bool hasDot = false, Color? dotColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor ?? color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}