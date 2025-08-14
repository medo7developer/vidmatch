class AppConstants {
  // API Keys
  static const String firebaseApiKey = 'AIzaSyA7syl0NYZo1RAOK9ieMg9jrCz9x8_4934';

  // App Settings
  static const int reconnectAttempts = 3;
  static const int sessionTimeoutSeconds = 120;

  // URLs
  static const String privacyPolicyUrl = 'https://example.com/privacy-policy';
  static const String termsOfServiceUrl = 'https://example.com/terms-of-service';
  static const String reportAbuseUrl = 'https://example.com/report-abuse';

  // WebRTC
  static const Map<String, dynamic> webRtcConfig = {
    'iceServers': [
      {'urls': ['stun:stun1.l.google.com:19302']},
      {'urls': ['stun:stun2.l.google.com:19302']},
    ],
  };

  // Timeouts
  static const Duration userInactiveTimeout = Duration(minutes: 5);
  static const Duration searchTimeout = Duration(seconds: 30);

  // Firebase References
  static const String usersRef = 'users';
  static const String sessionsRef = 'sessions';
}
