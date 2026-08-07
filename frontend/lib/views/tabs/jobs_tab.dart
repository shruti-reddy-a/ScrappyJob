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
        if (!_selectedSalaries.contains(item.job.salary)) return false;
      }
      if (_selectedTimes.isNotEmpty) {
        if (!_selectedTimes.contains(item.job.postedDate)) return false;
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
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
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
                    fillColor: Colors.white,
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
              final uniqueSalaries = allJobs.map((e) => e.job.salary).where((s) => s != 'N/A' && s.isNotEmpty).toSet().toList()..sort();
              final uniqueTimes = allJobs.map((e) => e.job.postedDate).where((t) => t != 'N/A' && t.isNotEmpty).toSet().toList()..sort();

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildDropdownFilter('Any company', uniqueCompanies, _selectedCompanies, (val) => setState(() => _selectedCompanies = val)),
                  _buildDropdownFilter('Any location', uniqueLocations, _selectedLocations, (val) => setState(() => _selectedLocations = val)),
                  _buildDropdownFilter('Any salary', uniqueSalaries, _selectedSalaries, (val) => setState(() => _selectedSalaries = val)),
                  _buildDropdownFilter('Any time', uniqueTimes, _selectedTimes, (val) => setState(() => _selectedTimes = val)),
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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

  Widget _buildDropdownFilter(String hint, List<String> options, List<String> selectedValues, ValueChanged<List<String>> onChanged) {
    return SearchableDropdown(
      hint: hint,
      options: options,
      selectedValues: selectedValues,
      onApply: onChanged,
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
              item.job.postedDate.isNotEmpty 
                ? (item.job.postingTime != 'N/A' && item.job.postingTime.isNotEmpty ? '${item.job.postedDate}\n${item.job.postingTime}' : item.job.postedDate) 
                : 'N/A',
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
            color: AppColors.successBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, size: 16, color: AppColors.success),
              const SizedBox(width: 4),
              const Text(
                'Applied',
                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13),
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
