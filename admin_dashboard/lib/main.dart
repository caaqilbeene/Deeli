import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: 'https://foyqelzwfyilhkasweoo.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZveXFlbHp3ZnlpbGhrYXN3ZW9vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxNDg1ODEsImV4cCI6MjA5NDcyNDU4MX0.OtCYO29ZpdyUypOlfUMdoMn1tSICJIhS5LGFawQ9TwE',
    );
  } catch (e) {
    debugPrint('Supabase Initialization Error: $e');
  }

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Al Raxma Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          primary: Colors.deepOrange,
          secondary: Colors.orangeAccent,
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      home: const LoginPage(),
    );
  }
}
