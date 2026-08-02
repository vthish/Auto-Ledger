import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';

class FinesScreen extends StatefulWidget {
  final void Function(String, IconData) onLogActivity;
  final ValueChanged<bool> onSelectionModeChanged;
  final int initialTab;

  const FinesScreen({
    super.key,
    required this.onLogActivity,
    required this.onSelectionModeChanged,
    this.initialTab = 0,
  });

  @override
  State<FinesScreen> createState() => _FinesScreenState();
}

class _FinesScreenState extends State<FinesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedFines = {};

  List<Map<String, dynamic>> _pendingFines = [];
  List<Map<String, dynamic>> _paidFines = [];

  bool _isLoading = true;
  String _errorMessage = '';

  Timer? _paymentTimer;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _tabController.addListener(_handleTabChange);
    _fetchFines();
  }

  @override
  void dispose() {
    _paymentTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final tabName = _tabController.index == 0
          ? 'Pending Fines'
          : _tabController.index == 1
              ? 'Paid Fines'
              : 'Points History';
      widget.onLogActivity('Viewed $tabName', Icons.tab);
      if (_selectedFines.isNotEmpty) {
        setState(() => _selectedFines.clear());
        widget.onSelectionModeChanged(false);
      }
    }
  }

  Future<void> _fetchFines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.dio.get('/fines/my-fines');
      final finesData = response.data as List<dynamic>;

      final List<Map<String, dynamic>> parsedPending = [];
      final List<Map<String, dynamic>> parsedPaid = [];

      for (var f in finesData) {
        double totalAmount = 0.0;
        int totalPoints = 0;
        List<Map<String, dynamic>> offenseDetails = [];

        if (f['offenses'] != null) {
          for (var o in f['offenses']) {
            final category = o['offenceCategory'];
            if (category != null) {
              final amount = (category['amount'] as num?)?.toDouble() ?? 0.0;
              final points = (category['points_Value'] as num?)?.toInt() ?? 0;
              totalAmount += amount;
              totalPoints += points;
              offenseDetails.add({
                'name': category['name'].toString(),
                'code': category['code'] ?? '',
                'points': points,
                'amount': amount,
              });
            }
          }
        }

        final officer = f['trafficOfficer'];
        final officerName = officer != null
            ? '${officer['name']} (${officer['badge_No']})'
            : 'Unknown Officer';

        final status = f['status'];
        final hasPayment = f['payment'] != null;

        final mappedFine = {
          'id': f['fine_Id'],
          'date': f['issue_At'],
          'amount': totalAmount,
          'points': totalPoints,
          'offenses': offenseDetails.isNotEmpty
              ? offenseDetails
              : [
                  {
                    'name': 'Unknown Offense',
                    'code': '',
                    'points': 0,
                    'amount': 0
                  }
                ],
          'status': status,
          'officer': officerName,
          'comment': f['comment'] ?? '',
          'dueDate': f['due_Date'],
          'payment': f['payment'],
          'scanLocation': f['scanLocation'],
        };

        if (status == 'PAID' || (status == 'COURT_CASE' && hasPayment)) {
          parsedPaid.add(mappedFine);
        } else {
          parsedPending.add(mappedFine);
        }
      }

      if (mounted) {
        setState(() {
          _pendingFines = parsedPending;
          _paidFines = parsedPaid;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              e.response?.data['message'] ?? 'Failed to load fines.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred.';
        });
      }
    }
  }

  Future<void> _processPayment(
      List<Map<String, dynamic>> finesToPay, double totalAmount) async {
    FocusManager.instance.primaryFocus?.unfocus();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      if (finesToPay.length == 1) {
        await ApiService.dio.post('/fines/${finesToPay.first['id']}/pay',
            data: {'amount': totalAmount});
      } else {
        final ids = finesToPay.map((f) => f['id'].toString()).toList();
        await ApiService.dio.post('/fines/pay-bulk',
            data: {'fineIds': ids, 'totalAmount': totalAmount});
      }

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);

      HapticFeedback.heavyImpact();
      widget.onLogActivity(
          'Successfully Paid Rs. ${totalAmount.toStringAsFixed(2)}',
          Icons.check_circle);

      setState(() => _selectedFines.clear());
      widget.onSelectionModeChanged(false);

      showDialog(
        context: context,
        barrierColor: Colors.black.withAlpha(160),
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.symmetric(
                        vertical: 30, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withAlpha(40),
                          Colors.white.withAlpha(15)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withAlpha(60), width: 1.0),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 40,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withAlpha(30),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.greenAccent.withAlpha(60),
                                width: 1.5),
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.greenAccent, size: 40),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Payment Successful!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      _paymentTimer?.cancel();
      _paymentTimer = Timer(const Duration(milliseconds: 2000), () {
        if (mounted) {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          if (mounted) {
            _fetchFines();
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showGlassToast('Payment Failed! Please try again.', isError: true);
    }
  }

  void _showReceiptDialog(Map<String, dynamic> fine) {
    widget.onLogActivity('Viewed Fine Receipt', Icons.receipt);
    showDialog(
      context: context,
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
                borderRadius: BorderRadius.circular(30),
                border:
                    Border.all(color: Colors.white.withAlpha(60), width: 1.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: Colors.white, size: 50),
                  const SizedBox(height: 16),
                  const Text(
                    'Download Receipt',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Fine #${_formatId(fine['id'])}',
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.white70)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(40),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side:
                                  BorderSide(color: Colors.white.withAlpha(60)),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onLogActivity(
                                'Downloaded Receipt #${_formatId(fine['id'])}',
                                Icons.picture_as_pdf);
                            PdfService.generateAndPrintReceipt(fine);
                          },
                          child: const Text('Download',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '---';
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '---';
    }
  }

  String _formatId(String uuid) {
    return uuid.length >= 8 ? '#${uuid.substring(0, 8).toUpperCase()}' : uuid;
  }

  void _toggleSelection(String id) {
    HapticFeedback.selectionClick();
    final wasEmpty = _selectedFines.isEmpty;
    setState(() {
      if (!_selectedFines.remove(id)) {
        _selectedFines.add(id);
        widget.onLogActivity(
            'Selected Fine ${_formatId(id)}', Icons.touch_app_rounded);
      } else {
        widget.onLogActivity(
            'Deselected Fine ${_formatId(id)}', Icons.touch_app_rounded);
      }
    });
    if (wasEmpty != _selectedFines.isEmpty) {
      widget.onSelectionModeChanged(_selectedFines.isNotEmpty);
    }
  }

  double _calculateTotalSelectedAmount() {
    return _pendingFines
        .where((fine) => _selectedFines.contains(fine['id']))
        .fold(0, (sum, fine) => sum + fine['amount']);
  }

  void _showPaymentDialog(List<Map<String, dynamic>> finesToPay) {
    final double totalAmount =
        finesToPay.fold(0, (sum, item) => sum + item['amount']);
    final bool isBulk = finesToPay.length > 1;

    widget.onLogActivity(
        'Initiated ${isBulk ? 'Bulk ' : ''}Payment', Icons.payment);

    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(160),
      builder: (BuildContext context) {
        bool isCvvObscured = true;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(horizontal: 24),
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
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: Colors.white.withAlpha(70), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 40,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payment_rounded,
                            size: 40, color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          isBulk ? 'Bulk Payment' : 'Pay Fine',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withAlpha(50), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isBulk ? 'Bulk Payment' : 'Pay Fine',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isBulk
                                            ? '${finesToPay.length} Fines Selected'
                                            : 'ID: ${_formatId(finesToPay.first['id'])}',
                                        style: const TextStyle(
                                            color: Colors.white60,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Rs. ${totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.redAccent),
                                  ),
                                ],
                              ),
                              if (finesToPay.length == 1 &&
                                  finesToPay.first['offenses'] != null) ...[
                                const SizedBox(height: 12),
                                ...List.generate(
                                    finesToPay.first['offenses'].length,
                                    (index) {
                                  final offense =
                                      finesToPay.first['offenses'][index];
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        Text(offense['code'] ?? '',
                                            style: TextStyle(
                                                color: Colors.white60,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Text(offense['name'],
                                                style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12))),
                                        Text('+${offense['points']} pts',
                                            style: TextStyle(
                                                color: Colors.orangeAccent,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  children: List.generate(
                                      30,
                                      (index) => Expanded(
                                          child: Container(
                                              height: 1.2,
                                              color: index % 2 == 0
                                                  ? Colors.white.withAlpha(50)
                                                  : Colors.transparent))),
                                ),
                              ),
                              _buildPaymentTextField(
                                'Card Number',
                                Icons.credit_card_rounded,
                                true,
                                fontSize: 15,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(16),
                                  _CardNumberFormatter(),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildPaymentTextField(
                                    'MM/YY',
                                    Icons.calendar_today_rounded,
                                    true,
                                    inputFormatters: [
                                      _ExpiryDateFormatter(),
                                      LengthLimitingTextInputFormatter(5),
                                    ],
                                  )),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: _buildPaymentTextField(
                                    'CVV',
                                    Icons.lock_outline_rounded,
                                    true,
                                    isObscure: isCvvObscured,
                                    suffixIcon: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        isCvvObscured
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: Colors.white70,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        setModalState(() {
                                          isCvvObscured = !isCvvObscured;
                                        });
                                      },
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                    ],
                                  )),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16))),
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: Colors.white.withAlpha(50),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                          color: Colors.white.withAlpha(80))),
                                ),
                                onPressed: () =>
                                    _processPayment(finesToPay, totalAmount),
                                child: const Text('CONFIRM',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentTextField(
    String label,
    IconData icon,
    bool isNumber, {
    bool isObscure = false,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    double? fontSize,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(50), width: 1.0),
      ),
      child: TextField(
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        obscureText: isObscure,
        inputFormatters: inputFormatters,
        style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: fontSize ?? 15),
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          labelStyle: const TextStyle(
              color: Colors.white60, fontWeight: FontWeight.w600, fontSize: 12),
          prefixIcon: Icon(icon, color: Colors.white70, size: 18),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 34, minHeight: 34),
          suffixIcon: suffixIcon,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 34, minHeight: 34),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                      shape: BoxShape.circle))),
          Positioned(
              bottom: 50,
              right: -100,
              child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                      color: Colors.teal.shade900.withAlpha(120),
                      shape: BoxShape.circle))),
          Positioned(
              top: 250,
              right: 20,
              child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                      color: Colors.purpleAccent.withAlpha(50),
                      shape: BoxShape.circle))),
          Positioned.fill(
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
                  child: Container(color: Colors.transparent))),
        ],
      ),
    );
  }

  Widget _buildFineCard(Map<String, dynamic> fine, bool isPending) {
    final bool hasPayment = fine['payment'] != null;
    final bool isPendingDH = isPending && hasPayment;
    final isSelected = _selectedFines.contains(fine['id']);
    final isOverdue = fine['dueDate'] != null &&
        DateTime.parse(fine['dueDate']).isBefore(DateTime.now());

    final gradientColors = isSelected
        ? [
            const Color(0xFF1A2980).withAlpha(45),
            const Color(0xFF1A2980).withAlpha(15)
          ]
        : [Colors.white.withAlpha(35), Colors.white.withAlpha(15)];

    final borderColor = isSelected
        ? const Color(0xFF1A2980).withAlpha(150)
        : Colors.white.withAlpha(60);

    String displayStatus = fine['status'];
    if (hasPayment && fine['status'] == 'COURT_CASE') {
      displayStatus = 'PAID - PENDING DH';
    }

    return GestureDetector(
      onTap: (isPending && !isPendingDH)
          ? () => _toggleSelection(fine['id'])
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: borderColor, width: isSelected ? 2.0 : 1.0),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 25,
                      offset: const Offset(0, 8))
                ],
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (isPending && !isPendingDH) ...[
                            Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color:
                                    isSelected ? Colors.white : Colors.white60,
                                size: 22),
                            const SizedBox(width: 10),
                          ],
                          Text(_formatId(fine['id']),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontSize: 16,
                                  letterSpacing: 1.0)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: displayStatus == 'PAID - PENDING DH'
                              ? Colors.blue.withAlpha(30)
                              : (isPending
                                  ? Colors.red.withAlpha(30)
                                  : Colors.green.withAlpha(30)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: displayStatus == 'PAID - PENDING DH'
                                  ? Colors.blue.withAlpha(80)
                                  : (isPending
                                      ? (isOverdue
                                          ? Colors.red.shade400.withAlpha(80)
                                          : Colors.red.withAlpha(80))
                                      : Colors.green.withAlpha(80))),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayStatus,
                              style: TextStyle(
                                color: displayStatus == 'PAID - PENDING DH'
                                    ? Colors.blue.shade300
                                    : (isPending
                                        ? (isOverdue
                                            ? Colors.red.shade400
                                            : Colors.red.shade300)
                                        : Colors.green.shade300),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (isOverdue && isPending && !isPendingDH) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.warning_rounded,
                                color: Colors.redAccent,
                                size: 12,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 8),
                      Text(_formatDate(fine['date']),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (fine['dueDate'] != null) ...[
                    Row(
                      children: [
                        Icon(Icons.event_note,
                            size: 14,
                            color: isOverdue
                                ? Colors.red.shade300
                                : Colors.white70),
                        const SizedBox(width: 8),
                        Text(
                          'Due: ${_formatDate(fine['dueDate'])}',
                          style: TextStyle(
                            color:
                                isOverdue ? Colors.red.shade300 : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (fine['scanLocation'] != null &&
                      fine['scanLocation'].toString().isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fine['scanLocation'].toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fine['officer'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (fine['comment'] != null &&
                      fine['comment'].isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.comment_outlined,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fine['comment'],
                            style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (hasPayment) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.payment,
                            size: 14, color: Colors.green.shade300),
                        const SizedBox(width: 8),
                        Text(
                          'Paid on: ${_formatDateTime(fine['payment']['created_At'] ?? fine['payment']['createdAt'] ?? fine['payment']['paidTime'] ?? DateTime.now().toIso8601String())}',
                          style: TextStyle(
                              color: Colors.green.shade300,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child:
                        Container(height: 1, color: Colors.white.withAlpha(50)),
                  ),
                  const Text('OFFENSES',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  ...List.generate(fine['offenses'].length, (index) {
                    final offense = fine['offenses'][index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 14, color: Colors.orangeAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                if (offense['code'] != null &&
                                    offense['code'].isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade800
                                          .withAlpha(50),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      offense['code'],
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.blueGrey.shade300,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    offense['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (offense['points'] > 0)
                            Text(
                              '+${offense['points']} pts',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent.withAlpha(180),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOTAL AMOUNT',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0)),
                          const SizedBox(height: 2),
                          Text(
                            'Rs. ${fine['amount'].toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: (isPending && !isPendingDH)
                                  ? (isOverdue
                                      ? Colors.red.shade400
                                      : Colors.redAccent)
                                  : Colors.teal.shade300,
                            ),
                          ),
                          if (fine['points'] > 0)
                            Text(
                              '+${fine['points']} points',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.redAccent.withAlpha(180),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      if (isPending && !isSelected && !isPendingDH)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(35),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            elevation: 0,
                            side: BorderSide(
                                color: Colors.white.withAlpha(70), width: 1.0),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _showPaymentDialog([fine]);
                          },
                          child: const Text('PAY NOW',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                      if (hasPayment)
                        TextButton.icon(
                          onPressed: () => _showReceiptDialog(fine),
                          icon: const Icon(Icons.picture_as_pdf,
                              color: Colors.white70, size: 16),
                          label: const Text(
                            'Receipt',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulkPaymentBar() {
    final total =
        _selectedFines.isEmpty ? 0.0 : _calculateTotalSelectedAmount();
    final finesToPay =
        _pendingFines.where((f) => _selectedFines.contains(f['id'])).toList();

    return IgnorePointer(
      ignoring: _selectedFines.isEmpty,
      child: AnimatedSlide(
        offset: _selectedFines.isEmpty ? const Offset(0, 2.0) : Offset.zero,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: 25, left: 24, right: 24),
          height: 65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2980).withAlpha(150),
                  borderRadius: BorderRadius.circular(35),
                  border:
                      Border.all(color: Colors.white.withAlpha(60), width: 1.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${_selectedFines.length} Selected',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        Text('Rs. ${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha(50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side:
                                BorderSide(color: Colors.white.withAlpha(70))),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 0),
                        elevation: 0,
                        minimumSize: const Size(0, 36),
                      ),
                      onPressed: () => _showPaymentDialog(finesToPay),
                      child: const Text('PAY SELECTED',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 0.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointsHistoryTab() {
    final allFines = [..._pendingFines, ..._paidFines]..sort((a, b) =>
        DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

    if (allFines.isEmpty) {
      return const Center(
        child: Text(
          'No points history available.',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
        ),
      );
    }

    int totalPoints = 0;
    final List<Map<String, dynamic>> history = [];

    for (var fine in allFines) {
      final points = (fine['points'] as int?) ?? 0;
      totalPoints += points;
      history.add({
        'date': fine['date'],
        'points': points,
        'cumulative': totalPoints,
        'status': fine['status'],
        'id': fine['id'],
        'officer': fine['officer'],
      });
    }

    return RefreshIndicator(
      onRefresh: () async {
        widget.onLogActivity('Retried loading fines', Icons.refresh);
        await _fetchFines();
      },
      color: Colors.cyanAccent,
      backgroundColor: Colors.white.withAlpha(30),
      child: ListView.builder(
        cacheExtent: 500,
        padding: const EdgeInsets.only(
            top: kToolbarHeight + kTextTabBarHeight + 56,
            left: 16,
            right: 16,
            bottom: 100),
        itemCount: history.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final item = history[index];
          final isPending = item['status'] == 'PENDING';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(isPending ? 25 : 15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPending
                          ? Colors.white.withAlpha(50)
                          : Colors.white.withAlpha(30),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isPending
                              ? Colors.orangeAccent
                              : Colors.greenAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(item['date']),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                            Text(
                              '#${_formatId(item['id'])}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 10),
                            ),
                            Text(
                              item['officer'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item['status'],
                              style: TextStyle(
                                color: isPending
                                    ? Colors.orangeAccent
                                    : Colors.greenAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+${item['points']}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Total: ${item['cumulative']}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: const Color(0xFF0B0F19).withAlpha(120),
              flexibleSpace: ClipRect(
                  child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(color: Colors.transparent))),
              title: const Text('Traffic Fines',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.cyanAccent,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.cyanAccent,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'PENDING'),
                  Tab(text: 'PAID'),
                  Tab(text: 'POINTS'),
                ],
              ),
            ),
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.white, size: 50),
                            const SizedBox(height: 16),
                            Text(_errorMessage,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withAlpha(40)),
                                onPressed: () {
                                  widget.onLogActivity(
                                      'Retried loading fines', Icons.refresh);
                                  _fetchFines();
                                },
                                child: const Text('Retry',
                                    style: TextStyle(color: Colors.white))),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          TabBarView(
                            controller: _tabController,
                            children: [
                              _PendingFinesList(
                                pendingFines: _pendingFines,
                                onRefresh: _fetchFines,
                                buildCard: _buildFineCard,
                                onLogActivity: widget.onLogActivity,
                              ),
                              _PaidFinesList(
                                paidFines: _paidFines,
                                onRefresh: _fetchFines,
                                buildCard: _buildFineCard,
                                onLogActivity: widget.onLogActivity,
                              ),
                              _buildPointsHistoryTab(),
                            ],
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: _buildBulkPaymentBar(),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\s+'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write('   ');
      }
    }
    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return newValue;

    if (text.length == 1 && int.parse(text) > 1) {
      text = '0$text';
    }

    if (text.length >= 2) {
      int month = int.parse(text.substring(0, 2));
      if (month < 1 || month > 12) {
        return oldValue;
      }
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      } else if (i == 1 && text.length == 2) {
        buffer.write('/');
      }
    }

    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _PendingFinesList extends StatefulWidget {
  final List<Map<String, dynamic>> pendingFines;
  final Future<void> Function() onRefresh;
  final Widget Function(Map<String, dynamic>, bool) buildCard;
  final void Function(String, IconData) onLogActivity;

  const _PendingFinesList({
    required this.pendingFines,
    required this.onRefresh,
    required this.buildCard,
    required this.onLogActivity,
  });

  @override
  State<_PendingFinesList> createState() => _PendingFinesListState();
}

class _PendingFinesListState extends State<_PendingFinesList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.pendingFines.isEmpty) {
      return const Center(
        child: Text("No pending fines available.",
            style:
                TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
      );
    }
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: Colors.cyanAccent,
      backgroundColor: Colors.white.withAlpha(30),
      child: ListView.builder(
        cacheExtent: 500,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        padding: const EdgeInsets.only(
            top: kToolbarHeight + kTextTabBarHeight + 56,
            left: 16,
            right: 16,
            bottom: 100),
        itemCount: widget.pendingFines.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) => RepaintBoundary(
          child: widget.buildCard(widget.pendingFines[index], true),
        ),
      ),
    );
  }
}

class _PaidFinesList extends StatefulWidget {
  final List<Map<String, dynamic>> paidFines;
  final Future<void> Function() onRefresh;
  final Widget Function(Map<String, dynamic>, bool) buildCard;
  final void Function(String, IconData) onLogActivity;

  const _PaidFinesList({
    required this.paidFines,
    required this.onRefresh,
    required this.buildCard,
    required this.onLogActivity,
  });

  @override
  State<_PaidFinesList> createState() => _PaidFinesListState();
}

class _PaidFinesListState extends State<_PaidFinesList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.paidFines.isEmpty) {
      return const Center(
        child: Text("No paid fines history.",
            style:
                TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
      );
    }
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: Colors.cyanAccent,
      backgroundColor: Colors.white.withAlpha(30),
      child: ListView.builder(
        cacheExtent: 500,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        padding: const EdgeInsets.only(
            top: kToolbarHeight + kTextTabBarHeight + 56,
            left: 16,
            right: 16,
            bottom: 100),
        itemCount: widget.paidFines.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) => RepaintBoundary(
          child: widget.buildCard(widget.paidFines[index], false),
        ),
      ),
    );
  }
}
