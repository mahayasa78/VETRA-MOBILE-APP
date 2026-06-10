import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ImgbbService {
  static const String _apiKey = '2aa8726d59f37da4b4139a2df1f0770e';
  static const String _apiUrl = 'https://api.imgbb.com/1/upload';

  static Future<String?> uploadImage(Uint8List imageBytes, {int retryCount = 0}) async {
    try {
      if (imageBytes.isEmpty) {
        throw Exception("Image bytes are empty");
      }

      String base64Image = base64Encode(imageBytes);
      print("ImgBB: Uploading image (${imageBytes.length} bytes), attempt ${retryCount + 1}");

      var request = http.MultipartRequest('POST', Uri.parse('$_apiUrl?key=$_apiKey'));
      request.fields['image'] = base64Image;

      var response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout after 30 seconds');
        },
      );

      var responseData = await response.stream.bytesToString();
      print("ImgBB Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        var result = json.decode(responseData);

        if (result['success'] == true) {
          // Gunakan data.url (direct link) agar gambar bisa dimuat tanpa masalah Referer
          final imageUrl = result['data']?['url']
              ?? result['data']?['image']?['url']
              ?? result['data']?['display_url'];

          print("ImgBB Image URL: $imageUrl");

          if (imageUrl == null || imageUrl.toString().isEmpty) {
            throw Exception("ImgBB returned empty URL");
          }

          return imageUrl.toString();
        } else {
          final errorMsg = result['error']?['message'] ?? 'Failed to upload image to ImgBB';
          print("ImgBB Error: $errorMsg");
          throw Exception(errorMsg);
        }
      } else {
        print("ImgBB Response Data: $responseData");

        if ((response.statusCode >= 500 || response.statusCode == 429) && retryCount < 2) {
          print("Retrying upload after ${retryCount + 1} seconds...");
          await Future.delayed(Duration(seconds: retryCount + 1));
          return uploadImage(imageBytes, retryCount: retryCount + 1);
        }

        throw Exception("HTTP ${response.statusCode}: $responseData");
      }
    } on http.ClientException catch (e) {
      print("ImgBB ClientException: $e");

      if (retryCount < 2) {
        print("Retrying upload after ${retryCount + 1} seconds...");
        await Future.delayed(Duration(seconds: retryCount + 1));
        return uploadImage(imageBytes, retryCount: retryCount + 1);
      }

      throw Exception("Koneksi gagal: $e. Pastikan internet stabil.");
    } catch (e) {
      print("ImgBB Upload Error: $e");

      if (retryCount < 2 && e.toString().contains('SocketException')) {
        print("Retrying upload after ${retryCount + 1} seconds...");
        await Future.delayed(Duration(seconds: retryCount + 1));
        return uploadImage(imageBytes, retryCount: retryCount + 1);
      }

      throw Exception("Gagal mengunggah gambar: $e");
    }
  }
}
