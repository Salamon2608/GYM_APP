class AppConstants {
  // Backend API URL
  static const String apiBaseUrl = 'http://192.168.1.36:3000/api';

  // Razorpay Configuration
  // USER: Replace with your actual Razorpay Key (Test or Live)
  // Get this from: https://dashboard.razorpay.com/app/keys
  static const String razorpayKey = 'rzp_test_YOUR_KEY';

  // Attendance Configuration
  static const int defaultGeoFenceRadiusMeters = 100;

  /// Dynamically formats a relative or absolute upload path to use the current API server base URL.
  static String getFullImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';

    try {
      final apiUri = Uri.parse(apiBaseUrl);
      final serverBaseUrl =
          '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ":${apiUri.port}" : ""}';

      if (url.startsWith('http')) {
        if (url.contains('/uploads/')) {
          final parts = url.split('/uploads/');
          return '$serverBaseUrl/uploads/${parts.sublist(1).join('/uploads/')}';
        }
        return url;
      }

      if (url.startsWith('/')) {
        return '$serverBaseUrl$url';
      }
      return '$serverBaseUrl/$url';
    } catch (_) {
      return url;
    }
  }
}
