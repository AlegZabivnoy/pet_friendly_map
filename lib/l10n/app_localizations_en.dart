// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTitle => 'Welcome!';

  @override
  String get welcomeSubtitle => 'Let\'s create your profile';

  @override
  String get loginTitle => 'Welcome back!';

  @override
  String get loginSubtitle => 'Log in to your profile';

  @override
  String get nameHint => 'Your name';

  @override
  String get nicknameHint => 'Nickname (@doglover)';

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Password';

  @override
  String get loginBtn => 'Log In';

  @override
  String get registerBtn => 'Sign Up';

  @override
  String get noAccount => 'Don\'t have an account? Sign Up';

  @override
  String get haveAccount => 'Already have an account? Log In';

  @override
  String get errorEmailPassword => 'Enter email and password';

  @override
  String get errorName => 'Enter your name';

  @override
  String get errorDefault => 'An error occurred';

  @override
  String get myProfile => 'My Profile';

  @override
  String get myPets => 'My Pets';

  @override
  String get addFirstPet => 'Add your first pet';

  @override
  String get newPetTitle => 'New Pet';

  @override
  String get petNameHint => 'Pet name';

  @override
  String get petSize => 'Pet Size';

  @override
  String get sizeSmall => 'Small (<10 kg)';

  @override
  String get sizeMedium => 'Medium (10–25 kg)';

  @override
  String get sizeLarge => 'Large (>25 kg)';

  @override
  String get sizeSmallShort => 'Small';

  @override
  String get sizeMediumShort => 'Medium';

  @override
  String get sizeLargeShort => 'Large';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get noName => 'No name';

  @override
  String get nameNotSpecified => 'Name not specified';

  @override
  String get savedPlaces => 'Saved Places';

  @override
  String get noSavedPlaces => 'No saved places yet';
}
