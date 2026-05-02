import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ToastUtils {
  static void show(BuildContext context, String message, {bool isError = false}) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Clear existing snackbars
    scaffoldMessenger.removeCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: isError ? const Color(0xFFD32F2F) : const Color(0xFF388E3C),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.only(
          bottom: 20, // Show at bottom instead of forcing to top which causes errors
          left: 20,
          right: 20,
        ),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    show(context, message, isError: true);
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message, isError: false);
  }
}
