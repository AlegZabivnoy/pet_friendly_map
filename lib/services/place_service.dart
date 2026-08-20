import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';
import '../data/mock_places.dart';

class PlaceService {
  // Вставьте сюда вашу ссылку из Google Apps Script (/exec на конце)
  static const String _url = 'https://script.google.com/macros/s/AKfycbybL1xyzDHL6bIS_EABZXOzl4dlxWE1uGRPxgCeEQ22U_J5RtU3fKMTQ-k33K4RIpwd/exec';

  static Future<List<PetFriendlyPlace>> fetchPlaces() async {
    try {
      final response = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
        final places = data
            .map((e) => PetFriendlyPlace.fromJson(e))
            // Отсеиваем строки без названия или с нулевыми координатами
            .where((place) => 
                place.name.isNotEmpty && 
                (place.coordinates.latitude != 0.0 || place.coordinates.longitude != 0.0)
            )
            .toList();

        if (places.isNotEmpty) {
          return places;
        }
      } else {
        print('Ошибка сервера Google: статус ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка загрузки из Google Таблицы: $e');
    }

    // Если нет интернета или ошибка — отдаем запасной список
    return mockPlacesList;
  }
}