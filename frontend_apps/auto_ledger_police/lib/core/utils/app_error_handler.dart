import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppErrorHandler {
  static void showPopup(
      BuildContext context, {
        required String message,
        bool isError = true,
      }) {
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 18,
          right: 18,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isError ? AppTheme.primaryBlack : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isError ? AppTheme.primaryBlack : AppTheme.borderGray,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: isError ? Colors.white : AppTheme.primaryBlack,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: isError ? Colors.white : AppTheme.primaryBlack,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);

    Timer(const Duration(seconds: 3), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}