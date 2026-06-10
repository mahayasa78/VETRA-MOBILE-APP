import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'clinic_dashboard_screen.dart';
import 'clinic_booking_screen.dart';
import 'clinic_doctor_list_screen.dart';
import 'clinic_profile_screen.dart';

class ClinicHomeScreen extends StatefulWidget {
  const ClinicHomeScreen({super.key});

  @override
  State<ClinicHomeScreen> createState() => _ClinicHomeScreenState();
}

class _ClinicHomeScreenState extends State<ClinicHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ClinicDashboardScreen(),
    const ClinicBookingScreen(),
    const ClinicDoctorListScreen(),
    const ClinicProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Booking"),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: "Dokter"),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: "Profil"),
        ],
      ),
    );
  }
}
