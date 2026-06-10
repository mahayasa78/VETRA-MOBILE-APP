import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'search_screen.dart';
import 'clinic_list_screen.dart';
import 'chat_screen.dart';
import 'user_profile_screen.dart';
import 'booking_screen.dart';
import 'add_review_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../utils/app_network_image.dart';

class UserHomeScreen extends StatefulWidget {
  final VoidCallback? onGoToProfile;
  const UserHomeScreen({super.key, this.onGoToProfile});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  bool _showNotificationBadge = false;
  Set<String> _readNotificationIds = {};
  List<Map<String, dynamic>> _allNotifications = [];
  List<Map<String, dynamic>> _bookingsList = [];
  List<Map<String, dynamic>> _articlesList = [];
  StreamSubscription? _bookingsSub;
  StreamSubscription? _articlesSub;

  @override
  void initState() {
    super.initState();
    _loadReadNotifications();
    _listenToNotifications();
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    _articlesSub?.cancel();
    super.dispose();
  }

  bool _isFirstBookingLoad = true;
  Map<String, String> _localBookingStatuses = {};
  bool _isFirstArticleLoad = true;
  Set<String> _localArticleIds = {};

  Future<void> _loadReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _readNotificationIds = Set<String>.from(prefs.getStringList('read_notification_ids') ?? []);
      });
    }
  }

  void _listenToNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _bookingsSub = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      
      final Map<String, String> newStatuses = {};
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        final status = data['status'] ?? 'Menunggu';
        newStatuses[doc.id] = status;
        
        return {
          'id': doc.id,
          'clinicName': data['clinicName'] ?? 'Klinik',
          'doctorName': data['doctorName'] ?? 'Dokter',
          'status': status,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();

      if (!_isFirstBookingLoad) {
        for (var docId in newStatuses.keys) {
          final oldStatus = _localBookingStatuses[docId];
          final newStatus = newStatuses[docId];
          if (oldStatus != null && oldStatus != newStatus) {
            final bookingData = list.firstWhere((element) => element['id'] == docId, orElse: () => {});
            if (bookingData.isNotEmpty) {
              final clinicName = bookingData['clinicName'];
              final doctorName = bookingData['doctorName'];
              
              String title = 'Status Booking Diperbarui';
              String body = 'Booking Anda dengan $doctorName di $clinicName sekarang berstatus: $newStatus.';
              if (newStatus == 'Dikonfirmasi') {
                title = 'Booking Dikonfirmasi! 🎉';
                body = 'Booking dengan $doctorName di $clinicName telah disetujui.';
              } else if (newStatus == 'Ditolak') {
                title = 'Booking Ditolak ⚠️';
                body = 'Booking Anda di $clinicName tidak disetujui.';
              } else if (newStatus == 'Selesai') {
                title = 'Booking Selesai 🏥';
                body = 'Konsultasi Anda selesai. Berikan rating & ulasan sekarang!';
              }
              
              NotificationService.showNotification(title, body);
            }
          }
        }
      }
      
      _localBookingStatuses = newStatuses;
      _isFirstBookingLoad = false;

      setState(() {
        _bookingsList = list;
        _combineNotifications();
      });
    });

    _articlesSub = FirebaseFirestore.instance
        .collection('articles')
        .orderBy('created_at', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      
      final Set<String> newIds = snapshot.docs.map((doc) => doc.id).toSet();
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Artikel Baru',
          'createdAt': (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();

      if (!_isFirstArticleLoad) {
        for (var docId in newIds) {
          if (!_localArticleIds.contains(docId)) {
            final articleData = list.firstWhere((element) => element['id'] == docId, orElse: () => {});
            if (articleData.isNotEmpty) {
              final title = articleData['title'];
              NotificationService.showNotification(
                'Artikel Edukasi Baru! 📚',
                'Yuk baca artikel terbaru: "$title"',
              );
            }
          }
        }
      }
      
      _localArticleIds = newIds;
      _isFirstArticleLoad = false;

      setState(() {
        _articlesList = list;
        _combineNotifications();
      });
    });
  }

  void _combineNotifications() {
    final List<Map<String, dynamic>> temp = [];

    // Process bookings
    for (var b in _bookingsList) {
      final bId = b['id'];
      final status = b['status'];
      final time = b['createdAt'] as DateTime;
      final clinicName = b['clinicName'];
      final doctorName = b['doctorName'];

      String text = '';
      String title = '';
      if (status == 'Menunggu') {
        title = 'Booking Menunggu';
        text = 'Booking baru di $clinicName berhasil dibuat, menunggu konfirmasi.';
      } else if (status == 'Dikonfirmasi') {
        title = 'Booking Dikonfirmasi';
        text = 'Booking dengan $doctorName di $clinicName telah dikonfirmasi!';
      } else if (status == 'Ditolak') {
        title = 'Booking Ditolak';
        text = 'Booking Anda di $clinicName ditolak.';
      } else if (status == 'Selesai') {
        title = 'Booking Selesai';
        text = 'Konsultasi di $clinicName selesai. Mohon berikan ulasan!';
      } else {
        title = 'Update Booking';
        text = 'Status booking Anda di $clinicName menjadi $status.';
      }

      final notifId = 'booking_${bId}_$status';

      temp.add({
        'id': notifId,
        'title': title,
        'text': text,
        'time': time,
      });
    }

    // Process articles
    for (var a in _articlesList) {
      final aId = a['id'];
      final title = a['title'];
      final time = a['createdAt'] as DateTime;

      temp.add({
        'id': 'article_$aId',
        'title': 'Artikel Baru',
        'text': 'Artikel baru dipublikasi: "$title"',
        'time': time,
      });
    }

    // Sort by time descending
    temp.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

    _allNotifications = temp;

    bool hasUnread = false;
    for (var n in _allNotifications) {
      if (!_readNotificationIds.contains(n['id'])) {
        hasUnread = true;
        break;
      }
    }

    _showNotificationBadge = hasUnread;
  }

  Future<void> _markAllNotificationsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final allIds = _allNotifications.map((n) => n['id'] as String).toList();
    _readNotificationIds.addAll(allIds);
    await prefs.setStringList('read_notification_ids', _readNotificationIds.toList());
    if (mounted) {
      setState(() {
        _showNotificationBadge = false;
      });
    }
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    final isAddress = title == "Alamat";
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(title, style: const TextStyle(color: AppColors.darkGrey)),
        ),
        const Text(": "),
        Expanded(
          child: isAddress
              ? InkWell(
                  onTap: () => _openMapSearch(value),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Future<void> _openMapSearch(String address) async {
    if (address.isEmpty || address == 'Alamat belum diatur') return;
    try {
      final q = Uri.encodeComponent(address);
      final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$q");
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      print("Error opening map: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllSearchData() async {
    List<Map<String, dynamic>> results = [];

    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final role = data['role']?.toString().toLowerCase();
      if (role == 'dokter' || role == 'klinik') {
        results.add({
          'id': doc.id,
          'type': role,
          'title': data['name'] ?? '',
          'subtitle': role == 'dokter' ? (data['spesialis'] ?? '') : (data['address'] ?? ''),
          'profilePic': data['profilePic'],
        });
      }
    }

    final articlesSnapshot = await FirebaseFirestore.instance.collection('articles').get();
    for (var doc in articlesSnapshot.docs) {
      final data = doc.data();
      results.add({
        'id': doc.id,
        'type': 'artikel',
        'title': data['title'] ?? '',
        'subtitle': data['desc'] ?? '',
        'profilePic': null,
      });
    }

    return results;
  }

  void _openSearch(BuildContext context) {
    final searchFuture = _fetchAllSearchData();
    showSearch(context: context, delegate: VetraSearchDelegate(searchFuture));
  }

  // 🔹 QUICK MENU GRID (5 ITEMS)
  Widget _buildQuickMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _quickMenuItem(context, Icons.smart_toy_outlined, "Chatbot", "/chatbot"),
          _quickMenuItem(context, Icons.chat_bubble_outline, "Konsultasi", "/consultation"),
          _quickMenuItem(context, Icons.calendar_today_outlined, "Booking", "/booking"),
          _quickMenuItem(context, Icons.article_outlined, "Artikel", "/article"),
          _quickMenuItem(context, Icons.local_hospital_outlined, "Klinik", null, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ClinicListScreen()));
          }),
        ],
      ),
    );
  }

  Widget _quickMenuItem(BuildContext context, IconData icon, String title, String? route, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap();
        } else if (route != null) {
          Navigator.pushNamed(context, route);
        }
      },
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F6F6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // 🔹 CHATBOT CTA CARD (NEW DESIGN)
  Widget _buildChatbotCTACard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF008D8E), Color(0xFF00A2A3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF008D8E).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Chatbot VETRA",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Konsultasi gratis 24 jam\nTanya apa saja seputar anabulmu",
                    style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF008D8E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/chatbot');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text("Mulai Chat", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 FRIENDLY EMPTY SCHEDULE CARD
  Widget _buildFriendlyEmptySchedule(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Belum ada jadwal aktif",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Yuk buat janji dengan dokter sekarang!",
                        style: TextStyle(color: AppColors.darkGrey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/booking');
                },
                child: const Text("Buat Booking", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 REDESIGNED DOKTER CARD
  Widget doctorCard(BuildContext context, String doctorId, String name, String role, String initials, String? profilePic, Map<String, dynamic> fullData) {
    final bool isOnline = fullData['isOnline'] ?? false;
    final clinicId = fullData['clinicId'] ?? '';

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('reviews')
          .where('targetId', isEqualTo: doctorId)
          .get(),
      builder: (context, reviewSnap) {
        double avgRating = 0;
        int reviewCount = 0;
        if (reviewSnap.hasData && reviewSnap.data!.docs.isNotEmpty) {
          double total = 0;
          for (var r in reviewSnap.data!.docs) {
            total += (r['rating'] ?? 5.0).toDouble();
          }
          reviewCount = reviewSnap.data!.docs.length;
          avgRating = total / reviewCount;
        }
        final ratingStr = reviewCount > 0
            ? "${avgRating.toStringAsFixed(1)} ($reviewCount)"
            : "Belum ada ulasan";

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          color: Colors.white,
          child: InkWell(
            onTap: () => _showDoctorDetailSheet(context, fullData, doctorId),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Avatar + online dot
                  Stack(children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: (profilePic != null && profilePic.isNotEmpty) ? appNetworkImageProvider(profilePic) : null,
                      child: (profilePic == null || profilePic.isEmpty)
                          ? Text(initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16))
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 13, height: 13,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 3),
                        Row(children: [
                          Flexible(
                            child: Text(role,
                                style: const TextStyle(fontSize: 12, color: AppColors.darkGrey),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.star_rounded,
                              color: reviewCount > 0 ? Colors.amber : Colors.grey.shade400,
                              size: 12),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(ratingStr,
                                style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600,
                                  color: reviewCount > 0 ? Colors.amber.shade700 : AppColors.darkGrey,
                                ),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                        // Nama klinik
                        if (clinicId.isNotEmpty)
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(clinicId).get(),
                            builder: (ctx, snap) {
                              if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
                              final cData = snap.data!.data() as Map<String, dynamic>;
                              final cName = cData['name'] ?? '';
                              if (cName.isEmpty) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Row(children: [
                                  const Icon(Icons.local_hospital_outlined, size: 12, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(cName,
                                      style: const TextStyle(fontSize: 12, color: AppColors.primary),
                                      overflow: TextOverflow.ellipsis)),
                                ]),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser == null) return;
                      final chatId = '${currentUser.uid}_$doctorId';
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: chatId,
                          receiverId: doctorId,
                          receiverName: name,
                        ),
                      ));
                    },
                    child: const Text("Chat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  // Helper method to make phone calls via url_launcher
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      print("Could not launch phone call: $e");
    }
  }


  // 🔹 KLINIK MITRA SECTION — tampilan sama dengan Cari Klinik
  Widget _buildKlinikMitra(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Klinik Mitra Terdekat",
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18)),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ClinicListScreen())),
                child: const Text("Lihat Semua →",
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'klinik')
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text("Belum ada klinik mitra.", style: TextStyle(color: AppColors.darkGrey)),
              );
            }

            final clinics = snapshot.data!.docs;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: clinics.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Klinik';
                  final address = data['address'] ?? 'Alamat belum diatur';
                  final profilePic = data['profilePic'] ?? '';
                  final bool isOpen = data['isClinicOpen'] ?? true;
                  final phone = (data['phone'] ?? '').toString();
                  final operationalHours = data['operationalHours'] as Map<String, dynamic>?;

                  String initials = "K";
                  if (name.isNotEmpty) {
                    final w = name.trim().split(' ');
                    initials = w.length > 1 ? (w[0][0] + w[1][0]).toUpperCase() : name[0].toUpperCase();
                  }

                  // Jam operasional ringkas
                  String opSummary = "Hubungi untuk jam operasional";
                  if (operationalHours != null && operationalHours.isNotEmpty) {
                    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
                    final openDays = days.where((d) => operationalHours[d]?['isOpen'] == true).toList();
                    if (openDays.isNotEmpty) {
                      final openTime = operationalHours[openDays.first]?['open'] ?? '08:00';
                      final closeTime = operationalHours[openDays.first]?['close'] ?? '17:00';
                      opSummary = openDays.length == 7
                          ? "Setiap hari $openTime–$closeTime"
                          : "${openDays.first}–${openDays.last} $openTime–$closeTime";
                    }
                  }

                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('reviews')
                        .where('targetId', isEqualTo: doc.id)
                        .get(),
                    builder: (context, reviewFuture) {
                      double avgRating = 0;
                      int reviewCount = 0;
                      if (reviewFuture.hasData && reviewFuture.data!.docs.isNotEmpty) {
                        double total = 0;
                        for (var r in reviewFuture.data!.docs) {
                          total += (r['rating'] ?? 5.0).toDouble();
                        }
                        reviewCount = reviewFuture.data!.docs.length;
                        avgRating = total / reviewCount;
                      }
                      final ratingStr = reviewCount > 0
                          ? "★ ${avgRating.toStringAsFixed(1)} ($reviewCount)"
                          : "★ 0.0";

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        color: Colors.white,
                        child: InkWell(
                          onTap: () => _showClinicDetailSheet(context, data, doc.id, ratingStr),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Banner foto
                              Stack(children: [
                                profilePic.isNotEmpty
                                    ? AppNetworkImage(
                                        url: profilePic,
                                        width: double.infinity,
                                        height: 110,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => _clinicPlaceholder(initials),
                                      )
                                    : _clinicPlaceholder(initials),
                                Positioned(
                                  top: 10, right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isOpen ? Colors.green.shade600 : Colors.red.shade600,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                    ),
                                    child: Text(
                                      isOpen ? "BUKA" : "TUTUP",
                                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ]),

                              // Info
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 5),
                                    Row(children: [
                                      Icon(Icons.star_rounded,
                                          color: reviewCount > 0 ? Colors.amber : Colors.grey.shade400,
                                          size: 13),
                                      const SizedBox(width: 3),
                                      Text(
                                        reviewCount > 0
                                            ? "${avgRating.toStringAsFixed(1)} ($reviewCount)"
                                            : "Belum ada ulasan",
                                        style: TextStyle(
                                          fontSize: 11, fontWeight: FontWeight.w600,
                                          color: reviewCount > 0 ? Colors.amber.shade700 : AppColors.darkGrey,
                                        ),
                                      ),
                                    ]),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      const Icon(Icons.access_time_outlined, size: 12, color: AppColors.darkGrey),
                                      const SizedBox(width: 3),
                                      Expanded(child: Text(opSummary,
                                          style: const TextStyle(fontSize: 11, color: AppColors.darkGrey),
                                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    ]),
                                    const SizedBox(height: 3),
                                    Row(children: [
                                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.darkGrey),
                                      const SizedBox(width: 3),
                                      Expanded(child: Text(address,
                                          style: const TextStyle(fontSize: 11, color: AppColors.darkGrey),
                                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    ]),
                                  ],
                                ),
                              ),

                              // Action buttons
                              const SizedBox(height: 8),
                              Divider(height: 1, color: Colors.grey.shade100),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _iconActionBtn(Icons.phone_outlined, "Telepon", () {
                                      if (phone.isNotEmpty) {
                                        _makePhoneCall(phone);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Nomor telepon tidak tersedia.")));
                                      }
                                    }),
                                    Container(width: 1, height: 28, color: Colors.grey.shade200),
                                    _iconActionBtn(Icons.map_outlined, "Peta", () {
                                      if (address.isNotEmpty && address != 'Alamat belum diatur') {
                                        _openMapSearch(address);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Alamat klinik belum diatur.")));
                                      }
                                    }),
                                    Container(width: 1, height: 28, color: Colors.grey.shade200),
                                    _iconActionBtn(Icons.calendar_today_outlined, "Booking", () {
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => BookingScreen(
                                          preselectedClinicId: doc.id,
                                          preselectedClinicName: name,
                                        ),
                                      ));
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _iconActionBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

    // 🔹 DETAIL SHEET KLINIK MITRA DENGAN REVIEW & FOTO
  void _showClinicDetailSheet(
    BuildContext context,
    Map<String, dynamic> data,
    String clinicId,
    String ratingStr,
  ) {
    final name = data['name'] ?? 'Klinik';
    final address = data['address'] ?? 'Alamat belum diatur';
    final phone = data['phone'] ?? '';
    final emergencyPhone = data['emergencyPhone'] ?? '';
    final profilePic = data['profilePic'] ?? '';
    final bool isOpen = data['isClinicOpen'] ?? true;
    final operationalHours = data['operationalHours'] as Map<String, dynamic>?;
    final List<String> days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, scrollController) => StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('targetId', isEqualTo: clinicId)
              .snapshots(),
          builder: (context, reviewSnap) {
            double avgRating = 0;
            int reviewCount = 0;
            List<String> reviewPhotos = [];

            if (reviewSnap.hasData && reviewSnap.data!.docs.isNotEmpty) {
              double totalRating = 0;
              for (var doc in reviewSnap.data!.docs) {
                final r = doc.data() as Map<String, dynamic>;
                totalRating += (r['rating'] ?? 5.0).toDouble();
                final imgUrl = r['image_url'] ?? '';
                if (imgUrl.isNotEmpty) {
                  reviewPhotos.add(imgUrl);
                }
              }
              reviewCount = reviewSnap.data!.docs.length;
              avgRating = totalRating / reviewCount;
            }

            final dynamicRatingText = reviewCount > 0
                ? "★ ${avgRating.toStringAsFixed(1)} ($reviewCount)"
                : "★ 0.0 (0)";

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: profilePic.isNotEmpty ? appNetworkImageProvider(profilePic) : null,
                        child: profilePic.isEmpty
                            ? Text(
                                name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isOpen ? Colors.green.shade200 : Colors.red.shade200),
                                  ),
                                  child: Text(
                                    isOpen ? "BUKA" : "TUTUP",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isOpen ? Colors.green.shade700 : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(dynamicRatingText, style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold,
                                  color: reviewCount > 0 ? Colors.amber : Colors.grey,
                                )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  _buildDetailRow(Icons.location_on, "Alamat", address),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.phone, "Telepon", phone.isNotEmpty ? phone : '-'),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.emergency, "No. Darurat", emergencyPhone.isNotEmpty ? emergencyPhone : '-'),

                  const Divider(height: 32),

                  if (reviewPhotos.isNotEmpty) ...[
                    const Text("Foto dari Ulasan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: reviewPhotos.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 90,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: AppNetworkImage(
                              url: reviewPhotos[index],
                              fit: BoxFit.cover,
                              errorWidget: (c, u, e) => Container(color: Colors.grey.shade100, child: const Icon(Icons.image, color: Colors.grey)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const Divider(height: 32),

                  // ── Beri Rating Section (Google Maps style) ──────────────
                  Builder(builder: (innerCtx) {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) return const SizedBox();
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
                      builder: (context, userSnap) {
                        String uPhoto = '';
                        String uName = 'Pengguna';
                        if (userSnap.hasData && userSnap.data!.exists) {
                          final userData = userSnap.data!.data() as Map<String, dynamic>?;
                          uPhoto = userData?['profilePic'] ?? '';
                          uName = userData?['name'] ?? 'Pengguna';
                        }
                        final uInitial = uName.isNotEmpty ? uName.substring(0, 1).toUpperCase() : 'P';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Ulasan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(innerCtx, MaterialPageRoute(
                                      builder: (_) => AddReviewScreen(
                                        targetId: clinicId,
                                        targetName: name,
                                        targetType: 'klinik',
                                      ),
                                    ));
                                  },
                                  child: const Text('Tambah ulasan',
                                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primaryLight,
                                  backgroundImage: uPhoto.isNotEmpty ? appNetworkImageProvider(uPhoto) : null,
                                  child: uPhoto.isEmpty
                                      ? Text(uInitial, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16))
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Row(
                                  children: List.generate(5, (i) => GestureDetector(
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      Navigator.push(innerCtx, MaterialPageRoute(
                                        builder: (_) => AddReviewScreen(
                                          targetId: clinicId,
                                          targetName: name,
                                          targetType: 'klinik',
                                        ),
                                      ));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 3),
                                      child: Icon(
                                        reviewCount > 0 && i < avgRating.round()
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: reviewCount > 0 && i < avgRating.round()
                                            ? Colors.amber
                                            : Colors.grey.shade400,
                                        size: 32,
                                      ),
                                    ),
                                  )),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(innerCtx, MaterialPageRoute(
                                  builder: (_) => AddReviewScreen(
                                    targetId: clinicId,
                                    targetName: name,
                                    targetType: 'klinik',
                                  ),
                                ));
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 20),
                                    SizedBox(width: 8),
                                    Text('Posting foto & komentar',
                                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 20),
                          ],
                        );
                      }
                    );
                  }),

                  if (!reviewSnap.hasData || reviewSnap.data!.docs.isEmpty)
                    const Text("Belum ada ulasan.", style: TextStyle(color: AppColors.darkGrey, fontSize: 13))
                  else
                    Column(
                      children: reviewSnap.data!.docs.map((doc) {
                        final r = doc.data() as Map<String, dynamic>;
                        return _buildReviewItem(r);
                      }).toList(),
                    ),

              const Divider(height: 24),

              if (operationalHours != null) ...[
                const Text("Jam Operasional", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                ...days.map((day) {
                  final h = operationalHours[day] as Map<String, dynamic>?;
                  final dayOpen = h?['isOpen'] ?? false;
                  final openT = h?['open'] ?? '08:00';
                  final closeT = h?['close'] ?? '17:00';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(width: 72, child: Text(day, style: const TextStyle(fontSize: 13))),
                        Expanded(
                          child: Text(
                            dayOpen ? "$openT – $closeT" : "Tutup",
                            style: TextStyle(
                              fontSize: 13,
                              color: dayOpen ? AppColors.darkGrey : Colors.red,
                              fontWeight: dayOpen ? FontWeight.normal : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(height: 32),
              ],

              const Text("Dokter di Klinik Ini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'dokter')
                    .where('clinicId', isEqualTo: clinicId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Text("Belum ada dokter terdaftar di klinik ini.", style: TextStyle(color: AppColors.darkGrey, fontSize: 12));
                  }
                  return Column(
                    children: docs.map((doc) {
                      final dData = doc.data() as Map<String, dynamic>;
                      final dName = dData['name'] ?? 'Dokter';
                      final dSpesialis = dData['spesialis'] ?? 'Umum';
                      final dPic = dData['profilePic'];
                      String dInitials = "D";
                      if (dName.isNotEmpty) {
                        dInitials = dName.substring(0, 1).toUpperCase();
                      }
                      return doctorCard(context, doc.id, dName, dSpesialis, dInitials, dPic, dData);
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingScreen(
                          preselectedClinicId: clinicId,
                          preselectedClinicName: name,
                        ),
                      ),
                    );
                  },
                  child: const Text("Buat Janji Temu (Booking)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
          },
        ),
      ),
    );
  }

  // ── Helper: render satu item ulasan dengan avatar foto profil user ──────────
  Widget _buildReviewItem(Map<String, dynamic> r) {
    final userName = r['userName'] ?? 'Pengguna';
    final userAvatar = r['userAvatar'] ?? '';
    final double rating = (r['rating'] ?? 5.0).toDouble();
    final comment = r['comment'] ?? '';
    final imgUrl = r['image_url'] ?? '';
    final date = (r['createdAt'] as Timestamp?)?.toDate();
    final dateStr = date != null ? DateFormat('dd MMM yyyy').format(date) : '';
    final initial = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'P';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto profil user
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: userAvatar.isNotEmpty ? appNetworkImageProvider(userAvatar) : null,
                child: userAvatar.isEmpty
                    ? Text(initial, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        if (dateStr.isNotEmpty)
                          Text(dateStr, style: const TextStyle(color: AppColors.darkGrey, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 14,
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Text(comment, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4)),
            ),
          ],
          // Foto ulasan — hanya tampil jika memang ada foto
          if (imgUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Container(
                height: 90,
                width: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                clipBehavior: Clip.antiAlias,
                child: AppNetworkImage(
                  url: imgUrl,
                  fit: BoxFit.cover,
                  errorWidget: (c, e, s) => Container(
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey.shade100),
        ],
      ),
    );
  }

  Widget _clinicPlaceholder(String initials) {
    return Container(
      width: double.infinity,
      height: 90,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F6F6), Color(0xFFD4EFEF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 32),
      ),
    );
  }


  // 🔹 DOKTER TERPERCAYA SECTION
  Widget _buildDokterTerpercaya(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text("Dokter Terpercaya", style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18)),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'dokter')
                .limit(4)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Belum ada data dokter.", style: TextStyle(color: AppColors.darkGrey)));
              }
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Dokter';
                  final spesialis = data['spesialis'] ?? 'Umum';
                  final profilePic = data['profilePic'] as String?;
                  String initials = "D";
                  if (name.isNotEmpty) {
                    final words = name.replaceAll('drh.', '').trim().split(' ');
                    initials = words.length > 1
                        ? (words[0][0] + words[1][0]).toUpperCase()
                        : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
                  }
                  return doctorCard(context, doc.id, name, spesialis, initials, profilePic, data);
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // 🔹 JADWAL MENDATANG SECTION
  Widget _buildUpcomingSchedule(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Jadwal Mendatang",
              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                print("Error fetching home bookings: ${snapshot.error}");
                return const Text("Gagal memuat jadwal.");
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildFriendlyEmptySchedule(context);
              }

              var docs = snapshot.data!.docs.toList();
              docs.sort((a, b) {
                final tsA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                final tsB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                if (tsA == null || tsB == null) return 0;
                return tsB.compareTo(tsA);
              });

              QueryDocumentSnapshot? activeBooking;
              for (var doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                String s = d['status'] ?? '';
                if (s != 'Selesai') {
                  DateTime? scheduledTime;
                  var scheduledAtField = d['scheduledAt'];
                  if (scheduledAtField is Timestamp) {
                    scheduledTime = scheduledAtField.toDate();
                  } else {
                    var dateField = d['date'];
                    DateTime? parsedDate;
                    if (dateField is Timestamp) {
                      parsedDate = dateField.toDate();
                    }

                    var timeField = d['time']?.toString() ?? '';
                    if (parsedDate != null && timeField.isNotEmpty) {
                      try {
                        final parts = timeField.split(':');
                        final hour = int.parse(parts[0]);
                        final minute = int.parse(parts[1]);
                        scheduledTime = DateTime(
                          parsedDate.year,
                          parsedDate.month,
                          parsedDate.day,
                          hour,
                          minute,
                        );
                      } catch (e) {
                        scheduledTime = parsedDate;
                      }
                    } else if (parsedDate != null) {
                      scheduledTime = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, 23, 59, 59);
                    }
                  }

                  if (scheduledTime != null && scheduledTime.isBefore(DateTime.now())) {
                    continue;
                  }

                  activeBooking = doc;
                  break;
                }
              }

              if (activeBooking == null) {
                return _buildFriendlyEmptySchedule(context);
              }

              final data = activeBooking.data() as Map<String, dynamic>;
              final bookingId = activeBooking.id;
              Color statusColor = AppColors.grey;
              String status = data['status'] ?? 'Menunggu';
              if (status == 'Dikonfirmasi') statusColor = Colors.green;
              if (status == 'Selesai') statusColor = Colors.blue;
              if (status == 'Ditolak') statusColor = Colors.red;
              if (status == 'Sekarang') statusColor = Colors.orange;

              var dateField = data['date'];
              String dateStr = '';
              if (dateField is Timestamp) {
                dateStr = DateFormat('dd MMM yyyy').format(dateField.toDate());
              } else {
                dateStr = dateField?.toString() ?? '';
              }

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                elevation: 0,
                color: Colors.white,
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Center(
                                  child: Container(
                                    width: 40,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text("Detail Booking", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 20),
                                _buildDetailRow(Icons.local_hospital, "Klinik", data['clinicName'] ?? '-'),
                                const SizedBox(height: 10),
                                _buildDetailRow(Icons.person, "Dokter", data['doctorName'] ?? '-'),
                                const SizedBox(height: 10),
                                _buildDetailRow(Icons.pets, "Peliharaan", data['petName'] ?? '-'),
                                const SizedBox(height: 10),
                                _buildDetailRow(Icons.calendar_today, "Jadwal", "$dateStr • ${data['time'] ?? '-'}"),
                                const SizedBox(height: 10),
                                _buildDetailRow(Icons.notes, "Keluhan", data['complaint'] ?? '-'),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                if (status == 'Ditolak') ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(color: Colors.red),
                                            padding: const EdgeInsets.symmetric(vertical: 15),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () async {
                                            await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();
                                            if (context.mounted) Navigator.pop(context);
                                          },
                                          child: const Text("Hapus"),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(vertical: 15),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.pushNamed(context, '/booking');
                                          },
                                          child: const Text("Booking Ulang", style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  )
                                ] else ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Tutup", style: TextStyle(color: Colors.white, fontSize: 16)),
                                    ),
                                  )
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Konsultasi — ${data['doctorName'] ?? '-'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text("$dateStr • ${data['time'] ?? '-'}", style: const TextStyle(fontSize: 12, color: AppColors.darkGrey)),
                              Text(data['clinicName'] ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.darkGrey)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _HomeHeader(
            onGoToProfile: widget.onGoToProfile,
            openSearch: _openSearch,
            showNotificationBadge: _showNotificationBadge,
            notifications: _allNotifications,
            readSet: _readNotificationIds,
            onNotificationOpened: () {
              _markAllNotificationsRead();
            },
          ),
          const SizedBox(height: 16),
          _PetCarousel(
            userId: FirebaseAuth.instance.currentUser?.uid ?? '',
            onGoToProfile: widget.onGoToProfile,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  _buildQuickMenu(context),
                  const SizedBox(height: 20),
                  _buildChatbotCTACard(context),
                  const SizedBox(height: 24),
                  _buildUpcomingSchedule(context),
                  const SizedBox(height: 24),
                  _buildKlinikMitra(context),
                  const SizedBox(height: 24),
                  _buildDokterTerpercaya(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDoctorDetailSheet(BuildContext context, Map<String, dynamic> data, String doctorId) {
    final name = data['name'] ?? 'Dokter';
    final spesialis = data['spesialis'] ?? 'Dokter Hewan Umum';
    final profilePic = data['profilePic'] ?? '';
    final bool isOnline = data['isOnline'] ?? false;
    
    // Simple inline implementation of initials
    String initials = "D";
    if (name.isNotEmpty) {
      final clean = name.replaceAll('drh.', '').trim();
      final words = clean.split(' ');
      initials = words.length > 1
          ? (words[0][0] + words[1][0]).toUpperCase()
          : clean.substring(0, 1).toUpperCase();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, controller) => StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('targetId', isEqualTo: doctorId)
              .snapshots(),
          builder: (context, reviewSnap) {
            double avgRating = 0.0;
            int reviewCount = 0;
            List<String> reviewPhotos = [];

            if (reviewSnap.hasData && reviewSnap.data!.docs.isNotEmpty) {
              double totalRating = 0.0;
              for (var doc in reviewSnap.data!.docs) {
                final r = doc.data() as Map<String, dynamic>;
                totalRating += (r['rating'] ?? 5.0).toDouble();
                final imgUrl = r['image_url'] ?? '';
                if (imgUrl.isNotEmpty) {
                  reviewPhotos.add(imgUrl);
                }
              }
              reviewCount = reviewSnap.data!.docs.length;
              avgRating = totalRating / reviewCount;
            }

            final dynamicRatingStr = reviewCount > 0
                ? "★ ${avgRating.toStringAsFixed(1)} ($reviewCount)"
                : "★ 0.0 (0)";

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),

                  Row(children: [
                    Stack(children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: profilePic.isNotEmpty ? appNetworkImageProvider(profilePic) : null,
                        child: profilePic.isEmpty ? Text(initials, style: const TextStyle(fontSize: 24, color: AppColors.primary, fontWeight: FontWeight.bold)) : null,
                      ),
                      Positioned(bottom: 0, right: 0, child: Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(color: isOnline ? Colors.green : Colors.grey, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      )),
                    ]),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(spesialis, style: const TextStyle(color: AppColors.darkGrey, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isOnline ? Colors.green.shade200 : Colors.grey.shade300),
                            ),
                            child: Text(
                              isOnline ? "ONLINE" : "OFFLINE",
                              style: TextStyle(
                                fontSize: 10,
                                color: isOnline ? Colors.green.shade700 : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(dynamicRatingStr, style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold,
                            color: reviewCount > 0 ? Colors.amber : Colors.grey,
                          )),
                        ],
                      ),
                    ])),
                  ]),

                  const Divider(height: 28),

                  // ── Info klinik (sama dengan consultation_screen) ──
                  if ((data['clinicId'] ?? '').isNotEmpty)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(data['clinicId'])
                          .get(),
                      builder: (context, snap) {
                        if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
                        final c = snap.data!.data() as Map<String, dynamic>;
                        final cName = c['name'] ?? '';
                        final cAddr = c['address'] ?? '';
                        final cPhone = c['phone'] ?? '';
                        if (cName.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Klinik",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.local_hospital, color: AppColors.primary, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(cName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                  ]),
                                  if (cAddr.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      const Icon(Icons.location_on_outlined, color: AppColors.darkGrey, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(cAddr,
                                          style: const TextStyle(fontSize: 13, color: AppColors.darkGrey))),
                                    ]),
                                  ],
                                  if (cPhone.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(children: [
                                      const Icon(Icons.phone_outlined, color: AppColors.darkGrey, size: 16),
                                      const SizedBox(width: 8),
                                      Text(cPhone,
                                          style: const TextStyle(fontSize: 13, color: AppColors.darkGrey)),
                                    ]),
                                  ],
                                ],
                              ),
                            ),
                            const Divider(height: 28),
                          ],
                        );
                      },
                    ),

                  if (reviewPhotos.isNotEmpty) ...[
                    const Divider(height: 28),
                    const Text("Foto dari Ulasan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: reviewPhotos.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 90,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: AppNetworkImage(
                              url: reviewPhotos[index],
                              fit: BoxFit.cover,
                              errorWidget: (c, u, e) => Container(color: Colors.grey.shade100, child: const Icon(Icons.image, color: Colors.grey)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const Divider(height: 28),

                  // ── Beri Rating Section (Google Maps style) ──────────────
                  Builder(builder: (innerCtx) {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) return const SizedBox();
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
                      builder: (context, userSnap) {
                        String uPhoto = '';
                        String uName = 'Pengguna';
                        if (userSnap.hasData && userSnap.data!.exists) {
                          final userData = userSnap.data!.data() as Map<String, dynamic>?;
                          uPhoto = userData?['profilePic'] ?? '';
                          uName = userData?['name'] ?? 'Pengguna';
                        }
                        final uInitial = uName.isNotEmpty ? uName.substring(0, 1).toUpperCase() : 'P';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Ulasan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(innerCtx, MaterialPageRoute(
                                      builder: (_) => AddReviewScreen(
                                        targetId: doctorId,
                                        targetName: name,
                                        targetType: 'dokter',
                                      ),
                                    ));
                                  },
                                  child: const Text('Tambah ulasan',
                                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primaryLight,
                                  backgroundImage: uPhoto.isNotEmpty ? appNetworkImageProvider(uPhoto) : null,
                                  child: uPhoto.isEmpty
                                      ? Text(uInitial, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16))
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Row(
                                  children: List.generate(5, (i) {
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        Navigator.push(innerCtx, MaterialPageRoute(
                                          builder: (_) => AddReviewScreen(
                                            targetId: doctorId,
                                            targetName: name,
                                            targetType: 'dokter',
                                          ),
                                        ));
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 3),
                                        child: Icon(
                                          reviewCount > 0 && i < avgRating.round()
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          color: reviewCount > 0 && i < avgRating.round()
                                              ? Colors.amber
                                              : Colors.grey.shade400,
                                          size: 32,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(innerCtx, MaterialPageRoute(
                                  builder: (_) => AddReviewScreen(
                                    targetId: doctorId,
                                    targetName: name,
                                    targetType: 'dokter',
                                  ),
                                ));
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 20),
                                    SizedBox(width: 8),
                                    Text('Posting foto & komentar',
                                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 20),
                          ],
                        );
                      }
                    );
                  }),

                  if (!reviewSnap.hasData || reviewSnap.data!.docs.isEmpty)
                    const Text("Belum ada ulasan.", style: TextStyle(color: AppColors.darkGrey, fontSize: 13))
                  else
                    Column(
                      children: reviewSnap.data!.docs.map((doc) {
                        final r = doc.data() as Map<String, dynamic>;
                        return _buildReviewItem(r);
                      }).toList(),
                    ),

                  const SizedBox(height: 24),

                  // CTA — Chat
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                      label: const Text("Chat dengan Dokter Ini", style: TextStyle(color: Colors.white, fontSize: 16)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null) return;
                        final chatId = '${currentUser.uid}_$doctorId';
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chatId,
                            receiverId: doctorId,
                            receiverName: name,
                          ),
                        ));
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paw Print Background Painter
// ─────────────────────────────────────────────────────────────────────────────
class PawBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    _drawPaw(canvas, paint, Offset(size.width * 0.1, size.height * 0.2), 30);
    _drawPaw(canvas, paint, Offset(size.width * 0.8, size.height * 0.35), 45);
    _drawPaw(canvas, paint, Offset(size.width * 0.3, size.height * 0.75), 25);
    _drawPaw(canvas, paint, Offset(size.width * 0.85, size.height * 0.85), 35);
  }

  void _drawPaw(Canvas canvas, Paint paint, Offset center, double size) {
    final rect = Rect.fromCenter(center: center, width: size, height: size * 0.85);
    canvas.drawOval(rect, paint);

    final toeSize = size * 0.28;
    canvas.drawCircle(Offset(center.dx - size * 0.38, center.dy - size * 0.3), toeSize, paint);
    canvas.drawCircle(Offset(center.dx - size * 0.14, center.dy - size * 0.52), toeSize, paint);
    canvas.drawCircle(Offset(center.dx + size * 0.14, center.dy - size * 0.52), toeSize, paint);
    canvas.drawCircle(Offset(center.dx + size * 0.38, center.dy - size * 0.3), toeSize, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Header Widget
// ─────────────────────────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  final VoidCallback? onGoToProfile;
  final void Function(BuildContext) openSearch;
  final bool showNotificationBadge;
  final VoidCallback onNotificationOpened;
  final List<Map<String, dynamic>> notifications;
  final Set<String> readSet;

  const _HomeHeader({
    this.onGoToProfile,
    required this.openSearch,
    required this.showNotificationBadge,
    required this.onNotificationOpened,
    required this.notifications,
    required this.readSet,
  });

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return "Baru saja";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} menit yang lalu";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} jam yang lalu";
    } else if (difference.inDays == 1) {
      return "Kemarin";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} hari yang lalu";
    } else {
      return DateFormat('dd MMM yyyy').format(dateTime);
    }
  }

  void _showNotificationSheet(BuildContext context) {
    onNotificationOpened();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 20),
            const Text("Notifikasi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: notifications.isEmpty
                  ? const Center(
                      child: Text("Belum ada notifikasi baru.", style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        final isNew = !readSet.contains(notif['id']);
                        return _notificationItem(
                          notif['text'] ?? '',
                          _formatTimeAgo(notif['time'] as DateTime),
                          isNew,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _notificationItem(String text, String time, bool isNew) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isNew ? AppColors.primaryLight : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications,
              color: isNew ? AppColors.primary : Colors.grey.shade500,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isNew ? FontWeight.bold : FontWeight.w500,
                    color: isNew ? Colors.black87 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 11, color: AppColors.darkGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PawBackgroundPainter(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F9B9C), Color(0xFF1DB0B1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            String userName = "Pengguna";
            String initials = "U";
            String? profilePicUrl;
            String userAddress = "Alamat belum diatur";

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              userName = data['name'] ?? "Pengguna";
              profilePicUrl = data['profilePic'];
              userAddress = data['address'] ?? "Alamat belum diatur";
              if (userName.isNotEmpty) {
                final words = userName.trim().split(' ');
                initials = words.length > 1
                    ? (words[0][0] + words[1][0]).toUpperCase()
                    : userName.substring(0, userName.length >= 2 ? 2 : 1).toUpperCase();
              }
            }

            String _getGreeting() {
              final hour = DateTime.now().hour;
              if (hour >= 5 && hour < 11) {
                return "Selamat pagi";
              } else if (hour >= 11 && hour < 15) {
                return "Selamat siang";
              } else if (hour >= 15 && hour < 18) {
                return "Selamat sore";
              } else {
                return "Selamat malam";
              }
            }
            final greeting = _getGreeting();

            int unreadCount = notifications.where((n) => !readSet.contains(n['id'])).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$greeting, $userName",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                              onPressed: () => _showNotificationSheet(context),
                            ),
                            if (showNotificationBadge && unreadCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                  child: Center(
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          offset: const Offset(0, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          color: Colors.white,
                          elevation: 10,
                          shadowColor: Colors.black26,
                          onSelected: (val) async {
                            if (val == 'profile') {
                              if (onGoToProfile != null) {
                                onGoToProfile!();
                              } else {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()));
                              }
                            } else if (val == 'logout') {
                              await FirebaseAuth.instance.signOut();
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'profile',
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.person_outline, color: AppColors.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                const Text("Profil Saya", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                              ]),
                            ),
                            const PopupMenuDivider(height: 1),
                            PopupMenuItem(
                              value: 'logout',
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Icon(Icons.logout, color: Colors.red.shade400, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Text("Keluar", style: TextStyle(color: Colors.red.shade500, fontWeight: FontWeight.w500, fontSize: 14)),
                              ]),
                            ),
                          ],
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage: (profilePicUrl != null && profilePicUrl.isNotEmpty) ? appNetworkImageProvider(profilePicUrl) : null,
                            child: (profilePicUrl == null || profilePicUrl.isEmpty)
                                ? Text(initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        userAddress,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    readOnly: true,
                    onTap: () => openSearch(context),
                    decoration: InputDecoration(
                      hintText: "Cari dokter, klinik, artikel...",
                      filled: true,
                      fillColor: Colors.transparent,
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: const Icon(Icons.mic_none_outlined, color: AppColors.darkGrey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


}

// ─────────────────────────────────────────────────────────────────────────────
// Pet Carousel Widget — auto-scroll, real-time foto, semua peliharaan
// ─────────────────────────────────────────────────────────────────────────────
class _PetCarousel extends StatefulWidget {
  final String userId;
  final VoidCallback? onGoToProfile;
  const _PetCarousel({required this.userId, this.onGoToProfile});

  @override
  State<_PetCarousel> createState() => _PetCarouselState();
}

class _PetCarouselState extends State<_PetCarousel> {
  late final PageController _pageController;
  Stream<QuerySnapshot>? _petsStream;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.93);
    if (widget.userId.isNotEmpty) {
      _petsStream = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('pets')
          .snapshots();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer(int count) {
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentPage + 1) % count;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  String _getEmojiForType(String type) {
    final t = type.toLowerCase().trim();
    if (t.contains('kucing') || t.contains('cat') || t.contains('kitten')) return '🐱';
    if (t.contains('anjing') || t.contains('dog') || t.contains('puppy')) return '🐶';
    if (t.contains('kelinci') || t.contains('rabbit') || t.contains('bunny')) return '🐰';
    if (t.contains('hamster')) return '🐹';
    if (t.contains('burung') || t.contains('bird')) return '🐦';
    return '🐾';
  }

  Widget _emojiBox(String emoji) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.secondaryOrangeLight,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 26)),
    );
  }

  Widget _buildPetCard(BuildContext context, Map<String, dynamic> pet) {
    final String petPic = pet['petPic'] as String? ?? '';
    final String emoji = _getEmojiForType(pet['type'] ?? '');
    final String name = pet['name'] ?? 'Peliharaan';
    final String status = pet['status'] ?? 'Sehat';
    final String vaccineDate = pet['vaccineDate'] ?? '';

    String vaccineText = "Vaksin: -";
    if (vaccineDate.isNotEmpty && vaccineDate != '-') {
      try {
        final parsed = DateFormat('dd MMM yyyy').parse(vaccineDate);
        final diff = parsed.difference(DateTime.now()).inDays;
        if (diff == 0) {
          vaccineText = "Vaksin Rabies / Hari ini";
        } else if (diff > 0) {
          vaccineText = "Vaksin Rabies / $diff hari lagi";
        } else {
          vaccineText = "Vaksin Rabies / Terlewat ${diff.abs()} hari";
        }
      } catch (e) {
        vaccineText = "Vaksin Rabies / $vaccineDate";
      }
    } else {
      vaccineText = "Vaksin Rabies / Belum terjadwal";
    }

    String checkupText = "Cek Kesehatan / 30 Mei 2026";
    if (name.isNotEmpty) {
      final stableDay = (name.hashCode.abs() % 28) + 1;
      checkupText = "Cek Kesehatan / $stableDay Jun 2026";
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: petPic.isNotEmpty
                      ? AppNetworkImage(
                          url: petPic,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 50,
                            height: 50,
                            color: AppColors.secondaryOrangeLight,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (ctx, url, err) => _emojiBox(emoji),
                        )
                      : _emojiBox(emoji),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: status == 'Sehat' ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: status == 'Sehat' ? Colors.green.shade200 : Colors.orange.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: status == 'Sehat' ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: status == 'Sehat' ? Colors.green.shade700 : Colors.orange.shade700,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${pet['type'] ?? ''} • ${pet['age'] ?? ''} • ${pet['breed'] ?? ''}",
                        style: const TextStyle(fontSize: 11, color: AppColors.darkGrey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.grey),
                  onPressed: widget.onGoToProfile,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.vaccines_outlined, size: 13, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            vaccineText,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.health_and_safety_outlined, size: 13, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            checkupText,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_petsStream == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: _petsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200, width: 1.5),
              ),
              elevation: 0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.pets, color: AppColors.primary),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Belum ada peliharaan",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Tambahkan profil anabulmu di menu Profil",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final pets = snapshot.data!.docs;
        final int count = pets.length;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startTimer(count);
        });

        if (count == 1) {
          final pet = pets.first.data() as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 132,
              child: _buildPetCard(context, pet),
            ),
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 132,
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: count,
                onPageChanged: (i) {
                  if (mounted) setState(() => _currentPage = i);
                },
                itemBuilder: (context, index) {
                  final pet = pets[index].data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildPetCard(context, pet),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(count, (i) {
                final bool active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
