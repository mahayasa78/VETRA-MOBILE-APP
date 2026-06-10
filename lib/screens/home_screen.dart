import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import 'user_home_screen.dart';
import 'user_chat_history_screen.dart';
import 'user_booking_history_screen.dart';
import 'user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      UserHomeScreen(onGoToProfile: () => _onItemTapped(3)),
      const UserChatHistoryScreen(),
      const UserBookingHistoryScreen(),
      const UserProfileScreen(),
    ];

    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: currentUser != null
            ? FirebaseFirestore.instance
                .collection('chats')
                .where('userId', isEqualTo: currentUser.uid)
                .snapshots()
            : const Stream.empty(),
        builder: (context, snapshot) {
          int totalUnread = 0;
          if (snapshot.hasData && snapshot.data != null) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              totalUnread += (data['unreadUser'] ?? 0) as int;
            }
          }

          return BottomNavigationBar(
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.grey,
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
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
                            color: AppColors.secondaryRed,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Center(
                            child: Text(
                              totalUnread > 99 ? '99+' : '$totalUnread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
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