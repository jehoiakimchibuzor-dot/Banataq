final class AppConstants {
  AppConstants._();

  static const String appName = 'Banataq';
  static const int maxMessageLength = 5000;
  static const int maxConversationTitleLength = 100;
  static const int recentMessageCount = 50;
  static const int syncRetryMaxAttempts = 5;
  static const Duration syncRetryBaseDelay = Duration(seconds: 2);
  static const Duration sessionTimeout = Duration(days: 30);
}
