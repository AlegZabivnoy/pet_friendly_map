import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _key = 'favorite_places_ids';

  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<bool> isFavorite(String id) async {
    final list = await getFavorites();
    return list.contains(id);
  }

  static Future<bool> toggleFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    bool isFav;
    if (list.contains(id)) {
      list.remove(id);
      isFav = false;
    } else {
      list.add(id);
      isFav = true;
    }
    await prefs.setStringList(_key, list);
    return isFav;
  }
}