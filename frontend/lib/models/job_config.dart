import 'package:cloud_firestore/cloud_firestore.dart';

class JobConfig {
  String id;
  String userId;
  List<String> jobTitles;
  List<String> locations;
  List<String> targetAts;
  String timeframe;
  String scrapeFrequency;
  String targetEmail;
  bool isActive;
  DateTime? createdAt;
  DateTime? updatedAt;

  JobConfig({
    required this.id,
    required this.userId,
    this.jobTitles = const ["Product Manager", "AI Product Manager", "Senior Product Manager"],
    this.locations = const ["San Francisco Bay Area", "California, USA"],
    this.targetAts = const ["Greenhouse", "Ashby", "Workday", "iCIMS", "Lever", "BambooHR", "Workable", "LinkedIn", "Indeed"],
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
      jobTitles: List<String>.from(data['job_titles'] ?? []),
      locations: List<String>.from(data['locations'] ?? []),
      targetAts: List<String>.from(data['target_ats'] ?? []),
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
      'job_titles': jobTitles,
      'locations': locations,
      'target_ats': targetAts,
      'timeframe': timeframe,
      'scrape_frequency': scrapeFrequency,
      'target_email': targetEmail,
      'is_active': isActive,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}

class JobRun {
  String id;
  String configId;
  String userId;
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
  DateTime? createdAt;

  JobRun({
    required this.id,
    required this.configId,
    required this.userId,
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
    this.createdAt,
  });

  factory JobRun.fromMap(Map<String, dynamic> data, String documentId) {
    return JobRun(
      id: documentId,
      configId: data['config_id'] ?? '',
      userId: data['user_id'] ?? '',
      runDate: data['run_date'] ?? '',
      totalFound: data['total_found'] ?? 0,
      driveFolderId: data['drive_folder_id'] ?? '',
      driveFolderUrl: data['drive_folder_url'] ?? '',
      excelFileId: data['excel_file_id'] ?? '',
      excelFileUrl: data['excel_file_url'] ?? '',
      emailSent: data['email_sent'] ?? false,
      status: data['status'] ?? '',
      executionTimeMs: data['execution_time_ms'] ?? 0,
      logs: data['logs'] != null ? List<Map<String, dynamic>>.from(data['logs']) : [],
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
