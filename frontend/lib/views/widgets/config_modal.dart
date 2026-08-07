import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';
import '../../models/job_config.dart';
import '../../constants/app_colors.dart';

class ConfigModal extends StatefulWidget {
  final JobConfig? job;
  final VoidCallback? onRun;
  const ConfigModal({super.key, this.job, this.onRun});

  @override
  State<ConfigModal> createState() => _ConfigModalState();
}

class _ConfigModalState extends State<ConfigModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _jobLabelCtrl;
  late TextEditingController _jobTitlesCtrl;
  late TextEditingController _locationsCtrl;
  late TextEditingController _targetUrlsCtrl;
  late TextEditingController _emailCtrl;
  
  String _selectedFrequency = 'Every 4 hours';
  String _selectedTimeframe = 'Past 24 hours';
  List<String> _selectedAts = [];

  final List<String> _frequencyOptions = ['Now', 'Every 4 hours', 'Every 6 hours', 'Every 12 hours', 'Daily'];
  final List<String> _timeframeOptions = ['Past 12 hours', 'Past 24 hours', 'Past 48 hours', 'Past 7 days'];

  @override
  void initState() {
    super.initState();
    _jobLabelCtrl = TextEditingController(text: widget.job?.jobLabel == 'My Scraper Job' ? '' : (widget.job?.jobLabel ?? ''));
    _jobTitlesCtrl = TextEditingController(
      text: widget.job?.jobTitles.join(', ') == 'Product Manager, AI Product Manager, Senior Product Manager' 
          ? '' 
          : (widget.job?.jobTitles.join(', ') ?? '')
    );
    _locationsCtrl = TextEditingController(
      text: widget.job?.locations.join(', ') == 'San Francisco Bay Area, California, USA' 
          ? '' 
          : (widget.job?.locations.join(', ') ?? '')
    );
    _targetUrlsCtrl = TextEditingController(text: widget.job?.targetUrls.join(', ') ?? '');
    _emailCtrl = TextEditingController(text: widget.job?.targetEmail ?? '');
    
    if (widget.job != null) {
      _selectedFrequency = widget.job!.scrapeFrequency;
      _selectedTimeframe = widget.job!.timeframe;
      _selectedAts = List.from(widget.job!.targetAts);
    } else {
      // Select all by default for a new search
      // The available ATS list will be fetched in build, but we can set a dummy here
      // and update it in didChangeDependencies if needed. We'll just leave it empty
      // and populate it in build if it's a new job and _selectedAts is empty.
    }
  }

  bool _initializedAts = false;

  @override
  void dispose() {
    _jobLabelCtrl.dispose();
    _jobTitlesCtrl.dispose();
    _locationsCtrl.dispose();
    _targetUrlsCtrl.dispose();
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
        jobLabel: _jobLabelCtrl.text.trim(),
        jobTitles: _jobTitlesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        locations: _locationsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        targetUrls: _targetUrlsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.outline),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        fillColor: Colors.white,
        filled: true,
      ),
      validator: isOptional ? null : (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final service = context.watch<FirebaseService>();
    final availableAts = service.activeAtsPlatforms.map((p) => p.name).toList();
    
    if (widget.job == null && !_initializedAts && availableAts.isNotEmpty) {
      _selectedAts = List.from(availableAts);
      _initializedAts = true;
    }

    for (var ats in _selectedAts) {
      if (!availableAts.contains(ats)) {
        availableAts.add(ats);
      }
    }
    
    // Sort ATS alphabetically
    availableAts.sort();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.job == null ? 'New search' : 'Edit search',
                  style: GoogleFonts.lora(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.outline),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 24,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderColor),
          
          // Scrollable Form Body
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomInset + 24, left: 24, right: 24, top: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('SEARCH NAME'),
                    _buildTextField(
                      controller: _jobLabelCtrl,
                      hint: 'e.g. SF Product Managers',
                    ),
                    const SizedBox(height: 24),
                    
                    _buildLabel('JOB TITLES'),
                    _buildTextField(
                      controller: _jobTitlesCtrl,
                      hint: 'Product manager, Senior product manager',
                    ),
                    const SizedBox(height: 24),
                    
                    _buildLabel('LOCATIONS'),
                    _buildTextField(
                      controller: _locationsCtrl,
                      hint: 'SF Bay area, CA, USA',
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('RUNS'),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.outline),
                                initialValue: _selectedFrequency,
                                items: _frequencyOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedFrequency = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('LOOKS BACK'),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.outline),
                                initialValue: _selectedTimeframe,
                                items: _timeframeOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedTimeframe = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        const Icon(Icons.mail_outline, size: 16, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 6),
                        _buildLabel('EMAIL RESULTS TO (OPTIONAL)'),
                      ],
                    ),
                    _buildTextField(
                      controller: _emailCtrl,
                      hint: 'you@email.com',
                      isOptional: true,
                    ),
                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('PLATFORMS TO SEARCH'),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedAts = List.from(availableAts);
                                });
                              },
                              child: const Text('Select all', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedAts.clear();
                                });
                              },
                              child: const Text('Clear', style: TextStyle(color: AppColors.outline, fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 12.0,
                      children: availableAts.map((ats) {
                        final isSelected = _selectedAts.contains(ats);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedAts.remove(ats);
                              } else {
                                _selectedAts.add(ats);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.borderColor,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              ats,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? AppColors.primary : AppColors.onSurface,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
          
          // Footer Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderColor, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      foregroundColor: AppColors.onSurface,
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9EBBB5), // Custom light green as in screenshot
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Save search', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}