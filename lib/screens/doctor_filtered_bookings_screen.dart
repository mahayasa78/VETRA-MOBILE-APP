import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';

class DoctorFilteredBookingsScreen extends StatelessWidget {
  final String filterType; // 'Dikonfirmasi', 'Menunggu', 'Bulan Ini'
  
  const DoctorFilteredBookingsScreen({super.key, required this.filterType});

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
        Navigator.pop(context); // Close the bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status jadwal berhasil diubah menjadi $newStatus')),
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
                const Text("Detail Booking Pasien", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      child: Text(
                        status,
                        style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                if (status == 'Menunggu') ...[
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
                          onPressed: () => _updateBookingStatus(context, bookingId, 'Ditolak'),
                          child: const Text("Tolak"),
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
                        backgroundColor: AppColors.secondaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
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
  }

  Widget _detailRow(IconData icon, String title, String value) {
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
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Silakan login"));

    String appBarTitle = "Daftar Pasien";
    if (filterType == 'Dikonfirmasi') appBarTitle = "Pasien Dikonfirmasi";
    if (filterType == 'Menunggu') appBarTitle = "Pasien Menunggu";
    if (filterType == 'Bulan Ini') appBarTitle = "Jadwal Bulan Ini";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            return const Center(child: Text("Belum ada data."));
          }

          final now = DateTime.now();
          var bookings = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? '';
            
            if (filterType == 'Dikonfirmasi') {
              return status == 'Dikonfirmasi';
            } else if (filterType == 'Menunggu') {
              return status == 'Menunggu';
            } else if (filterType == 'Bulan Ini') {
              Timestamp? dateTs = data['scheduledAt'] ?? data['date'];
              if (dateTs != null) {
                final dt = dateTs.toDate();
                return dt.month == now.month && dt.year == now.year;
              }
              return false;
            }
            return true;
          }).toList();

          bookings.sort((a, b) {
            final tsA = (a.data() as Map)['scheduledAt'] ?? (a.data() as Map)['createdAt'];
            final tsB = (b.data() as Map)['scheduledAt'] ?? (b.data() as Map)['createdAt'];
            if (tsA == null || tsB == null) return 0;
            return (tsA as Timestamp).compareTo(tsB as Timestamp); // Ascending
          });

          if (bookings.isEmpty) {
            return const Center(child: Text("Tidak ada pasien di kategori ini."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final data = bookings[index].data() as Map<String, dynamic>;
              
              final patientName = data['userName'] ?? 'Pasien';
              final petName = data['petName'] ?? '-';
              final timeStr = data['time'] ?? '';
              final status = data['status'] ?? 'Menunggu';

              var dateField = data['date'];
              String dateStr = '';
              if (dateField is Timestamp) {
                dateStr = DateFormat('dd MMM yyyy').format(dateField.toDate());
              } else {
                dateStr = dateField?.toString() ?? '';
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _showBookingDetails(context, data, bookings[index].id),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                patientName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                        const Divider(),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.pets, size: 16, color: AppColors.darkGrey),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(petName, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: AppColors.darkGrey),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                "$dateStr • $timeStr",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
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
