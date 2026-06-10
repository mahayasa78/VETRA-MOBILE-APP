import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_colors.dart';
import '../services/image_upload_service.dart';

class ClinicProfileScreen extends StatefulWidget {
  const ClinicProfileScreen({super.key});

  @override
  State<ClinicProfileScreen> createState() => _ClinicProfileScreenState();
}

class _ClinicProfileScreenState extends State<ClinicProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool isUploading = false;

  // Controllers for editable fields
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Jam operasional state
  final List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  Map<String, Map<String, dynamic>> _operationalHours = {};
  bool _isEditingHours = false;
  bool _isEditingInfo = false;

  void _initOperationalHours(Map<String, dynamic> existingData) {
    final saved = existingData['operationalHours'] as Map<String, dynamic>?;
    for (var day in _days) {
      if (saved != null && saved.containsKey(day)) {
        _operationalHours[day] = Map<String, dynamic>.from(saved[day]);
      } else {
        _operationalHours[day] = {
          'isOpen': day != 'Minggu',
          'open': '08:00',
          'close': '17:00',
        };
      }
    }
  }

  Future<void> _uploadProfilePicture() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
      if (image == null || currentUser == null) return;
      setState(() => isUploading = true);
      Uint8List bytes = await image.readAsBytes();
      String? url = await ImageUploadService.uploadImage(bytes, folder: 'profile_pics');
      if (url == null) throw Exception("Gagal mendapatkan URL.");
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({'profilePic': url});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto berhasil diperbarui!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  Future<void> _saveInfo() async {
    if (currentUser == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'phone': _phoneController.text.trim(),
        'emergencyPhone': _emergencyPhoneController.text.trim(),
        'address': _addressController.text.trim(),
      });
      if (mounted) {
        setState(() => _isEditingInfo = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Info klinik berhasil disimpan!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _saveOperationalHours() async {
    if (currentUser == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'operationalHours': _operationalHours,
      });
      if (mounted) {
        setState(() => _isEditingHours = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jam operasional berhasil disimpan!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _pickTime(BuildContext context, String day, String field) async {
    final current = _operationalHours[day]?[field] ?? '08:00';
    final parts = current.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: initialTime);
    if (picked != null) {
      setState(() {
        _operationalHours[day]![field] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Center(child: Text("Silakan login"));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Profil Klinik"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Data tidak ditemukan."));

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? 'Klinik';
          final email = data['email'] ?? currentUser!.email ?? '';
          final phone = data['phone'] ?? '-';
          final emergencyPhone = data['emergencyPhone'] ?? '-';
          final address = data['address'] ?? '-';
          final profilePic = data['profilePic'] ?? '';
          final bool isClinicOpen = data['isClinicOpen'] ?? true;

          // Init controllers if not editing
          if (!_isEditingInfo) {
            _phoneController.text = phone == '-' ? '' : phone;
            _emergencyPhoneController.text = emergencyPhone == '-' ? '' : emergencyPhone;
            _addressController.text = address == '-' ? '' : address;
          }

          // Init jam operasional if not editing
          if (!_isEditingHours && _operationalHours.isEmpty) {
            _initOperationalHours(data);
          }

          String initials = "K";
          if (name.isNotEmpty) {
            var words = name.trim().split(' ');
            initials = words.length > 1
                ? (words[0][0] + words[1][0]).toUpperCase()
                : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // --- PHOTO ---
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                        child: profilePic.isEmpty
                            ? Text(initials, style: const TextStyle(fontSize: 40, color: AppColors.primary, fontWeight: FontWeight.bold))
                            : null,
                      ),
                      if (isUploading) const Positioned.fill(child: CircularProgressIndicator()),
                      Positioned(
                        bottom: 0, right: 0,
                        child: GestureDetector(
                          onTap: isUploading ? null : _uploadProfilePicture,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(name, style: Theme.of(context).textTheme.displayMedium),
                Text(email, style: const TextStyle(color: AppColors.darkGrey, fontSize: 13)),

                const SizedBox(height: 20),

                // --- STATUS KLINIK ---
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("Status Klinik", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                            isClinicOpen ? "Buka Sekarang" : "Sedang Tutup",
                            style: TextStyle(color: isClinicOpen ? AppColors.primary : AppColors.darkGrey, fontWeight: FontWeight.bold),
                          ),
                        ]),
                        Switch(
                          value: isClinicOpen,
                          activeColor: AppColors.primary,
                          activeTrackColor: AppColors.primaryLight,
                          onChanged: (val) async {
                            await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({'isClinicOpen': val});
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // --- INFO KLINIK ---
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Informasi Klinik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            TextButton.icon(
                              onPressed: () {
                                if (_isEditingInfo) {
                                  _saveInfo();
                                } else {
                                  setState(() => _isEditingInfo = true);
                                }
                              },
                              icon: Icon(_isEditingInfo ? Icons.save : Icons.edit, size: 16),
                              label: Text(_isEditingInfo ? "Simpan" : "Edit"),
                              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                            ),
                          ],
                        ),
                        const Divider(),
                        if (_isEditingInfo) ...[
                          _editField(Icons.phone, "Nomor Telepon", _phoneController, TextInputType.phone),
                          const SizedBox(height: 12),
                          _editField(Icons.emergency, "Nomor Darurat", _emergencyPhoneController, TextInputType.phone),
                          const SizedBox(height: 12),
                          _editField(Icons.location_on, "Alamat", _addressController, TextInputType.streetAddress, maxLines: 2),
                        ] else ...[
                          _infoRow(Icons.phone, "Telepon", phone),
                          const SizedBox(height: 10),
                          _infoRow(Icons.emergency, "No. Darurat", emergencyPhone),
                          const SizedBox(height: 10),
                          _infoRow(Icons.location_on, "Alamat", address),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // --- JAM OPERASIONAL ---
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Jam Operasional", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            TextButton.icon(
                              onPressed: () {
                                if (_isEditingHours) {
                                  _saveOperationalHours();
                                } else {
                                  if (_operationalHours.isEmpty) _initOperationalHours(data);
                                  setState(() => _isEditingHours = true);
                                }
                              },
                              icon: Icon(_isEditingHours ? Icons.save : Icons.edit, size: 16),
                              label: Text(_isEditingHours ? "Simpan" : "Edit"),
                              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                            ),
                          ],
                        ),
                        const Divider(),
                        ..._days.map((day) {
                          final hours = _operationalHours[day];
                          if (hours == null) return const SizedBox.shrink();
                          final bool isOpen = hours['isOpen'] ?? true;
                          final String openTime = hours['open'] ?? '08:00';
                          final String closeTime = hours['close'] ?? '17:00';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 70,
                                  child: Text(day, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                ),
                                if (_isEditingHours) ...[
                                  Switch(
                                    value: isOpen,
                                    activeColor: AppColors.primary,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (val) => setState(() => _operationalHours[day]!['isOpen'] = val),
                                  ),
                                  if (isOpen) ...[
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _pickTime(context, day, 'open'),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                                          child: Text(openTime, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                                        ),
                                      ),
                                    ),
                                    const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text("-", style: TextStyle(color: AppColors.darkGrey))),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _pickTime(context, day, 'close'),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                                          child: Text(closeTime, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                                        ),
                                      ),
                                    ),
                                  ] else
                                    const Expanded(child: Text("Tutup", style: TextStyle(color: Colors.grey, fontSize: 13))),
                                ] else ...[
                                  isOpen
                                      ? Expanded(child: Text("$openTime – $closeTime", style: const TextStyle(fontSize: 13, color: AppColors.darkGrey)))
                                      : const Expanded(child: Text("Tutup", style: TextStyle(fontSize: 13, color: Colors.red))),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- LOGOUT ---
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text("Keluar"),
                    onPressed: () async => await FirebaseAuth.instance.signOut(),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: AppColors.primary, size: 18),
      const SizedBox(width: 10),
      SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppColors.darkGrey, fontSize: 13))),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
    ]);
  }

  Widget _editField(IconData icon, String label, TextEditingController controller, TextInputType keyboardType, {int maxLines = 1}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Icon(icon, color: AppColors.primary, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ),
    ]);
  }
}
