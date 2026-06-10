import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../utils/app_network_image.dart';
import 'chat_screen.dart';
import 'doctor_filtered_bookings_screen.dart';
import 'doctor_profile_screen.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  Widget _buildStatCard(BuildContext context, String value, String label, Color color, String filterType) {
    return Card(
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorFilteredBookingsScreen(filterType: filterType),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 5),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.darkGrey), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJadwalTile(String id, String time, String patientName, String type, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: AppColors.grey, width: 1),
        ),
        elevation: 0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: Text(time, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
          title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(type),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("Silakan login kembali."));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Center(child: Text("Data dokter tidak ditemukan."));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final String name = userData['name'] ?? 'Dokter';
        final String spesialis = userData['spesialis'] ?? 'Umum';
        
        String initials = "D";
        if (name.isNotEmpty) {
          var words = name.replaceAll('drh. ', '').trim().split(' ');
          if (words.length > 1) {
            initials = (words[0][0] + words[1][0]).toUpperCase();
          } else {
            initials = name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('doctorId', isEqualTo: currentUser.uid)
              .snapshots(),
          builder: (context, bookingSnapshot) {
            int totalPasien = 0;
            int totalMenunggu = 0;
            int totalBulanIni = 0;
            List<QueryDocumentSnapshot> todayBookings = [];

            if (bookingSnapshot.hasData) {
              final allBookings = bookingSnapshot.data!.docs;
              
              final now = DateTime.now();
              
              totalPasien = allBookings.where((doc) {
                final status = (doc.data() as Map)['status'];
                return status == 'Dikonfirmasi';
              }).length;

              totalMenunggu = allBookings.where((doc) {
                final status = (doc.data() as Map)['status'];
                return status == 'Menunggu';
              }).length;

              totalBulanIni = allBookings.where((doc) {
                final data = doc.data() as Map;
                Timestamp? dateTs = data['scheduledAt'] ?? data['date'];
                if (dateTs != null) {
                  final dt = dateTs.toDate();
                  return dt.month == now.month && dt.year == now.year;
                }
                return false;
              }).length;
              
              // Sort locally by scheduledAt and filter active bookings
              var sortedDocs = allBookings.toList();
              sortedDocs.sort((a, b) {
                final tsA = (a.data() as Map)['scheduledAt'] ?? (a.data() as Map)['createdAt'];
                final tsB = (b.data() as Map)['scheduledAt'] ?? (b.data() as Map)['createdAt'];
                if (tsA == null || tsB == null) return 0;
                return (tsA as Timestamp).compareTo(tsB as Timestamp); // Ascending (nearest first)
              });

              // Just take first 5 active
              todayBookings = sortedDocs.where((doc) {
                final status = (doc.data() as Map)['status'];
                return status != 'Selesai' && status != 'Ditolak';
              }).take(5).toList(); 
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  // 🔵 HEADER
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppColors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              spesialis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryLight),
                            ),
                          ],
                        ),
                        PopupMenuButton<String>(
                          offset: const Offset(0, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          color: Colors.white,
                          elevation: 10,
                          shadowColor: Colors.black26,
                          onSelected: (val) async {
                            if (val == 'profile') {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorProfileScreen()));
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
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage: userData['profilePic'] != null && userData['profilePic'].toString().isNotEmpty
                                ? appNetworkImageProvider(userData['profilePic'])
                                : null,
                            radius: 25,
                            child: userData['profilePic'] != null && userData['profilePic'].toString().isNotEmpty
                                ? null
                                : Text(
                                    initials,
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 📊 STATISTIK
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(child: _buildStatCard(context, "$totalPasien", "Total Pasien", AppColors.primary, 'Dikonfirmasi')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildStatCard(context, "$totalMenunggu", "Menunggu", AppColors.secondaryOrange, 'Menunggu')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildStatCard(context, "$totalBulanIni", "Bulan Ini", AppColors.secondaryGreen, 'Bulan Ini')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 📅 JADWAL HARI INI
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Jadwal Terkini",
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (todayBookings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text("Belum ada jadwal pasien yang aktif."),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: todayBookings.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final time = data['time'] ?? '00:00';
                          final status = data['status'] ?? 'Menunggu';
                          final patientName = data['userName'] ?? "Pasien"; 
                          Color statusColor = AppColors.darkGrey;
                          if (status == 'Selesai') statusColor = AppColors.secondaryGreen;
                          if (status == 'Dikonfirmasi' || status == 'Sekarang') statusColor = AppColors.primary;
                          if (status == 'Ditolak') statusColor = AppColors.secondaryRed;
                          if (status == 'Menunggu') statusColor = AppColors.secondaryOrange;

                          return _buildJadwalTile(doc.id, time, patientName, "Konsultasi", status, statusColor);
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 25),

                  // 💬 PESAN MASUK
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Pesan Masuk",
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .where('doctorId', isEqualTo: currentUser.uid)
                        .snapshots(),
                    builder: (context, chatSnapshot) {
                      if (chatSnapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text("Error: ${chatSnapshot.error}"),
                        );
                      }
                      if (chatSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text("Belum ada pesan masuk.", style: TextStyle(color: AppColors.darkGrey)),
                        );
                      }

                      final chats = chatSnapshot.data!.docs.toList();
                      chats.sort((a, b) {
                        final tsA = (a.data() as Map<String, dynamic>)['lastTimestamp'] as Timestamp?;
                        final tsB = (b.data() as Map<String, dynamic>)['lastTimestamp'] as Timestamp?;
                        if (tsA == null || tsB == null) return 0;
                        return tsB.compareTo(tsA);
                      });

                      return Column(
                        children: chats.take(3).map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final userName = data['userName'] ?? 'User';
                          final lastMessage = data['lastMessage'] ?? '';
                          final userId = data['userId'] ?? '';
                          final int unreadCount = (data['unreadDoctor'] ?? 0) as int;
                          // lastSenderId: siapa yang mengirim pesan terakhir
                          final lastSenderId = data['lastSenderId'] ?? '';
                          final bool isSentByMe = lastSenderId == currentUser.uid;
                          // unreadUser: apakah user sudah baca pesan terakhir dari dokter
                          final int unreadByUser = (data['unreadUser'] ?? 0) as int;

                          Timestamp? ts = data['lastTimestamp'];
                          String timeStr = "";
                          if (ts != null) {
                            final dt = ts.toDate();
                            final now = DateTime.now();
                            timeStr = (dt.year == now.year && dt.month == now.month && dt.day == now.day)
                                ? DateFormat('HH:mm').format(dt)
                                : DateFormat('dd/MM').format(dt);
                          }

                          String initials = "U";
                          if (userName.isNotEmpty) {
                            initials = userName.substring(0, 1).toUpperCase();
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      chatId: doc.id,
                                      receiverId: userId,
                                      receiverName: userName,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: AppColors.grey, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.primaryLight,
                                      child: Text(initials,
                                          style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  userName,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                timeStr,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: unreadCount > 0 ? AppColors.primary : Colors.grey,
                                                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              // Centang untuk pesan yang dikirim dokter
                                              if (isSentByMe) ...[
                                                Icon(
                                                  Icons.done_all,
                                                  size: 14,
                                                  // Abu = user belum baca, Biru = user sudah baca
                                                  color: unreadByUser == 0
                                                      ? Colors.blue
                                                      : Colors.grey.shade400,
                                                ),
                                                const SizedBox(width: 4),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  lastMessage,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                                                    fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              if (unreadCount > 0) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.all(5),
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Text(
                                                    unreadCount > 99 ? "99+" : "$unreadCount",
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
