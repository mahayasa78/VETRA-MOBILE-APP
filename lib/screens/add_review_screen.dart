import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_upload_service.dart';
import '../utils/app_colors.dart';

class AddReviewScreen extends StatefulWidget {
  final String targetId;
  final String targetType; // 'klinik' atau 'dokter'
  final String targetName;

  const AddReviewScreen({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.targetName,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> with TickerProviderStateMixin {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  Uint8List? _selectedImageBytes;
  bool _isSubmitting = false;
  late AnimationController _starAnimController;

  final List<String> _ratingLabels = [
    '',
    'Buruk 😞',
    'Kurang 😕',
    'Cukup 😐',
    'Bagus 😊',
    'Sangat Bagus 🤩',
  ];

  final List<Color> _ratingColors = [
    Colors.transparent,
    Colors.red.shade400,
    Colors.orange.shade400,
    Colors.yellow.shade700,
    Colors.lightGreen.shade500,
    Colors.green.shade500,
  ];

  @override
  void initState() {
    super.initState();
    _starAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _starAnimController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _selectedImageBytes = bytes);
    }
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih rating bintang terlebih dahulu.'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? user.displayName ?? 'Pengguna';
      final userAvatar = userDoc.data()?['profilePic'] ?? user.photoURL ?? '';

      // Upload image if selected
      String imageUrl = '';
      if (_selectedImageBytes != null) {
        final uploadedUrl = await ImageUploadService.uploadImage(_selectedImageBytes!, folder: 'reviews');
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          imageUrl = uploadedUrl;
        } else {
          throw Exception("Gagal mendapatkan URL gambar");
        }
      }

      // Check if user already reviewed this target
      final existingReview = await FirebaseFirestore.instance
          .collection('reviews')
          .where('targetId', isEqualTo: widget.targetId)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (existingReview.docs.isNotEmpty) {
        // Update existing review
        await existingReview.docs.first.reference.update({
          'rating': _selectedRating.toDouble(),
          'comment': _commentController.text.trim(),
          if (imageUrl.isNotEmpty) 'image_url': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new review
        await FirebaseFirestore.instance.collection('reviews').add({
          'targetId': widget.targetId,
          'targetType': widget.targetType,
          'userId': user.uid,
          'userName': userName,
          'userAvatar': userAvatar,
          'rating': _selectedRating.toDouble(),
          'comment': _commentController.text.trim(),
          'image_url': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Ulasan berhasil dikirim! Terima kasih.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim ulasan: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Belum login')),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, userSnap) {
        String userPhoto = '';
        String userName = 'Pengguna';
        if (userSnap.hasData && userSnap.data!.exists) {
          final userData = userSnap.data!.data() as Map<String, dynamic>?;
          userPhoto = userData?['profilePic'] ?? '';
          userName = userData?['name'] ?? 'Pengguna';
        }
        final userInitial = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'P';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Beri Ulasan',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : const Text(
                          'Kirim',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (i) {
                    final starIndex = i + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedRating = starIndex);
                        _starAnimController.forward(from: 0);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Icon(
                          starIndex <= _selectedRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: starIndex <= _selectedRating
                              ? Colors.amber
                              : Colors.grey.shade400,
                          size: 42,
                        ),
                      ),
                    );
                  }),
                ),

            // Rating label
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 8),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10, left: 60),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _selectedRating > 0
                        ? _ratingColors[_selectedRating].withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _selectedRating > 0 ? _ratingLabels[_selectedRating] : '',
                    style: TextStyle(
                      color: _selectedRating > 0 ? _ratingColors[_selectedRating] : Colors.transparent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              crossFadeState: _selectedRating > 0
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),

            const SizedBox(height: 24),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 20),

            // Photo upload — "Tambahkan foto & komentar" (like Google Maps)
            const Text(
              'Tambahkan foto & komentar dari kunjungan terakhir',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),

            // Photo button (Google Maps style)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Posting foto & komentar',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Preview selected image
            if (_selectedImageBytes != null) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _selectedImageBytes!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImageBytes = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 20),

            // Comment box
            const Text(
              'Tulis ulasan',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Bagikan pengalaman Anda dengan klinik / dokter ini...\n\nContoh: Dokternya ramah, antrian cepat, fasilitas bersih.',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12, height: 1.5),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),

            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedRating > 0 ? AppColors.primary : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: _selectedRating > 0 ? 2 : 0,
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Kirim Ulasan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
