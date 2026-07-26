import 'package:dash/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/chat_home_screen.dart'; // <--- ඔයාගේ Main Chat/Home Screen එක මෙතැනට Import කරන්න

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connected Chat App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D0D11),
      ),
      // Builder එකක් පාවිච්චි කිරීමෙන් MaterialApp එකට යටින් තියෙන valid context එකක් ලබාගන්න පුළුවන්
      home: Builder(
        builder: (context) {
          return AuthScreen(
            onAuthSuccess: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ChatHomeScreen()),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Successfully logged in!')),
              );
            },
          );
        },
      ),
    );
  }
}