import 'job_config.dart';

class JobViewItem {
  final String runId;
  final int originalIndex;
  final ScrapedJob job;

  JobViewItem({
    required this.runId,
    required this.originalIndex,
    required this.job,
  });
}
