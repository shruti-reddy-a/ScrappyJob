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

  List<String> _selectedCompanies = [];
  List<String> _selectedLocations = [];
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
    
    if (isHourly && maxSal < 1000) maxSal *= 2000;
    else if (maxSal < 1000) maxSal *= 2000; // Assume hourly if < 1000
    
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
      if (_selectedSalaries.isNotEmpty) {
        int threshold = int.parse(_selectedSalaries.first.replaceAll(RegExp(r'[^0-9]'), ''));
        int? jobSal = _extractAnnualSalary(item.job.salary);
        if (jobSal == null || jobSal < threshold) return false;
      }
      if (_selectedTimes.isNotEmpty) {
        final selectedTime = _selectedTimes.first;
        Duration? maxDuration;
        if (selectedTime == 'Last 3 hours') maxDuration = const Duration(hours: 3);
        else if (selectedTime == 'Last 6 hours') maxDuration = const Duration(hours: 6);
        else if (selectedTime == 'Last 12 hours') maxDuration = const Duration(hours: 12);
        else if (selectedTime == 'Past 24 hours') maxDuration = const Duration(hours: 24);
        else if (selectedTime == 'Past week') maxDuration = const Duration(days: 7);
        else if (selectedTime == 'Past month') maxDuration = const Duration(days: 30);
        
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

          // Data Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    _buildTableHeader(),
                    const Divider(height: 1, color: AppColors.borderColor),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filteredJobs.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderColor),
                        itemBuilder: (context, index) {
                          return _buildTableRow(filteredJobs[index], firebaseService);
                        },
                      ),
                    ),
                  ],
                ),
              ),
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
        color: const Color(0xFFF3F4F6), // light gray background for segmented control
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

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _headerCell('ROLE', flex: 3),
          _headerCell('COMPANY', flex: 2),
          _headerCell('LOCATION', flex: 2),
          _headerCell('SOURCE', flex: 2),
          _headerCell('SALARY', flex: 2),
          _headerCell('POSTED', flex: 1),
          _headerCell('APPLY', flex: 2, align: TextAlign.right),
        ],
      ),
    );
  }

  Widget _headerCell(String title, {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        textAlign: align,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTableRow(JobViewItem item, FirebaseService firebaseService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.job.jobTitle,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.onSurface),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.job.company,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.job.location,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.job.sourceAts,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.job.salary.isNotEmpty ? item.job.salary : 'N/A',
              style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _getFormattedPostedDate(item.job.postedDate, item.job.postingTime),
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (item.job.applicationLink.isNotEmpty)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _launchUrl(item.job.applicationLink),
                      child: Row(
                        children: [
                          const Text(
                            'Apply',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.open_in_new, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                _buildApplyButton(item, firebaseService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(JobViewItem item, FirebaseService firebaseService) {
    if (item.job.isApplied) {
      return InkWell(
        onTap: () {
           final run = firebaseService.jobRuns.firstWhere((r) => r.id == item.runId);
           firebaseService.toggleJobApplied(item.runId, run.jobs, item.originalIndex, false);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F6F4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, size: 16, color: Color(0xFF165C53)),
              const SizedBox(width: 4),
              const Text(
                'Applied',
                style: TextStyle(color: Color(0xFF165C53), fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {
         final run = firebaseService.jobRuns.firstWhere((r) => r.id == item.runId);
         firebaseService.toggleJobApplied(item.runId, run.jobs, item.originalIndex, true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Mark\napplied',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.1),
        ),
      ),
    );
  }
}
