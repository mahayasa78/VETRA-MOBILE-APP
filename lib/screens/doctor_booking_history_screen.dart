import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';

class DoctorBookingHistoryScreen extends StatefulWidget {
  const DoctorBookingHistoryScreen({super.key});

  @override
  State<DoctorBookingHistoryScreen> createState() => _DoctorBookingHistoryScreenState();
}

class _DoctorBookingHistoryScreenState extends State<DoctorBookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'dikonfirmasi':
        return Colors.green;
      case 'selesai':
        return Colors.blue;
      case 'ditolak':
        return Colors.red;
      case 'sekarang':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _updateBookingStatus(BuildContext context, String bookingId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': newStatus,
      });
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status berhasil diubah menjadi $newStatus')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status: $e')),
        );
      }
    }
  }

  void _showBookingDetails(BuildContext context, Map<String, dynamic> data, String bookingId) {
    final patientName = data['userName'] ?? 'Pasien';
    final clinicName = data['clinicName'] ?? 'Klinik';
    final status = data['status'] ?? 'Menunggu';
    final timeStr = data['time'] ?? '';
    final petName = data['petName'] ?? '-';
    final complaint = data['complaint'] ?? '-';

    var dateField = data['date'];
    String dateStr = '';
    if (dateField is Timestamp) {
      dateStr = DateFormat('dd MMM yyyy').format(dateField.toDate());
    } else {
      dateStr = dateField?.toString() ?? '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Detail Pasien", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _detailRow(Icons.person, "Pasien", patientName),
                const SizedBox(height: 10),
                _detailRow(Icons.local_hospital, "Klinik", clinicName),
                const SizedBox(height: 10),
                _detailRow(Icons.pets, "Peliharaan", petName),
                const SizedBox(height: 10),
                _detailRow(Icons.calendar_today, "Jadwal", "$dateStr • $timeStr"),
                const SizedBox(height: 10),
                _detailRow(Icons.notes, "Keluhan", complaint),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(status, style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (status == 'Menunggu') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _updateBookingStatus(context, bookingId, 'Ditolak'),
                          child: const Text("Tolak"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _updateBookingStatus(context, bookingId, 'Dikonfirmasi'),
                          child: const Text("Konfirmasi", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                ] else if (status == 'Dikonfirmasi' || status == 'Sekarang') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => _updateBookingStatus(context, bookingId, 'Selesai'),
                      child: const Text("Tandai Selesai", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  )
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tutup", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  )
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        SizedBox(width: 80, child: Text(title, style: const TextStyle(color: AppColors.darkGrey))),
        const Text(": "),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildBookingCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final patientName = data['userName'] ?? 'Pasien';
    final petName = data['petName'] ?? '-';
    final timeStr = data['time'] ?? '';
    final status = data['status'] ?? 'Menunggu';
    final complaint = data['complaint'] ?? '-';

    var dateField = data['date'];
    String dateStr = '';
    if (dateField is Timestamp) {
      dateStr = DateFormat('dd MMM yyyy').format(dateField.toDate());
    } else {
      dateStr = dateField?.toString() ?? '';
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.grey, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showBookingDetails(context, data, doc.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      patientName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )
                ],
              ),
              const Divider(height: 14),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.darkGrey),
                  const SizedBox(width: 4),
                  Text("$dateStr • $timeStr", style: const TextStyle(fontSize: 13, color: AppColors.darkGrey)),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.pets, size: 14, color: AppColors.darkGrey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(petName, style: const TextStyle(fontSize: 13, color: AppColors.darkGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              if (complaint != '-') ...[
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes, size: 14, color: AppColors.darkGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        complaint,
                        style: const TextStyle(fontSize: 13, color: AppColors.darkGrey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTab(User currentUser) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('doctorId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState("Belum ada jadwal aktif.");
        }

        // Filter active only (Menunggu, Dikonfirmasi, Sekarang)
        var bookings = snapshot.data!.docs.where((doc) {
          final status = (doc.data() as Map)['status'] ?? '';
          return status == 'Menunggu' || status == 'Dikonfirmasi' || status == 'Sekarang';
        }).toList();

        // Sort by scheduledAt ascending (nearest first)
        bookings.sort((a, b) {
          final tsA = (a.data() as Map)['scheduledAt'] ?? (a.data() as Map)['date'];
          final tsB = (b.data() as Map)['scheduledAt'] ?? (b.data() as Map)['date'];
          if (tsA == null) return 1;
          if (tsB == null) return -1;
          return (tsA as Timestamp).compareTo(tsB as Timestamp);
        });

        if (bookings.isEmpty) {
          return _emptyState("Tidak ada jadwal aktif saat ini.");
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: bookings.length,
          itemBuilder: (context, index) => _buildBookingCard(context, bookings[index]),
        );
      },
    );
  }

  Widget _buildHistoryTab(User currentUser) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 12, 15, 6),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Cari nama pasien, peliharaan, atau keluhan...",
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppColors.darkGrey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('doctorId', isEqualTo: currentUser.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _emptyState("Belum ada riwayat konsultasi.");
              }

              // Filter completed/rejected only
              var bookings = snapshot.data!.docs.where((doc) {
                final status = (doc.data() as Map)['status'] ?? '';
                return status == 'Selesai' || status == 'Ditolak';
              }).toList();

              // Sort by scheduledAt descending (most recent first)
              bookings.sort((a, b) {
                final tsA = (a.data() as Map)['scheduledAt'] ?? (a.data() as Map)['date'];
                final tsB = (b.data() as Map)['scheduledAt'] ?? (b.data() as Map)['date'];
                if (tsA == null) return 1;
                if (tsB == null) return -1;
                return (tsB as Timestamp).compareTo(tsA as Timestamp);
              });

              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                bookings = bookings.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['userName'] ?? '').toString().toLowerCase();
                  final pet = (data['petName'] ?? '').toString().toLowerCase();
                  final complaint = (data['complaint'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) ||
                      pet.contains(_searchQuery) ||
                      complaint.contains(_searchQuery);
                }).toList();
              }

              return bookings.isEmpty
                  ? _emptyState(_searchQuery.isNotEmpty ? "Tidak ditemukan hasil pencarian." : "Belum ada riwayat konsultasi.")
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(15, 6, 15, 15),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) => _buildBookingCard(context, bookings[index]),
                    );
            },
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.darkGrey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Silakan login"));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Jadwal Konsultasi"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.primaryLight,
          indicatorColor: AppColors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Aktif"),
            Tab(text: "Riwayat Offline"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTab(currentUser),
          _buildHistoryTab(currentUser),
        ],
      ),
    );
  }
}
