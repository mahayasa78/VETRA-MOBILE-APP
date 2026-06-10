import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import '../utils/app_network_image.dart';
import 'booking_screen.dart';
import 'add_review_screen.dart';
import 'chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ClinicListScreen extends StatefulWidget {
  const ClinicListScreen({super.key});

  @override
  State<ClinicListScreen> createState() => _ClinicListScreenState();
}

class _ClinicListScreenState extends State<ClinicListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'Semua'; // 'Semua', 'Buka', 'Tutup'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "K";
    final words = name.trim().split(' ');
    if (words.length >= 2) return (words[0][0] + words[1][0]).toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _getOperationalSummary(Map<String, dynamic>? hours) {
    if (hours == null || hours.isEmpty) return "Hubungi untuk jam operasional";
    final List<String> days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final openDays = days.where((d) => hours[d]?['isOpen'] == true).toList();
    if (openDays.isEmpty) return "Sementara tutup";
    final firstDay = openDays.first;
    final lastDay = openDays.last;
    final openTime = hours[firstDay]?['open'] ?? '08:00';
    final closeTime = hours[firstDay]?['close'] ?? '17:00';
    if (openDays.length == 7) return "Setiap hari $openTime–$closeTime";
    return "${openDays.first}–${openDays.last} $openTime–$closeTime";
  }

  void _showClinicDetail(BuildContext context, Map<String, dynamic> data, String clinicId) {
    final name = data['name'] ?? 'Klinik';
    final address = data['address'] ?? '-';
    final phone = data['phone'] ?? '-';
    final emergencyPhone = data['emergencyPhone'] ?? '-';
    final profilePic = data['profilePic'] ?? '';
    final bool isOpen = data['isClinicOpen'] ?? true;
    final initials = _getInitials(name);
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
        builder: (_, controller) => StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('targetId', isEqualTo: clinicId)
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
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: profilePic.isNotEmpty ? appNetworkImageProvider(profilePic) : null,
                      child: profilePic.isEmpty ? Text(initials, style: const TextStyle(fontSize: 24, color: AppColors.primary, fontWeight: FontWeight.bold)) : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                          Text(dynamicRatingStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                        ],
                      ),
                    ])),
                  ]),

                  const Divider(height: 28),

                  _detailRow(Icons.location_on, "Alamat", address),
                  const SizedBox(height: 10),
                  _detailRow(Icons.phone, "Telepon", phone),
                  const SizedBox(height: 10),
                  _detailRow(Icons.emergency, "No. Darurat", emergencyPhone),

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

                  if (operationalHours != null) ...[
                    const Divider(height: 28),
                    const Text("Jam Operasional", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    ...days.map((day) {
                      final h = operationalHours[day] as Map<String, dynamic>?;
                      final dayOpen = h?['isOpen'] ?? false;
                      final openT = h?['open'] ?? '08:00';
                      final closeT = h?['close'] ?? '17:00';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(children: [
                          SizedBox(width: 72, child: Text(day, style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text(
                            dayOpen ? "$openT – $closeT" : "Tutup",
                            style: TextStyle(fontSize: 13, color: dayOpen ? AppColors.darkGrey : Colors.red, fontWeight: dayOpen ? FontWeight.normal : FontWeight.w500),
                          )),
                        ]),
                      );
                    }).toList(),
                  ],

                  const Divider(height: 28),
                  const Text("Dokter di Klinik Ini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'dokter')
                        .where('clinicId', isEqualTo: clinicId)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return const Text("Belum ada dokter terdaftar.", style: TextStyle(color: AppColors.darkGrey));
                      }
                      return Column(
                        children: snap.data!.docs.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          final docName = d['name'] ?? 'Dokter';
                          final spesialis = d['spesialis'] ?? 'Umum';
                          final bool docOnline = d['isOnline'] ?? false;
                          final docPic = d['profilePic'] ?? '';
                          final docIni = _getInitials(docName.replaceAll('drh.', '').trim());
                          return FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('reviews')
                                .where('targetId', isEqualTo: doc.id)
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

                              return ListTile(
                                onTap: () => _showDoctorDetailSheet(context, d, doc.id),
                                contentPadding: EdgeInsets.zero,
                                leading: Stack(children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.primaryLight,
                                    backgroundImage: docPic.isNotEmpty ? appNetworkImageProvider(docPic) : null,
                                    child: docPic.isEmpty ? Text(docIni, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)) : null,
                                  ),
                                  Positioned(bottom: 0, right: 0, child: Container(
                                    width: 10, height: 10,
                                    decoration: BoxDecoration(color: docOnline ? Colors.green : Colors.grey, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                                  )),
                                ]),
                                title: Text(docName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Row(
                                  children: [
                                    Text(spesialis, style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.star, color: Colors.amber, size: 12),
                                    const SizedBox(width: 3),
                                    Text(
                                      ratingStr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: reviewCount > 0 ? Colors.amber.shade700 : AppColors.darkGrey,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: docOnline ? AppColors.primaryLight : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(docOnline ? "Online" : "Offline", style: TextStyle(fontSize: 11, color: docOnline ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold)),
                                ),
                              );
                            }
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const Divider(height: 28),

                  // ── Beri Rating Section (Google Maps style) ──────────────
                  Builder(builder: (innerCtx) {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) return const SizedBox();
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
                      builder: (context, userSnap) {
                        String uPhoto = '';
                        String uName = 'Pengguna';
                        if (userSnap.hasData && userSnap.data!.exists) {
                          final userData = userSnap.data!.data() as Map<String, dynamic>?;
                          uPhoto = userData?['profilePic'] ?? '';
                          uName = userData?['name'] ?? 'Pengguna';
                        } else {
                          uPhoto = currentUser.photoURL ?? '';
                          uName = currentUser.displayName ?? 'Pengguna';
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
                                    Navigator.pop(context);
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
                                  children: List.generate(5, (i) {
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
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
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
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

                  const SizedBox(height: 24),

              // CTA — Book
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  label: const Text("Booking di Klinik Ini", style: TextStyle(color: Colors.white, fontSize: 16)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => BookingScreen(preselectedClinicId: clinicId, preselectedClinicName: name),
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

  Widget _detailRow(IconData icon, String label, String value) {
    final isAddress = label == "Alamat";
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: AppColors.primary, size: 18),
      const SizedBox(width: 8),
      SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppColors.darkGrey, fontSize: 13))),
      Expanded(
        child: isAddress
            ? InkWell(
                onTap: () async {
                  try {
                    final query = Uri.encodeComponent(value);
                    final googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
                    await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    print("Error launching map: $e");
                  }
                },
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            : Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Cari Klinik"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari nama atau alamat klinik...",
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

          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 2, 15, 8),
            child: Row(
              children: ['Semua', 'Buka', 'Tutup'].map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: _filter == f,
                  selectedColor: AppColors.primaryLight,
                  labelStyle: TextStyle(
                    color: _filter == f ? AppColors.primary : Colors.grey[700],
                    fontWeight: _filter == f ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _filter = f),
                ),
              )).toList(),
            ),
          ),

          // Clinic list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'klinik')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.local_hospital_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      const Text("Belum ada klinik terdaftar.", style: TextStyle(color: AppColors.darkGrey)),
                    ]),
                  );
                }

                var clinics = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final bool isOpen = data['isClinicOpen'] ?? true;
                  if (_filter == 'Buka' && !isOpen) return false;
                  if (_filter == 'Tutup' && isOpen) return false;
                  if (_searchQuery.isNotEmpty) {
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final address = (data['address'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) || address.contains(_searchQuery);
                  }
                  return true;
                }).toList();

                // Open clinics first
                clinics.sort((a, b) {
                  final aOpen = ((a.data() as Map)['isClinicOpen'] ?? true) as bool;
                  final bOpen = ((b.data() as Map)['isClinicOpen'] ?? true) as bool;
                  if (aOpen && !bOpen) return -1;
                  if (!aOpen && bOpen) return 1;
                  return 0;
                });

                if (clinics.isEmpty) {
                  return const Center(child: Text("Tidak ada klinik yang sesuai.", style: TextStyle(color: AppColors.darkGrey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  itemCount: clinics.length,
                  itemBuilder: (context, index) {
                    final doc = clinics[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final clinicId = doc.id;
                    final name = data['name'] ?? 'Klinik';
                    final address = data['address'] ?? 'Alamat belum diatur';
                    final profilePic = data['profilePic'] ?? '';
                    final bool isOpen = data['isClinicOpen'] ?? true;
                    final operationalHours = data['operationalHours'] as Map<String, dynamic>?;
                    final initials = _getInitials(name);
                    final opSummary = _getOperationalSummary(operationalHours);
                    final phone = (data['phone'] ?? '').toString();

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('reviews')
                          .where('targetId', isEqualTo: clinicId)
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
                            onTap: () => _showClinicDetail(context, data, clinicId),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Banner Image ────────────────────────────
                                Stack(
                                  children: [
                                    profilePic.isNotEmpty
                                        ? AppNetworkImage(
                                            url: profilePic,
                                            width: double.infinity,
                                            height: 110,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => _buildPlaceholderBanner(initials),
                                          )
                                        : _buildPlaceholderBanner(initials),
                                    Positioned(
                                      top: 10,
                                      right: 10,
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
                                  ],
                                ),

                                // ── Info ────────────────────────────────────
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Icon(Icons.star_rounded, color: reviewCount > 0 ? Colors.amber : Colors.grey.shade400, size: 13),
                                          const SizedBox(width: 3),
                                          Text(
                                            reviewCount > 0
                                                ? "${avgRating.toStringAsFixed(1)} ($reviewCount)"
                                                : "Belum ada ulasan",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: reviewCount > 0 ? Colors.amber : AppColors.darkGrey,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.access_time_outlined, size: 13, color: AppColors.darkGrey),
                                          const SizedBox(width: 3),
                                          Expanded(
                                            child: Text(
                                              opSummary,
                                              style: const TextStyle(fontSize: 11, color: AppColors.darkGrey),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 13, color: AppColors.darkGrey),
                                          const SizedBox(width: 3),
                                          Expanded(
                                            child: Text(
                                              address,
                                              style: const TextStyle(fontSize: 11, color: AppColors.darkGrey),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // ── Action buttons ──────────────────────────
                                const SizedBox(height: 8),
                                Divider(height: 1, color: Colors.grey.shade100),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _iconActionButton(
                                        icon: Icons.phone_outlined,
                                        label: "Telepon",
                                        onTap: () async {
                                          if (phone.isNotEmpty) {
                                            final uri = Uri(scheme: 'tel', path: phone);
                                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Nomor telepon tidak tersedia.")),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                      Container(width: 1, height: 28, color: Colors.grey.shade200),
                                      _iconActionButton(
                                        icon: Icons.map_outlined,
                                        label: "Peta",
                                        onTap: () async {
                                          if (address.isNotEmpty && address != 'Alamat belum diatur') {
                                            try {
                                              final q = Uri.encodeComponent(address);
                                              final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$q");
                                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text("Gagal membuka peta: $e")),
                                                );
                                              }
                                            }
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Alamat klinik belum diatur.")),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                      Container(width: 1, height: 28, color: Colors.grey.shade200),
                                      _iconActionButton(
                                        icon: Icons.calendar_today_outlined,
                                        label: "Booking",
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BookingScreen(
                                              preselectedClinicId: clinicId,
                                              preselectedClinicName: name,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderBanner(String initials) {
    return Container(
      width: double.infinity,
      height: 110,
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
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 36),
      ),
    );
  }

  Widget _iconActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
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
                  errorWidget: (c, u, e) => Container(
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

  void _showDoctorDetailSheet(BuildContext context, Map<String, dynamic> data, String doctorId) {
    final name = data['name'] ?? 'Dokter';
    final spesialis = data['spesialis'] ?? 'Umum';
    final profilePic = data['profilePic'] ?? '';
    final bool isOnline = data['isOnline'] ?? false;
    final initials = _getInitials(name.replaceAll('drh.', '').trim());

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
                          Text(dynamicRatingStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                        ],
                      ),
                    ])),
                  ]),

                  const Divider(height: 28),

                  _detailRow(Icons.person_outline, "Spesialis", spesialis),
                  const SizedBox(height: 10),
                  _detailRow(Icons.chat_bubble_outline, "Konsultasi", "Melalui Chat Vetra"),

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
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
                      builder: (context, userSnap) {
                        String uPhoto = '';
                        String uName = 'Pengguna';
                        if (userSnap.hasData && userSnap.data!.exists) {
                          final userData = userSnap.data!.data() as Map<String, dynamic>?;
                          uPhoto = userData?['profilePic'] ?? '';
                          uName = userData?['name'] ?? 'Pengguna';
                        } else {
                          uPhoto = currentUser.photoURL ?? '';
                          uName = currentUser.displayName ?? 'Pengguna';
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
