import 'package:flutter_test/flutter_test.dart';
import 'package:scrappy_job/models/job_config.dart';
import 'package:scrappy_job/models/ats_platform.dart';

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
        'current_ats': 'Greenhouse',
        'jobs_found_so_far': 10,
        'ats_completed': 1,
        'total_ats': 5,
        'jobs_per_ats': {'Greenhouse': 10},
        'job_run_id': 'run123',
        'user_id': 'user123',
        'updated_at': null,
      };

      final progress = RunProgress.fromMap(data, 'prog1');

      expect(progress.id, 'prog1');
      expect(progress.status, 'RUNNING');
      expect(progress.currentAts, 'Greenhouse');
      expect(progress.jobsFoundSoFar, 10);
      expect(progress.atsCompleted, 1);
      expect(progress.totalAts, 5);
      expect(progress.jobsPerAts['Greenhouse'], 10);
      expect(progress.jobRunId, 'run123');
    });
  });

  group('AtsPlatform Model Tests', () {
    test('AtsPlatform.fromMap correctly parses data', () {
      final data = {
        'user_id': 'user123',
        'name': 'Greenhouse',
        'domain': 'boards.greenhouse.io',
        'is_enabled': true,
        'created_at': null,
      };

      final platform = AtsPlatform.fromMap(data, 'plat1');

      expect(platform.id, 'plat1');
      expect(platform.userId, 'user123');
      expect(platform.name, 'Greenhouse');
      expect(platform.domain, 'boards.greenhouse.io');
      expect(platform.isEnabled, true);
    });

    test('AtsPlatform.toMap correctly serializes data', () {
      final platform = AtsPlatform(
        id: 'plat1',
        userId: 'user123',
        name: 'Ashby',
        domain: 'jobs.ashbyhq.com',
        isEnabled: false,
      );

      final map = platform.toMap();

      expect(map['user_id'], 'user123');
      expect(map['name'], 'Ashby');
      expect(map['domain'], 'jobs.ashbyhq.com');
      expect(map['is_enabled'], false);
    });
  });
}
