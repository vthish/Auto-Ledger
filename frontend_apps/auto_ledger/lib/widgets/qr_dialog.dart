import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';

class QRDialog extends StatefulWidget {
  final String sessionId;
  final DateTime initialExpiresAt;
  final bool initiallyScanned;
  final VoidCallback onClose;
  final VoidCallback onExpired;
  final ValueChanged<DateTime> onSessionActivated;
  final VoidCallback onBack;

  const QRDialog({
    super.key,
    required this.sessionId,
    required this.initialExpiresAt,
    required this.initiallyScanned,
    required this.onClose,
    required this.onExpired,
    required this.onSessionActivated,
    required this.onBack,
  });

  @override
  State<QRDialog> createState() => _QRDialogState();
}

class _QRDialogState extends State<QRDialog> {
  Timer? _pollingTimer;
  Timer? _countdownTimer;

  bool _isScanned = false;
  bool _isExpired = false;
  int _remainingSeconds = 600;
  DateTime? _currentExpiresAt;

  @override
  void initState() {
    super.initState();
    _currentExpiresAt = widget.initialExpiresAt;

    if (widget.initiallyScanned) {
      final remaining =
          widget.initialExpiresAt.difference(DateTime.now()).inSeconds;
      _isScanned = true;
      _remainingSeconds = remaining.clamp(0, 600).toInt();

      if (_remainingSeconds > 0) {
        _startCountdown();
      } else {
        _isExpired = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onExpired();
        });
      }
    } else {
      _startPolling();
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isScanned || _isExpired) {
        timer.cancel();
        return;
      }
      try {
        final response = await ApiService.dio.get(
          '/qr/status/${widget.sessionId}',
        );

        final status = response.data['status'];
        final expiresAt = DateTime.parse(response.data['expiresAt']);

        if (mounted) {
          setState(() {
            _currentExpiresAt = expiresAt;
          });
        }

        if (status == 'EXPIRED') {
          timer.cancel();
          if (mounted) {
            setState(() => _isExpired = true);
            widget.onExpired();
          }
        } else if (status == 'ACTIVE') {
          timer.cancel();
          _onQrScanned(expiresAt);
        }
      } catch (_) {}
    });
  }

  void _onQrScanned(DateTime newExpiresAt) {
    if (!mounted || _isScanned) return;

    final now = DateTime.now();
    int remaining = newExpiresAt.difference(now).inSeconds;
    if (remaining > 600) remaining = 600;
    if (remaining < 0) remaining = 0;

    setState(() {
      _isScanned = true;
      _remainingSeconds = remaining;
      _currentExpiresAt = newExpiresAt;
    });

    widget.onSessionActivated(newExpiresAt);
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _countdownTimer?.cancel();
        setState(() => _isExpired = true);
        widget.onExpired();
      }
    });
  }

  String get _formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayExpiresAt = _currentExpiresAt ?? widget.initialExpiresAt;

    return RepaintBoundary(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withAlpha(60),
                  Colors.white.withAlpha(30)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withAlpha(80), width: 1.0),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 25,
                    offset: const Offset(0, 10))
              ],
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          widget.onBack();
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Show this to the Officer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(140),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withAlpha(80), width: 1.5),
                    ),
                    child: QrImageView(
                      data: widget.sessionId,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isScanned && !_isExpired) ...[
                    Text(
                      'Valid for: $_formattedTime',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _remainingSeconds < 30
                            ? Colors.redAccent
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ] else if (!_isScanned && !_isExpired) ...[
                    const Text(
                      'Waiting for officer to scan...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'QR code will remain valid until scanned.',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                  if (!_isExpired) ...[
                    if (_isScanned) ...[
                      Text(
                        'QR code will expire at ${_formatTime(displayExpiresAt)}',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 2),
                  ],
                  if (_isScanned && !_isExpired) ...[
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.greenAccent, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'QR Code Scanned!',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_isExpired) ...[
                    const Icon(Icons.timer_off,
                        color: Colors.redAccent, size: 32),
                    const SizedBox(height: 4),
                    const Text(
                      'QR Code Expired',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Please generate a new QR code.',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha(25),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.white.withAlpha(40)),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        widget.onClose();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Close',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
