import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/scraping_config.dart';

class FirebaseService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;
  ScrapingConfig? _currentConfig;
  List<JobRun> _jobRuns = [];
  bool _isLoading = false;

  User? get user => _user;
  ScrapingConfig? get currentConfig => _currentConfig;
  List<JobRun> get jobRuns => _jobRuns;
  bool get isLoading => _isLoading;

  FirebaseService() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _fetchConfig();
        _fetchJobRuns();
      } else {
        _currentConfig = null;
        _jobRuns = [];
        notifyListeners();
      }
    });
  }

  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      print("Error signing in anonymously: \$e");
    }
  }

  Future<void> _fetchConfig() async {
    if (_user == null) return;
    _setLoading(true);
    try {
      DocumentSnapshot doc = await _firestore.collection('scraping_config').doc(_user!.uid).get();
      if (doc.exists) {
        _currentConfig = ScrapingConfig.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } else {
        // Create default config
        _currentConfig = ScrapingConfig(userId: _user!.uid);
        await saveConfig(_currentConfig!);
      }
    } catch (e) {
      print("Error fetching config: \$e");
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
      print("Error fetching job runs: \$e");
    }
  }

  Future<void> saveConfig(ScrapingConfig config) async {
    if (_user == null) return;
    _setLoading(true);
    try {
      await _firestore.collection('scraping_config').doc(_user!.uid).set(config.toMap());
      _currentConfig = config;
      notifyListeners();
    } catch (e) {
      print("Error saving config: \$e");
    }
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
