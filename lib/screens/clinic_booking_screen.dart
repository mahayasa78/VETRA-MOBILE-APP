import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';

class ClinicBookingScreen extends StatefulWidget {
  const ClinicBookingScreen({super.key});

  @override
  State<ClinicBookingScreen> createState() => _ClinicBookingScreenState();
}

class _ClinicBookingScreenState extends State<ClinicBookingScreen>
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'dikonfirmasi': return Colors.green;
      case 'selesai': return Colors.blue;
      case 'ditolak': return Colors.red;
      case 'menunggu': return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _updateStatus(BuildContext context, String bookingId, String newStatus) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'status': newStatus});
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status diubah menjadi $newStatus')));
    }
  }

  void _showDetail(BuildContext context, Map<String, dynamic> data, String bookingId) {
    final patientName = data['userName'] ?? 'Pasien';
    final doctorName = data['doctorName'] ?? 'Dokter';
    final status = data['status'] ?? 'Menunggu';
    final timeStr = data['time'] ?? '';
    final petName = data['petName'] ?? '-';
    final complaint = data['complaint'] ?? '-';
    var dateField = data['date'];
    String dateStr = '';
    if (dateField is Timestamp) dateStr = DateFormat('dd MMM yyyy').format(dateField.toDate());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              const Text("Detail Booking", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _row(Icons.person, "Pasien", patientName),
              const SizedBox(height: 10),
              _row(Icons.medical_services, "Dokter", doctorName),
              const SizedBox(height: 10),
              _row(Icons.pets, "Peliharaan", petName),
              const SizedBox(height: 10),
              _row(Icons.calendar_today, "Jadwal", "$dateStr • $timeStr"),
              const SizedBox(height: 10),
              _row(Icons.notes, "Keluhan", complaint),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(status, style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (status == 'Menunggu') ...[
                Row(children: [
                  Expanded(child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => _updateStatus(ctx, bookingId, 'Ditolak'),
                    child: const Text("Tolak"),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => _updateStatus(ctx, bookingId, 'Dikonfirmasi'),
                    child: const Text("Konfirmasi", style: TextStyle(color: Colors.white)),
                  )),
                ]),
              ] else if (status == 'Dikonfirmasi') ...[
                SizedBox(width: double.infinity, child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () => _updateStatus(ctx, bookingId, 'Selesai'),
                  child: const Text("Tandai Selesai", style: TextStyle(color: Colors.white)),
                )),
              ] else ...[
                SizedBox(width: double.infinity, child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Tutup", style: TextStyle(color: Colors.white)),
                )),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String title, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 10),
      SizedBox(width: 80, child: Text(title, style: const TextStyle(color: AppColors.darkGrey))),
      const Text(": "),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
    ]);
  }

  Widget _buildCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final patientName = data['userName'] ?? 'Pasien';
    final doctorName = data['doctorName'] ?? 'Dokter';
    final timeStr = data['time'] ?? '';
    final status = data['status'] ?? 'Menunggu';
    final petName = data['petName'] ?? '-';
    var dateField = data['date'];
    String dateStr = '';
    if (dateField is Timestamp) dateStr = DateFormat('dd MMM yyyy').format(dateField.toDate());

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.grey)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(context, data, doc.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(status, style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const Divider(height: 14),
              Row(children: [
                const Icon(Icons.medical_services, size: 14, color: AppColors.darkGrey),
                const SizedBox(width: 4),
                Expanded(child: Text(doctorName, style: const TextStyle(fontSize: 13, color: AppColors.darkGrey), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time, size: 14, color: AppColors.darkGrey),
                const SizedBox(width: 4),
                Text("$dateStr • $timeStr", style: const TextStyle(fontSize: 13, color: AppColors.darkGrey)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.pets, size: 14, color: AppColors.darkGrey),
                const SizedBox(width: 4),
                Expanded(child: Text(petName, style: const TextStyle(fontSize: 13, color: AppColors.darkGrey), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String msg) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text(msg, style: const TextStyle(color: AppColors.darkGrey)),
    ],
  ));

  Widget _buildActiveTab(String clinicId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').where('clinicId', isEqualTo: clinicId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData) return _emptyState("Belum ada booking.");

        var bookings = snapshot.data!.docs.where((d) {
          final s = (d.data() as Map)['status'];
          return s == 'Menunggu' || s == 'Dikonfirmasi' || s == 'Sekarang';
        }).toList();

        bookings.sort((a, b) {
          final tsA = ((a.data() as Map)['scheduledAt'] ?? (a.data() as Map)['date']) as Timestamp?;
          final tsB = ((b.data() as Map)['scheduledAt'] ?? (b.data() as Map)['date']) as Timestamp?;
          if (tsA == null) return 1;
          if (tsB == null) return -1;
          return tsA.compareTo(tsB);
        });

        if (bookings.isEmpty) return _emptyState("Tidak ada booking aktif saat ini.");
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: bookings.length,
          itemBuilder: (ctx, i) => _buildCard(ctx, bookings[i]),
        );
      },
    );
  }

  Widget _buildHistoryTab(String clinicId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').where('clinicId', isEqualTo: clinicId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData) return _emptyState("Belum ada riwayat.");

        var bookings = snapshot.data!.docs.where((d) {
          final s = (d.data() as Map)['status'];
          return s == 'Selesai' || s == 'Ditolak';
        }).toList();

        bookings.sort((a, b) {
          final tsA = ((a.data() as Map)['scheduledAt'] ?? (a.data() as Map)['date']) as Timestamp?;
          final tsB = ((b.data() as Map)['scheduledAt'] ?? (b.data() as Map)['date']) as Timestamp?;
          if (tsA == null) return 1;
          if (tsB == null) return -1;
          return tsB.compareTo(tsA); // descending
        });

        if (_searchQuery.isNotEmpty) {
          bookings = bookings.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['userName'] ?? '').toString().toLowerCase().contains(_searchQuery) ||
                (data['doctorName'] ?? '').toString().toLowerCase().contains(_searchQuery) ||
                (data['petName'] ?? '').toString().toLowerCase().contains(_searchQuery);
          }).toList();
        }

        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari pasien, dokter, atau peliharaan...",
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.darkGrey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => _searchController.clear())
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: bookings.isEmpty
                ? _emptyState(_searchQuery.isNotEmpty ? "Tidak ada hasil pencarian." : "Belum ada riwayat booking.")
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 6, 15, 15),
                    itemCount: bookings.length,
                    itemBuilder: (ctx, i) => _buildCard(ctx, bookings[i]),
                  ),
          ),
        ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Silakan login"));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Booking Masuk"),
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
            Tab(text: "Riwayat"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTab(currentUser.uid),
          _buildHistoryTab(currentUser.uid),
        ],
      ),
    );
  }
}
