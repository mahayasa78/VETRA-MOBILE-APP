import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = "REMOVED_API_KEY";

  static final List<Content> _systemHistory = [
    Content.text(
      "Mulai sekarang, kamu adalah VETRA, asisten virtual dan ahli kesehatan hewan peliharaan. "
      "Tugasmu adalah menjawab pertanyaan pengguna mengenai kesehatan, perawatan, dan perilaku hewan peliharaan (kucing, anjing, burung, dll). "
      "Gunakan bahasa Indonesia yang ramah, profesional, dan empatik. "
      "PENTING: Jangan pernah menjawab pertanyaan di luar topik hewan peliharaan. Tolak dengan sopan jika itu terjadi.",
    ),
    Content.model([TextPart("Baik, saya mengerti. Saya adalah VETRA, asisten virtual kesehatan hewan peliharaan. Saya siap membantu Anda!")]),
  ];

  /// Kirim pesan teks biasa
  static Future<String> sendMessage(String text) async {
    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
      final chat = model.startChat(history: _systemHistory);
      final response = await chat.sendMessage(Content.text(text));
      return response.text ?? "Maaf, saya tidak dapat merespon saat ini.";
    } catch (e) { 
      final err = e.toString(); 
      if (err.contains('503') || err.contains('high demand')) { 
        return "Maaf, sistem VETRA saat ini sedang sibuk karena banyaknya permintaan. Mohon tunggu beberapa saat dan coba lagi. 🙏"; 
      } 
        return "Terjadi kesalahan pada sistem VETRA. Mohon coba lagi nanti."; 
    }
  }

  /// Kirim pesan dengan gambar (Gemini Vision)
  static Future<String> sendMessageWithImage(String text, Uint8List imageBytes) async {
    try {
      // gemini-1.5-flash mendukung vision
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
      final chat = model.startChat(history: _systemHistory);

      final prompt = text.trim().isNotEmpty ? text.trim() : "Tolong analisis gambar hewan ini dan berikan pendapat tentang kondisi kesehatannya.";

      final content = Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]);

      final response = await chat.sendMessage(content);
      return response.text ?? "Maaf, saya tidak dapat menganalisis gambar ini.";
    } catch (e) {
      final err = e.toString();
      if (err.contains('503') || err.contains('high demand')) {
        return "Maaf, sistem VETRA saat ini sedang sibuk karena banyaknya permintaan. Mohon tunggu beberapa saat dan coba lagi. 🙏";
      }
      return "Terjadi kesalahan saat menganalisis gambar. Mohon coba lagi nanti.";
    }
  }
}
