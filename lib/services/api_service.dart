import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String nickname,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'nickname': nickname.isEmpty ? '@user' : nickname,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        await prefs.setString('user_name', data['user']['name']);
        await prefs.setString('user_nickname', data['user']['nickname']);
        await prefs.setBool('is_registered', true);
        return {'success': true};
      }
      return {'success': false, 'error': data['error'] ?? 'Ошибка регистрации'};
    } catch (e) {
      return {'success': false, 'error': 'Сервер недоступен'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        await prefs.setString('user_name', data['user']['name']);
        await prefs.setString('user_nickname', data['user']['nickname']);
        await prefs.setBool('is_registered', true);
        return {'success': true};
      }
      return {'success': false, 'error': data['error'] ?? 'Ошибка входа'};
    } catch (e) {
      return {'success': false, 'error': 'Сервер недоступен'};
    }
  }

  static Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> addPet(String name, String? imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/pets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'imagePath': imagePath,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<bool> deletePet(int petId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/pets/$petId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}