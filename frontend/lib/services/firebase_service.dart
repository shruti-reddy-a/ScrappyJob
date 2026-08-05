import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/job_config.dart';
import '../models/ats_platform.dart';

class FirebaseService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;
  List<JobConfig> _jobs = [];
  List<JobRun> _jobRuns = [];
  List<AtsPlatform> _atsPlatforms = [];
  bool _isLoading = false;

  User? get user => _user;
  List<JobConfig> get jobs => _jobs;
  List<JobRun> get jobRuns => _jobRuns;
  List<AtsPlatform> get atsPlatforms => _atsPlatforms;
  List<AtsPlatform> get activeAtsPlatforms => _atsPlatforms.where((p) => p.isEnabled).toList();
  bool get isLoading => _isLoading;

  FirebaseService() {
    if (!kIsWeb) {
      GoogleSignIn.instance.initialize();
    }
    _auth.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _fetchJobs();
        _fetchJobRuns();
        _fetchAtsPlatforms();
        _listenToGlobalProgress();
      } else {
        _jobs = [];
        _jobRuns = [];
        _atsPlatforms = [];
        _activeProgress = null;
        _globalProgressSub?.cancel();
        notifyListeners();
      }
    });
  }

  StreamSubscription? _globalProgressSub;

  void _listenToGlobalProgress() {
    _globalProgressSub?.cancel();
    if (_user == null) return;
    _globalProgressSub = _firestore
        .collection('run_progress')
        .where('user_id', isEqualTo: _user!.uid)
        .where('status', isEqualTo: 'RUNNING')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        // If there is an active running job, set it. 
        // If there are multiple (unlikely), pick the first.
        _activeProgress = RunProgress.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
        notifyListeners();
      } else if (_activeProgress != null && _activeProgress!.status == 'RUNNING') {
         // It might have just completed or cancelled, let's keep the completed state on screen for a moment
         // We do this by not nullifying it immediately if it was running, 
         // but wait, if it completed, we should probably fetch the latest document for the current active job to see its COMPLETED status.
         _firestore.collection('run_progress').doc(_activeProgress!.id).get().then((doc) {
             if (doc.exists) {
                 _activeProgress = RunProgress.fromMap(doc.data()!, doc.id);
                 notifyListeners();
             }
         });
      }
    });
  }

  Future<String?> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> registerWithEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        await _auth.signInWithPopup(authProvider);
      } else {
        final googleUser = await GoogleSignIn.instance.authenticate();

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error signing out: $e");
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
        _jobs.sort((a, b) {
          final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
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

  Future<void> _fetchAtsPlatforms() async {
    if (_user == null) return;
    try {
      _firestore
          .collection('ats_platforms')
          .where('user_id', isEqualTo: _user!.uid)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.docs.isEmpty) {
          // Seed the database with defaults if empty
          await _seedDefaultAtsPlatforms();
        } else {
          _atsPlatforms = snapshot.docs.map((doc) => AtsPlatform.fromMap(doc.data(), doc.id)).toList();
          _atsPlatforms.sort((a, b) => a.name.compareTo(b.name));
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint("Error fetching ATS platforms: $e");
    }
  }

  Future<void> _seedDefaultAtsPlatforms() async {
    final defaults = {
      "Greenhouse": "boards.greenhouse.io",
      "Ashby": "jobs.ashbyhq.com",
      "Workday": "myworkdayjobs.com",
      "iCIMS": "icims.com/jobs",
      "Lever": "jobs.lever.co",
      "BambooHR": "bamboohr.com/careers",
      "Workable": "apply.workable.com",
      "LinkedIn": "linkedin.com/jobs",
      "Indeed": "indeed.com",
      "SmartRecruiters": "jobs.smartrecruiters.com",
      "Taleo": "taleo.net",
      "Jobvite": "jobs.jobvite.com",
      "ADP": "workforcenow.adp.com",
      "Paycom": "paycomonline.net",
      "JazzHR": "applytojob.com",
      "Breezy HR": "breezy.hr",
      "Paylocity": "recruiting.paylocity.com",
      "UKG": "ultipro.com",
      "ClearCompany": "clearcompany.com",
    };
    for (var entry in defaults.entries) {
      final plat = AtsPlatform(id: '', userId: _user!.uid, name: entry.key, domain: entry.value, isEnabled: true);
      await _firestore.collection('ats_platforms').add(plat.toMap());
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

  Future<void> saveAtsPlatform(AtsPlatform platform) async {
    if (_user == null) return;
    _setLoading(true);
    try {
      if (platform.id.isEmpty) {
        await _firestore.collection('ats_platforms').add(platform.toMap());
      } else {
        await _firestore.collection('ats_platforms').doc(platform.id).update(platform.toMap());
      }
    } catch (e) {
      debugPrint("Error saving ATS platform: $e");
    }
    _setLoading(false);
  }

  Future<void> deleteAtsPlatform(String platformId) async {
    if (_user == null) return;
    _setLoading(true);
    try {
      await _firestore.collection('ats_platforms').doc(platformId).delete();
    } catch (e) {
      debugPrint("Error deleting ATS platform: $e");
    }
    _setLoading(false);
  }

  Future<void> toggleAtsPlatform(String platformId, bool isEnabled) async {
    if (_user == null) return;
    try {
      await _firestore.collection('ats_platforms').doc(platformId).update({'is_enabled': isEnabled});
    } catch (e) {
      debugPrint("Error toggling ATS platform: $e");
    }
  }

  RunProgress? _activeProgress;
  RunProgress? get activeProgress => _activeProgress;
  void setActiveJobId(String? jobId) {
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

  Future<void> toggleJobApplied(String runId, List<ScrapedJob> jobs, int jobIndex, bool isApplied) async {
    if (_user == null) return;
    try {
      jobs[jobIndex].isApplied = isApplied;
      await _firestore.collection('job_runs').doc(runId).update({
        'jobs': jobs.map((j) => j.toMap()).toList(),
      });
    } catch (e) {
      debugPrint("Error toggling job applied: $e");
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
