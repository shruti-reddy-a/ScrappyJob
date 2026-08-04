import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:provider/provider.dart';
import 'services/firebase_service.dart';
import 'views/dashboard_view.dart';
import 'firebase_options.dart'; // Ensure you generate this via flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Note: For this to work out of the box, you need to run `flutterfire configure`
  // and provide the generated firebase_options.dart. 
  // We'll use a placeholder initialization for now.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
    // Fallback if options not found (user must configure)
    await Firebase.initializeApp();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FirebaseService()),
      ],
      child: const JobScraperApp(),
    ),
  );
}

class JobScraperApp extends StatelessWidget {
  const JobScraperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScrappyJob',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Auto sign-in anonymously for demonstration purposes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FirebaseService>().signInAnonymously();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseService>(
      builder: (context, service, child) {
        if (service.user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const DashboardView();
      },
    );
  }
}
