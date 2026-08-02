import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/secure_storage.dart';
import '../widgets/qr_dialog.dart';
import 'login_screen.dart';
import 'fines_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _finesInitialTab = 0;
  bool _isFront = true;
  bool _isSelectionMode = false;

  Map<String, dynamic>? _licenseData;
  bool _isLoading = true;
  String _errorMessage = '';
  final Set<String> _shownPointsWarningLevels = <String>{};
  bool _isLicenseRequestInProgress = false;
  bool _isAppActive = true;
  Timer? _licenseRefreshTimer;
  final List<Map<String, dynamic>> _recentActivities = [];

  String? _activeQrSessionId;
  DateTime? _activeQrExpiry;
  bool _isActiveQrSessionScanned = false;
  Timer? _qrButtonCountdownTimer;
  int _qrButtonRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchLicenseData();
    _startLicenseRefreshTimer();
  }

  @override
  void dispose() {
    _licenseRefreshTimer?.cancel();
    _qrButtonCountdownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppActive = true;
      _startLicenseRefreshTimer();
      _startQrButtonCountdown();
      unawaited(_fetchLicenseData(silent: true));
      return;
    }

    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _isAppActive = false;
      _licenseRefreshTimer?.cancel();
      _licenseRefreshTimer = null;
      _qrButtonCountdownTimer?.cancel();
      _qrButtonCountdownTimer = null;
    }
  }

  void _startLicenseRefreshTimer() {
    _licenseRefreshTimer?.cancel();
    _licenseRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_isAppActive && _currentIndex == 0) {
        unawaited(_fetchLicenseData(silent: true));
      }
    });
  }

  void _startQrButtonCountdown() {
    _qrButtonCountdownTimer?.cancel();
    _qrButtonCountdownTimer = null;

    _updateQrButtonCountdown();

    if (!_isAppActive ||
        !_isActiveQrSessionScanned ||
        _activeQrExpiry == null ||
        _activeQrSessionId == null) {
      return;
    }

    _qrButtonCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateQrButtonCountdown();
    });
  }

  void _updateQrButtonCountdown() {
    if (!mounted) return;

    final expiry = _activeQrExpiry;
    if (!_isActiveQrSessionScanned ||
        _activeQrSessionId == null ||
        expiry == null) {
      if (_qrButtonRemainingSeconds != 0) {
        setState(() => _qrButtonRemainingSeconds = 0);
      }
      return;
    }

    final remaining = expiry.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _qrButtonCountdownTimer?.cancel();
      _qrButtonCountdownTimer = null;
      setState(() {
        _activeQrSessionId = null;
        _activeQrExpiry = null;
        _isActiveQrSessionScanned = false;
        _qrButtonRemainingSeconds = 0;
      });
      return;
    }

    if (_qrButtonRemainingSeconds != remaining) {
      setState(() => _qrButtonRemainingSeconds = remaining);
    }
  }

  String get _formattedQrButtonTime {
    final minutes = _qrButtonRemainingSeconds ~/ 60;
    final seconds = _qrButtonRemainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _clearActiveQrSession() {
    _qrButtonCountdownTimer?.cancel();
    _qrButtonCountdownTimer = null;
    if (!mounted) return;
    setState(() {
      _activeQrSessionId = null;
      _activeQrExpiry = null;
      _isActiveQrSessionScanned = false;
      _qrButtonRemainingSeconds = 0;
    });
  }

  void _addRecentActivity(String title, IconData icon) {
    if (!mounted) return;
    setState(() {
      _recentActivities.insert(0, {
        'title': title,
        'date': _formatDate(DateTime.now().toIso8601String()),
        'icon': icon,
      });
    });
  }

  Future<void> _fetchLicenseData({bool silent = false}) async {
    if (_isLicenseRequestInProgress) return;
    _isLicenseRequestInProgress = true;

    try {
      final oldStatus = _licenseData?['status'];

      final response = await ApiService.dio.get('/license/my-license');
      if (!mounted) return;

      setState(() {
        _licenseData = Map<String, dynamic>.from(response.data);
        _isLoading = false;
        _errorMessage = '';
      });

      if (oldStatus == 'REVOKED' && _licenseData?['status'] == 'ACTIVE') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('seen_big_dialog_WARNING');
        await prefs.remove('seen_big_dialog_SEVERE');
        await prefs.remove('seen_big_dialog_CRITICAL');
        _shownPointsWarningLevels.clear();
        _addRecentActivity(
            'License Reactivated - Warnings Reset', Icons.autorenew);
      }

      final points = (_licenseData?['points'] as num?)?.toInt() ?? 0;
      final warningLevel = _getPointsWarningLevel(points);

      if (warningLevel != null && _shownPointsWarningLevels.add(warningLevel)) {
        Future.microtask(() {
          if (mounted) {
            _showInAppPushNotification(points);
          }
        });

        final prefs = await SharedPreferences.getInstance();
        final hasSeenBigDialog =
            prefs.getBool('seen_big_dialog_$warningLevel') ?? false;

        if (!hasSeenBigDialog) {
          await prefs.setBool('seen_big_dialog_$warningLevel', true);
          Future.microtask(() {
            if (mounted) {
              _showPointsWarning(points);
            }
          });
        }
      }
    } on DioException catch (e) {
      if (!mounted) return;
      if (!silent || _licenseData == null) {
        setState(() {
          _errorMessage =
              e.response?.data['message'] ?? 'Failed to load license details.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent || _licenseData == null) {
        setState(() {
          _errorMessage = 'An unexpected error occurred.';
          _isLoading = false;
        });
      }
    } finally {
      _isLicenseRequestInProgress = false;
    }
  }

  String? _getPointsWarningLevel(int points) {
    if (points >= 80 && points <= 99) {
      return 'CRITICAL';
    }
    if (points >= 45 && points <= 49) {
      return 'SEVERE';
    }
    if (points >= 20 && points <= 23) {
      return 'WARNING';
    }
    return null;
  }

  void _showPointsWarning(int points) {
    final (color, icon, title, message) = _getWarningData(points);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(160),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withAlpha(40),
                    Colors.white.withAlpha(15)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                border:
                    Border.all(color: Colors.white.withAlpha(80), width: 1.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: color.withAlpha(30), shape: BoxShape.circle),
                    child: Icon(icon, size: 40, color: color),
                  ),
                  const SizedBox(height: 20),
                  Text(title,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  const SizedBox(height: 15),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha(40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.white.withAlpha(60)),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: const Text('I Understand',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showInAppPushNotification(int points) {
    final (color, icon, title, message) = _getWarningData(points);
    final topPadding = MediaQuery.of(context).padding.top;

    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPadding + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -150 * (1 - value)),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! < -5) {
                  entry?.remove();
                  entry = null;
                }
              },
              onTap: () {
                entry?.remove();
                entry = null;
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0F19).withAlpha(220),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: color.withAlpha(150), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(40),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Navigator.of(context, rootNavigator: true).overlay?.insert(entry!);

    Future.delayed(const Duration(seconds: 6), () {
      if (entry != null && entry!.mounted) {
        entry!.remove();
        entry = null;
      }
    });
  }

  (Color, IconData, String, String) _getWarningData(int points) {
    if (points >= 80 && points <= 99) {
      return (
        Colors.red.shade400,
        Icons.warning_rounded,
        'CRITICAL RISK',
        'You have high demerit points ($points points). Reach 100 points and your license will be permanently revoked.'
      );
    } else if (points >= 45 && points <= 49) {
      return (
        Colors.orange.shade400,
        Icons.warning_rounded,
        'SEVERE RISK',
        'You have high demerit points ($points points). Reach 50 points and your license will be suspended.'
      );
    } else {
      return (
        Colors.amber.shade400,
        Icons.info_outline_rounded,
        'WARNING',
        'You have high demerit points ($points points). Reach 24 points and your license will be suspended.'
      );
    }
  }

  void _showTemporaryLicenseSheet(Map<String, dynamic> tempLicense) {
    _addRecentActivity(
        'Viewed Temporary License', Icons.assignment_late_outlined);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withAlpha(50),
                  Colors.white.withAlpha(20)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35), topRight: Radius.circular(35)),
              border: Border.all(color: Colors.white.withAlpha(60), width: 1.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                            color: Colors.white.withAlpha(60),
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Icon(Icons.assignment_late_outlined,
                        color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text('Temporary License',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTempInfoRow(
                    'Issued Date', _formatDate(tempLicense['issue_Date'])),
                Divider(height: 20, color: Colors.white.withAlpha(20)),
                _buildTempInfoRow(
                    'Valid Until', _formatDate(tempLicense['expiry_Date']),
                    isHighlight: true),
                Divider(height: 20, color: Colors.white.withAlpha(20)),
                _buildTempInfoRow('Issued By (Officer)',
                    tempLicense['issued_By'] ?? 'Unknown'),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(30),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.white.withAlpha(60)),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _addRecentActivity(
                          'Closed Temporary License', Icons.close);
                      Navigator.pop(context);
                    },
                    child: const Text('Close',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTempInfoRow(String title, String value,
      {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                color: Colors.white70,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isHighlight ? Colors.redAccent : Colors.white)),
        ),
      ],
    );
  }

  void _showQrDialog(String sessionId, DateTime expiry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => QRDialog(
        sessionId: sessionId,
        initialExpiresAt: expiry,
        initiallyScanned: _isActiveQrSessionScanned,
        onClose: () {
          _clearActiveQrSession();
          _addRecentActivity('Closed QR Code Dialog', Icons.close);
        },
        onExpired: _clearActiveQrSession,
        onSessionActivated: (expiresAt) {
          if (!mounted) return;
          setState(() {
            _activeQrExpiry = expiresAt;
            _isActiveQrSessionScanned = true;
          });
          _startQrButtonCountdown();
        },
        onBack: () {
          _startQrButtonCountdown();
          _addRecentActivity('Navigated Back from QR', Icons.arrow_back);
        },
      ),
    );
  }

  Future<void> _generateQR() async {
    final status = _licenseData?['status'];
    if (status == 'SUSPENDED' || status == 'REVOKED') {
      _showGlassToast('Access Denied: Your license is $status.', isError: true);
      return;
    }

    if (_activeQrSessionId != null) {
      if (_activeQrExpiry == null ||
          DateTime.now().isBefore(_activeQrExpiry!)) {
        _showQrDialog(_activeQrSessionId!,
            _activeQrExpiry ?? DateTime.now().add(const Duration(minutes: 10)));
        return;
      } else {
        _clearActiveQrSession();
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final userId = _licenseData?['user_Id'] ?? '';
      final response = await ApiService.dio.post(
        '/qr/generate',
        data: {'userId': userId},
      );

      final String sessionId = response.data['qrToken'];
      final DateTime expiry = DateTime.now().add(const Duration(minutes: 10));

      if (mounted) {
        setState(() {
          _activeQrSessionId = sessionId;
          _activeQrExpiry = expiry;
          _isActiveQrSessionScanned = false;
          _qrButtonRemainingSeconds = 0;
        });
        Navigator.pop(context);
        _addRecentActivity('Generated QR Code', Icons.qr_code_scanner);
        _showQrDialog(sessionId, expiry);
      }
    } on DioException catch (e) {
      if (mounted) Navigator.pop(context);
      final errorMsg =
          e.response?.data['message'] ?? 'Failed to generate QR Code.';
      _showGlassToast(errorMsg, isError: true);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showGlassToast('Failed to generate QR Code.', isError: true);
    }
  }

  void _showGlassToast(String message, {bool isError = false}) {
    final topPadding = MediaQuery.of(context).padding.top;
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPadding + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: isError
                      ? Colors.redAccent.withAlpha(50)
                      : Colors.green.shade600.withAlpha(50),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withAlpha(100), width: 1.0),
                ),
                child: Row(
                  children: [
                    Icon(
                        isError
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(message,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Navigator.of(context, rootNavigator: true).overlay?.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  Future<void> _logout() async {
    await SecureStorage.deleteToken();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '---';
    try {
      final date = DateTime.parse(isoString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return '---';
    }
  }

  Widget _buildDetailText(String number, String value, double fontSize,
      {bool isBold = false}) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
              text: number,
              style: TextStyle(
                  fontSize: fontSize * 0.85,
                  color: Colors.blueGrey[200],
                  fontWeight: FontWeight.bold)),
          TextSpan(
              text: value,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFrontCard() {
    final data = _licenseData;
    if (data == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final cardHeight = isSmallScreen ? screenWidth * 0.68 : screenWidth * 0.58;
    final fontSize = isSmallScreen ? 8.0 : 9.5;

    return _buildLicenseGlassCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: cardHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.05,
                  child: Image.asset('assets/emblem.png',
                      width: screenWidth * 0.35,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (c, e, s) => const SizedBox()),
                ),
              ),
            ),
            Positioned(
              bottom: 18,
              right: 48,
              child: Opacity(
                opacity: 0.10,
                child: Image.asset('assets/punkalasa.png',
                    width: screenWidth * 0.15,
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcIn,
                    errorBuilder: (c, e, s) => Icon(Icons.security,
                        size: screenWidth * 0.13, color: Colors.white)),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                children: [
                  _buildLicenseHeader(screenWidth, fontSize),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _buildLicenseBody(data, screenWidth, fontSize),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseHeader(double screenWidth, double fontSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.white24, width: 0.5)),
          child: Image.asset('assets/flag.png',
              width: screenWidth * 0.09,
              height: screenWidth * 0.055,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                  width: screenWidth * 0.09,
                  height: screenWidth * 0.055,
                  color: Colors.grey[800])),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('DRIVING LICENCE',
                  style: TextStyle(
                      fontSize: fontSize * 1.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.0)),
              Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  height: 1.0,
                  width: double.infinity,
                  color: Colors.white12),
              Text('DEMOCRATIC SOCIALIST REPUBLIC OF SRI LANKA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: fontSize * 0.9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Image.asset('assets/emblem.png',
            width: screenWidth * 0.08,
            height: screenWidth * 0.1,
            errorBuilder: (c, e, s) =>
                SizedBox(width: screenWidth * 0.08, height: screenWidth * 0.1)),
      ],
    );
  }

  Widget _buildLicenseBody(
      Map<String, dynamic> data, double screenWidth, double fontSize) {
    final status = data['status'] ?? 'UNKNOWN';
    final imageUrl = data['image'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 10.0),
          child: Column(
            children: [
              Container(
                width: screenWidth * 0.18,
                height: screenWidth * 0.22,
                decoration: const BoxDecoration(color: Colors.transparent),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person,
                                size: 40, color: Colors.white60))
                    : const Icon(Icons.person, size: 40, color: Colors.white60),
              ),
              const SizedBox(height: 4),
              Text('4a. ${_formatDate(data['issue_Date'])}',
                  style: TextStyle(
                      fontSize: fontSize * 1.1,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70)),
              const SizedBox(height: 12),
              _buildStatusBadge(status, fontSize),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _buildDetailText(
                            '5. ', data['license_No'] ?? 'N/A', fontSize,
                            isBold: true)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildDetailText(
                            '4c. ', data['nic_No'] ?? 'N/A', fontSize)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDetailText(
                    '1, 2. ', data['full_Name'] ?? 'N/A', fontSize),
                const SizedBox(height: 8),
                _buildDetailText('8. ', data['address'] ?? 'N/A', fontSize),
                const SizedBox(height: 8),
                _buildDetailText(
                    '3. ', _formatDate(data['date_of_birth']), fontSize),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Blood Group  ',
                        style: TextStyle(
                            fontSize: fontSize * 1.2,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70)),
                    Text(data['blood_Group'] ?? '-',
                        style: TextStyle(
                            fontSize: fontSize * 1.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const Spacer(),
                    Text('SL',
                        style: TextStyle(
                            fontSize: fontSize * 2.8,
                            fontWeight: FontWeight.w900,
                            color: Colors.purple.shade300)),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, double fontSize) {
    final colors = status == 'ACTIVE'
        ? [const Color(0xFF00b09b), const Color(0xFF96c93d)]
        : status == 'SUSPENDED'
            ? [const Color(0xFFf12711), const Color(0xFFf5af19)]
            : [const Color(0xFFcb2d3e), const Color(0xFFef473a)];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: colors.map((c) => c.withAlpha(200)).toList()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize * 1.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8))
        ],
      ),
    );
  }

  TableRow _buildCategoryRow(String code, String icon, double fontSize) {
    final categories =
        _licenseData?['vehicleCategories'] as List<dynamic>? ?? [];
    final cat = categories.cast<Map<String, dynamic>>().firstWhere(
          (c) => c['vehicle_Class'] == code,
          orElse: () => <String, dynamic>{},
        );
    if (cat.isNotEmpty) {
      return _buildTableRow(
          '$code $icon',
          _formatDate(cat['issue_Date']),
          _formatDate(cat['expiry_Date']),
          cat['restriction'] ?? '---',
          fontSize);
    }
    return _buildTableRow('$code $icon', '---', '---', '---', fontSize);
  }

  Widget _buildLegendText(String text, double fontSize) => Padding(
        padding: const EdgeInsets.only(bottom: 2.5),
        child: Text(text,
            style: TextStyle(
                fontSize: fontSize * 0.7,
                color: Colors.blueGrey[300],
                fontWeight: FontWeight.w600,
                height: 1.0)),
      );

  TableRow _buildTableRow(String col1, String col2, String col3,
      String restriction, double fontSize,
      {bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(
          color: isHeader ? Colors.white.withAlpha(20) : Colors.transparent),
      children: [
        Padding(
          padding: const EdgeInsets.all(1.0),
          child: Text(col1,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: isHeader ? fontSize * 0.8 : fontSize * 0.9,
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                  color: Colors.white)),
        ),
        Padding(
          padding: const EdgeInsets.all(1.0),
          child: Text(col2,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: isHeader ? fontSize * 0.8 : fontSize * 0.9,
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                  color: Colors.white70)),
        ),
        Padding(
          padding: const EdgeInsets.all(1.0),
          child: Text(col3,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: isHeader ? fontSize * 0.8 : fontSize * 0.9,
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                  color: Colors.white70)),
        ),
        Padding(
          padding: const EdgeInsets.all(1.0),
          child: Text(restriction,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: isHeader ? fontSize * 0.8 : fontSize * 0.9,
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                  color: Colors.white60)),
        ),
      ],
    );
  }

  Widget _buildBackCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final cardHeight = isSmallScreen ? screenWidth * 0.68 : screenWidth * 0.58;
    final fontSize = isSmallScreen ? 7.5 : 9.0;

    return _buildLicenseGlassCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: cardHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.03,
                  child: Image.asset('assets/emblem.png',
                      width: screenWidth * 0.35,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (c, e, s) => const SizedBox()),
                ),
              ),
            ),
            Positioned(
              left: 6,
              top: 15,
              bottom: 15,
              child: Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text('Department of Motor Traffic - Sri Lanka',
                      style: TextStyle(
                          fontSize: fontSize * 1.1,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[300])),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 28, right: 12, top: 12, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendText('1. Surname', fontSize),
                        _buildLegendText('2. Other names', fontSize),
                        _buildLegendText('3. Date of birth', fontSize),
                        _buildLegendText(
                            '4a. Date of Issue of the License', fontSize),
                        _buildLegendText('4b. Issuing Authority', fontSize),
                        _buildLegendText('4c. Administrative Number', fontSize),
                        _buildLegendText('5. Number of the LICENCE', fontSize),
                        _buildLegendText(
                            '7. Signature of the holder', fontSize),
                        _buildLegendText(
                            '8. Permanent place of residence', fontSize),
                        _buildLegendText('9. Categories of vehicles', fontSize),
                        _buildLegendText(
                            '10. Date of Issue per category', fontSize),
                        _buildLegendText(
                            '11. Date of Expiry per category', fontSize),
                        _buildLegendText(
                            '12. Restrictions in code form', fontSize),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 7,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Table(
                        border: TableBorder.all(
                            color: Colors.white.withAlpha(40), width: 0.5),
                        columnWidths: const {
                          0: FlexColumnWidth(1.8),
                          1: FlexColumnWidth(1.8),
                          2: FlexColumnWidth(1.8),
                          3: FlexColumnWidth(1.4),
                        },
                        children: [
                          _buildTableRow('9.', '10.', '11.', '12.', fontSize,
                              isHeader: true),
                          _buildCategoryRow('A1', '🛺', fontSize),
                          _buildCategoryRow('A', '🏍️', fontSize),
                          _buildCategoryRow('B1', '🛺', fontSize),
                          _buildCategoryRow('B', '🚗', fontSize),
                          _buildCategoryRow('C1', '🚚', fontSize),
                          _buildCategoryRow('C', '🚛', fontSize),
                          _buildCategoryRow('CE', '🚛', fontSize),
                          _buildCategoryRow('D1', '🚐', fontSize),
                          _buildCategoryRow('D', '🚌', fontSize),
                          _buildCategoryRow('DE', '🚌', fontSize),
                          _buildCategoryRow('G1', '🚜', fontSize),
                          _buildCategoryRow('G', '🚜', fontSize),
                          _buildCategoryRow('J', '🏗️', fontSize),
                          _buildCategoryRow('H', '♿', fontSize)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseGlassCard(
      {required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withAlpha(45), Colors.white.withAlpha(18)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(60), width: 1.0),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 25,
                  offset: const Offset(0, 10))
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassButton(
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onPressed}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(60), width: 1.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 26, color: Colors.white),
                const SizedBox(width: 12),
                Text(label,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesFragment() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(40), width: 1.5),
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recent Activities',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 10),
                Container(height: 1.0, color: Colors.white24),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: _recentActivities.length,
                    separatorBuilder: (context, index) =>
                        Divider(color: Colors.white.withAlpha(15)),
                    itemBuilder: (context, index) {
                      final activity = _recentActivities[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              shape: BoxShape.circle),
                          child: Icon(activity['icon'],
                              color: Colors.white70, size: 20),
                        ),
                        title: Text(activity['title'],
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        subtitle: Text(activity['date'],
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 50),
              const SizedBox(height: 16),
              Text(_errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(30)),
                onPressed: () {
                  _addRecentActivity('Retried loading license', Icons.refresh);
                  setState(() {
                    _isLoading = true;
                    _errorMessage = '';
                  });
                  _fetchLicenseData();
                },
                child:
                    const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final List<dynamic> tempLicenses = _licenseData?['temporaryLicenses'] ?? [];
    final String licenseStatus = _licenseData?['status'] ?? 'UNKNOWN';
    final bool isQrBlocked =
        licenseStatus == 'SUSPENDED' || licenseStatus == 'REVOKED';
    final bool hasActiveQrCountdown = !isQrBlocked &&
        _isActiveQrSessionScanned &&
        _activeQrSessionId != null &&
        _activeQrExpiry != null &&
        _qrButtonRemainingSeconds > 0;

    return RefreshIndicator(
      onRefresh: () async {
        _addRecentActivity('Retried loading license', Icons.refresh);
        await _fetchLicenseData();
      },
      color: Colors.cyanAccent,
      backgroundColor: Colors.white.withAlpha(20),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
            left: 16.0, right: 16.0, top: kToolbarHeight + 40, bottom: 120.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            const Text('Tap the card to rotate side',
                style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _addRecentActivity('Flipped License Card', Icons.flip);
                setState(() => _isFront = !_isFront);
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: _isFront ? _buildFrontCard() : _buildBackCard(),
              ),
            ),
            const SizedBox(height: 24),
            if (tempLicenses.isNotEmpty) ...[
              _buildGlassButton(
                label: 'VIEW TEMPORARY LICENSE',
                icon: Icons.assignment_late_outlined,
                color: Colors.orangeAccent,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showTemporaryLicenseSheet(
                      tempLicenses.last as Map<String, dynamic>);
                },
              ),
              const SizedBox(height: 16),
            ],
            _buildGlassButton(
              label: isQrBlocked
                  ? 'QR BLOCKED ($licenseStatus)'
                  : hasActiveQrCountdown
                      ? 'OPEN QR • $_formattedQrButtonTime'
                      : 'SHOW QR TO OFFICER',
              icon: isQrBlocked ? Icons.block : Icons.qr_code_scanner,
              color: isQrBlocked ? Colors.redAccent : Colors.blueAccent,
              onPressed: () {
                HapticFeedback.lightImpact();
                if (isQrBlocked) {
                  _showGlassToast(
                      'Access Denied: Your license is $licenseStatus.',
                      isError: true);
                } else {
                  _generateQR();
                }
              },
            ),
            const SizedBox(height: 24),
            _buildRecentActivitiesFragment(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (_currentIndex == index) return;
        HapticFeedback.selectionClick();

        if (index == 0) {
          _addRecentActivity('Viewed License Dashboard', Icons.credit_card);
        } else if (index == 1) {
          _finesInitialTab = 0;
          _addRecentActivity('Navigated to Fines', Icons.receipt_long);
        } else if (index == 2) {
          _addRecentActivity('Navigated to Profile', Icons.person);
        }

        setState(() => _currentIndex = index);

        if (index == 0) {
          unawaited(_fetchLicenseData(silent: true));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : Colors.white60, size: 22),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGlassBackground() {
    return RepaintBoundary(
      child: Stack(
        children: [
          Container(color: const Color(0xFF0B0F19)),
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withAlpha(140),
                  shape: BoxShape.circle),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                  color: Colors.teal.shade900.withAlpha(120),
                  shape: BoxShape.circle),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
                child: Container(color: Colors.transparent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          _buildGlassBackground(),
          Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            extendBodyBehindAppBar: true,
            appBar: _currentIndex == 0
                ? AppBar(
                    automaticallyImplyLeading: false,
                    backgroundColor: const Color(0xFF0B0F19).withAlpha(120),
                    flexibleSpace: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: Colors.white.withAlpha(40),
                                    width: 1.0)),
                          ),
                        ),
                      ),
                    ),
                    foregroundColor: Colors.white,
                    title: const Text('Auto-Ledger Dashboard',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    elevation: 0,
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 12.0, top: 6.0, bottom: 6.0),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withAlpha(30),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.redAccent.withAlpha(80),
                                width: 1.0),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.logout_rounded,
                                color: Colors.redAccent, size: 20),
                            onPressed: () {
                              _addRecentActivity(
                                  'Initiated Logout', Icons.logout);
                              _logout();
                            },
                            tooltip: 'Logout',
                          ),
                        ),
                      ),
                    ],
                  )
                : null,
            body: _currentIndex == 0
                ? _buildDashboard()
                : _currentIndex == 1
                    ? FinesScreen(
                        initialTab: _finesInitialTab,
                        onLogActivity: _addRecentActivity,
                        onSelectionModeChanged: (isSelected) =>
                            setState(() => _isSelectionMode = isSelected),
                      )
                    : ProfileScreen(
                        onLogActivity: _addRecentActivity,
                        onPointsClicked: () {
                          setState(() {
                            _finesInitialTab = 2;
                            _currentIndex = 1;
                          });
                        },
                      ),
            bottomNavigationBar: AnimatedSlide(
              offset: _isSelectionMode ? const Offset(0, 2) : Offset.zero,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: SafeArea(
                child: Container(
                  margin:
                      const EdgeInsets.only(bottom: 16, left: 30, right: 30),
                  height: 65,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0F19).withAlpha(160),
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(
                              color: Colors.white.withAlpha(40), width: 1.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(0, 'License', Icons.credit_card),
                            _buildNavItem(1, 'Fines', Icons.receipt_long),
                            _buildNavItem(2, 'Profile', Icons.person),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
