import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/app_colors.dart';
import '../services/image_upload_service.dart';
import '../utils/app_network_image.dart';
import 'location_picker_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isUploadingPic = false;

  // ──── QUICK EDIT satu field ────
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

  // ──── PILIH LOKASI (GoFood-style) ────
  Future<void> _pickLocation(String currentAddress) async {
    // Tampilkan bottom sheet pilih metode
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Atur Alamat",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Pilih cara untuk mengatur lokasi alamatmu",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // Opsi 1: Lokasi saat ini
            _locationOptionTile(
              ctx: ctx,
              icon: Icons.my_location,
              color: AppColors.primary,
              title: "Gunakan Lokasi Saat Ini",
              subtitle: "Deteksi otomatis via GPS",
              onTap: () async {
                Navigator.pop(ctx);
                await _useCurrentLocation();
              },
            ),
            const SizedBox(height: 12),

            // Opsi 2: Pilih di peta
            _locationOptionTile(
              ctx: ctx,
              icon: Icons.map_outlined,
              color: Colors.deepOrange,
              title: "Pilih di Peta",
              subtitle: "Geser peta untuk titik lokasi akurat",
              onTap: () async {
                Navigator.pop(ctx);
                await _openMapPicker();
              },
            ),
            const SizedBox(height: 12),

            // Opsi 3: Ketik manual
            _locationOptionTile(
              ctx: ctx,
              icon: Icons.edit_location_alt_outlined,
              color: Colors.blueGrey,
              title: "Tulis Alamat Manual",
              subtitle: "Masukkan alamat secara langsung",
              onTap: () {
                Navigator.pop(ctx);
                _quickEdit('address', 'Alamat', currentAddress, maxLines: 3);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationOptionTile({
    required BuildContext ctx,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    try {
      // Tampilkan loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                SizedBox(width: 12),
                Text("Mendapatkan lokasi..."),
              ],
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Izin lokasi ditolak.")),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Izin lokasi diblokir. Aktifkan di Pengaturan.")),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      String address = '';
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];
        if ((p.street ?? '').isNotEmpty) parts.add(p.street!);
        if ((p.subLocality ?? '').isNotEmpty) parts.add(p.subLocality!);
        if ((p.locality ?? '').isNotEmpty) parts.add(p.locality!);
        if ((p.subAdministrativeArea ?? '').isNotEmpty) parts.add(p.subAdministrativeArea!);
        if ((p.administrativeArea ?? '').isNotEmpty) parts.add(p.administrativeArea!);
        address = parts.join(', ');
      }

      if (address.isNotEmpty && mounted) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({'address': address});
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Alamat diperbarui: $address")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mendapatkan lokasi: $e")),
        );
      }
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerScreen(),
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'address': result});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Alamat diperbarui: $result")),
      );
    }
  }

  // ──── UPLOAD FOTO PROFIL ────
  Future<void> _uploadProfilePic() async {
    try {
      final picker = ImagePicker();
      final XFile? img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
      if (img == null) return;
      setState(() => _isUploadingPic = true);
      final bytes = await img.readAsBytes();
      final url = await ImageUploadService.uploadImage(bytes, folder: 'profile_pics');
      if (url == null) throw Exception("Gagal upload");
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({'profilePic': url});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto berhasil diperbarui!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if (mounted) setState(() => _isUploadingPic = false);
    }
  }

  // ──── HAPUS HEWAN PELIHARAAN ────
  Future<void> _deletePet(String petId, String petName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Peliharaan?"),
        content: Text("Data $petName akan dihapus secara permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('pets')
          .doc(petId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$petName berhasil dihapus.")),
        );
      }
    }
  }

  // ──── EDIT / TAMBAH HEWAN PELIHARAAN ────
  void _showAddEditPetSheet([Map<String, dynamic>? pet, String? petId]) {
    final predefinedTypes = ['Kucing', 'Anjing', 'Burung', 'Kelinci', 'Lainnya'];

    // Tentukan apakah type yang tersimpan adalah custom (bukan dari list predefined)
    String savedType = pet?['type'] ?? 'Kucing';
    bool isCustomType = savedType.isNotEmpty && !predefinedTypes.contains(savedType);

    final nameCtrl = TextEditingController(text: pet?['name'] ?? '');
    final ageCtrl = TextEditingController(text: pet?['age'] ?? '');
    final breedCtrl = TextEditingController(text: pet?['breed'] ?? '');
    final customTypeCtrl = TextEditingController(text: isCustomType ? savedType : '');

    String dropdownType = isCustomType ? 'Lainnya' : savedType;
    String status = pet?['status'] ?? 'Sehat';
    String gender = pet?['gender'] ?? 'Jantan';
    String vaccineDate = pet?['vaccineDate'] ?? '';
    Uint8List? petImageBytes;
    String? existingPetPic = pet?['petPic'];
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => StatefulBuilder(
          builder: (ctx2, setModalState) {
            // Tentukan emoji/gambar default berdasarkan jenis hewan
            String currentType = dropdownType == 'Lainnya'
                ? (customTypeCtrl.text.trim().isNotEmpty ? customTypeCtrl.text.trim() : 'Lainnya')
                : dropdownType;
            String emoji = _getEmojiForType(currentType);

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollCtrl,
                padding: EdgeInsets.only(
                    top: 16,
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(ctx2).viewInsets.bottom + 24),
                children: [
                  Center(
                    child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    pet == null ? "Tambah Hewan Peliharaan" : "Edit Peliharaan",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // ── Foto hewan ──
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final XFile? img = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 70,
                            maxWidth: 800);
                        if (img == null) return;
                        final bytes = await img.readAsBytes();
                        setModalState(() => petImageBytes = bytes);
                      },
                      child: Stack(children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.secondaryOrangeLight,
                          backgroundImage: petImageBytes != null
                              ? MemoryImage(petImageBytes!) as ImageProvider
                              : (existingPetPic != null && existingPetPic.isNotEmpty
                                  ? appNetworkImageProvider(existingPetPic) as ImageProvider
                                  : null),
                          // Jika tidak ada foto, tampilkan emoji sesuai jenis hewan
                          child: (petImageBytes == null &&
                                  (existingPetPic == null || existingPetPic.isEmpty))
                              ? Text(emoji, style: const TextStyle(fontSize: 36))
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                                color: AppColors.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text("Tap untuk ganti foto hewan",
                        style: TextStyle(fontSize: 12, color: AppColors.darkGrey)),
                  ),
                  const SizedBox(height: 24),

                  _petField(Icons.pets, "Nama Hewan", nameCtrl),
                  const SizedBox(height: 16),

                  // ── Dropdown jenis hewan ──
                  _petDropdown(
                    Icons.category,
                    "Jenis Hewan",
                    dropdownType,
                    predefinedTypes,
                    (v) => setModalState(() {
                      dropdownType = v!;
                      if (v != 'Lainnya') customTypeCtrl.clear();
                    }),
                  ),

                  // ── Input custom jika pilih "Lainnya" ──
                  if (dropdownType == 'Lainnya') ...[
                    const SizedBox(height: 12),
                    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      const Icon(Icons.edit_note, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: customTypeCtrl,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => setModalState(() {}), // update emoji live
                          decoration: InputDecoration(
                            labelText: "Tulis jenis hewan (contoh: Hamster)",
                            labelStyle: const TextStyle(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ],

                  const SizedBox(height: 16),
                  _petField(Icons.cake, "Umur (contoh: 2 tahun)", ageCtrl),
                  const SizedBox(height: 16),
                  _petField(Icons.diversity_3, "Ras (contoh: Persia)", breedCtrl),
                  const SizedBox(height: 16),
                  // ── Gender ──
                  _petDropdown(
                    Icons.transgender,
                    "Gender",
                    gender,
                    ['Jantan', 'Betina'],
                    (v) => setModalState(() => gender = v!),
                  ),
                  const SizedBox(height: 16),
                  _petDropdown(
                    Icons.health_and_safety,
                    "Status Kesehatan",
                    status,
                    ['Sehat', 'Sakit', 'Masa Pemulihan'],
                    (v) => setModalState(() => status = v!),
                  ),
                  const SizedBox(height: 16),

                  // ── Date picker vaksin ──
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx2,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (c, child) => Theme(
                          data: Theme.of(c).copyWith(
                              colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white)),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setModalState(() =>
                            vaccineDate = DateFormat('dd MMM yyyy').format(picked));
                      }
                    },
                    child: Row(children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  vaccineDate.isEmpty ? "Tanggal Vaksin" : vaccineDate,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: vaccineDate.isEmpty
                                          ? Colors.grey
                                          : Colors.black87),
                                ),
                                const Icon(Icons.arrow_drop_down,
                                    color: AppColors.darkGrey),
                              ]),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 28),

                  // ── Tombol simpan ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isUploading
                          ? null
                          : () async {
                              if (nameCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Nama hewan tidak boleh kosong.")));
                                return;
                              }
                              // Tentukan final type
                              String finalType = dropdownType == 'Lainnya'
                                  ? (customTypeCtrl.text.trim().isNotEmpty
                                      ? customTypeCtrl.text.trim()
                                      : 'Lainnya')
                                  : dropdownType;

                              setModalState(() => isUploading = true);
                              String? petPicUrl = existingPetPic;
                              
                              try {
                                if (petImageBytes != null) {
                                  petPicUrl = await ImageUploadService.uploadImage(petImageBytes!, folder: 'pet_pics');
                                  if (petPicUrl == null || petPicUrl.isEmpty) {
                                    throw Exception("URL gambar kosong");
                                  }
                                }

                                final petData = <String, dynamic>{
                                  'name': nameCtrl.text.trim(),
                                  'type': finalType,
                                  'age': ageCtrl.text.trim(),
                                  'breed': breedCtrl.text.trim(),
                                  'gender': gender,
                                  'status': status,
                                  'vaccineDate': vaccineDate,
                                  'petPic': petPicUrl ?? '',
                                  'updatedAt': FieldValue.serverTimestamp(),
                                };
                                if (petId == null) {
                                  petData['createdAt'] = FieldValue.serverTimestamp();
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(currentUser!.uid)
                                      .collection('pets')
                                      .add(petData);
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(currentUser!.uid)
                                      .collection('pets')
                                      .doc(petId)
                                      .update(petData);
                                }
                                setModalState(() => isUploading = false);
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (e) {
                                setModalState(() => isUploading = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Gagal menyimpan: $e")),
                                  );
                                }
                              }
                            },
                      child: isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(
                              pet == null ? "Tambah Peliharaan" : "Simpan Perubahan",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16)),
                    ),
                  ),

                  // ── Tombol hapus (hanya saat edit) ──
                  if (petId != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text("Hapus Peliharaan",
                            style: TextStyle(fontSize: 16)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deletePet(petId, nameCtrl.text.trim().isNotEmpty
                              ? nameCtrl.text.trim()
                              : (pet?['name'] ?? 'Peliharaan'));
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ──── HELPER: emoji berdasarkan jenis hewan ────
  String _getEmojiForType(String type) {
    final t = type.toLowerCase().trim();

    // Hewan populer
    if (t.contains('kucing') || t.contains('cat') || t.contains('kitten')) return '🐱';
    if (t.contains('anjing') || t.contains('dog') || t.contains('puppy')) return '🐶';
    if (t.contains('kelinci') || t.contains('rabbit') || t.contains('bunny')) return '🐰';
    if (t.contains('hamster')) return '🐹';

    // Burung
    if (t.contains('burung') || t.contains('bird')) return '🐦';
    if (t.contains('parrot') || t.contains('beo') || t.contains('nuri') || t.contains('kakatua')) return '🦜';
    if (t.contains('ayam') || t.contains('chicken') || t.contains('rooster')) return '🐔';
    if (t.contains('bebek') || t.contains('duck') || t.contains('itik')) return '🦆';
    if (t.contains('angsa') || t.contains('goose')) return '🦢';
    if (t.contains('merpati') || t.contains('pigeon') || t.contains('dove')) return '🕊️';
    if (t.contains('elang') || t.contains('eagle') || t.contains('hawk')) return '🦅';
    if (t.contains('burung hantu') || t.contains('owl')) return '🦉';
    if (t.contains('flamingo')) return '🦩';
    if (t.contains('merak') || t.contains('peacock')) return '🦚';
    if (t.contains('penguin')) return '🐧';

    // Ikan & air
    if (t.contains('ikan') || t.contains('fish')) return '🐟';
    if (t.contains('koi') || t.contains('mas')) return '🐠';
    if (t.contains('hiu') || t.contains('shark')) return '🦈';
    if (t.contains('lumba') || t.contains('dolphin')) return '🐬';
    if (t.contains('paus') || t.contains('whale')) return '�';
    if (t.contains('gurita') || t.contains('octopus')) return '🐙';
    if (t.contains('kepiting') || t.contains('crab')) return '🦀';
    if (t.contains('udang') || t.contains('shrimp')) return '🦐';
    if (t.contains('lobster')) return '🦞';
    if (t.contains('siput') || t.contains('snail')) return '🐌';

    // Reptil & amfibi
    if (t.contains('kura') || t.contains('turtle') || t.contains('tortoise')) return '🐢';
    if (t.contains('ular') || t.contains('snake') || t.contains('python') || t.contains('cobra')) return '🐍';
    if (t.contains('iguana') || t.contains('kadal') || t.contains('lizard') || t.contains('gecko')) return '🦎';
    if (t.contains('buaya') || t.contains('crocodile') || t.contains('alligator')) return '🐊';
    if (t.contains('katak') || t.contains('kodok') || t.contains('frog') || t.contains('toad')) return '�';
    if (t.contains('bunglon') || t.contains('chameleon') || t.contains('komodo')) return '🦎';

    // Mamalia kecil
    if (t.contains('marmut') || t.contains('guinea pig')) return '🐹';
    if (t.contains('tikus') || t.contains('rat') || t.contains('mouse') || t.contains('mencit')) return '🐭';
    if (t.contains('landak') || t.contains('hedgehog')) return '🦔';
    if (t.contains('tupai') || t.contains('squirrel')) return '�️';
    if (t.contains('musang') || t.contains('ferret')) return '🦡';
    if (t.contains('rakun') || t.contains('raccoon')) return '🦝';
    if (t.contains('berang') || t.contains('otter')) return '🦦';
    if (t.contains('kelelawar') || t.contains('bat')) return '🦇';

    // Mamalia besar / ternak
    if (t.contains('sapi') || t.contains('cow') || t.contains('lembu') || t.contains('kerbau')) return '�';
    if (t.contains('kambing') || t.contains('goat') || t.contains('domba') || t.contains('sheep')) return '🐐';
    if (t.contains('babi') || t.contains('pig') || t.contains('piglet')) return '🐷';
    if (t.contains('kuda') || t.contains('horse') || t.contains('pony')) return '🐴';
    if (t.contains('keledai') || t.contains('donkey')) return '🫏';
    if (t.contains('unta') || t.contains('camel')) return '🐪';
    if (t.contains('rusa') || t.contains('deer')) return '🦌';
    if (t.contains('gajah') || t.contains('elephant')) return '�';
    if (t.contains('jerapah') || t.contains('giraffe')) return '🦒';
    if (t.contains('zebra')) return '🦓';
    if (t.contains('kuda nil') || t.contains('hippo')) return '🦛';
    if (t.contains('badak') || t.contains('rhino')) return '🦏';
    if (t.contains('beruang') || t.contains('bear')) return '🐻';
    if (t.contains('panda')) return '🐼';
    if (t.contains('koala')) return '🐨';
    if (t.contains('kanguru') || t.contains('kangaroo')) return '🦘';
    if (t.contains('monyet') || t.contains('monkey') || t.contains('kera')) return '🐒';
    if (t.contains('gorila') || t.contains('gorilla')) return '🦍';
    if (t.contains('singa') || t.contains('lion')) return '🦁';
    if (t.contains('harimau') || t.contains('tiger')) return '🐯';
    if (t.contains('macan') || t.contains('leopard') || t.contains('cheetah')) return '🐆';
    if (t.contains('serigala') || t.contains('wolf')) return '🐺';
    if (t.contains('rubah') || t.contains('fox')) return '�';
    if (t.contains('bison') || t.contains('banteng')) return '🐃';
    if (t.contains('llama') || t.contains('alpaka') || t.contains('alpaca')) return '🦙';

    // Serangga & lainnya
    if (t.contains('kupu') || t.contains('butterfly')) return '🦋';
    if (t.contains('lebah') || t.contains('bee') || t.contains('tawon')) return '🐝';
    if (t.contains('semut') || t.contains('ant')) return '🐜';
    if (t.contains('kumbang') || t.contains('beetle') || t.contains('bug')) return '🐛';
    if (t.contains('laba') || t.contains('spider')) return '🕷️';
    if (t.contains('kalajengking') || t.contains('scorpion')) return '🦂';
    if (t.contains('belalang') || t.contains('grasshopper') || t.contains('cricket')) return '🦗';

    // Default
    return '🐾';
  }

  Widget _petField(IconData icon, String label, TextEditingController ctrl) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: label, labelStyle: const TextStyle(fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ),
    ]);
  }

  Widget _petDropdown(IconData icon, String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: label, labelStyle: const TextStyle(fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
          items: items.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: onChanged,
        ),
      ),
    ]);
  }

  // ──── TAPPABLE INFO ROW ────
  Widget _infoRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    final bool editable = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
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

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Center(child: Text("Silakan login"));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Profil Saya"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Data profil tidak ditemukan."));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? "Pengguna";
          final email = data['email'] ?? currentUser!.email ?? "";
          final phone = (data['phone'] as String?) ?? '';
          final address = (data['address'] as String?) ?? '';
          final profilePicUrl = data['profilePic'] as String?;

          String initials = "U";
          if (name.isNotEmpty) {
            final w = name.trim().split(' ');
            initials = w.length > 1 ? (w[0][0] + w[1][0]).toUpperCase() : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Foto Profil ──
                Center(
                  child: Stack(alignment: Alignment.bottomRight, children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primaryLight,
                      child: _isUploadingPic
                          ? const CircularProgressIndicator()
                          : (profilePicUrl != null && profilePicUrl.isNotEmpty)
                              ? ClipOval(
                                  child: AppNetworkImage(
                                    url: profilePicUrl,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) {
                                      return Text(
                                        initials,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 40,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Text(
                                  initials,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 40,
                                  ),
                                ),
                    ),
                    GestureDetector(
                      onTap: _uploadProfilePic,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                Center(child: Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                Center(child: Text(email, style: const TextStyle(color: AppColors.darkGrey, fontSize: 13))),

                const SizedBox(height: 24),

                // ── Informasi Akun (tappable rows, no Edit button) ──
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Align(alignment: Alignment.centerLeft,
                          child: Text("Informasi Akun", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      ),
                      const Divider(height: 1),
                      _infoRow(Icons.person, "Nama", name,
                          onTap: () => _quickEdit('name', 'Nama Lengkap', name)),
                      const Divider(height: 1),
                      _infoRow(Icons.email, "Email", email), // read-only
                      const Divider(height: 1),
                      _infoRow(Icons.phone, "Telepon", phone.isEmpty ? '-' : phone,
                          onTap: () => _quickEdit('phone', 'Nomor Telepon', phone, inputType: TextInputType.phone)),
                      const Divider(height: 1),
                      _infoRow(Icons.location_on, "Alamat", address.isEmpty ? '-' : address,
                          onTap: () => _pickLocation(address)),
                      const SizedBox(height: 4),
                    ]),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Hewan Peliharaan ──
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("Hewan Peliharaan Saya", style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
                    onPressed: () => _showAddEditPetSheet(),
                  ),
                ]),
                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).collection('pets').snapshots(),
                  builder: (context, petSnap) {
                    if (petSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!petSnap.hasData || petSnap.data!.docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: AppColors.primaryLight),
                        ),
                        child: Column(children: [
                          const Icon(Icons.pets, size: 40, color: AppColors.primary),
                          const SizedBox(height: 10),
                          const Text("Belum ada hewan peliharaan", style: TextStyle(color: AppColors.darkGrey)),
                          TextButton(
                            onPressed: () => _showAddEditPetSheet(),
                            child: const Text("Tambah Sekarang", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ),
                        ]),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: petSnap.data!.docs.length,
                      itemBuilder: (context, index) {
                        final petDoc = petSnap.data!.docs[index];
                        final pet = petDoc.data() as Map<String, dynamic>;
                        final String emoji = _getEmojiForType(pet['type'] ?? '');
                        final petPic = pet['petPic'] as String? ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            // Tap card → langsung edit
                            onTap: () => _showAddEditPetSheet(pet, petDoc.id),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: AppColors.secondaryOrangeLight,
                                  backgroundImage: petPic.isNotEmpty ? appNetworkImageProvider(petPic) : null,
                                  child: petPic.isEmpty ? Text(emoji, style: const TextStyle(fontSize: 28)) : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(pet['name'] ?? 'Peliharaan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text("${pet['type']} • ${pet['age']} • ${pet['breed']}", style: const TextStyle(fontSize: 12, color: AppColors.darkGrey)),
                                    const SizedBox(height: 6),
                                    Row(children: [
                                      // Gender badge
                                      if ((pet['gender'] ?? '').isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: pet['gender'] == 'Betina' ? Colors.pink.shade50 : Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: pet['gender'] == 'Betina' ? Colors.pink.shade200 : Colors.blue.shade200),
                                          ),
                                          child: Text(
                                            pet['gender'] == 'Betina' ? '♀ Betina' : '♂ Jantan',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: pet['gender'] == 'Betina' ? Colors.pink.shade600 : Colors.blue.shade600),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: pet['status'] == 'Sehat' ? AppColors.secondaryGreen : AppColors.secondaryOrange,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(pet['status'] ?? 'Sehat', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text("Vaksin: ${pet['vaccineDate'] ?? '-'}", style: const TextStyle(fontSize: 11, color: AppColors.darkGrey), overflow: TextOverflow.ellipsis),
                                      ),
                                    ]),
                                  ]),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.grey),
                              ]),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 32),

                // ── Tombol Keluar ──
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      backgroundColor: Colors.red.shade50,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async => await FirebaseAuth.instance.signOut(),
                    child: Text(
                      "Keluar",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red.shade600, letterSpacing: 0.3),
                    ),
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
