import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import 'doctor_dashboard_screen.dart';
import 'doctor_chat_history_screen.dart';
import 'doctor_booking_history_screen.dart';
import 'doctor_profile_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DoctorDashboardScreen(),
    const DoctorChatHistoryScreen(),
    const DoctorBookingHistoryScreen(),
    const DoctorProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: currentUser != null
            ? FirebaseFirestore.instance
                .collection('chats')
                .where('doctorId', isEqualTo: currentUser.uid)
                .snapshots()
            : const Stream.empty(),
        builder: (context, snapshot) {
          int totalUnread = 0;
          if (snapshot.hasData && snapshot.data != null) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              totalUnread += (data['unreadDoctor'] ?? 0) as int;
            }
          }

          return BottomNavigationBar(
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.grey,
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                  icon: Icon(Icons.home), label: "Beranda"),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat),
                    if (totalUnread > 0)
                      Positioned(
                        right: -6,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                              minWidth: 14, minHeight: 14),
                          child: Center(
                            child: Text(
                              totalUnread > 99 ? '99+' : '$totalUnread',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                label: "Chat",
              ),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today), label: "Jadwal"),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: "Profil"),
            ],
          );
        },
      ),
    );
  }
}
