import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';
import '../data/mock_places.dart';

class PlaceService {
  // Вставьте сюда вашу ссылку из Google Apps Script (/exec на конце)
  static const String _url = 'https://script.google.com/macros/s/AKfycbwwCY0CgpYLsoXU26kQtAUTZR-usfeRYlJzWwSsbsGl7YehJz0m2p2ja6-wFdz4_L1h/exec';

  static Future<List<PetFriendlyPlace>> fetchPlaces() async {
    try {
      final response = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => PetFriendlyPlace.fromJson(e)).toList();
      }
    } catch (e) {
      print('Ошибка загрузки из Google Таблицы: $e');
    }

    // Если нет интернета — отдаем запасной список
    return mockPlacesList;
  }
}