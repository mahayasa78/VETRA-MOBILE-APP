import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_upload_service.dart';
import '../utils/app_colors.dart';

class AddArticleScreen extends StatefulWidget {
  final String? articleId;
  final Map<String, dynamic>? initialData;

  const AddArticleScreen({super.key, this.articleId, this.initialData});

  @override
  State<AddArticleScreen> createState() => _AddArticleScreenState();
}

class _AddArticleScreenState extends State<AddArticleScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  Uint8List? _imageBytes;
  String? _existingImageUrl;
  bool _isLoading = false;

  bool get _isEditMode => widget.articleId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode && widget.initialData != null) {
      _titleController.text = widget.initialData!['title'] ?? '';
      _contentController.text = widget.initialData!['desc'] ?? '';
      _existingImageUrl = widget.initialData!['image_url'];
    }
  }

  Future<void> _pickImage() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Gagal mengambil gambar: $e")),
      );
    }
  }

  Future<void> _submitArticle() async {
    final title = _titleController.text.trim();
    final desc = _contentController.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul dan isi artikel tidak boleh kosong!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      String? finalImageUrl = _existingImageUrl;

      // Upload new image if selected
      if (_imageBytes != null) {
        finalImageUrl = await ImageUploadService.uploadImage(_imageBytes!, folder: 'articles');
        if (finalImageUrl == null) {
          throw Exception("Gagal mendapatkan URL gambar.");
        }
      }

      final articleData = {
        'title': title,
        'desc': desc,
        'image_url': finalImageUrl ?? '',
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (_isEditMode) {
        await FirebaseFirestore.instance.collection('articles').doc(widget.articleId).update(articleData);
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text("Artikel berhasil diperbarui!")),
          );
        }
      } else {
        articleData['created_at'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('articles').add(articleData);
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text("Artikel berhasil ditambahkan!")),
          );
        }
      }
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditMode ? "Edit Artikel" : "Tambah Artikel Baru"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🖼️ Image Picker / Banner Preview
              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.grey),
                    image: _imageBytes != null
                        ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                        : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty
                            ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover)
                            : null),
                  ),
                  child: (_imageBytes == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty))
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 50, color: AppColors.darkGrey),
                            SizedBox(height: 8),
                            Text("Pilih Gambar Sampul Artikel", style: TextStyle(color: AppColors.darkGrey, fontSize: 13)),
                            Text("(Ukuran disarankan lanskap)", style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        )
                      : Container(
                          alignment: Alignment.bottomRight,
                          padding: const EdgeInsets.all(10),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.edit, color: Colors.white, size: 18),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Title Field
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Judul Artikel",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Formatting Guide Card
              Card(
                color: Colors.blue.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.shade100),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Text("Tips Format Teks Menarik:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text("• Ketik # [spasi] teks di awal baris untuk membuat Judul Utama.", style: TextStyle(fontSize: 11, color: Colors.black87)),
                      Text("• Ketik ## [spasi] teks di awal baris untuk membuat Sub-judul.", style: TextStyle(fontSize: 11, color: Colors.black87)),
                      Text("• Ketik - [spasi] teks di awal baris untuk membuat Point-point (List).", style: TextStyle(fontSize: 11, color: Colors.black87)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Content Field
              TextField(
                controller: _contentController,
                maxLines: 12,
                decoration: InputDecoration(
                  labelText: "Isi Artikel / Edukasi",
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitArticle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isEditMode ? "Update Artikel" : "Simpan & Publikasikan",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
