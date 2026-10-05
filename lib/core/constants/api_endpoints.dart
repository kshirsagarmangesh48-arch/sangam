class ApiEndpoints {
  // Base URLs
  static const String productionBaseUrl = 'https://api.makeinsatara.in/api/v1';
  static const String directIpBaseUrl = 'http://206.189.136.110/api/v1';
  static const String localBaseUrl = 'http://localhost:3000/api/v1';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:3000/api/v1';

  // Active Base URL (change to local/emulator when running local backend)
  static const String activeBaseUrl = productionBaseUrl;

  // Sangam Home Auth Endpoints
  static const String login = '/sangam-home/auth/login';
  static const String refresh = '/sangam-home/auth/refresh';
  static const String changePassword = '/sangam-home/auth/change-password';

  // Module Endpoints
  static const String stats = '/sangam-home/stats';
  static const String members = '/sangam-home/members';
  static const String accounts = '/sangam-home/accounts';
  static const String categories = '/sangam-home/categories';
  static const String transactions = '/sangam-home/transactions';

  // Document Endpoints
  static const String documents = '/sangam-home/documents';
  static const String documentCategories = '/sangam-home/document-categories';
  static const String documentUploadsBaseUrl =
      'https://api.makeinsatara.in/uploads/sangam-home/documents';

  /// Resolves any document filename or relative path to the full CDN/Server URL:
  /// e.g. `https://api.makeinsatara.in/uploads/sangam-home/documents/<filename>`
  static String resolveDocumentUrl(String urlOrPath) {
    final trimmed = urlOrPath.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final clean = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    if (clean.startsWith('uploads/sangam-home/documents/')) {
      return 'https://api.makeinsatara.in/$clean';
    }
    if (clean.startsWith('uploads/')) {
      return 'https://api.makeinsatara.in/$clean';
    }
    return '$documentUploadsBaseUrl/$clean';
  }
}

