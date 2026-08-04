import 'package:cloud_firestore/cloud_firestore.dart';

class ScrapingConfig {
  String userId;
  List<String> jobTitles;
  List<String> locations;
  List<String> targetAts;
  int hoursSincePosted;
  String cronSchedule;
  String targetEmail;
  bool isActive;
  DateTime? updatedAt;

  ScrapingConfig({
    required this.userId,
    this.jobTitles = const ["Product Manager", "AI Product Manager", "Senior Product Manager"],
    this.locations = const ["San Francisco Bay Area", "California, USA"],
    this.targetAts = const ["Greenhouse", "Ashby", "Workday", "iCIMS", "Lever", "BambooHR", "Workable", "LinkedIn", "Indeed"],
    this.hoursSincePosted = 24,
    this.cronSchedule = "0 7 * * *",
    this.targetEmail = "",
    this.isActive = true,
    this.updatedAt,
  });

  factory ScrapingConfig.fromMap(Map<String, dynamic> data, String documentId) {
    return ScrapingConfig(
      userId: data['user_id'] ?? documentId,
      jobTitles: List<String>.from(data['job_titles'] ?? []),
      locations: List<String>.from(data['locations'] ?? []),
      targetAts: List<String>.from(data['target_ats'] ?? []),
      hoursSincePosted: data['hours_since_posted'] ?? 24,
      cronSchedule: data['cron_schedule'] ?? "0 7 * * *",
      targetEmail: data['target_email'] ?? "",
      isActive: data['is_active'] ?? true,
      updatedAt: data['updated_at'] != null ? (data['updated_at'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'job_titles': jobTitles,
      'locations': locations,
      'target_ats': targetAts,
      'hours_since_posted': hoursSincePosted,
      'cron_schedule': cronSchedule,
      'target_email': targetEmail,
      'is_active': isActive,
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
      createdAt: data['created_at'] != null ? (data['created_at'] as Timestamp).toDate() : null,
    );
  }
}
