import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scrappy_job/services/firebase_service.dart';
import 'package:scrappy_job/models/job_config.dart';
import 'package:scrappy_job/models/ats_platform.dart';
import 'package:scrappy_job/models/job_view_item.dart';
import 'package:scrappy_job/views/tabs/dashboard_tab.dart';
import 'package:scrappy_job/views/tabs/config_tab.dart';
import 'package:scrappy_job/views/tabs/settings_tab.dart';
import 'package:firebase_auth/firebase_auth.dart';

// A simple fake FirebaseService to provide data for the tabs
class FakeFirebaseService extends ChangeNotifier implements FirebaseService {
  @override
  User? get user => null;

  @override
  List<JobConfig> get jobs => [
        JobConfig(
          id: 'test-job-1',
          userId: 'test-user',
          jobLabel: 'Test Job Config',
          targetAts: ['greenhouse.io'],
          jobTitles: ['Product Manager'],
          locations: ['Remote'],
          scrapeFrequency: 'Daily',
          timeframe: 'Past 24 hours',
          isActive: true,
          createdAt: DateTime.now(),
        )
      ];

  @override
  Map<String, dynamic> get userSettings => {};

  @override
  List<JobRun> get jobRuns => [];

  @override
  List<AtsPlatform> get atsPlatforms => [
        AtsPlatform(
          id: 'greenhouse',
          userId: 'test-user',
          name: 'Greenhouse',
          domain: 'greenhouse.io',
          isEnabled: true,
        )
      ];

  @override
  List<AtsPlatform> get activeAtsPlatforms => atsPlatforms.where((p) => p.isEnabled).toList();

  @override
  bool get isLoading => false;

  @override
  List<JobViewItem> get allJobs => [];

  @override
  RunProgress? get activeProgress => null;

  // We must implement the remaining methods to satisfy the interface but they can be empty for tests
  @override
  Future<String?> signInWithGoogle() async { return null; }

  @override
  Future<String?> signInWithEmail(String email, String password) async { return null; }
  
  @override
  Future<String?> registerWithEmail(String email, String password) async { return null; }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> saveUserSettings(Map<String, dynamic> settings) async {}

  @override
  Future<void> saveJob(JobConfig job) async {}

  @override
  Future<void> deleteJob(String jobId) async {}

  @override
  void setActiveJobId(String? jobId) {}

  @override
  Future<void> saveAtsPlatform(AtsPlatform platform) async {}
  
  @override
  Future<void> deleteAtsPlatform(String platformId) async {}

  @override
  Future<void> toggleAtsPlatform(String platformId, bool currentStatus) async {}
  
  @override
  Future<void> toggleJobApplied(String runId, List<ScrapedJob> currentJobs, int jobIndex, bool isApplied) async {}
  
  @override
  Future<void> stopAgentRun(String jobId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Disable HTTP requests for fonts during tests
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget createTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FirebaseService>(create: (_) => FakeFirebaseService()),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('Tabs Widget Tests', () {
    testWidgets('DashboardTab renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(DashboardTab(onNavigateToSearches: () {})));
      await tester.pump();

      expect(find.text("Here's where your searches stand."), findsOneWidget);
    });

    // testWidgets('JobsTab renders correctly', (WidgetTester tester) async {
    //   await tester.pumpWidget(createTestWidget(const JobsTab()));
    //   await tester.pump();
    //   expect(find.text('Jobs'), findsWidgets);
    // });

    testWidgets('ConfigTab renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(ConfigTab(onRunStarted: () {})));
      await tester.pump();

      expect(find.text('Searches'), findsWidgets);
      expect(find.text('Test Job Config'), findsOneWidget);
    });

    testWidgets('SettingsTab renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const SettingsTab()));
      await tester.pump();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Save Settings'), findsOneWidget);
    });
  });
}
