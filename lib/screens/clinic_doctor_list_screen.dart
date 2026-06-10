import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import 'add_doctor_screen.dart';

class ClinicDoctorListScreen extends StatefulWidget {
  const ClinicDoctorListScreen({super.key});

  @override
  State<ClinicDoctorListScreen> createState() => _ClinicDoctorListScreenState();
}

class _ClinicDoctorListScreenState extends State<ClinicDoctorListScreen> {
  String _filter = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  Future<void> _deleteDoctor(BuildContext context, String docId, String docName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Dokter?"),
        content: Text("Apakah Anda yakin ingin menghapus $docName dari klinik ini? Akun login dokter akan tetap ada, namun tidak terhubung ke klinik."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Remove clinicId so the doctor is unlinked from the clinic
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'clinicId': FieldValue.delete(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$docName berhasil dihapus dari klinik.")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menghapus: $e")));
        }
      }
    }
  }

  void _showDoctorDetail(BuildContext context, Map<String, dynamic> data, String docId, String clinicId) {
    final name = data['name'] ?? 'Dokter';
    final email = data['email'] ?? '-';
    final phone = data['phone'] ?? '-';
    final spesialis = data['spesialis'] ?? 'Umum';
    final profilePic = data['profilePic'] ?? '';
    final bool isOnline = data['isOnline'] ?? false;

    String ini = "D";
    if (name.isNotEmpty) {
      final w = name.replaceAll('drh.', '').trim().split(' ');
      ini = w.length > 1 ? (w[0][0] + w[1][0]).toUpperCase() : name[0].toUpperCase();
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
              child: profilePic.isEmpty ? Text(ini, style: const TextStyle(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.bold)) : null,
            ),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(spesialis, style: const TextStyle(color: AppColors.darkGrey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isOnline ? AppColors.primaryLight : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isOnline ? "Online & Aktif" : "Offline",
                style: TextStyle(color: isOnline ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            if (email != '-') ListTile(dense: true, leading: const Icon(Icons.email, color: AppColors.primary, size: 20), title: Text(email, style: const TextStyle(fontSize: 14)), contentPadding: EdgeInsets.zero),
            if (phone != '-') ListTile(dense: true, leading: const Icon(Icons.phone, color: AppColors.primary, size: 20), title: Text(phone, style: const TextStyle(fontSize: 14)), contentPadding: EdgeInsets.zero),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.person_remove, size: 18),
                    label: const Text("Hapus"),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteDoctor(context, docId, name);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: const Text("Edit", style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AddDoctorScreen(
                          docId: docId,
                          initialData: data,
                          preselectedClinicId: clinicId,
                        ),
                      ));
                    },
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
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Silakan login"));
    final String clinicId = currentUser.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Manajemen Dokter"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text("Tambah Dokter", style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => AddDoctorScreen(preselectedClinicId: clinicId),
          ));
        },
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari nama atau spesialisasi dokter...",
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
            padding: const EdgeInsets.fromLTRB(15, 4, 15, 8),
            child: Row(
              children: ['Semua', 'Online', 'Offline'].map((f) => Padding(
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

          // Doctor list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'dokter')
                  .where('clinicId', isEqualTo: clinicId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text("Belum ada dokter terdaftar di klinik ini.", style: TextStyle(color: AppColors.darkGrey)),
                        const SizedBox(height: 8),
                        const Text("Tekan tombol + untuk menambahkan dokter.", style: TextStyle(color: AppColors.darkGrey, fontSize: 13)),
                        const SizedBox(height: 80), // space for FAB
                      ],
                    ),
                  );
                }

                var doctors = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final isOnline = data['isOnline'] ?? false;
                  if (_filter == 'Online' && !isOnline) return false;
                  if (_filter == 'Offline' && isOnline) return false;
                  if (_searchQuery.isNotEmpty) {
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final spesialis = (data['spesialis'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) || spesialis.contains(_searchQuery);
                  }
                  return true;
                }).toList();

                // Online first
                doctors.sort((a, b) {
                  final aOnline = ((a.data() as Map)['isOnline'] ?? false) as bool;
                  final bOnline = ((b.data() as Map)['isOnline'] ?? false) as bool;
                  if (aOnline && !bOnline) return -1;
                  if (!aOnline && bOnline) return 1;
                  return 0;
                });

                if (doctors.isEmpty) {
                  return const Center(child: Text("Tidak ada dokter sesuai filter.", style: TextStyle(color: AppColors.darkGrey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(15, 8, 15, 90), // bottom padding for FAB
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final data = doctors[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Dokter';
                    final spesialis = data['spesialis'] ?? 'Umum';
                    final bool isOnline = data['isOnline'] ?? false;
                    final profilePic = data['profilePic'] ?? '';

                    String ini = "D";
                    if (name.isNotEmpty) {
                      final w = name.replaceAll('drh.', '').trim().split(' ');
                      ini = w.length > 1 ? (w[0][0] + w[1][0]).toUpperCase() : name[0].toUpperCase();
                    }

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.grey)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _showDoctorDetail(context, data, doctors[index].id, clinicId),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppColors.primaryLight,
                                    backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                                    child: profilePic.isEmpty ? Text(ini, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)) : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: isOnline ? Colors.green : Colors.grey,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 3),
                                    Text(spesialis, style: const TextStyle(color: AppColors.darkGrey, fontSize: 13)),
                                  ],
                                ),
                              ),
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isOnline ? AppColors.primaryLight : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isOnline ? "Online" : "Offline",
                                  style: TextStyle(color: isOnline ? AppColors.primary : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Quick delete button
                              GestureDetector(
                                onTap: () => _deleteDoctor(context, doctors[index].id, name),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.person_remove, color: Colors.red, size: 18),
                                ),
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
          ),
        ],
      ),
    );
  }
}
