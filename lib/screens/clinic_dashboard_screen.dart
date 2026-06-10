import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import 'clinic_filtered_bookings_screen.dart';
import 'clinic_profile_screen.dart';

class ClinicDashboardScreen extends StatelessWidget {
  const ClinicDashboardScreen({super.key});

  Widget _buildStatCard(BuildContext context, String value, String label, Color color, String filterType, String clinicId) {
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
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ClinicFilteredBookingsScreen(filterType: filterType, clinicId: clinicId),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 5),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.darkGrey), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Silakan login kembali."));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Center(child: Text("Data klinik tidak ditemukan."));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final String name = userData['name'] ?? 'Klinik';
        final String address = userData['address'] ?? 'Alamat belum diatur';
        final bool isClinicOpen = userData['isClinicOpen'] ?? true;
        final String profilePic = userData['profilePic'] ?? '';

        String initials = "K";
        if (name.isNotEmpty) {
          var words = name.trim().split(' ');
          initials = words.length > 1
              ? (words[0][0] + words[1][0]).toUpperCase()
              : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('clinicId', isEqualTo: currentUser.uid)
              .snapshots(),
          builder: (context, bookingSnapshot) {
            int totalKonfirmasi = 0;
            int totalMenunggu = 0;
            int totalBulanIni = 0;
            List<QueryDocumentSnapshot> recentActive = [];

            if (bookingSnapshot.hasData) {
              final all = bookingSnapshot.data!.docs;
              final now = DateTime.now();

              totalKonfirmasi = all.where((d) => (d.data() as Map)['status'] == 'Dikonfirmasi').length;
              totalMenunggu = all.where((d) => (d.data() as Map)['status'] == 'Menunggu').length;
              totalBulanIni = all.where((d) {
                final ts = ((d.data() as Map)['scheduledAt'] ?? (d.data() as Map)['date']) as Timestamp?;
                if (ts == null) return false;
                final dt = ts.toDate();
                return dt.month == now.month && dt.year == now.year;
              }).length;

              var sorted = all.toList();
              sorted.sort((a, b) {
                final tsA = ((a.data() as Map)['scheduledAt'] ?? (a.data() as Map)['date']) as Timestamp?;
                final tsB = ((b.data() as Map)['scheduledAt'] ?? (b.data() as Map)['date']) as Timestamp?;
                if (tsA == null) return 1;
                if (tsB == null) return -1;
                return tsA.compareTo(tsB); // ascending: nearest first
              });
              recentActive = sorted.where((d) {
                final s = (d.data() as Map)['status'];
                return s == 'Menunggu' || s == 'Dikonfirmasi';
              }).take(5).toList();
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'dokter')
                  .where('clinicId', isEqualTo: currentUser.uid)
                  .where('isOnline', isEqualTo: true)
                  .snapshots(),
              builder: (context, doctorSnapshot) {
                final onlineDoctors = doctorSnapshot.data?.docs ?? [];

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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppColors.white)),
                                  const SizedBox(height: 4),
                                  Text(address, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              offset: const Offset(0, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              color: Colors.white,
                              elevation: 10,
                              shadowColor: Colors.black26,
                              onSelected: (val) async {
                                if (val == 'profile') {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ClinicProfileScreen()));
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
                                radius: 25,
                                backgroundColor: AppColors.primaryLight,
                                backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                                child: profilePic.isEmpty
                                    ? Text(initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16))
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🟢 STATUS KLINIK
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: AppColors.grey)),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Status Klinik", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(
                                      isClinicOpen ? "Buka Sekarang" : "Sedang Tutup",
                                      style: TextStyle(color: isClinicOpen ? AppColors.primary : AppColors.darkGrey, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: isClinicOpen,
                                  activeColor: AppColors.primary,
                                  activeTrackColor: AppColors.primaryLight,
                                  onChanged: (val) async {
                                    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({'isClinicOpen': val});
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // 📊 STATISTIK
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(child: _buildStatCard(context, "$totalKonfirmasi", "Dikonfirmasi", AppColors.primary, 'Dikonfirmasi', currentUser.uid)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatCard(context, "$totalMenunggu", "Menunggu", AppColors.secondaryOrange, 'Menunggu', currentUser.uid)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatCard(context, "$totalBulanIni", "Bulan Ini", AppColors.secondaryGreen, 'Bulan Ini', currentUser.uid)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // 👨‍⚕️ DOKTER ON DUTY
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(alignment: Alignment.centerLeft, child: Text("Dokter On Duty", style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18))),
                      ),
                      const SizedBox(height: 10),
                      if (onlineDoctors.isEmpty)
                        const Padding(padding: EdgeInsets.all(16), child: Text("Tidak ada dokter yang sedang aktif."))
                      else
                        ...onlineDoctors.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          final docName = d['name'] ?? 'Dokter';
                          final spesialis = d['spesialis'] ?? 'Umum';
                          String ini = "D";
                          if (docName.isNotEmpty) {
                            final w = docName.replaceAll('drh.', '').trim().split(' ');
                            ini = w.length > 1 ? (w[0][0] + w[1][0]).toUpperCase() : docName[0].toUpperCase();
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.grey)),
                              elevation: 0,
                              child: ListTile(
                                leading: CircleAvatar(backgroundColor: AppColors.primaryLight, child: Text(ini, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                                title: Text(docName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(spesialis),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                                  child: const Text("Online", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),

                      const SizedBox(height: 25),

                      // 📋 BOOKING AKTIF TERKINI
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(alignment: Alignment.centerLeft, child: Text("Jadwal Terkini", style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18))),
                      ),
                      const SizedBox(height: 10),
                      if (recentActive.isEmpty)
                        const Padding(padding: EdgeInsets.all(16), child: Text("Belum ada jadwal aktif."))
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: recentActive.map((doc) {
                              final d = doc.data() as Map<String, dynamic>;
                              final patientName = d['userName'] ?? 'Pasien';
                              final doctorName = d['doctorName'] ?? 'Dokter';
                              final time = d['time'] ?? '';
                              final status = d['status'] ?? 'Menunggu';
                              var dateField = d['date'];
                              String dateStr = '';
                              if (dateField is Timestamp) dateStr = DateFormat('dd MMM').format(dateField.toDate());

                              Color sc = AppColors.darkGrey;
                              if (status == 'Dikonfirmasi') sc = AppColors.primary;
                              if (status == 'Menunggu') sc = AppColors.secondaryOrange;
                              if (status == 'Selesai') sc = AppColors.secondaryGreen;
                              if (status == 'Ditolak') sc = AppColors.secondaryRed;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.grey)),
                                elevation: 0,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                                    child: Text(time, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                                  ),
                                  title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text("$doctorName • $dateStr", style: const TextStyle(fontSize: 12)),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                    child: Text(status, style: TextStyle(color: sc, fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
