import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scrappy_job/models/job_config.dart';

void main() {
  group('JobConfig Model Tests', () {
    test('JobConfig.fromMap correctly parses data', () {
      final data = {
        'user_id': 'user123',
        'job_titles': ['Engineer'],
        'locations': ['Remote'],
        'target_ats': ['Workday'],
        'timeframe': 'Past 24 Hours',
        'scrape_frequency': 'Daily',
        'target_email': 'test@example.com',
        'is_active': false,
        'created_at': Timestamp.fromDate(DateTime(2023, 1, 1)),
      };

      final jobConfig = JobConfig.fromMap(data, 'doc123');

      expect(jobConfig.id, 'doc123');
      expect(jobConfig.userId, 'user123');
      expect(jobConfig.jobTitles, ['Engineer']);
      expect(jobConfig.locations, ['Remote']);
      expect(jobConfig.targetAts, ['Workday']);
      expect(jobConfig.timeframe, 'Past 24 Hours');
      expect(jobConfig.scrapeFrequency, 'Daily');
      expect(jobConfig.targetEmail, 'test@example.com');
      expect(jobConfig.isActive, false);
      expect(jobConfig.createdAt?.year, 2023);
    });

    test('JobConfig.toMap correctly serializes data', () {
      final jobConfig = JobConfig(
        id: 'doc123',
        userId: 'user123',
        jobTitles: ['Engineer'],
        locations: ['Remote'],
        targetAts: ['Workday'],
        timeframe: 'Past 24 Hours',
        scrapeFrequency: 'Daily',
        targetEmail: 'test@example.com',
        isActive: false,
      );

      final map = jobConfig.toMap();

      expect(map['user_id'], 'user123');
      expect(map['job_titles'], ['Engineer']);
      expect(map['locations'], ['Remote']);
      expect(map['target_ats'], ['Workday']);
      expect(map['timeframe'], 'Past 24 Hours');
      expect(map['scrape_frequency'], 'Daily');
      expect(map['target_email'], 'test@example.com');
      expect(map['is_active'], false);
    });
  });

  group('JobRun Model Tests', () {
    test('JobRun.fromMap correctly parses data', () {
      final data = {
        'config_id': 'config123',
        'user_id': 'user123',
        'job_titles': ['DevOps'],
        'run_date': '2023-01-01',
        'total_found': 42,
        'status': 'SUCCESS',
        'jobs': [
          {
            'Job Title': 'Engineer',
            'Company': 'TechCorp',
            'Application Link': 'https://example.com'
          }
        ]
      };

      final jobRun = JobRun.fromMap(data, 'run123');

      expect(jobRun.id, 'run123');
      expect(jobRun.configId, 'config123');
      expect(jobRun.userId, 'user123');
      expect(jobRun.jobTitles, ['DevOps']);
      expect(jobRun.runDate, '2023-01-01');
      expect(jobRun.totalFound, 42);
      expect(jobRun.status, 'SUCCESS');
      expect(jobRun.jobs.length, 1);
      expect(jobRun.jobs.first.jobTitle, 'Engineer');
    });
  });

  group('RunProgress Model Tests', () {
    test('RunProgress.fromMap correctly parses data', () {
      final data = {
        'status': 'RUNNING',
        'current_ats': 'Workday',
        'jobs_found_so_far': 10,
        'ats_completed': 1,
        'total_ats': 5,
        'command': 'STOP',
        'jobs_per_ats': {'Workday': 10},
      };

      final progress = RunProgress.fromMap(data, 'prog123');

      expect(progress.id, 'prog123');
      expect(progress.status, 'RUNNING');
      expect(progress.currentAts, 'Workday');
      expect(progress.jobsFoundSoFar, 10);
      expect(progress.atsCompleted, 1);
      expect(progress.totalAts, 5);
      expect(progress.command, 'STOP');
      expect(progress.jobsPerAts['Workday'], 10);
    });
  });
}
