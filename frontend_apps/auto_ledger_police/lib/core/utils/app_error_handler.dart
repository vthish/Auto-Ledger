import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

class AppErrorHandler {
  static OverlayEntry? _currentEntry;
  static Timer? _autoHideTimer;

  static void showPopup(
    BuildContext context, {
    required String message,
    bool isError = true,
  }) {
    _removeCurrentEntry();

    final overlay = Overlay.of(context);
    final color = isError ? AppTheme.errorRed : AppTheme.successGreen;

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 25,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                      color: color,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), _removeCurrentEntry);
  }

  static void _removeCurrentEntry() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}