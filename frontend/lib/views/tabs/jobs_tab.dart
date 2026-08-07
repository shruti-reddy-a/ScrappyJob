import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firebase_service.dart';
import '../../constants/app_colors.dart';
import '../../models/job_view_item.dart';
import '../../widgets/searchable_dropdown.dart';

enum JobFilter { all, notApplied, applied }

class JobsTab extends StatefulWidget {
  const JobsTab({super.key});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> {
  String _searchQuery = '';
  JobFilter _currentFilter = JobFilter.all;
  final TextEditingController _searchController = TextEditingController();
  JobViewItem? _selectedJob;

  List<String> _selectedCompanies = [];
  List<String> _selectedLocations = [];
  List<String> _selectedSources = [];
  List<String> _selectedSalaries = [];
  List<String> _selectedTimes = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  int? _extractAnnualSalary(String salaryStr) {
    if (salaryStr == 'N/A' || salaryStr.isEmpty) return null;
    bool isHourly = salaryStr.toLowerCase().contains('hour') || salaryStr.toLowerCase().contains('hr');
    
    String s = salaryStr.toLowerCase().replaceAll('k', '000');
    s = s.replaceAll(RegExp(r'[^0-9\-]'), '');
    if (s.isEmpty) return null;
    
    List<String> parts = s.split('-');
    int maxSal = 0;
    for (String part in parts) {
      if (part.isNotEmpty) {
        int? val = int.tryParse(part);
        if (val != null && val > maxSal) {
          maxSal = val;
        }
      }
    }
    
    if (maxSal == 0) return null;
    
    if (isHourly && maxSal < 1000) { maxSal *= 2000; }
    else if (maxSal < 1000) { maxSal *= 2000; } // Assume hourly if < 1000
    
    if (salaryStr.toLowerCase().contains('month') || salaryStr.toLowerCase().contains('mo')) {
      if (maxSal < 20000) maxSal *= 12;
    }
    
    return maxSal;
  }

  Duration? _parsePostedDate(String postedDate) {
    if (postedDate == 'N/A' || postedDate.isEmpty) return null;
    final s = postedDate.toLowerCase();
    
    // Check for explicit "ago" strings
    if (s.contains('ago')) {
      int? val = int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), ''));
      if (val == null) return null;
      if (s.contains('m') || s.contains('min')) return Duration(minutes: val);
      if (s.contains('h') || s.contains('hr') || s.contains('hour')) return Duration(hours: val);
      if (s.contains('d') || s.contains('day')) return Duration(days: val);
      if (s.contains('w') || s.contains('week')) return Duration(days: val * 7);
      if (s.contains('mo') || s.contains('month')) return Duration(days: val * 30);
      if (s.contains('y') || s.contains('year')) return Duration(days: val * 365);
    }
    
    // Check for "just now" or "today"
    if (s.contains('just now') || s.contains('today')) return const Duration(minutes: 1);
    if (s.contains('yesterday')) return const Duration(days: 1);
    
    // Check if it's a YYYY-MM-DD format
    try {
      DateTime dt = DateTime.parse(postedDate);
      return DateTime.now().difference(dt);
    } catch (e) {
      // Ignored
    }
    
    return null;
  }

  String _getFormattedPostedDate(String postedDate, String postingTime) {
    if (postedDate.isEmpty || postedDate == 'N/A') return 'N/A';
    Duration? d = _parsePostedDate(postedDate);
    
    // If we couldn't parse it, just return it as is
    if (d == null) {
      if (postingTime != 'N/A' && postingTime.isNotEmpty) {
        return '$postedDate\n$postingTime';
      }
      return postedDate;
    }
    
    // Format based on rules
    if (d.inSeconds < 60) {
      return '${d.inSeconds < 0 ? 0 : d.inSeconds}s ago';
    } else if (d.inMinutes < 60) {
      return '${d.inMinutes}m ago';
    } else if (d.inHours < 24) {
      return '${d.inHours}h ago';
    } else if (d.inDays < 7) {
      return '${d.inDays}d ago';
    } else {
      return '${d.inDays ~/ 7}w ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.watch<FirebaseService>();
    final allJobs = firebaseService.allJobs;

    // Filter jobs
    var filteredJobs = allJobs.where((item) {
      if (_currentFilter == JobFilter.notApplied && item.job.isApplied) return false;
      if (_currentFilter == JobFilter.applied && !item.job.isApplied) return false;

      if (_selectedCompanies.isNotEmpty) {
        if (!_selectedCompanies.contains(item.job.company)) return false;
      }
      if (_selectedLocations.isNotEmpty) {
        if (!_selectedLocations.contains(item.job.location)) return false;
      }
      if (_selectedSources.isNotEmpty) {
        if (!_selectedSources.contains(item.job.sourceAts)) return false;
      }
      if (_selectedSalaries.isNotEmpty) {
        int threshold = int.parse(_selectedSalaries.first.replaceAll(RegExp(r'[^0-9]'), ''));
        int? jobSal = _extractAnnualSalary(item.job.salary);
        if (jobSal == null || jobSal < threshold) return false;
      }
      if (_selectedTimes.isNotEmpty) {
        final selectedTime = _selectedTimes.first;
        Duration? maxDuration;
        if (selectedTime == 'Last 3 hours') { maxDuration = const Duration(hours: 3); }
        else if (selectedTime == 'Last 6 hours') { maxDuration = const Duration(hours: 6); }
        else if (selectedTime == 'Last 12 hours') { maxDuration = const Duration(hours: 12); }
        else if (selectedTime == 'Past 24 hours') { maxDuration = const Duration(hours: 24); }
        else if (selectedTime == 'Past week') { maxDuration = const Duration(days: 7); }
        else if (selectedTime == 'Past month') { maxDuration = const Duration(days: 30); }
        
        if (maxDuration != null) {
          Duration? jobDuration = _parsePostedDate(item.job.postedDate);
          if (jobDuration == null || jobDuration > maxDuration) return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchRole = item.job.jobTitle.toLowerCase().contains(q);
        final matchCompany = item.job.company.toLowerCase().contains(q);
        final matchLocation = item.job.location.toLowerCase().contains(q);
        if (!matchRole && !matchCompany && !matchLocation) return false;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jobs',
            style: GoogleFonts.lora(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${filteredJobs.length} roles found across every search.',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Search & Filter Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search role, company, or location',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildSegmentedControl(),
            ],
          ),
          const SizedBox(height: 16),
          
          // Dropdown Filters Row
          Builder(
            builder: (context) {
              final uniqueCompanies = allJobs.map((e) => e.job.company).where((c) => c.isNotEmpty).toSet().toList()..sort();
              final uniqueLocations = allJobs.map((e) => e.job.location).where((l) => l.isNotEmpty).toSet().toList()..sort();
              final uniqueSources = allJobs.map((e) => e.job.sourceAts).where((s) => s.isNotEmpty).toSet().toList()..sort();
              final salaryOptions = [
                r'$40,000+',
                r'$60,000+',
                r'$80,000+',
                r'$100,000+',
                r'$120,000+',
                r'$140,000+',
                r'$160,000+',
                r'$180,000+',
                r'$200,000+',
              ];
              final timeOptions = [
                'Any time',
                'Last 3 hours',
                'Last 6 hours',
                'Last 12 hours',
                'Past 24 hours',
                'Past week',
                'Past month',
              ];

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildDropdownFilter('Any company', uniqueCompanies, _selectedCompanies, (val) => setState(() => _selectedCompanies = val)),
                  _buildDropdownFilter('Any location', uniqueLocations, _selectedLocations, (val) => setState(() => _selectedLocations = val)),
                  _buildDropdownFilter('Any source', uniqueSources, _selectedSources, (val) => setState(() => _selectedSources = val)),
                  _buildDropdownFilter('Any salary', salaryOptions, _selectedSalaries, (val) => setState(() => _selectedSalaries = val), isMultiSelect: false, showSearch: false, secondaryButtonText: 'Cancel'),
                  _buildDropdownFilter('Any time', timeOptions, _selectedTimes, (val) {
                    setState(() {
                      if (val.contains('Any time')) {
                        _selectedTimes = [];
                      } else {
                        _selectedTimes = val;
                      }
                    });
                  }, isMultiSelect: false, showSearch: false, secondaryButtonText: 'Reset'),
                ],
              );
            }
          ),
          const SizedBox(height: 24),

          // Two-pane Layout
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Pane: Job List
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: filteredJobs.isEmpty
                        ? const Center(child: Text('No jobs found.', style: TextStyle(color: AppColors.outline)))
                        : ListView.separated(
                            itemCount: filteredJobs.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderColor),
                            itemBuilder: (context, index) {
                              final item = filteredJobs[index];
                              final isSelected = _selectedJob == item;
                              return InkWell(
                                onTap: () => setState(() => _selectedJob = item),
                                child: Container(
                                  color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.job.jobTitle,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: isSelected ? AppColors.primary : AppColors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.job.company} • ${item.job.location}',
                                        style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _getFormattedPostedDate(item.job.postedDate, item.job.postingTime),
                                            style: const TextStyle(fontSize: 12, color: AppColors.outline),
                                          ),
                                          if (item.job.isApplied)
                                            const Icon(Icons.check_circle, size: 16, color: AppColors.success)
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Right Pane: Job Details
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: _selectedJob == null
                        ? const Center(
                            child: Text(
                              'Select a job to view details',
                              style: TextStyle(color: AppColors.outline, fontSize: 16),
                            ),
                          )
                        : _buildJobDetails(_selectedJob!, firebaseService),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(String hint, List<String> options, List<String> selectedValues, ValueChanged<List<String>> onChanged, {bool isMultiSelect = true, bool showSearch = true, String secondaryButtonText = 'Reset'}) {
    return SearchableDropdown(
      hint: hint,
      options: options,
      selectedValues: selectedValues,
      onApply: onChanged,
      isMultiSelect: isMultiSelect,
      showSearch: showSearch,
      secondaryButtonText: secondaryButtonText,
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegmentButton('All', JobFilter.all),
          _buildSegmentButton('Not applied', JobFilter.notApplied),
          _buildSegmentButton('Applied', JobFilter.applied),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String text, JobFilter filter) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.onSurface : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildJobDetails(JobViewItem item, FirebaseService firebaseService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Detail Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.job.jobTitle,
                      style: GoogleFonts.lora(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.business, size: 16, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text(
                          item.job.company,
                          style: const TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text(
                          item.job.location,
                          style: const TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (item.job.salary.isNotEmpty)
                          Chip(
                            label: Text(item.job.salary.replaceAll('.0 ', ' ').replaceAll('.0', '')),
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                            side: BorderSide.none,
                          ),
                        Chip(
                          label: Text('Source: ${item.job.sourceAts}'),
                          backgroundColor: AppColors.surfaceContainerHigh,
                          labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                          side: BorderSide.none,
                        ),
                        Chip(
                          label: Text('Posted: ${_getFormattedPostedDate(item.job.postedDate, item.job.postingTime)}'),
                          backgroundColor: AppColors.surfaceContainerHigh,
                          labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.borderColor),
        
        // Snippets or Full Description
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Snippets from Job Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ...item.job.snippets.map((snippet) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6.0, right: 8.0),
                        child: Icon(Icons.circle, size: 6, color: AppColors.primary),
                      ),
                      Expanded(
                        child: Text(
                          snippet.trim(),
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                if (item.job.snippets.isEmpty)
                  const Text('No snippets extracted for this job.', style: TextStyle(color: AppColors.outline)),
              ],
            ),
          ),
        ),
        
        // Footer Actions
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.borderColor)),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildApplyButton(item, firebaseService),
              const SizedBox(width: 16),
              if (item.job.applicationLink.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _launchUrl(item.job.applicationLink),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Apply Now', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApplyButton(JobViewItem item, FirebaseService firebaseService) {
    if (item.job.isApplied) {
      return OutlinedButton.icon(
        onPressed: () {
           final run = firebaseService.jobRuns.firstWhere((r) => r.id == item.runId);
           firebaseService.toggleJobApplied(item.runId, run.jobs, item.originalIndex, false);
           setState(() {}); // trigger rebuild to update button text if needed
        },
        icon: const Icon(Icons.check, size: 18, color: AppColors.success),
        label: const Text('Applied', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 15)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: AppColors.success, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return OutlinedButton(
      onPressed: () {
         final run = firebaseService.jobRuns.firstWhere((r) => r.id == item.runId);
         firebaseService.toggleJobApplied(item.runId, run.jobs, item.originalIndex, true);
         setState(() {}); 
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: const BorderSide(color: AppColors.borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        foregroundColor: AppColors.onSurfaceVariant,
      ),
      child: const Text('Mark as applied', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
    );
  }
}
