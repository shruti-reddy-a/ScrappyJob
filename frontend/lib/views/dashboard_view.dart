import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../services/firebase_service.dart';
import '../models/job_config.dart';

class AppColors {
  static const background = Color(0xFFF9F9FC);
  static const onBackground = Color(0xFF1A1C1E);
  static const surfaceContainerHigh = Color(0xFFE8E8EA);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF1A1C1E);
  static const onSurfaceVariant = Color(0xFF424752);
  static const outline = Color(0xFF727784);
  static const outlineVariant = Color(0xFFC2C6D4);
  static const secondary = Color(0xFF006B5F);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF8DF5E4);
  static const onSecondaryContainer = Color(0xFF007165);
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0;

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Text(
        '$title (Coming Soon)',
        style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'ScrappyJob',
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 24,
            letterSpacing: 0,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const DashboardTab(),
          ConfigTab(onRunStarted: () => setState(() => _currentIndex = 2)),
          const AgentTab(),
          const LogsTab(),
          const SettingsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: AppColors.onSurface,
          unselectedItemColor: AppColors.onSurfaceVariant,
          backgroundColor: AppColors.surfaceContainerLowest,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          items: [
            _buildNavItem(Icons.dashboard, 'Dashboard', 0),
            _buildNavItem(Icons.tune, 'Config', 1),
            _buildNavItem(Icons.smart_toy, 'Agent', 2),
            _buildNavItem(Icons.list_alt, 'Logs', 3),
            _buildNavItem(Icons.settings, 'Settings', 4),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
        ),
      ),
      label: label,
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FirebaseService>();
    final activeJobsCount = service.jobs.where((j) => j.isActive).length;
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
              Expanded(child: _buildMetricCard('Active Jobs', activeJobsCount.toString(), Icons.tune)),
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

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
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
  }
}

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

class ConfigModal extends StatefulWidget {
  final JobConfig? job;
  const ConfigModal({super.key, this.job});

  @override
  State<ConfigModal> createState() => _ConfigModalState();
}

class _ConfigModalState extends State<ConfigModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _jobTitlesCtrl;
  late TextEditingController _locationsCtrl;
  late TextEditingController _emailCtrl;
  
  String _selectedFrequency = 'Every 4 Hours';
  String _selectedTimeframe = 'Past 24 Hours';
  List<String> _selectedAts = [];

  final List<String> _availableAts = ["Greenhouse", "Ashby", "Workday", "iCIMS", "Lever", "BambooHR", "Workable", "LinkedIn", "Indeed"];
  final List<String> _frequencyOptions = ['Now', 'Every 4 Hours', 'Every 6 Hours', 'Every 12 Hours', 'Daily'];
  final List<String> _timeframeOptions = ['Past 12 Hours', 'Past 24 Hours', 'Past 48 Hours', 'Past 7 Days'];

  @override
  void initState() {
    super.initState();
    _jobTitlesCtrl = TextEditingController(text: widget.job?.jobTitles.join(', ') ?? 'Product manager, senior product manager');
    _locationsCtrl = TextEditingController(text: widget.job?.locations.join(', ') ?? 'SF Bay area, CA, USA');
    _emailCtrl = TextEditingController(text: widget.job?.targetEmail ?? '');
    if (widget.job != null) {
      _selectedFrequency = widget.job!.scrapeFrequency;
      _selectedTimeframe = widget.job!.timeframe;
      _selectedAts = List.from(widget.job!.targetAts);
    } else {
      _selectedAts = ["Greenhouse", "Lever", "Workday"];
    }
  }

  @override
  void dispose() {
    _jobTitlesCtrl.dispose();
    _locationsCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final service = context.read<FirebaseService>();
      if (service.user == null) return;
      
      final updatedJob = JobConfig(
        id: widget.job?.id ?? '',
        userId: service.user!.uid,
        jobTitles: _jobTitlesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        locations: _locationsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        targetAts: _selectedAts,
        scrapeFrequency: _selectedFrequency,
        timeframe: _selectedTimeframe,
        targetEmail: _emailCtrl.text.trim(),
        isActive: true,
      );
      
      await service.saveJob(updatedJob);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job saved successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset, left: 24, right: 24, top: 32),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.job == null ? 'Schedule New Job' : 'Edit Job Config',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.onSurface)
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _jobTitlesCtrl,
                decoration: InputDecoration(
                  labelText: 'Target Job Titles (comma-separated)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.secondary)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationsCtrl,
                decoration: InputDecoration(
                  labelText: 'Target Locations (comma-separated)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.secondary)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Scraping Frequency',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.secondary)),
                      ),
                      initialValue: _selectedFrequency,
                      items: _frequencyOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFrequency = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Timeframe Limit',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.secondary)),
                      ),
                      initialValue: _selectedTimeframe,
                      items: _timeframeOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTimeframe = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Target Email for Reports (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.secondary)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              const Text('Target ATS Platforms', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.onSurface)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _availableAts.map((ats) {
                  final isSelected = _selectedAts.contains(ats);
                  return FilterChip(
                    label: Text(ats),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: AppColors.secondaryContainer,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? AppColors.secondaryContainer.withValues(alpha: 0.5) : AppColors.outlineVariant.withValues(alpha: 0.3),
                      )
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAts.add(ats);
                        } else {
                          _selectedAts.remove(ats);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  if (widget.job != null) ...[
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          await context.read<FirebaseService>().deleteJob(widget.job!.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                        child: const Text('Delete Job', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.onSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        elevation: 1,
                      ),
                      child: const Text('Save Parameters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

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
          const Text('Execution Log History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
                          columns: const [
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Total Found')),
                            DataColumn(label: Text('Exec Time (ms)')),
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
                                  else
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Text('N/A', style: TextStyle(color: AppColors.outline)),
                                    ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<FirebaseService>().user;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.person, color: AppColors.outline),
              title: const Text('User ID', style: TextStyle(color: AppColors.onSurface)),
              subtitle: Text(user?.uid ?? 'Not signed in', style: const TextStyle(color: AppColors.onSurfaceVariant)),
            ),
          )
        ],
      ),
    );
  }
}
