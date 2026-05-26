class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'SIGAT_API_URL',
    defaultValue: 'http://10.0.2.2:8081/api',
  );
}
