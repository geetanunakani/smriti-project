/// Pass the key at run time so it never lives in source control:
///   flutter run --dart-define=GEMINI_API_KEY=your_key_here
/// (Android Studio: Run > Edit Configurations > "Additional run args")
///
/// No key? The app runs in DEMO MODE with sample data, which is handy
/// for testing the UI.
class AppConfig {
  static const geminiApiKey =
  String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static bool get hasKey => geminiApiKey.isNotEmpty;

  /// Change here if Google renames the model.
  static const geminiModel = 'gemini-3.5-flash';
}