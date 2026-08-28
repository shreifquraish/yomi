import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'providers/notes_provider.dart';
import 'screens/login_screen.dart';
import 'screens/notes_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Firebase Init Error: $e')))));
    return;
  }
  runApp(const YoumiApp());
}

class YoumiApp extends StatelessWidget {
  const YoumiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotesProvider()),
      ],
      child: MaterialApp(
        title: 'يومي',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', 'AE'), // Arabic
        ],
        locale: const Locale('ar', 'AE'),
        theme: ThemeData(
          primaryColor: const Color(0xFF4F6DCE),
          scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF4F6DCE))),
          );
        }
        
        if (snapshot.hasData) {
          return const NotesScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}
