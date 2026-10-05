/// Base URL of the LearnHub API. Override at build/run time:
/// `flutter run -d chrome --dart-define=API_URL=https://example.com/api`
const String apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:4000/api',
);
