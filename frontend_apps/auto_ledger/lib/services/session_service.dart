import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';

typedef SessionExpiredCallback = Future<void> Function();

class SessionService with WidgetsBindingObserver {
  SessionService._();

  static final SessionService instance = SessionService._();

  Timer? _expiryTimer;
  DateTime? _expiresAt;
  SessionExpiredCallback? _onSessionExpired;
  bool _observerRegistered = false;
  bool _isExpiring = false;

  void configure({required SessionExpiredCallback onSessionExpired}) {
    _onSessionExpired = onSessionExpired;
  }

  bool initialize(String? token) {
    if (!_observerRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _observerRegistered = true;
    }

    if (token == null || token.isEmpty) {
      cancel();
      return true;
    }

    return _scheduleFromToken(token, notifyWhenExpired: false);
  }

  void start(String token) {
    _scheduleFromToken(token, notifyWhenExpired: true);
  }

  void cancel() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _expiresAt = null;
  }

  Future<void> expireNow() async {
    await _expireSession();
  }

  bool _scheduleFromToken(
    String token, {
    required bool notifyWhenExpired,
  }) {
    _expiryTimer?.cancel();
    _expiryTimer = null;

    final expiry = _readExpiry(token);
    _expiresAt = expiry;

    if (expiry == null) {
      if (notifyWhenExpired) {
        unawaited(_expireSession());
      }
      return false;
    }

    final remaining = expiry.difference(DateTime.now().toUtc());
    if (remaining <= Duration.zero) {
      if (notifyWhenExpired) {
        unawaited(_expireSession());
      }
      return false;
    }

    _expiryTimer = Timer(remaining, () {
      unawaited(_expireSession());
    });
    return true;
  }

  DateTime? _readExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadString);

      if (payload is! Map<String, dynamic>) {
        return null;
      }

      final expValue = payload['exp'];
      final int? expirySeconds = switch (expValue) {
        int value => value,
        double value => value.toInt(),
        String value => int.tryParse(value),
        _ => null,
      };

      if (expirySeconds == null) {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(
        expirySeconds * 1000,
        isUtc: true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _expireSession() async {
    if (_isExpiring) {
      return;
    }

    _isExpiring = true;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _expiresAt = null;

    try {
      final callback = _onSessionExpired;
      if (callback != null) {
        await callback();
      }
    } finally {
      _isExpiring = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    final expiry = _expiresAt;
    if (expiry == null) {
      return;
    }

    final remaining = expiry.difference(DateTime.now().toUtc());
    if (remaining <= Duration.zero) {
      unawaited(_expireSession());
      return;
    }

    _expiryTimer?.cancel();
    _expiryTimer = Timer(remaining, () {
      unawaited(_expireSession());
    });
  }
}
