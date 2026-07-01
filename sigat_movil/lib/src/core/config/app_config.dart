class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'SIGAT_API_URL',
    defaultValue: 'http://44.211.181.183:8081/api',
  );
}
