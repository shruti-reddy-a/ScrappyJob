import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/scraping_config.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _jobTitlesCtrl;
  late TextEditingController _locationsCtrl;
  late TextEditingController _cronCtrl;
  late TextEditingController _emailCtrl;
  
  int _selectedHours = 24;
  List<String> _selectedAts = [];
  bool _isActive = true;

  final List<String> _availableAts = [
    "Greenhouse", "Ashby", "Workday", "iCIMS", "Lever", 
    "BambooHR", "Workable", "LinkedIn", "Indeed"
  ];
  
  final List<int> _timeframes = [12, 24, 48, 168]; // 168 = 7 days

  @override
  void initState() {
    super.initState();
    _jobTitlesCtrl = TextEditingController();
    _locationsCtrl = TextEditingController();
    _cronCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    
    // Initialize form with current config
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfig();
    });
  }

  void _loadConfig() {
    final config = context.read<FirebaseService>().currentConfig;
    if (config != null) {
      setState(() {
        _jobTitlesCtrl.text = config.jobTitles.join(', ');
        _locationsCtrl.text = config.locations.join(', ');
        _cronCtrl.text = config.cronSchedule;
        _emailCtrl.text = config.targetEmail;
        _selectedHours = config.hoursSincePosted;
        _selectedAts = List.from(config.targetAts);
        _isActive = config.isActive;
      });
    }
  }

  @override
  void dispose() {
    _jobTitlesCtrl.dispose();
    _locationsCtrl.dispose();
    _cronCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      final service = context.read<FirebaseService>();
      final currentUser = service.user;
      if (currentUser == null) return;
      
      final updatedConfig = ScrapingConfig(
        userId: currentUser.uid,
        jobTitles: _jobTitlesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        locations: _locationsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        cronSchedule: _cronCtrl.text.trim(),
        targetEmail: _emailCtrl.text.trim(),
        hoursSincePosted: _selectedHours,
        targetAts: _selectedAts,
        isActive: _isActive,
      );
      
      await service.saveConfig(updatedConfig);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration saved successfully!')),
        );
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch \$urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FirebaseService>();
    final isLoading = service.isLoading;
    final runs = service.jobRuns;

    if (isLoading && _jobTitlesCtrl.text.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Scraper Control Center', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF002060),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isActive ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _isActive ? Colors.green : Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(_isActive ? Icons.check_circle : Icons.warning, 
                       color: _isActive ? Colors.green : Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isActive 
                        ? 'Cron Job is ACTIVE. Scraping scheduled at: \${_cronCtrl.text}'
                        : 'Cron Job is PAUSED.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (val) {
                      setState(() => _isActive = val);
                    },
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Configuration Form
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Configuration Parameters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Divider(),
                      TextFormField(
                        controller: _jobTitlesCtrl,
                        decoration: const InputDecoration(labelText: 'Target Job Titles (comma-separated)', hintText: 'e.g., Product Manager, AI Product Manager'),
                        validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationsCtrl,
                        decoration: const InputDecoration(labelText: 'Target Locations (comma-separated)', hintText: 'e.g., San Francisco Bay Area, Remote'),
                        validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cronCtrl,
                              decoration: const InputDecoration(labelText: 'CRON Schedule', hintText: '0 7 * * *'),
                              validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(labelText: 'Target Email for Reports'),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Timeframe Limit', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<int>(
                        value: _selectedHours,
                        isExpanded: true,
                        items: _timeframes.map((hours) {
                          String label = hours == 168 ? '7 days' : '\$hours hours';
                          return DropdownMenuItem(value: hours, child: Text('Posted within last \$label'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedHours = val);
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text('Target ATS Platforms', style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 8.0,
                        children: _availableAts.map((ats) {
                          return FilterChip(
                            label: Text(ats),
                            selected: _selectedAts.contains(ats),
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
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _saveConfig,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF002060),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save Parameters', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Execution Logs
            const Text('Execution Log History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              elevation: 4,
              child: runs.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text("No runs recorded yet.")),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
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
                              ? DateFormat('yyyy-MM-dd HH:mm').format(run.createdAt!) 
                              : run.runDate)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: run.status == 'SUCCESS' ? Colors.green.shade100 : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(run.status, style: TextStyle(
                                  color: run.status == 'SUCCESS' ? Colors.green.shade800 : Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12
                                )),
                              )
                            ),
                            DataCell(Text(run.totalFound.toString())),
                            DataCell(Text(run.executionTimeMs.toString())),
                            DataCell(
                              run.excelFileUrl.isNotEmpty
                                ? TextButton.icon(
                                    icon: const Icon(Icons.table_chart),
                                    label: const Text('View Sheet'),
                                    onPressed: () => _launchUrl(run.excelFileUrl),
                                  )
                                : const Text('N/A')
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
