import 'package:dalab/Home.dart/homepage.dart';
import 'package:dalab/auth/loginpage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // TODO: Fadlan ku baddal url iyo anonKey-gaaga dhabta ah ee Supabase
  try {
    await Supabase.initialize(
      url: 'https://foyqelzwfyilhkasweoo.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZveXFlbHp3ZnlpbGhrYXN3ZW9vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxNDg1ODEsImV4cCI6MjA5NDcyNDU4MX0.OtCYO29ZpdyUypOlfUMdoMn1tSICJIhS5LGFawQ9TwE',
    );
  } catch (e) {
    debugPrint('Supabase Initialization Error (Update URL/Key): $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If the user is logged in, show Homepage
          if (snapshot.hasData) {
            return const Homepage();
          }
          // Otherwise, show LoginPage
          return const LoginPage();
        },
      ),
    );
  }
}
