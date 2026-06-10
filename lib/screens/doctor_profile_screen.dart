import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_colors.dart';
import '../utils/app_network_image.dart';
import '../services/image_upload_service.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool isUploading = false;

  void _quickEdit(String field, String label, String current, {int maxLines = 1, TextInputType inputType = TextInputType.text}) {
    final ctrl = TextEditingController(text: current == '-' ? '' : current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Edit $label", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: TextField(
          controller: ctrl,
          keyboardType: inputType,
          maxLines: maxLines,
          autofocus: true,
          decoration: InputDecoration(
            hintText: label,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final value = ctrl.text.trim();
              if (field == 'name' && value.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama tidak boleh kosong.")));
                return;
              }
              await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({field: value});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    final bool editable = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        child: Row(children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.darkGrey)),
              const SizedBox(height: 2),
              Text(value.isEmpty ? "-" : value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: value.isEmpty || value == '-' ? Colors.grey : Colors.black87)),
            ]),
          ),
          if (editable) const Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
        ]),
      ),
    );
  }

  Future<void> _uploadProfilePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 800,
      );
      
      if (image == null) return;
      if (currentUser == null) return;

      setState(() => isUploading = true);

      Uint8List bytes = await image.readAsBytes();
      String? downloadUrl = await ImageUploadService.uploadImage(bytes, folder: 'profile_pics');

      if (downloadUrl == null) {
        throw Exception("Gagal mendapatkan URL gambar dari ImgBB.");
      }

      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'profilePic': downloadUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Center(child: Text("Silakan login"));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Profil Dokter"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Data profil tidak ditemukan."));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final name = userData['name'] ?? 'Dokter';
          final email = userData['email'] ?? currentUser!.email ?? '';
          final phone = userData['phone'] ?? '-';
          final spesialis = userData['spesialis'] ?? 'Umum';
          final profilePic = userData['profilePic'] ?? '';
          final bool isOnline = userData['isOnline'] ?? false;

          String initials = "D";
          if (name.isNotEmpty) {
            var words = name.replaceAll('drh. ', '').trim().split(' ');
            if (words.length > 1) {
              initials = (words[0][0] + words[1][0]).toUpperCase();
            } else {
              initials = name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Picture
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: profilePic.isNotEmpty ? appNetworkImageProvider(profilePic) : null,
                        child: profilePic.isEmpty
                            ? Text(initials, style: const TextStyle(fontSize: 40, color: AppColors.primary, fontWeight: FontWeight.bold))
                            : null,
                      ),
                      if (isUploading)
                        const Positioned.fill(
                          child: CircularProgressIndicator(),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: isUploading ? null : _uploadProfilePicture,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(name, style: Theme.of(context).textTheme.displayMedium),
                Text(spesialis, style: const TextStyle(color: AppColors.darkGrey)),
                
                const SizedBox(height: 30),

                // Status Praktik Toggle
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Status Praktik", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodySmall,
                                children: [
                                  const TextSpan(text: "Saat ini: "),
                                  TextSpan(
                                    text: isOnline ? "Online & Aktif" : "Offline",
                                    style: TextStyle(
                                      color: isOnline ? AppColors.primary : AppColors.darkGrey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: isOnline,
                          activeColor: AppColors.primary,
                          activeTrackColor: AppColors.primaryLight,
                          onChanged: (val) async {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser!.uid)
                                .update({'isOnline': val});
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                 Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                  child: Column(
                    children: [
                      _infoRow(Icons.person, "Nama", name,
                          onTap: () => _quickEdit('name', 'Nama Lengkap', name)),
                      const Divider(height: 1),
                      _infoRow(Icons.medical_services, "Spesialis", spesialis,
                          onTap: () => _quickEdit('spesialis', 'Spesialis', spesialis)),
                      const Divider(height: 1),
                      _infoRow(Icons.email, "Email", email), // read-only
                      const Divider(height: 1),
                      _infoRow(Icons.phone, "Nomor Telepon", phone == '-' ? '' : phone,
                          onTap: () => _quickEdit('phone', 'Nomor Telepon', phone == '-' ? '' : phone, inputType: TextInputType.phone)),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text("Keluar"),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
