import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000/api";

  static Future<Map<String, dynamic>?> register(
      String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Accept": "application/json"},
        body: {
          "name": name,
          "email": email,
          "password": password,
        },
      );

      print("REGISTER STATUS: ${response.statusCode}");
      print("REGISTER BODY: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print("ERROR: $e");
      return null;
    }
  }

  static Future<bool> login(String email, String password) async {
    try {
      final url = Uri.parse("$baseUrl/login");

      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json", // ✅ penting untuk Laravel
        },
        body: {
          "email": email,
          "password": password,
        },
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("USER DATA: $data");
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("ERROR: $e");
      return false;
    }
  }
}