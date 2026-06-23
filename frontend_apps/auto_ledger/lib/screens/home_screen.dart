import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../utils/secure_storage.dart';
import 'login_screen.dart';
import 'fines_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isFront = true;
  bool _isSelectionMode = false;

  Map<String, dynamic>? _licenseData;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _hasShownPointsWarning = false;
  final List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _fetchLicenseData();
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

  Future<void> _fetchLicenseData() async {
    try {
      final response = await ApiService.dio.get('/license/my-license');
      if (!mounted) return;

      setState(() {
        _licenseData = Map<String, dynamic>.from(response.data);
        _isLoading = false;
      });

      if (!_hasShownPointsWarning) {
        final points = _licenseData?['points'] ?? 0;
        final bool isApproachingSuspension = (points >= 20 && points <= 23) ||
            (points >= 45 && points <= 49) ||
            (points >= 80 && points <= 99);

        if (isApproachingSuspension) {
          _hasShownPointsWarning = true;
          Future.microtask(() => _showPointsWarning(points));
        }
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.response?.data['message'] ?? 'Failed to load license details.';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
        _isLoading = false;
      });
    }
  }

  void _showPointsWarning(int points) {
    Color warningColor;
    IconData warningIcon;
    String warningTitle;
    String warningMessage;

    if (points >= 80 && points <= 99) {
      warningColor = Colors.red.shade400;
      warningIcon = Icons.warning_rounded;
      warningTitle = 'CRITICAL RISK';
      warningMessage = 'You have high demerit points ($points points). Reach 100 points and your license will be permanently revoked.';
    } else if (points >= 45 && points <= 49) {
      warningColor = Colors.orange.shade400;
      warningIcon = Icons.warning_rounded;
      warningTitle = 'SEVERE RISK';
      warningMessage = 'You have high demerit points ($points points). Reach 50 points and your license will be suspended.';
    } else {
      warningColor = Colors.amber.shade400;
      warningIcon = Icons.info_outline_rounded;
      warningTitle = 'WARNING';
      warningMessage = 'You have high demerit points ($points points). Reach 24 points and your license will be suspended.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(179),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(77),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withAlpha(128), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(backgroundColor: warningColor.withAlpha(51), radius: 40, child: Icon(warningIcon, size: 40, color: warningColor)),
                  const SizedBox(height: 20),
                  Text(warningTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: warningColor)),
                  const SizedBox(height: 15),
                  Text(warningMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A2980),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: const Text('I Understand', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _showTemporaryLicenseSheet(Map<String, dynamic> tempLicense) {
    _addRecentActivity('Viewed Temporary License', Icons.assignment_late_outlined);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(64),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
              border: Border.all(color: Colors.white.withAlpha(128), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white.withAlpha(128), borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Icon(Icons.assignment_late_outlined, color: Color(0xFF1A2980), size: 28),
                    SizedBox(width: 10),
                    Text('Temporary License', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A2980))),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTempInfoRow('Issued Date', _formatDate(tempLicense['issue_Date'])),
                Divider(height: 20, color: Colors.black.withAlpha(26)),
                _buildTempInfoRow('Valid Until', _formatDate(tempLicense['expiry_Date']), isHighlight: true),
                Divider(height: 20, color: Colors.black.withAlpha(26)),
                _buildTempInfoRow('Issued By (Officer)', tempLicense['issued_By'] ?? 'Unknown'),
                const SizedBox(height: 30),
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                            if (states.contains(WidgetState.pressed)) return Colors.grey.shade400.withAlpha(153);
                            return Colors.white.withAlpha(51);
                          }),
                          foregroundColor: WidgetStateProperty.all(Colors.black87),
                          elevation: WidgetStateProperty.all(0),
                          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.white.withAlpha(102), width: 1.5))),
                          overlayColor: WidgetStateProperty.all(Colors.black12),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                        },
                        child: const Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
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

  Widget _buildTempInfoRow(String title, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isHighlight ? Colors.red.shade900 : Colors.black87)),
      ],
    );
  }

  Future<void> _generateQR() async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)));
    try {
      final response = await ApiService.dio.get('/license/generate-qr');
      final String token = response.data['qrToken'];
      if (mounted) Navigator.pop(context);
      _addRecentActivity('Generated QR Code', Icons.qr_code_scanner);
      if (mounted) showDialog(context: context, barrierDismissible: false, builder: (BuildContext context) => _QRDialog(qrToken: token));
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate QR Code. Check license status.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _logout() async {
    await SecureStorage.deleteToken();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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
          TextSpan(text: number, style: TextStyle(fontSize: 8.5, color: Colors.blueGrey[800], fontWeight: FontWeight.bold)),
          TextSpan(text: value, style: TextStyle(fontSize: 9.5, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: Colors.black87)),
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      key: const ValueKey(true),
      width: double.infinity,
      height: screenWidth * 0.58,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(77)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: Center(child: Opacity(opacity: 0.08, child: Image.asset('assets/emblem.png', width: screenWidth * 0.35, color: Colors.black, colorBlendMode: BlendMode.srcIn, errorBuilder: (c, e, s) => const SizedBox())))),
          Positioned(bottom: 18, right: 48, child: Opacity(opacity: 0.15, child: Image.asset('assets/punkalasa.png', width: screenWidth * 0.15, color: Colors.black, colorBlendMode: BlendMode.srcIn, errorBuilder: (c, e, s) => Icon(Icons.security, size: screenWidth * 0.13, color: Colors.black)))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 0.5)), child: Image.asset('assets/flag.png', width: screenWidth * 0.09, height: screenWidth * 0.055, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: screenWidth * 0.09, height: screenWidth * 0.055, color: Colors.grey[300]))),
                    const SizedBox(width: 8),
                    Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [const Text('DRIVING LICENCE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1), letterSpacing: 1.0)), Container(margin: const EdgeInsets.symmetric(vertical: 2), height: 1.0, width: double.infinity, color: Colors.grey.withAlpha(102)), const Text('DEMOCRATIC SOCIALIST REPUBLIC OF SRI LANKA', textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1)))])),
                    const SizedBox(width: 8),
                    Image.asset('assets/emblem.png', width: screenWidth * 0.08, height: screenWidth * 0.1, errorBuilder: (c, e, s) => SizedBox(width: screenWidth * 0.08, height: screenWidth * 0.1)),
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
                            Container(width: screenWidth * 0.18, height: screenWidth * 0.22, decoration: const BoxDecoration(color: Colors.transparent), child: imageUrl != null && imageUrl.isNotEmpty ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: screenWidth * 0.14, color: Colors.black54)) : Icon(Icons.person, size: screenWidth * 0.14, color: Colors.black54)),
                            const SizedBox(height: 4),
                            Text('4a. $issueDate', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87)),
                            const SizedBox(height: 12),
                            Builder(
                              builder: (context) {
                                List<Color> statusGradient;
                                Color glowColor;
                                IconData statusIcon;
                                if (status == 'ACTIVE') { statusGradient = [const Color(0xFF00b09b), const Color(0xFF96c93d)]; glowColor = const Color(0xFF00b09b); statusIcon = Icons.check_circle_rounded; } else if (status == 'SUSPENDED') { statusGradient = [const Color(0xFFf12711), const Color(0xFFf5af19)]; glowColor = const Color(0xFFf12711); statusIcon = Icons.warning_rounded; } else { statusGradient = [const Color(0xFFcb2d3e), const Color(0xFFef473a)]; glowColor = const Color(0xFFcb2d3e); statusIcon = Icons.cancel_rounded; }
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(gradient: LinearGradient(colors: statusGradient.map((c) => c.withAlpha(204)).toList(), begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: glowColor.withAlpha(102), blurRadius: 4, spreadRadius: 1, offset: const Offset(0, 1))], border: Border.all(color: Colors.white.withAlpha(153), width: 1.0)),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(statusIcon, color: Colors.white, size: 11), const SizedBox(width: 4), Text(status, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.8))]),
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
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _buildDetailText('5. ', licenseNo, isBold: true)), const SizedBox(width: 8), Expanded(child: _buildDetailText('4c. ', nicNo))]),
                              const SizedBox(height: 8),
                              _buildDetailText('1, 2. ', name), const SizedBox(height: 8), _buildDetailText('8. ', address), const SizedBox(height: 8), _buildDetailText('3. ', dob),
                              const Spacer(),
                              Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [const Text('Blood Group  ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)), Text(bloodGroup, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)), const Spacer(), const Text('SL', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF8E24AA)))]),
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
    final cat = categories.cast<Map<String, dynamic>>().firstWhere((c) => c['vehicle_Class'] == code, orElse: () => <String, dynamic>{});
    if (cat.isNotEmpty) return _buildTableRow('$code $icon', _formatDate(cat['issue_Date']), _formatDate(cat['expiry_Date']), cat['restriction'] ?? '---');
    return _buildTableRow('$code $icon', '---', '---', '---');
  }

  Widget _buildLegendText(String text) => Padding(padding: const EdgeInsets.only(bottom: 2.5), child: Text(text, style: TextStyle(fontSize: 6.0, color: Colors.blueGrey[800], fontWeight: FontWeight.w600, height: 1.0)));

  TableRow _buildTableRow(String col1, String col2, String col3, String restriction, {bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(color: isHeader ? Colors.grey.withAlpha(51) : Colors.transparent),
      children: [
        Padding(padding: const EdgeInsets.all(1.0), child: Text(col1, textAlign: TextAlign.center, style: TextStyle(fontSize: isHeader ? 7.5 : 8.5, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal))),
        Padding(padding: const EdgeInsets.all(1.0), child: Text(col2, textAlign: TextAlign.center, style: TextStyle(fontSize: isHeader ? 7.5 : 8.5, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal))),
        Padding(padding: const EdgeInsets.all(1.0), child: Text(col3, textAlign: TextAlign.center, style: TextStyle(fontSize: isHeader ? 7.5 : 8.5, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal))),
        Padding(padding: const EdgeInsets.all(1.0), child: Text(restriction, textAlign: TextAlign.center, style: TextStyle(fontSize: isHeader ? 7.5 : 8.5, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal))),
      ],
    );
  }

  Widget _buildBackCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      key: const ValueKey(false),
      width: double.infinity,
      height: screenWidth * 0.58,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(77)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: Center(child: Opacity(opacity: 0.04, child: Image.asset('assets/emblem.png', width: screenWidth * 0.35, color: Colors.black, colorBlendMode: BlendMode.srcIn, errorBuilder: (c, e, s) => const SizedBox())))),
          Positioned(left: 6, top: 15, bottom: 15, child: Center(child: RotatedBox(quarterTurns: 3, child: Text('Department of Motor Traffic - Sri Lanka', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]))))),
          Padding(
            padding: const EdgeInsets.only(left: 28, right: 16, top: 12, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [_buildLegendText('1. Surname'), _buildLegendText('2. Other names'), _buildLegendText('3. Date of birth'), _buildLegendText('4a. Date of Issue of the License'), _buildLegendText('4b. Issuing Authority'), _buildLegendText('4c. Administrative Number'), _buildLegendText('5. Number of the LICENCE'), _buildLegendText('7. Signature of the holder'), _buildLegendText('8. Permanent place of residence'), _buildLegendText('9. Categories of vehicles'), _buildLegendText('10. Date of Issue per category'), _buildLegendText('11. Date of Expiry per category'), _buildLegendText('12. Restrictions in code form')])),
                const SizedBox(width: 6),
                Expanded(
                  flex: 7,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Table(
                      border: TableBorder.all(color: Colors.black.withAlpha(77), width: 0.5),
                      columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(2.2), 2: FlexColumnWidth(2.2), 3: FlexColumnWidth(1.2)},
                      children: [_buildTableRow('9.', '10.', '11.', '12.', isHeader: true), _buildCategoryRow('A1', '🛺'), _buildCategoryRow('A', '🏍️'), _buildCategoryRow('B1', '🛺'), _buildCategoryRow('B', '🚗'), _buildCategoryRow('C1', '🚚'), _buildCategoryRow('C', '🚛'), _buildCategoryRow('CE', '🚛'), _buildCategoryRow('D1', '🚐'), _buildCategoryRow('D', '🚌'), _buildCategoryRow('DE', '🚌'), _buildCategoryRow('G1', '🚜'), _buildCategoryRow('G', '🚜'), _buildCategoryRow('J', '🏗️'), _buildCategoryRow('H', '♿')],
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

  Widget _buildGlassButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(color: color.withAlpha(191), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withAlpha(102), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 5))]),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 26, color: Colors.white), const SizedBox(width: 12), Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white))]),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesFragment() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.42,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withAlpha(150), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withAlpha(153), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 15, offset: const Offset(0, 5))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recent Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2980))),
              const SizedBox(height: 10),
              Container(height: 1.5, decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF1A2980).withAlpha(100), Colors.transparent]))),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: _recentActivities.length,
                  separatorBuilder: (context, index) => Divider(color: Colors.black.withAlpha(26)),
                  itemBuilder: (context, index) {
                    final activity = _recentActivities[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF1A2980).withAlpha(38), shape: BoxShape.circle), child: Icon(activity['icon'], color: const Color(0xFF1A2980), size: 20)),
                      title: Text(activity['title'], style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(activity['date'], style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60), const SizedBox(height: 16),
              Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)), const SizedBox(height: 16),
              ElevatedButton(onPressed: () { setState(() { _isLoading = true; _errorMessage = ''; }); _fetchLicenseData(); }, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final List<dynamic> tempLicenses = _licenseData?['temporaryLicenses'] ?? [];
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 120.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Text(_isFront ? 'Tap the card to see the back side' : 'Tap the card to see the front side', style: const TextStyle(color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(onTap: () { HapticFeedback.selectionClick(); setState(() { _isFront = !_isFront; }); }, child: AnimatedSwitcher(duration: const Duration(milliseconds: 150), transitionBuilder: (Widget child, Animation<double> animation) { return FadeTransition(opacity: animation, child: child); }, child: _isFront ? _buildFrontCard() : _buildBackCard())),
          const SizedBox(height: 32),
          if (tempLicenses.isNotEmpty) ...[
            _buildGlassButton(label: 'VIEW TEMPORARY LICENSE', icon: Icons.assignment_late_outlined, color: Colors.orangeAccent.shade700, onPressed: () { HapticFeedback.lightImpact(); _showTemporaryLicenseSheet(tempLicenses.last as Map<String, dynamic>); }),
            const SizedBox(height: 16),
          ],
          _buildGlassButton(label: 'SHOW QR TO OFFICER', icon: Icons.qr_code_scanner, color: const Color(0xFF1A2980), onPressed: () { HapticFeedback.lightImpact(); _generateQR(); }),
          const SizedBox(height: 25),
          _buildRecentActivitiesFragment(),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (_currentIndex == index) return;
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = index);

        if (index == 0) {
          _addRecentActivity('Viewed License Dashboard', Icons.credit_card);
        } else if (index == 1) {
          _addRecentActivity('Navigated to Fines', Icons.receipt_long);
        } else if (index == 2) {
          _addRecentActivity('Navigated to Profile', Icons.person);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? Colors.white.withAlpha(51) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: isSelected ? Colors.white : Colors.white70, size: 22), if (isSelected) ...[const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))]]),
      ),
    );
  }

  Widget _buildGlassBackground() {
    return RepaintBoundary(
      child: Stack(
        children: [
          Container(color: const Color(0xFFF0F4FF)),
          Positioned(top: -50, left: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(color: const Color(0xFF1A2980).withAlpha(51), shape: BoxShape.circle))),
          Positioned(bottom: 100, right: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(color: Colors.greenAccent.withAlpha(51), shape: BoxShape.circle))),
          Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), child: Container(color: Colors.transparent))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildGlassBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          extendBodyBehindAppBar: true,
          appBar: _currentIndex == 0 ? AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF1A2980).withAlpha(217),
            flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
            foregroundColor: Colors.white,
            title: const Text('Auto-Ledger Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            elevation: 0,
            actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
          ) : null,
          body: SafeArea(
            top: _currentIndex == 0,
            bottom: false, // මෙන්න මේකෙන් තමයි අර යටින් ආව සුදු පාට ගැප් එක අයින් කරේ!
            child: _currentIndex == 0
                ? _buildDashboard()
                : _currentIndex == 1
                ? FinesScreen(
              onLogActivity: _addRecentActivity,
              onSelectionModeChanged: (isSelected) {
                setState(() {
                  _isSelectionMode = isSelected;
                });
              },
            )
                : const Center(child: Text('Profile Screen Coming Soon!')),
          ),
          bottomNavigationBar: AnimatedSlide(
            offset: _isSelectionMode ? const Offset(0, 2) : Offset.zero,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16, left: 30, right: 30),
                height: 65,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: Colors.black.withAlpha(38), blurRadius: 20, offset: const Offset(0, 10))]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      decoration: BoxDecoration(color: const Color(0xFF1A2980).withAlpha(217), borderRadius: BorderRadius.circular(35), border: Border.all(color: Colors.white.withAlpha(77), width: 1.5)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildNavItem(0, 'License', Icons.credit_card), _buildNavItem(1, 'Fines', Icons.receipt_long), _buildNavItem(2, 'Profile', Icons.person)]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QRDialog extends StatefulWidget {
  final String qrToken;
  const _QRDialog({required this.qrToken});
  @override State<_QRDialog> createState() => _QRDialogState();
}

class _QRDialogState extends State<_QRDialog> {
  int _remainingSeconds = 180; Timer? _pollingTimer; Timer? _countdownTimer; bool _isScanned = false;
  @override void initState() { super.initState(); _startPolling(); }
  @override void dispose() { _pollingTimer?.cancel(); _countdownTimer?.cancel(); super.dispose(); }
  void _startPolling() { _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async { try { final response = await ApiService.dio.get('/license/check-scan-status', queryParameters: {'qrToken': widget.qrToken}); if (response.data['scanned'] == true) { timer.cancel(); _onQrScanned(); } } catch (e) {} }); }
  void _onQrScanned() { if (!mounted || _isScanned) return; setState(() { _isScanned = true; }); _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) { if (_remainingSeconds > 0) { setState(() => _remainingSeconds--); } else { timer.cancel(); if (mounted) Navigator.pop(context); } }); }
  String get _formattedTime { int minutes = _remainingSeconds ~/ 60; int seconds = _remainingSeconds % 60; return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'; }

  @override Widget build(BuildContext context) {
    return BackdropFilter(filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), child: Dialog(backgroundColor: Colors.transparent, elevation: 0, child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white.withAlpha(64), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withAlpha(128), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 25, offset: const Offset(0, 10))]), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Show this to the Officer', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 20), Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withAlpha(102), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withAlpha(153), width: 2)), child: QrImageView(data: widget.qrToken, version: QrVersions.auto, size: 200.0, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1A2980)))), const SizedBox(height: 20), Text(_isScanned ? _formattedTime : '03:00', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _isScanned ? Colors.red.shade900 : Colors.black87)), const SizedBox(height: 15), ClipRRect(borderRadius: BorderRadius.circular(15), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), child: SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ButtonStyle(backgroundColor: WidgetStateProperty.resolveWith<Color>((states) { if (states.contains(WidgetState.pressed)) return Colors.grey.shade400.withAlpha(153); return Colors.white.withAlpha(51); }), foregroundColor: WidgetStateProperty.all(Colors.black87), elevation: WidgetStateProperty.all(0), shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.white.withAlpha(102), width: 1.5))), overlayColor: WidgetStateProperty.all(Colors.black12)), onPressed: () { HapticFeedback.mediumImpact(); Navigator.pop(context); }, child: const Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))))))]))));
  }
}