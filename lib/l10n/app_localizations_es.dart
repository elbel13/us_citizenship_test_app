// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Examen de Ciudadanía de EE.UU.';

  @override
  String get mainMenu => 'Menú Principal';

  @override
  String get flashcards => 'Tarjetas de Estudio';

  @override
  String get multipleChoice => 'Opción Múltiple';

  @override
  String get writing => 'Escritura';

  @override
  String get reading => 'Lectura';

  @override
  String get simulatedInterview => 'Entrevista Simulada';

  @override
  String get testReadiness => 'Preparación para el Examen';

  @override
  String get settings => 'Configuración';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';

  @override
  String get onboardingWelcome => '¡Bienvenido!';

  @override
  String get onboardingLanguageSubtitle =>
      'Selecciona tu idioma preferido para la interfaz de la aplicación';

  @override
  String get onboardingStudyLanguageTitle => 'Idioma de Materiales de Estudio';

  @override
  String get onboardingStudyLanguageSubtitle =>
      'El examen de ciudadanía se realiza en inglés. Recomendamos estudiar en inglés para la mejor preparación.';

  @override
  String studyInLanguageRecommended(String language) {
    return 'Estudiar en $language (Recomendado)';
  }

  @override
  String studyInLanguage(String language) {
    return 'Estudiar en $language';
  }

  @override
  String studyLanguageNote(String language) {
    return 'Usar traducciones al $language para ayudar a entender los conceptos';
  }

  @override
  String get onboardingTestVersionTitle => 'Seleccionar Versión del Examen';

  @override
  String get onboardingTestVersionSubtitle =>
      'Elige qué versión de las preguntas del examen de ciudadanía quieres estudiar';

  @override
  String get latest => 'Más Reciente';

  @override
  String get currentTestVersion =>
      'Versión actual del examen (para solicitudes recientes)';

  @override
  String get previousTestVersion => 'Versión anterior del examen';

  @override
  String get onboardingLocationTitle => 'Configuración de Ubicación';

  @override
  String get onboardingLocationSubtitle =>
      'Necesitamos tu ubicación para proporcionar información precisa sobre tus funcionarios gubernamentales locales';

  @override
  String get useMyLocation => 'Usar Mi Ubicación';

  @override
  String get or => 'o';

  @override
  String get enterZipCode => 'Ingresar Código Postal';

  @override
  String locationSet(String state) {
    return 'Ubicación establecida: $state';
  }

  @override
  String zipCode(String zip) {
    return 'Código Postal: $zip';
  }

  @override
  String get enterYourZipCode => 'Ingresa Tu Código Postal';

  @override
  String get cancel => 'Cancelar';

  @override
  String get submit => 'Enviar';

  @override
  String get next => 'Siguiente';

  @override
  String get back => 'Atrás';

  @override
  String get finish => 'Finalizar';

  @override
  String stepProgress(int current, int total) {
    return 'Paso $current de $total';
  }
}
