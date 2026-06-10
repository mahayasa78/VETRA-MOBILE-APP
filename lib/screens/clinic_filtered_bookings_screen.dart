import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';

class ClinicFilteredBookingsScreen extends StatelessWidget {
  final String filterType; // 'Dikonfirmasi', 'Menunggu', 'Bulan Ini'
  final String clinicId;

  const ClinicFilteredBookingsScreen({
    super.key,
    required this.filterType,
    required this.clinicId,
  });

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

  @override
  Widget build(BuildContext context) {
    String title = "Daftar Booking";
    if (filterType == 'Dikonfirmasi') title = "Pasien Dikonfirmasi";
    if (filterType == 'Menunggu') title = "Menunggu Konfirmasi";
    if (filterType == 'Bulan Ini') title = "Jadwal Bulan Ini";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('clinicId', isEqualTo: clinicId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada data."));
          }

          final now = DateTime.now();
          var bookings = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? '';
            if (filterType == 'Dikonfirmasi') return status == 'Dikonfirmasi';
            if (filterType == 'Menunggu') return status == 'Menunggu';
            if (filterType == 'Bulan Ini') {
              final ts = (data['scheduledAt'] ?? data['date']) as Timestamp?;
              if (ts == null) return false;
              final dt = ts.toDate();
              return dt.month == now.month && dt.year == now.year;
            }
            return true;
          }).toList();

          bookings.sort((a, b) {
            final tsA = ((a.data() as Map)['scheduledAt'] ?? (a.data() as Map)['date']) as Timestamp?;
            final tsB = ((b.data() as Map)['scheduledAt'] ?? (b.data() as Map)['date']) as Timestamp?;
            if (tsA == null) return 1;
            if (tsB == null) return -1;
            return tsA.compareTo(tsB); // ascending
          });

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  const Text("Tidak ada booking di kategori ini.", style: TextStyle(color: AppColors.darkGrey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final data = bookings[index].data() as Map<String, dynamic>;
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
                  onTap: () => _showDetail(context, data, bookings[index].id),
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
            },
          );
        },
      ),
    );
  }
}
