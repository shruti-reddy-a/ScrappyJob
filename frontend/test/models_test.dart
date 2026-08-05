import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scrappy_job/models/job_config.dart';

void main() {
  group('JobConfig Model Tests', () {
    test('JobConfig.fromMap correctly parses data', () {
      final data = {
        'user_id': 'user123',
        'job_label': 'Senior PM Job',
        'job_titles': ['Product Manager', 'Senior PM'],
        'locations': ['SF', 'NY'],
        'target_ats': ['Greenhouse'],
        'timeframe': 'Past 48 Hours',
        'scrape_frequency': 'Daily',
        'target_email': 'test@example.com',
        'is_active': true,
      };

      final job = JobConfig.fromMap(data, 'doc123');

      expect(job.id, 'doc123');
      expect(job.userId, 'user123');
      expect(job.jobLabel, 'Senior PM Job');
      expect(job.jobTitles, ['Product Manager', 'Senior PM']);
      expect(job.locations, ['SF', 'NY']);
      expect(job.targetAts, ['Greenhouse']);
      expect(job.timeframe, 'Past 48 Hours');
      expect(job.scrapeFrequency, 'Daily');
      expect(job.targetEmail, 'test@example.com');
      expect(job.isActive, true);
    });

    test('JobConfig.toMap correctly serializes data', () {
      final jobConfig = JobConfig(
        id: 'doc123',
        userId: 'user123',
        jobLabel: 'Backend Roles',
        jobTitles: ['Developer'],
        locations: ['Onsite'],
        targetAts: ['iCIMS'],
        timeframe: 'Past 48 Hours',
        scrapeFrequency: 'Weekly',
        targetEmail: 'admin@example.com',
        isActive: true,
      );

      final map = jobConfig.toMap();
      expect(map['user_id'], 'user123');
      expect(map['job_label'], 'Backend Roles');
      expect(map['job_titles'], ['Developer']);
      expect(map['locations'], ['Onsite']);
      expect(map['target_ats'], ['iCIMS']);
      expect(map['timeframe'], 'Past 48 Hours');
      expect(map['scrape_frequency'], 'Weekly');
      expect(map['target_email'], 'admin@example.com');
      expect(map['is_active'], true);
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
