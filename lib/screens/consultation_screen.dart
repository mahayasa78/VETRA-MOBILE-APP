import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../utils/app_network_image.dart';
import 'chat_screen.dart';
import 'add_review_screen.dart';

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
        () => setState(() => _searchQuery = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Review item dengan avatar ───────────────────────────────────────────────
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
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  if (dateStr.isNotEmpty)
                    Text(dateStr, style: const TextStyle(color: AppColors.darkGrey, fontSize: 11)),
                ]),
                const SizedBox(height: 3),
                Row(children: List.generate(5, (i) => Icon(
                  i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber, size: 14,
                ))),
              ]),
            ),
          ]),
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
                height: 90, width: 130,
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
                    child: const Icon(Icons.broken_image, color: Colors.grey)),
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

  // ─── Doctor Detail Sheet ─────────────────────────────────────────────────────
  void _showDoctorDetail(BuildContext context, Map<String, dynamic> data,
      String doctorId, User currentUser) {
    final name = data['name'] ?? 'Dokter';
    final spesialis = data['spesialis'] ?? 'Dokter Hewan Umum';
    final profilePic = data['profilePic'] ?? '';
    final bool isOnline = data['isOnline'] ?? false;

    String initials = "D";
    if (name.isNotEmpty) {
      final words = name.replaceAll('drh.', '').trim().split(' ');
      initials = words.length > 1
          ? (words[0][0] + words[1][0]).toUpperCase()
          : name[0].toUpperCase();
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
              double total = 0.0;
              for (var doc in reviewSnap.data!.docs) {
                final r = doc.data() as Map<String, dynamic>;
                total += (r['rating'] ?? 5.0).toDouble();
                final img = r['image_url'] ?? '';
                if (img.isNotEmpty) reviewPhotos.add(img);
              }
              reviewCount = reviewSnap.data!.docs.length;
              avgRating = total / reviewCount;
            }

            final ratingStr = reviewCount > 0
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
                  Center(child: Container(width: 40, height: 5,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),

                  // Header
                  Row(children: [
                    Stack(children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: profilePic.isNotEmpty ? appNetworkImageProvider(profilePic) : null,
                        child: profilePic.isEmpty
                            ? Text(initials, style: const TextStyle(fontSize: 24, color: AppColors.primary, fontWeight: FontWeight.bold))
                            : null,
                      ),
                      Positioned(bottom: 0, right: 0, child: Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      )),
                    ]),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(spesialis, style: const TextStyle(color: AppColors.darkGrey, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isOnline ? Colors.green.shade200 : Colors.grey.shade300),
                          ),
                          child: Text(
                            isOnline ? "ONLINE" : "OFFLINE",
                            style: TextStyle(fontSize: 10,
                              color: isOnline ? Colors.green.shade700 : Colors.grey.shade600,
                              fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(ratingStr, style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold,
                          color: reviewCount > 0 ? Colors.amber : Colors.grey,
                        )),
                      ]),
                    ])),
                  ]),

                  const Divider(height: 28),

                  // Info klinik
                  if ((data['clinicId'] ?? '').isNotEmpty)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users').doc(data['clinicId']).get(),
                      builder: (context, snap) {
                        if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
                        final c = snap.data!.data() as Map<String, dynamic>;
                        final cName = c['name'] ?? '';
                        final cAddr = c['address'] ?? '';
                        final cPhone = c['phone'] ?? '';
                        if (cName.isEmpty) return const SizedBox.shrink();
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text("Klinik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                const Icon(Icons.local_hospital, color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(cName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                              ]),
                              if (cAddr.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Icon(Icons.location_on_outlined, color: AppColors.darkGrey, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(cAddr, style: const TextStyle(fontSize: 13, color: AppColors.darkGrey))),
                                ]),
                              ],
                              if (cPhone.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(children: [
                                  const Icon(Icons.phone_outlined, color: AppColors.darkGrey, size: 16),
                                  const SizedBox(width: 8),
                                  Text(cPhone, style: const TextStyle(fontSize: 13, color: AppColors.darkGrey)),
                                ]),
                              ],
                            ]),
                          ),
                          const Divider(height: 28),
                        ]);
                      },
                    ),

                  // Foto ulasan
                  if (reviewPhotos.isNotEmpty) ...[
                    const Text("Foto dari Ulasan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: reviewPhotos.length,
                        itemBuilder: (context, i) => Container(
                          width: 90, margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: AppNetworkImage(
                            url: reviewPhotos[i],
                            fit: BoxFit.cover,
                            errorWidget: (c, u, e) => Container(
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.image, color: Colors.grey)),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 28),
                  ],

                  // Beri Rating
                  Builder(builder: (innerCtx) {
                    final cu = FirebaseAuth.instance.currentUser;
                    if (cu == null) return const SizedBox();
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(cu.uid).snapshots(),
                      builder: (context, userSnap) {
                        String uPhoto = '';
                        String uName = 'Pengguna';
                        if (userSnap.hasData && userSnap.data!.exists) {
                          final ud = userSnap.data!.data() as Map<String, dynamic>?;
                          uPhoto = ud?['profilePic'] ?? '';
                          uName = ud?['name'] ?? 'Pengguna';
                        }
                        final uInitial = uName.isNotEmpty ? uName.substring(0, 1).toUpperCase() : 'P';
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ulasan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(innerCtx, MaterialPageRoute(
                                    builder: (_) => AddReviewScreen(
                                      targetId: doctorId, targetName: name, targetType: 'dokter'),
                                  ));
                                },
                                child: const Text('Tambah ulasan',
                                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primaryLight,
                              backgroundImage: uPhoto.isNotEmpty ? appNetworkImageProvider(uPhoto) : null,
                              child: uPhoto.isEmpty
                                  ? Text(uInitial, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Row(children: List.generate(5, (i) => GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(innerCtx, MaterialPageRoute(
                                  builder: (_) => AddReviewScreen(
                                    targetId: doctorId, targetName: name, targetType: 'dokter'),
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
                            ))),
                          ]),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(innerCtx, MaterialPageRoute(
                                builder: (_) => AddReviewScreen(
                                  targetId: doctorId, targetName: name, targetType: 'dokter'),
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
                        ]);
                      },
                    );
                  }),

                  // List ulasan
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

                  // CTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                      label: const Text("Mulai Konsultasi",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final chatId = '${currentUser.uid}_$doctorId';
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chatId, receiverId: doctorId, receiverName: name),
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

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Konsultasi Dokter")),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari dokter, spesialisasi, atau klinik...",
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

          // Doctor list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'dokter')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Terjadi kesalahan memuat data."));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Belum ada dokter yang terdaftar."));
                }

                var doctors = snapshot.data!.docs;

                if (_searchQuery.isNotEmpty) {
                  doctors = doctors.where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final name = (d['name'] ?? '').toString().toLowerCase();
                    final spesialis = (d['spesialis'] ?? '').toString().toLowerCase();
                    final clinicName = (d['clinicName'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) ||
                        spesialis.contains(_searchQuery) ||
                        clinicName.contains(_searchQuery);
                  }).toList();
                }

                if (doctors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('Dokter "$_searchQuery" tidak ditemukan.',
                            style: const TextStyle(color: AppColors.darkGrey),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doc = doctors[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final doctorId = doc.id;
                    final name = data['name'] ?? 'Dokter';
                    final spesialis = data['spesialis'] ?? 'Dokter Hewan Umum';
                    final profilePic = data['profilePic'] ?? '';
                    final bool isOnline = data['isOnline'] ?? false;
                    final clinicId = data['clinicId'] ?? '';

                    String initials = "D";
                    if (name.isNotEmpty) {
                      final words = name.replaceAll('drh.', '').trim().split(' ');
                      initials = words.length > 1
                          ? (words[0][0] + words[1][0]).toUpperCase()
                          : name[0].toUpperCase();
                    }

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
                            onTap: () {
                              if (currentUser == null) return;
                              _showDoctorDetail(context, data, doctorId, currentUser);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  // Avatar + online dot
                                  Stack(children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: AppColors.primaryLight,
                                      backgroundImage: profilePic.isNotEmpty ? appNetworkImageProvider(profilePic) : null,
                                      child: profilePic.isEmpty
                                          ? Text(initials, style: const TextStyle(
                                              color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16))
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
                                            child: Text(spesialis,
                                                style: const TextStyle(fontSize: 12, color: AppColors.darkGrey),
                                                overflow: TextOverflow.ellipsis),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(Icons.star_rounded,
                                              color: reviewCount > 0 ? Colors.amber : Colors.grey.shade400,
                                              size: 12),
                                          const SizedBox(width: 3),
                                          Flexible(
                                            child: Text(ratingStr, style: TextStyle(
                                              fontSize: 11, fontWeight: FontWeight.w600,
                                              color: reviewCount > 0 ? Colors.amber.shade700 : AppColors.darkGrey,
                                            ), overflow: TextOverflow.ellipsis),
                                          ),
                                        ]),
                                        if (clinicId.isNotEmpty)
                                          FutureBuilder<DocumentSnapshot>(
                                            future: FirebaseFirestore.instance
                                                .collection('users').doc(clinicId).get(),
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

                                  // Chat button
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
                                      if (currentUser == null) return;
                                      final chatId = '${currentUser.uid}_$doctorId';
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          chatId: chatId, receiverId: doctorId, receiverName: name),
                                      ));
                                    },
                                    child: const Text("Chat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ],
                              ),
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
}
