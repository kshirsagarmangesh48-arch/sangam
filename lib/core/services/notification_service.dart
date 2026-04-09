import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  // TODO: Replace with your actual OneSignal App ID
  static const String appId = "9c1b9411-7989-4f18-9964-61dbd7db1b81";
  
  // TODO: Replace with your actual OneSignal REST API Key
  static const String restApiKey = "os_v2_app_tqnzielzrfhrrglemhn5pwy3qfv7moxtaxuucmvqvitgsqw7fhl2qx3p4ccuni4u5lzahpulc26bs5ckmuczojiz56spxhu3uebisqa";

  static Future<void> initialize() async {
    // Remove this method to stop OneSignal Debugging
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    OneSignal.initialize(appId);

    // The promptForPushNotificationsWithUserResponse function will show the iOS or Android push notification prompt. 
    // We recommend removing the following code and instead using an In-App Message to prompt for notification permission
    await OneSignal.Notifications.requestPermission(true);
  }

  /// Sends a notification to all subscribed users
  static Future<void> sendTransactionNotification({
    required double amount,
    required String description,
    required String paidByName,
    required String type, // 'income' or 'expense'
  }) async {
    final String heading = type == 'income' ? 'New Income Added' : 'New Expense Added';
    final String content = '₹$amount added for "$description" by $paidByName.';

    try {
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $restApiKey',
        },
        body: jsonEncode({
          'app_id': appId,
          // 'included_segments': ['All'], is deprecated. 'included_segments': ['Subscribed Users'] is the standard default
          'included_segments': ['Subscribed Users'],
          'headings': {'en': heading},
          'contents': {'en': content},
        }),
      );

      if (response.statusCode == 200) {
        print("Notification Sent Successfully!");
      } else {
        print("Notification Failed: \${response.body}");
      }
    } catch (e) {
      print("Error sending notification: \$e");
    }
  }
}
