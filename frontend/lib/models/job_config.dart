import 'package:cloud_firestore/cloud_firestore.dart';

class JobConfig {
  String id;
  String userId;
  String jobLabel;
  List<String> jobTitles;
  List<String> locations;
  List<String> targetAts;
  List<String> targetUrls;
  String timeframe;
  String scrapeFrequency;
  String targetEmail;
  bool isActive;
  DateTime? createdAt;
  DateTime? updatedAt;

  JobConfig({
    required this.id,
    required this.userId,
    this.jobLabel = "My Scraper Job",
    this.jobTitles = const ["Product Manager", "AI Product Manager", "Senior Product Manager"],
    this.locations = const ["San Francisco Bay Area", "California, USA"],
    this.targetAts = const ["Greenhouse", "Ashby", "Workday", "iCIMS", "Lever", "BambooHR", "Workable", "LinkedIn", "Indeed"],
    this.targetUrls = const [],
    this.timeframe = "Past 24 Hours",
    this.scrapeFrequency = "Every 4 Hours",
    this.targetEmail = "",
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory JobConfig.fromMap(Map<String, dynamic> data, String documentId) {
    return JobConfig(
      id: documentId,
      userId: data['user_id'] ?? '',
      jobLabel: data['job_label'] ?? 'My Scraper Job',
      jobTitles: (data['job_titles'] as List?)?.map((e) => e.toString()).toList() ?? [],
      locations: (data['locations'] as List?)?.map((e) => e.toString()).toList() ?? [],
      targetAts: (data['target_ats'] as List?)?.map((e) => e.toString()).toList() ?? [],
      targetUrls: (data['target_urls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      timeframe: data['timeframe'] ?? "Past 24 Hours",
      scrapeFrequency: data['scrape_frequency'] ?? "Every 4 Hours",
      targetEmail: data['target_email'] ?? "",
      isActive: data['is_active'] ?? true,
      createdAt: data['created_at'] != null ? (data['created_at'] as Timestamp).toDate() : null,
      updatedAt: data['updated_at'] != null ? (data['updated_at'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'job_label': jobLabel,
      'job_titles': jobTitles,
      'locations': locations,
      'target_ats': targetAts,
      'target_urls': targetUrls,
      'timeframe': timeframe,
      'scrape_frequency': scrapeFrequency,
      'target_email': targetEmail,
      'is_active': isActive,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}

class ScrapedJob {
  String sourceAts;
  String jobTitle;
  String company;
  String location;
  String applicationLink;
  String postedDate;
  String postingTime;
  String salary;
  String snippetNotes;
  bool isApplied;

  ScrapedJob({
    required this.sourceAts,
    required this.jobTitle,
    required this.company,
    required this.location,
    required this.applicationLink,
    required this.postedDate,
    required this.postingTime,
    this.salary = 'N/A',
    required this.snippetNotes,
    this.isApplied = false,
  });

  factory ScrapedJob.fromMap(Map<String, dynamic> data) {
    return ScrapedJob(
      sourceAts: data['Source ATS']?.toString() ?? '',
      jobTitle: data['Job Title']?.toString() ?? '',
      company: data['Company']?.toString() ?? '',
      location: data['Location']?.toString() ?? '',
      applicationLink: data['Application Link']?.toString() ?? '',
      postedDate: data['Posted Date']?.toString() ?? '',
      postingTime: data['Posting Time']?.toString() ?? '',
      salary: data['Salary']?.toString() ?? 'N/A',
      snippetNotes: data['Snippet/Notes']?.toString() ?? '',
      isApplied: data['isApplied'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Source ATS': sourceAts,
      'Job Title': jobTitle,
      'Company': company,
      'Location': location,
      'Application Link': applicationLink,
      'Posted Date': postedDate,
      'Posting Time': postingTime,
      'Salary': salary,
      'Snippet/Notes': snippetNotes,
      'isApplied': isApplied,
    };
  }
}

class JobRun {
  String id;
  String configId;
  String userId;
  List<String> jobTitles;
  String runDate;
  int totalFound;
  String driveFolderId;
  String driveFolderUrl;
  String excelFileId;
  String excelFileUrl;
  bool emailSent;
  String status;
  int executionTimeMs;
  List<Map<String, dynamic>> logs;
  List<ScrapedJob> jobs;
  DateTime? createdAt;

  JobRun({
    required this.id,
    required this.configId,
    required this.userId,
    this.jobTitles = const [],
    required this.runDate,
    required this.totalFound,
    required this.driveFolderId,
    required this.driveFolderUrl,
    required this.excelFileId,
    required this.excelFileUrl,
    required this.emailSent,
    required this.status,
    required this.executionTimeMs,
    this.logs = const [],
    this.jobs = const [],
    this.createdAt,
  });

  factory JobRun.fromMap(Map<String, dynamic> data, String documentId) {
    return JobRun(
      id: documentId,
      configId: data['config_id']?.toString() ?? '',
      userId: data['user_id']?.toString() ?? '',
      jobTitles: (data['job_titles'] as List?)?.map((e) => e.toString()).toList() ?? [],
      runDate: data['run_date']?.toString() ?? '',
      totalFound: data['total_found'] ?? 0,
      driveFolderId: data['drive_folder_id']?.toString() ?? '',
      driveFolderUrl: data['drive_folder_url']?.toString() ?? '',
      excelFileId: data['excel_file_id']?.toString() ?? '',
      excelFileUrl: data['excel_file_url']?.toString() ?? '',
      emailSent: data['email_sent'] == true,
      status: data['status']?.toString() ?? '',
      executionTimeMs: data['execution_time_ms'] ?? 0,
      logs: data['logs'] != null ? List<Map<String, dynamic>>.from(data['logs']) : [],
      jobs: data['jobs'] != null ? (data['jobs'] as List).where((j) => j != null).map((j) => ScrapedJob.fromMap(Map<String, dynamic>.from(j))).toList() : [],
      createdAt: data['created_at'] != null ? (data['created_at'] as Timestamp).toDate() : null,
    );
  }
}

class RunProgress {
  String id;
  String status;
  String currentAts;
  int jobsFoundSoFar;
  int atsCompleted;
  int totalAts;
  String command;
  Map<String, int> jobsPerAts;
  String? jobRunId;
  DateTime? startTime;
  DateTime? updatedAt;

  RunProgress({
    required this.id,
    required this.status,
    required this.currentAts,
    required this.jobsFoundSoFar,
    required this.atsCompleted,
    required this.totalAts,
    required this.command,
    this.jobsPerAts = const {},
    this.jobRunId,
    this.startTime,
    this.updatedAt,
  });

  factory RunProgress.fromMap(Map<String, dynamic> data, String documentId) {
    return RunProgress(
      id: documentId,
      status: data['status'] ?? 'UNKNOWN',
      currentAts: data['current_ats'] ?? '',
      jobsFoundSoFar: data['jobs_found_so_far'] ?? 0,
      atsCompleted: data['ats_completed'] ?? 0,
      totalAts: data['total_ats'] ?? 0,
      command: data['command'] ?? '',
      jobsPerAts: data['jobs_per_ats'] != null 
          ? Map<String, int>.from(data['jobs_per_ats']) 
          : {},
      jobRunId: data['job_run_id'],
      startTime: data['start_time'] != null ? (data['start_time'] as Timestamp).toDate() : null,
      updatedAt: data['updated_at'] != null ? (data['updated_at'] as Timestamp).toDate() : null,
    );
  }
}
