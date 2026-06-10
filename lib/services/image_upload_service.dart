import 'dart:typed_data';
import 'imgbb_service.dart';

/// Layanan upload gambar — hanya menggunakan ImgBB.
class ImageUploadService {
  static Future<String?> uploadImage(Uint8List imageBytes, {String folder = 'images'}) async {
    try {
      print("Uploading image via ImgBB (folder hint: $folder)...");
      final imgbbUrl = await ImgbbService.uploadImage(imageBytes);
      if (imgbbUrl != null && imgbbUrl.isNotEmpty) {
        print("✅ Upload successful via ImgBB: $imgbbUrl");
        return imgbbUrl;
      }
      throw Exception("ImgBB returned empty URL");
    } catch (e) {
      print("❌ Upload failed: $e");
      throw Exception("Gagal upload gambar. Coba lagi nanti.");
    }
  }
}
