abstract class AppTranslations {
  static const Map<String, Map<String, String>> data = {
    'en': {
      'search_hint': 'Search',
      'map_placeholder': 'Interactive map will be here',
      'cafe': 'Cafes',
      'restaurant': 'Restaurants',
      'park': 'Parks',
      'playground': 'Playgrounds',
      'build_route': 'Build route',
      'loading': 'Loading...',
      'km': 'km',
      'min': 'min',
      'settings': 'Settings',
      'theme_dark': 'Dark Mode',
      'language': 'Language',
    },
    'uk': {
      'search_hint': 'Пошук',
      'map_placeholder': 'Тут буде інтерактивна мапа',
      'cafe': 'Кав\'ярні',
      'restaurant': 'Ресторани',
      'park': 'Парки',
      'playground': 'Майданчики',
      'build_route': 'Побудувати маршрут',
      'loading': 'Завантаження...',
      'km': 'км',
      'min': 'хв',
      'settings': 'Налаштування',
      'theme_dark': 'Темна тема',
      'language': 'Мова',
    },
    'ru': {
      'search_hint': 'Поиск',
      'map_placeholder': 'Тут будет интерактивная карта',
      'cafe': 'Кафе',
      'restaurant': 'Рестораны',
      'park': 'Парки',
      'playground': 'Площадки',
      'build_route': 'Построить маршрут',
      'loading': 'Загрузка...',
      'km': 'км',
      'min': 'мин',
      'settings': 'Настройки',
      'theme_dark': 'Темная тема',
      'language': 'Язык',
    },
  };

  // Безопасный метод: перенаправляет 'ua' на 'uk' и никогда не возвращает null
  static String tr(String key, String lang) {
    // Поддерживаем и 'uk', и 'ua'
    final l = (lang == 'ua' || lang == 'uk') ? 'uk' : lang;
    final dict = data[l] ?? data['ru'] ?? data['en'] ?? {};
    return dict[key] ?? data['en']?[key] ?? key;
  }}