import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
// screens
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/article_screen.dart';
import 'screens/consultation_screen.dart';
import 'screens/doctor_home_screen.dart';
import 'screens/clinic_home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/app_theme.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await NotificationService.initialize();

  runApp(const VetraApp());
}

class VetraApp extends StatelessWidget {
  const VetraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      // 🔥 GANTI initialRoute DENGAN INI
      home: const AuthWrapper(),

      // 🔥 ROUTES TETAP DIPAKAI
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/chatbot': (context) => const ChatbotScreen(),
        '/booking': (context) => const BookingScreen(),
        '/article': (context) => const ArticleScreen(),
        '/consultation': (context) => const ConsultationScreen(),
      },
    );
  }
}

////////////////////////////////////////////////////
/// 🔥 AUTO LOGIN LOGIC
////////////////////////////////////////////////////
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // ⏳ loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ SUDAH LOGIN
        if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                String rawRole = userSnapshot.data!.get('role') ?? 'user';
                // Membersihkan spasi atau tanda kutip ganda (") jika tidak sengaja tertulis di Firestore
                String role = rawRole.replaceAll('"', '').trim().toLowerCase();
                
                if (role == 'admin') {
                  return const AdminHomeScreen();
                } else if (role == 'dokter' || role == 'doctor') {
                  return const DoctorHomeScreen();
                } else if (role == 'klinik' || role == 'clinic') {
                  return const ClinicHomeScreen();
                } else {
                  return const HomeScreen(); // user
                }
              }

              // Jika data tidak ditemukan, default ke user home
              return const HomeScreen();
            },
          );
        }

        // ❌ BELUM LOGIN
        return LoginScreen();
      },
    );
  }
}