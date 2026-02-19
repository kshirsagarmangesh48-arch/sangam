import 'package:flutter/material.dart';
import 'package:sangam/core/constants/global_keys.dart';

enum SnackBarType { success, error, info }

class AppSnackBar {
  static void show(
    String title,
    String message, {
    SnackBarType type = SnackBarType.info,
  }) {
    final messenger = rootScaffoldMessengerKey.currentState;

    if (messenger == null) return;

    Color backgroundColor;
    IconData icon;
    Color textColor = Colors.white;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = Colors.green.shade800;
        icon = Icons.check_circle_outline;
        break;
      case SnackBarType.error:
        backgroundColor = Colors.red.shade800;
        icon = Icons.error_outline;
        break;
      case SnackBarType.info:
        backgroundColor = Colors.grey.shade900;
        icon = Icons.info_outline;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
        duration: const Duration(seconds: 4),
        showCloseIcon: true,
        closeIconColor: textColor,
      ),
    );
  }

  static void success(String title, String message) =>
      show(title, message, type: SnackBarType.success);
  static void error(String title, String message) =>
      show(title, message, type: SnackBarType.error);
  static void info(String title, String message) =>
      show(title, message, type: SnackBarType.info);
}
