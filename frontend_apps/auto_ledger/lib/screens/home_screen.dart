import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../utils/secure_storage.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isFront = true;

  Map<String, dynamic>? _licenseData;
  bool _isLoading = true;
  String _errorMessage = '';

  bool _showQR = false;
  bool _isGeneratingQR = false;
  String _qrToken = '';
  int _remainingSeconds = 180;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchLicenseData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLicenseData() async {
    try {
      final response = await ApiService.dio.get('/license/my-license');
      setState(() {
        _licenseData = response.data;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data['message'] ?? 'Failed to load license details.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateQR() async {
    setState(() {
      _isGeneratingQR = true;
      _showQR = true;
    });

    try {
      final response = await ApiService.dio.get('/license/generate-qr');
      final String token = response.data['qrToken'];

      setState(() {
        _qrToken = token;
        _isGeneratingQR = false;
        _remainingSeconds = 180;
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          timer.cancel();
          setState(() => _showQR = false);
        }
      });
    } catch (e) {
      setState(() {
        _isGeneratingQR = false;
        _showQR = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate QR Code. Check license status.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String get _formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _logout() async {
    await SecureStorage.deleteToken();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
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

  Widget _buildDetailText(String number, String value, {bool isBold = false}) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: number,
            style: TextStyle(fontSize: 8.5, color: Colors.blueGrey[800], fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: value,
            style: TextStyle(fontSize: 9.5, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFrontCard() {
    final String name = _licenseData?['full_Name'] ?? 'N/A';
    final String address = _licenseData?['address'] ?? 'N/A';
    final String nicNo = _licenseData?['nic_No'] ?? 'N/A';
    final String licenseNo = _licenseData?['license_No'] ?? 'N/A';
    final String dob = _formatDate(_licenseData?['date_of_birth']);
    final String bloodGroup = _licenseData?['blood_Group'] ?? '-';
    final String issueDate = _formatDate(_licenseData?['issue_Date']);
    final String status = _licenseData?['status'] ?? 'UNKNOWN';
    final String? imageUrl = _licenseData?['image'];

    return Container(
      key: const ValueKey(true),
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/emblem.png',
                  width: 130,
                  color: Colors.black,
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (c, e, s) => const SizedBox(),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            right: 48,
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/punkalasa.png',
                width: 60,
                color: Colors.black,
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (c, e, s) => const Icon(Icons.security, size: 50, color: Colors.black),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 0.5)),
                      child: Image.asset(
                        'assets/flag.png',
                        width: 35,
                        height: 22,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(width: 35, height: 22, color: Colors.grey[300]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('DRIVING LICENCE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1), letterSpacing: 1.0)),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            height: 1.0,
                            width: double.infinity,
                            color: Colors.grey.withValues(alpha: 0.4),
                          ),
                          const Text('DEMOCRATIC SOCIALIST REPUBLIC OF SRI LANKA', textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/emblem.png',
                      width: 30,
                      height: 40,
                      errorBuilder: (c, e, s) => const SizedBox(width: 30, height: 40),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 10.0),
                        child: Column(
                          children: [
                            Container(
                              width: 70,
                              height: 85,
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
                              ),
                              child: imageUrl != null && imageUrl.isNotEmpty
                                  ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 55, color: Colors.black54),
                              )
                                  : const Icon(Icons.person, size: 55, color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Text('4a. $issueDate', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87)),
                            const SizedBox(height: 12),
                            Builder(
                              builder: (context) {
                                List<Color> statusGradient;
                                Color glowColor;
                                IconData statusIcon;

                                if (status == 'ACTIVE') {
                                  statusGradient = [const Color(0xFF00b09b), const Color(0xFF96c93d)];
                                  glowColor = const Color(0xFF00b09b);
                                  statusIcon = Icons.check_circle_rounded;
                                } else if (status == 'SUSPENDED') {
                                  statusGradient = [const Color(0xFFf12711), const Color(0xFFf5af19)];
                                  glowColor = const Color(0xFFf12711);
                                  statusIcon = Icons.warning_rounded;
                                } else {
                                  statusGradient = [const Color(0xFFcb2d3e), const Color(0xFFef473a)];
                                  glowColor = const Color(0xFFcb2d3e);
                                  statusIcon = Icons.cancel_rounded;
                                }

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: statusGradient.map((c) => c.withValues(alpha: 0.8)).toList(),
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: glowColor.withValues(alpha: 0.4),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(statusIcon, color: Colors.white, size: 11),
                                          const SizedBox(width: 4),
                                          Text(
                                            status,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
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
                                  Expanded(child: _buildDetailText('5. ', licenseNo, isBold: true)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildDetailText('4c. ', nicNo)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildDetailText('1, 2. ', name),
                              const SizedBox(height: 8),
                              _buildDetailText('8. ', address),
                              const SizedBox(height: 8),
                              _buildDetailText('3. ', dob),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text('Blood Group  ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  Text(bloodGroup, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const Spacer(),
                                  const Text('SL', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF8E24AA))),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildCategoryRow(String code, String icon) {
    final categories = _licenseData?['vehicleCategories'] as List<dynamic>? ?? [];
    final cat = categories.cast<Map<String, dynamic>>().firstWhere(
          (c) => c['vehicle_Class'] == code,
      orElse: () => <String, dynamic>{},
    );

    if (cat.isNotEmpty) {
      return _buildTableRow(
          '$code $icon',
          _formatDate(cat['issue_Date']),
          _formatDate(cat['expiry_Date']),
          cat['restriction'] ?? '---'
      );
    } else {
      return _buildTableRow('$code $icon', '---', '---', '---');
    }
  }

  Widget _buildBackCard() {
    return Container(
      key: const ValueKey(false),
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.04,
                child: Image.asset(
                  'assets/emblem.png',
                  width: 130,
                  color: Colors.black,
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (c, e, s) => const SizedBox(),
                ),
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
                child: Text(
                  'Department of Motor Traffic - Sri Lanka',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28, right: 16, top: 12, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendText('1. Surname'),
                      _buildLegendText('2. Other names'),
                      _buildLegendText('3. Date of birth'),
                      _buildLegendText('4a. Date of Issue of the License'),
                      _buildLegendText('4b. Issuing Authority'),
                      _buildLegendText('4c. Administrative Number'),
                      _buildLegendText('5. Number of the LICENCE'),
                      _buildLegendText('7. Signature of the holder'),
                      _buildLegendText('8. Permanent place of residence'),
                      _buildLegendText('9. Categories of vehicles'),
                      _buildLegendText('10. Date of Issue per category'),
                      _buildLegendText('11. Date of Expiry per category'),
                      _buildLegendText('12. Restrictions in code form'),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 7,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Table(
                      border: TableBorder.all(color: Colors.black.withValues(alpha: 0.3), width: 0.5),
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(2.2),
                        2: FlexColumnWidth(2.2),
                        3: FlexColumnWidth(1.2),
                      },
                      children: [
                        _buildTableRow('9.', '10.', '11.', '12.', isHeader: true),
                        _buildCategoryRow('A1', '🛺'),
                        _buildCategoryRow('A', '🏍️'),
                        _buildCategoryRow('B1', '🛺'),
                        _buildCategoryRow('B', '🚗'),
                        _buildCategoryRow('C1', '🚚'),
                        _buildCategoryRow('C', '🚛'),
                        _buildCategoryRow('CE', '🚛'),
                        _buildCategoryRow('D1', '🚐'),
                        _buildCategoryRow('D', '🚌'),
                        _buildCategoryRow('DE', '🚌'),
                        _buildCategoryRow('G1', '🚜'),
                        _buildCategoryRow('G', '🚜'),
                        _buildCategoryRow('J', '🏗️'),
                        _buildCategoryRow('H', '♿'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.5),
      child: Text(
        text,
        style: TextStyle(fontSize: 6.0, color: Colors.blueGrey[800], fontWeight: FontWeight.w600, height: 1.0),
      ),
    );
  }

  TableRow _buildTableRow(String col1, String col2, String col3, String restriction, {bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(color: isHeader ? Colors.grey.withValues(alpha: 0.2) : Colors.transparent),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 1.0),
          child: Text(col1, textAlign: TextAlign.center, style: TextStyle(fontSize: isHeader ? 7.5 : 8.5, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 1.0),
          child: Text(col2, textAlign: TextAlign.center, style: TextStyle(fontSize: isHeader ? 7.5 : 8.5, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 1.0),
          child: Text(col3, textAlign: TextAlign.center, style: TextStyle(fontSize: isHeader ? 7.5 : 8.5, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 1.0),
          child: Text(restriction, textAlign: TextAlign.center, style: TextStyle(fontSize: isHeader ? 7.5 : 8.5, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal)),
        ),
      ],
    );
  }

  Widget _buildDashboard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = '';
                  });
                  _fetchLicenseData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Text(
            _isFront ? 'Tap the card to see the back side' : 'Tap the card to see the front side',
            style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isFront = !_isFront;
              });
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _isFront ? _buildFrontCard() : _buildBackCard(),
            ),
          ),
          const SizedBox(height: 32),
          if (!_showQR)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2980),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                icon: const Icon(Icons.qr_code_scanner, size: 28),
                label: const Text('SHOW QR TO OFFICER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _generateQR,
              ),
            )
          else
            Column(
              children: [
                const Text('Scan within the time limit', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: _isGeneratingQR
                      ? const SizedBox(
                      height: 200,
                      width: 200,
                      child: Center(child: CircularProgressIndicator())
                  )
                      : QrImageView(
                    data: _qrToken,
                    version: QrVersions.auto,
                    size: 200.0,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1A2980)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _formattedTime,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _timer?.cancel();
                    setState(() => _showQR = false);
                  },
                  child: const Text('Close QR', style: TextStyle(fontSize: 16)),
                )
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2980),
        foregroundColor: Colors.white,
        title: const Text('Auto-Ledger Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _currentIndex == 0
          ? _buildDashboard()
          : _currentIndex == 1
          ? const Center(child: Text('Fines Screen Coming Soon!'))
          : const Center(child: Text('Profile Screen Coming Soon!')),
      bottomNavigationBar: NavigationBar(
        height: 65,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.credit_card), label: 'License'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Fines'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}