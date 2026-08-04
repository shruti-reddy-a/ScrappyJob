import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_config.dart';

class FirebaseService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;
  List<JobConfig> _jobs = [];
  List<JobRun> _jobRuns = [];
  bool _isLoading = false;

  User? get user => _user;
  List<JobConfig> get jobs => _jobs;
  List<JobRun> get jobRuns => _jobRuns;
  bool get isLoading => _isLoading;

  FirebaseService() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _fetchJobs();
        _fetchJobRuns();
      } else {
        _jobs = [];
        _jobRuns = [];
        notifyListeners();
      }
    });
  }

  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      debugPrint("Error signing in anonymously: $e");
    }
  }

  Future<void> _fetchJobs() async {
    if (_user == null) return;
    _setLoading(true);
    try {
      _firestore
          .collection('jobs')
          .where('user_id', isEqualTo: _user!.uid)
          .snapshots()
          .listen((snapshot) {
        _jobs = snapshot.docs.map((doc) => JobConfig.fromMap(doc.data(), doc.id)).toList();
        notifyListeners();
      });
    } catch (e) {
      debugPrint("Error fetching jobs: $e");
    }
    _setLoading(false);
  }

  Future<void> _fetchJobRuns() async {
    if (_user == null) return;
    try {
      _firestore.collection('job_runs')
          .where('user_id', isEqualTo: _user!.uid)
          .orderBy('created_at', descending: true)
          .limit(20)
          .snapshots()
          .listen((snapshot) {
        _jobRuns = snapshot.docs.map((doc) => JobRun.fromMap(doc.data(), doc.id)).toList();
        notifyListeners();
      });
    } catch (e) {
      debugPrint("Error fetching job runs: $e");
    }
  }

  Future<void> saveJob(JobConfig job) async {
    if (_user == null) return;
    _setLoading(true);
    try {
      if (job.id.isEmpty) {
        // Add new job
        await _firestore.collection('jobs').add(job.toMap());
      } else {
        // Update existing job
        await _firestore.collection('jobs').doc(job.id).update(job.toMap());
      }
    } catch (e) {
      debugPrint("Error saving job: $e");
    }
    _setLoading(false);
  }

  Future<void> deleteJob(String jobId) async {
    if (_user == null) return;
    _setLoading(true);
    try {
      await _firestore.collection('jobs').doc(jobId).delete();
    } catch (e) {
      debugPrint("Error deleting job: $e");
    }
    _setLoading(false);
  }

  RunProgress? _activeProgress;
  RunProgress? get activeProgress => _activeProgress;
  String? _activeJobId;
  
  void setActiveJobId(String? jobId) {
    _activeJobId = jobId;
    if (jobId != null) {
      _listenToProgress(jobId);
    } else {
      _activeProgress = null;
      notifyListeners();
    }
  }

  void _listenToProgress(String jobId) {
    _firestore.collection('run_progress').doc(jobId).snapshots().listen((doc) {
      if (doc.exists) {
        _activeProgress = RunProgress.fromMap(doc.data()!, doc.id);
        notifyListeners();
      } else {
        _activeProgress = null;
        notifyListeners();
      }
    });
  }

  Future<void> stopAgentRun(String jobId) async {
    if (_user == null) return;
    try {
      await _firestore.collection('run_progress').doc(jobId).update({'command': 'STOP'});
    } catch (e) {
      debugPrint("Error stopping run: $e");
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
