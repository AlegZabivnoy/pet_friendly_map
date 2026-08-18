// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get welcomeTitle => 'Добро пожаловать!';

  @override
  String get welcomeSubtitle => 'Давайте создадим ваш профиль';

  @override
  String get loginTitle => 'С возвращением!';

  @override
  String get loginSubtitle => 'Войдите в свой профиль';

  @override
  String get nameHint => 'Ваше имя';

  @override
  String get nicknameHint => 'Никнейм (@doglover)';

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Пароль';

  @override
  String get loginBtn => 'Войти';

  @override
  String get registerBtn => 'Зарегистрироваться';

  @override
  String get noAccount => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get haveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get errorEmailPassword => 'Заполните email и пароль';

  @override
  String get errorName => 'Введите ваше имя';

  @override
  String get errorDefault => 'Произошла ошибка';

  @override
  String get myProfile => 'Мой профиль';

  @override
  String get myPets => 'Мои питомцы';

  @override
  String get addFirstPet => 'Добавьте первого питомца';

  @override
  String get newPetTitle => 'Новый питомец';

  @override
  String get petNameHint => 'Кличка питомца';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get noName => 'Без клички';

  @override
  String get nameNotSpecified => 'Имя не указано';
}
