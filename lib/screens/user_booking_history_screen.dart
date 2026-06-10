import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_upload_service.dart';
import '../utils/app_colors.dart';

class UserBookingHistoryScreen extends StatelessWidget {
  const UserBookingHistoryScreen({super.key});

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

  void _showBookingDetails(BuildContext context, Map<String, dynamic> data, String bookingId) {
    final clinicName = data['clinicName'] ?? 'Klinik';
    final doctorName = data['doctorName'] ?? 'Dokter';
    final status = data['status'] ?? 'Menunggu';
    final timeStr = data['time'] ?? '';
    final petName = data['petName'] ?? '-';
    final complaint = data['complaint'] ?? '-';
    
    // Parse Date safely
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
                const Text("Detail Booking", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _detailRow(Icons.local_hospital, "Klinik", clinicName),
                const SizedBox(height: 10),
                _detailRow(Icons.person, "Dokter", doctorName),
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
                ] else if (status.toLowerCase() == 'selesai') ...[
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reviews')
                        .where('bookingId', isEqualTo: bookingId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final hasReview = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                      if (hasReview) {
                        final reviewDoc = snapshot.data!.docs.first;
                        final double rating = (reviewDoc['rating'] ?? 5.0).toDouble();
                        final comment = reviewDoc['comment'] ?? '';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const Text("Ulasan Anda", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 5),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                            ),
                            if (comment.toString().isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(comment, style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.darkGrey)),
                            ],
                            const SizedBox(height: 15),
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
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Tutup"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber.shade700,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showRatingDialog(context, bookingId, data);
                                },
                                child: const Text("Beri Ulasan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Riwayat Booking"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("🔥 Firestore Error in Booking History: ${snapshot.error}");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    const Text("Terjadi kesalahan memuat data booking.", textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text(
                      "Detail Error: ${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Anda belum memiliki riwayat booking."));
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final data = bookings[index].data() as Map<String, dynamic>;
              
              final clinicName = data['clinicName'] ?? 'Klinik';
              final doctorName = data['doctorName'] ?? 'Dokter';
              final timeStr = data['time'] ?? '';
              final status = data['status'] ?? 'Menunggu';

              // Parse Date safely
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
                                clinicName,
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
                            const Icon(Icons.person, size: 16, color: AppColors.darkGrey),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(doctorName, maxLines: 1, overflow: TextOverflow.ellipsis),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/booking');
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Booking Baru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String bookingId, Map<String, dynamic> bookingData) {
    double selectedRating = 5;
    final commentController = TextEditingController();
    Uint8List? selectedImageBytes;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Berikan Ulasan & Rating", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Bagaimana pengalaman Anda?"),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          icon: Icon(
                            starValue <= selectedRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: isUploading
                              ? null
                              : () {
                                  setStateDialog(() {
                                    selectedRating = starValue.toDouble();
                                  });
                                },
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      enabled: !isUploading,
                      decoration: InputDecoration(
                        hintText: "Tulis ulasan Anda disini...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 15),
                    selectedImageBytes != null
                        ? Stack(
                            children: [
                              Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.memory(selectedImageBytes!, fit: BoxFit.cover),
                              ),
                              if (!isUploading)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () {
                                      setStateDialog(() {
                                        selectedImageBytes = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : OutlinedButton.icon(
                            onPressed: isUploading
                                ? null
                                : () async {
                                    try {
                                      final ImagePicker picker = ImagePicker();
                                      final XFile? image = await picker.pickImage(
                                        source: ImageSource.gallery,
                                        maxWidth: 1024,
                                        imageQuality: 80,
                                      );
                                      if (image != null) {
                                        final bytes = await image.readAsBytes();
                                        setStateDialog(() {
                                          selectedImageBytes = bytes;
                                        });
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Gagal mengambil foto: $e")),
                                      );
                                    }
                                  },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                            label: const Text("Tambah Foto Ulasan", style: TextStyle(color: AppColors.primary)),
                          ),
                    if (isUploading) ...[
                      const SizedBox(height: 15),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                          SizedBox(width: 10),
                          Text("Mengunggah ulasan & foto...", style: TextStyle(fontSize: 12, color: AppColors.darkGrey)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isUploading
                      ? null
                      : () async {
                          final comment = commentController.text.trim();
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;

                          setStateDialog(() => isUploading = true);

                          try {
                            String uploadedImageUrl = '';
                            if (selectedImageBytes != null) {
                              final imgUrl = await ImageUploadService.uploadImage(selectedImageBytes!, folder: 'reviews');
                              if (imgUrl != null) {
                                uploadedImageUrl = imgUrl;
                              }
                            }

                            final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                            final userName = userDoc.exists ? (userDoc.data()?['name'] ?? 'Pengguna') : 'Pengguna';

                            await FirebaseFirestore.instance.collection('reviews').add({
                              'userId': user.uid,
                              'userName': userName,
                              'bookingId': bookingId,
                              'targetId': bookingData['clinicId'],
                              'targetName': bookingData['clinicName'] ?? 'Klinik',
                              'doctorId': bookingData['doctorId'],
                              'doctorName': bookingData['doctorName'],
                              'rating': selectedRating,
                              'comment': comment,
                              'image_url': uploadedImageUrl,
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Ulasan Anda berhasil dikirim!")),
                              );
                            }
                          } catch (e) {
                            setStateDialog(() => isUploading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Gagal mengirim ulasan: $e")),
                              );
                            }
                          }
                        },
                  child: const Text("Kirim", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
