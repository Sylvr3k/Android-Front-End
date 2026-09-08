/// Centralized runtime configuration for the app. Nothing else in the
/// codebase should hardcode the API base URL — override it per-environment
/// with `--dart-define=API_BASE_URL=...` at build/run time.
///
/// Defaults:
/// - Android emulator talking to a Laravel server on the host machine:
///   http://10.0.2.2:8000/api/v1 (the emulator's alias for the host's
///   localhost).
/// - Physical Android device: replace with your machine's LAN IP, e.g.
///   http://192.168.1.50:8000/api/v1.
/// - Production: an HTTPS domain, e.g. https://evaluations.ist.ac.ke/api/v1.
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const String appName = 'IST Trainer Evaluation';
}
