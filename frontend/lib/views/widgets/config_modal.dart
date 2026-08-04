import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../models/job_config.dart';
import '../../constants/app_colors.dart';

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