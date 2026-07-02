class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'SIGAT_API_URL',
    defaultValue: 'http://3.238.34.3:8081/api',
  );
}
