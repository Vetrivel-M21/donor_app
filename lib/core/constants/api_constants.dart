class ApiConstants {
  ApiConstants._();

  static const String defaultBaseUrl = 'https://trustapi.arminfo.in/api/v1';
  // static const String defaultBaseUrl = 'http://10.10.100.30:2091/api/v1';

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return defaultBaseUrl;
  }

  /// Default Razorpay API Key ID configured from the trust application environment.
  static const String defaultRazorpayKeyId = 'rzp_test_TfQpbUY4dzcxkF';

  static String get razorpayKeyId {
    const fromEnv = String.fromEnvironment('RAZORPAY_KEY_ID');
    if (fromEnv.isNotEmpty) return fromEnv;
    return defaultRazorpayKeyId;

  }

  static String assetUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final serverBase = baseUrl.replaceAll('/api/v1', '');
    return '$serverBase$path';
  }
}
 