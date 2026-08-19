// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get welcomeTitle => 'Ласкаво просимо!';

  @override
  String get welcomeSubtitle => 'Давайте створимо ваш профіль';

  @override
  String get loginTitle => 'З поверненням!';

  @override
  String get loginSubtitle => 'Увійдіть у свій профіль';

  @override
  String get nameHint => 'Ваше ім\'я';

  @override
  String get nicknameHint => 'Нікнейм (@doglover)';

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Пароль';

  @override
  String get loginBtn => 'Увійти';

  @override
  String get registerBtn => 'Зареєструватися';

  @override
  String get noAccount => 'Немає акаунту? Зареєструватися';

  @override
  String get haveAccount => 'Вже є акаунт? Увійти';

  @override
  String get errorEmailPassword => 'Заповніть email та пароль';

  @override
  String get errorName => 'Введіть ваше ім\'я';

  @override
  String get errorDefault => 'Сталася помилка';

  @override
  String get myProfile => 'Мій профіль';

  @override
  String get myPets => 'Мої улюбленці';

  @override
  String get addFirstPet => 'Додайте першого улюбленця';

  @override
  String get newPetTitle => 'Новий улюбленець';

  @override
  String get petNameHint => 'Кличка улюбленця';

  @override
  String get petSize => 'Розмір улюбленця';

  @override
  String get sizeSmall => 'Маленький (<10 кг)';

  @override
  String get sizeMedium => 'Середній (10–25 кг)';

  @override
  String get sizeLarge => 'Великий (>25 кг)';

  @override
  String get sizeSmallShort => 'Маленький';

  @override
  String get sizeMediumShort => 'Середній';

  @override
  String get sizeLargeShort => 'Великий';

  @override
  String get cancel => 'Скасувати';

  @override
  String get save => 'Зберегти';

  @override
  String get noName => 'Без клички';

  @override
  String get nameNotSpecified => 'Ім\'я не вказано';
}
