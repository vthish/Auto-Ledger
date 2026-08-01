import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/navigation/app_route_observer.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../models/license_model.dart';
import '../services/traffic_fine_service.dart';
import 'license_preview_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver, RouteAware {
  static const String _cameraPermissionRequestedKey =
      'camera_permission_requested';

  final TrafficFineService _trafficFineService = TrafficFineService();
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
  );

  ModalRoute<dynamic>? _route;
  bool _isLoading = false;
  bool _isScanning = false;
  bool _hasPermissionError = false;
  bool _isScannerActive = false;
  bool _isRouteCurrent = false;
  bool _isAppResumed = true;
  bool _isDisposed = false;
  bool _isReconcilingScanner = false;
  bool _scannerReconcileRequested = false;
  bool _permissionRequestPending = false;

  bool get _canRunScanner {
    return mounted &&
        !_isDisposed &&
        _isRouteCurrent &&
        _isAppResumed &&
        !_isLoading &&
        !_isScanning;
  }

  @override
  void initState() {
    super.initState();
    _isAppResumed =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextRoute = ModalRoute.of(context);
    if (identical(_route, nextRoute)) return;
    if (_route != null) {
      appRouteObserver.unsubscribe(this);
    }
    _route = nextRoute;
    if (nextRoute != null) {
      appRouteObserver.subscribe(this, nextRoute);
      _isRouteCurrent = nextRoute.isCurrent;
    } else {
      _isRouteCurrent = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_reconcileScanner(allowPermissionRequest: true));
    });
  }

  @override
  void didPush() {
    _isRouteCurrent = true;
    unawaited(_reconcileScanner(allowPermissionRequest: true));
  }

  @override
  void didPopNext() {
    _isRouteCurrent = true;
    unawaited(_reconcileScanner(allowPermissionRequest: true));
  }

  @override
  void didPushNext() {
    _isRouteCurrent = false;
    unawaited(_reconcileScanner());
  }

  @override
  void didPop() {
    _isRouteCurrent = false;
    unawaited(_reconcileScanner());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppResumed = state == AppLifecycleState.resumed;
    unawaited(_reconcileScanner());
  }

  Future<PermissionStatus> _resolveCameraPermission({
    required bool allowPermissionRequest,
  }) async {
    var status = await Permission.camera.status;
    if (status.isGranted || !status.isDenied || !allowPermissionRequest) {
      return status;
    }
    final preferences = await SharedPreferences.getInstance();
    final wasRequested =
        preferences.getBool(_cameraPermissionRequestedKey) ?? false;
    if (wasRequested) return status;
    await preferences.setBool(_cameraPermissionRequestedKey, true);
    status = await Permission.camera.request();
    return status;
  }

  Future<void> _reconcileScanner({
    bool allowPermissionRequest = false,
  }) async {
    _permissionRequestPending =
        _permissionRequestPending || allowPermissionRequest;
    if (_isReconcilingScanner) {
      _scannerReconcileRequested = true;
      return;
    }
    _isReconcilingScanner = true;
    try {
      do {
        _scannerReconcileRequested = false;
        final shouldRequestPermission = _permissionRequestPending;
        _permissionRequestPending = false;
        await _reconcileScannerOnce(
          allowPermissionRequest: shouldRequestPermission,
        );
      } while (_scannerReconcileRequested && !_isDisposed);
    } finally {
      _isReconcilingScanner = false;
    }
  }

  Future<void> _reconcileScannerOnce({
    required bool allowPermissionRequest,
  }) async {
    if (!_canRunScanner) {
      await _stopScannerController();
      return;
    }

    final permissionStatus = await _resolveCameraPermission(
      allowPermissionRequest: allowPermissionRequest,
    );

    if (_isDisposed || !_canRunScanner) {
      await _stopScannerController();
      return;
    }

    if (!permissionStatus.isGranted) {
      _setPermissionError(true);
      await _stopScannerController();
      return;
    }

    _setPermissionError(false);
    if (_isScannerActive) return;

    try {
      await _controller.start();
      if (_isDisposed || !_canRunScanner) {
        await _stopScannerController();
        return;
      }
      _setScannerActive(true);
    } catch (error) {
      if (_isPermissionIssue(error)) {
        _setPermissionError(true);
      }
      await _stopScannerController();
    }
  }

  Future<void> _stopScannerController() async {
    try {
      await _controller.stop();
    } catch (_) {}
    _setScannerActive(false);
  }

  void _setPermissionError(bool value) {
    if (_isDisposed || !mounted || _hasPermissionError == value) return;
    setState(() {
      _hasPermissionError = value;
    });
  }

  void _setScannerActive(bool value) {
    if (_isDisposed || !mounted || _isScannerActive == value) return;
    setState(() {
      _isScannerActive = value;
    });
  }

  bool _isPermissionIssue(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('permission') || message.contains('camera');
  }

  Future<void> _resumeScanner() async {
    if (!mounted || _isDisposed) return;
    setState(() {
      _isLoading = false;
      _isScanning = false;
    });
    await _reconcileScanner();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isRouteCurrent = false;
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.stop().whenComplete(_controller.dispose));
    super.dispose();
  }

  void _handleScan(BarcodeCapture capture) {
    if (!_canRunScanner || !_isScannerActive || _isScanning || _isLoading) {
      return;
    }
    if (capture.barcodes.isEmpty) return;
    final sessionId = capture.barcodes.first.rawValue;
    if (sessionId == null || sessionId.trim().isEmpty) {
      AppErrorHandler.showPopup(
        context,
        message: 'Please scan a valid QR code.',
      );
      return;
    }
    _isScanning = true;
    unawaited(_verifySession(sessionId.trim()));
  }

  Future<void> _verifySession(String sessionId) async {
    if (!mounted || _isDisposed) return;
    setState(() => _isLoading = true);
    await _reconcileScanner();
    try {
      final license = await _trafficFineService.scanQr(
        sessionId: sessionId,
      );
      if (!mounted || _isDisposed) return;
      final expiresAt = license.scanExpiresAt;
      if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
        AppErrorHandler.showPopup(
          context,
          message: 'This QR code has expired. Please scan a valid QR code.',
        );
        await _resumeScanner();
        return;
      }
      await _openPreviewWithLicense(license, sessionId);
      if (!mounted || _isDisposed) return;
      await _resumeScanner();
    } on ApiException catch (error) {
      if (!mounted || _isDisposed) return;
      AppErrorHandler.showPopup(
        context,
        message: error.message.toLowerCase().contains('expired')
            ? 'This QR code has expired. Please scan a valid QR code.'
            : error.message,
      );
      await _resumeScanner();
    } catch (_) {
      if (!mounted || _isDisposed) return;
      AppErrorHandler.showPopup(
        context,
        message: 'Unable to verify QR session. Please try again.',
      );
      await _resumeScanner();
    }
  }

  Future<void> _openPreviewWithLicense(
    LicenseModel license,
    String sessionId,
  ) async {
    if (!mounted || _isDisposed) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LicensePreviewScreen(
          qrToken: sessionId,
          license: license,
        ),
      ),
    );
  }

  void _toggleFlash() {
    if (!_canRunScanner || !_isScannerActive || _hasPermissionError) return;
    unawaited(_controller.toggleTorch());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: AppTheme.backgroundWhite,
       appBar: AppBar(
          title: const Text(
             'Scan Driver QR',
             style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
             IconButton(
               onPressed: _toggleFlash,

             icon: const Icon(Icons.flash_on_rounded),
             color: AppTheme.policeBlue,
          ),
        ],
      ),
      body: SafeArea(
         child: LayoutBuilder(
           builder: (context, constraints) {
             final screenWidth = constraints.maxWidth;
             final screenHeight = constraints.maxHeight;
             final squareSize = screenWidth < screenHeight
                 ? screenWidth - 32
                 : screenHeight - 200;
             return Column(
               children: [
                 Expanded(
                   flex: 6,
                   child: Center(
                     child: Container(
                       width: squareSize,
                       height: squareSize,
                       decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                             BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                             ),
                          ],
                       ),
                       clipBehavior: Clip.hardEdge,
                       child: Stack(
                          children: [
                             if (_hasPermissionError)
                                Container(
                                  color: Colors.black,
                                  padding: const EdgeInsets.all(20),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                           Icons.camera_alt_outlined,
                                           color: Colors.white54,
                                           size: 40,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                           'Camera permission is required.',
                                           textAlign: TextAlign.center,
                                           style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                           ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                           'Please allow camera access in App Settings to scan QR codes.',
                                           textAlign: TextAlign.center,
                                           style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 12,

                                            fontWeight: FontWeight.w400,
                                          ),
                                       ),
                                     ],
                                 ),
                               ),
                             )
                           else
                             MobileScanner(
                                controller: _controller,
                                onDetect: _handleScan,
                                errorBuilder: (context, error, child) {
                                   WidgetsBinding.instance.addPostFrameCallback(
                                      (_) {
                                         if (!mounted) return;
                                         final permissionIssue =
                                               _isPermissionIssue(error);
                                         if (permissionIssue) {
                                            _setPermissionError(true);
                                         }
                                         _setScannerActive(false);
                                      },
                                   );
                                   return const SizedBox.shrink();
                                },
                             ),
                           if (!_hasPermissionError)
                             CustomPaint(
                                painter: _QrOverlayPainter(
                                   cutOutSize: squareSize * 0.7,
                                ),
                                size: Size(squareSize, squareSize),
                             ),
                           if (_isLoading)
                             Container(
                                color: Colors.black.withValues(alpha: 0.6),
                                child: const Center(
                                   child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                         CircularProgressIndicator(
                                            color: Colors.white,
                                         ),
                                         SizedBox(height: 14),
                                         Text(
                                            'Verifying QR session...',
                                            style: TextStyle(
                                               color: Colors.white,
                                               fontSize: 15,
                                               fontWeight: FontWeight.w600,
                                            ),
                                         ),
                                      ],
                                   ),
                                ),
                             ),
                           if (!_hasPermissionError)
                             Positioned(
                                bottom: 20,
                                left: 0,
                                right: 0,
                                child: Container(
                                   padding: const EdgeInsets.symmetric(

                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    margin:
                                          const EdgeInsets.symmetric(horizontal: 24),
                                    decoration: BoxDecoration(
                                       color: Colors.black.withValues(alpha: 0.6),
                                       borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       children: [
                                          Icon(
                                             Icons.info_outline,
                                             color: Colors.white70,
                                             size: 16,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                             'Position QR code inside the frame',
                                             style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                             ),
                                          ),
                                       ],
                                    ),
                                 ),
                               ),
                          ],
                        ),
                     ),
                   ),
                ),
                Expanded(
                   flex: 1,
                   child: Center(
                      child: Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 24),
                         child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                               const Icon(
                                  Icons.qr_code_2_rounded,
                                  color: AppTheme.policeBlue,
                                  size: 28,
                               ),
                               const SizedBox(height: 8),
                               const Text(
                                  'Scan the QR code displayed on the driver\'s app',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                     color: AppTheme.textGray,
                                     fontSize: 13,
                                     fontWeight: FontWeight.w500,
                                  ),
                               ),
                            ],
                         ),
                      ),
                   ),
                ),
                const SizedBox(height: 8),
              ],

                );
             },
           ),
        ),
      );
  }
}
class _QrOverlayPainter extends CustomPainter {
  const _QrOverlayPainter({required this.cutOutSize});
  final double cutOutSize;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
       ..color = Colors.white.withValues(alpha: 0.85)
       ..style = PaintingStyle.stroke
       ..strokeWidth = 3;
    final left = (size.width - cutOutSize) / 2;
    final top = (size.height - cutOutSize) / 2;
    final right = left + cutOutSize;
    final bottom = top + cutOutSize;
    const cornerLength = 28.0;
    canvas.drawLine(
       Offset(left, top + cornerLength),
       Offset(left, top),
       paint,
    );
    canvas.drawLine(
       Offset(left, top),
       Offset(left + cornerLength, top),
       paint,
    );
    canvas.drawLine(
       Offset(right, top + cornerLength),
       Offset(right, top),
       paint,
    );
    canvas.drawLine(
       Offset(right, top),
       Offset(right - cornerLength, top),
       paint,
    );
    canvas.drawLine(
       Offset(left, bottom - cornerLength),
       Offset(left, bottom),
       paint,
    );
    canvas.drawLine(
       Offset(left, bottom),
       Offset(left + cornerLength, bottom),
       paint,
    );
    canvas.drawLine(
       Offset(right, bottom - cornerLength),
       Offset(right, bottom),
       paint,
    );
    canvas.drawLine(
       Offset(right, bottom),
       Offset(right - cornerLength, bottom),
       paint,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
