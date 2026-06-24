import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class FinesScreen extends StatefulWidget {
  final void Function(String, IconData) onLogActivity;
  final ValueChanged<bool> onSelectionModeChanged;

  const FinesScreen({
    super.key,
    required this.onLogActivity,
    required this.onSelectionModeChanged,
  });

  @override
  State<FinesScreen> createState() => _FinesScreenState();
}

class _FinesScreenState extends State<FinesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedFines = {};

  List<Map<String, dynamic>> _pendingFines = [];
  List<Map<String, dynamic>> _paidFines = [];

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchFines();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final tabName = _tabController.index == 0 ? 'Pending Fines' : 'Paid Fines';
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
        List<String> offenseNames = [];

        if (f['offenses'] != null) {
          for (var o in f['offenses']) {
            final category = o['offenceCategory'];
            if (category != null) {
              totalAmount += (category['amount'] ?? 0).toDouble();
              offenseNames.add(category['name'].toString());
            }
          }
        }

        final officer = f['trafficOfficer'];
        final officerName = officer != null
            ? '${officer['name']} (${officer['badge_No']})'
            : 'Unknown Officer';

        final mappedFine = {
          'id': f['fine_Id'],
          'date': f['issue_At'],
          'amount': totalAmount,
          'offenses': offenseNames.isNotEmpty ? offenseNames : ['Unknown Offense'],
          'status': f['status'],
          'officer': officerName,
          'location': 'Not Specified',
          'dueDate': f['due_Date'],
        };

        if (f['status'] == 'PAID') {
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
          _errorMessage = e.response?.data['message'] ?? 'Failed to load fines.';
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

  Future<void> _processPayment(List<Map<String, dynamic>> finesToPay, double totalAmount) async {
    FocusManager.instance.primaryFocus?.unfocus();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      if (finesToPay.length == 1) {
        await ApiService.dio.post('/fines/${finesToPay.first['id']}/pay', data: {'amount': totalAmount});
      } else {
        final ids = finesToPay.map((f) => f['id'].toString()).toList();
        await ApiService.dio.post('/fines/pay-bulk', data: {'fineIds': ids, 'totalAmount': totalAmount});
      }

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);

      HapticFeedback.heavyImpact();
      widget.onLogActivity('Successfully Paid Rs. ${totalAmount.toStringAsFixed(2)}', Icons.check_circle);

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
                    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withAlpha(40), Colors.white.withAlpha(15)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withAlpha(60), width: 1.0),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 40, offset: const Offset(0, 10))
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
                            border: Border.all(color: Colors.greenAccent.withAlpha(60), width: 1.5),
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.greenAccent, size: 40),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Payment Successful!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          Navigator.pop(context);
          _fetchFines();
        }
      });

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showGlassToast('Payment Failed! Please try again.', isError: true);
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
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: isError ? Colors.redAccent.withAlpha(50) : Colors.green.shade600.withAlpha(50),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(100), width: 1.0),
                ),
                child: Row(
                  children: [
                    Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
        widget.onLogActivity('Selected Fine ${_formatId(id)}', Icons.touch_app_rounded);
      } else {
        widget.onLogActivity('Deselected Fine ${_formatId(id)}', Icons.touch_app_rounded);
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
    final double totalAmount = finesToPay.fold(0, (sum, item) => sum + item['amount']);
    final bool isBulk = finesToPay.length > 1;

    widget.onLogActivity('Initiated ${isBulk ? 'Bulk ' : ''}Payment', Icons.payment);

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
                      colors: [Colors.white.withAlpha(40), Colors.white.withAlpha(15)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withAlpha(60), width: 1.0),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 40, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payment_rounded, size: 40, color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          isBulk ? 'Bulk Payment' : 'Pay Fine',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withAlpha(40), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isBulk ? 'Bulk Payment' : 'Pay Fine',
                                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isBulk ? '${finesToPay.length} Fines Selected' : 'ID: ${_formatId(finesToPay.first['id'])}',
                                        style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w600, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Rs. ${totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.redAccent),
                                  ),
                                ],
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  children: List.generate(
                                      30,
                                          (index) => Expanded(child: Container(height: 1.2, color: index % 2 == 0 ? Colors.white.withAlpha(40) : Colors.transparent))
                                  ),
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
                                      )
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: _buildPaymentTextField(
                                        'CVV',
                                        Icons.lock_outline_rounded,
                                        true,
                                        isObscure: isCvvObscured,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            isCvvObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
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
                                      )
                                  ),
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
                                style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: Colors.white.withAlpha(40),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withAlpha(60))),
                                ),
                                onPressed: () => _processPayment(finesToPay, totalAmount),
                                child: const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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

  Widget _buildPaymentTextField(String label, IconData icon, bool isNumber, {bool isObscure = false, List<TextInputFormatter>? inputFormatters, Widget? suffixIcon, double? fontSize}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(40), width: 1.0),
      ),
      child: TextField(
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        obscureText: isObscure,
        inputFormatters: inputFormatters,
        style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: fontSize ?? 15),
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w600, fontSize: 12),
          prefixIcon: Icon(icon, color: Colors.white70, size: 18),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildGlassBackground() {
    return RepaintBoundary(
      child: Stack(
        children: [
          Container(color: const Color(0xFF0B0F19)),
          Positioned(top: -50, left: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withAlpha(140), shape: BoxShape.circle))),
          Positioned(bottom: 50, right: -100, child: Container(width: 350, height: 350, decoration: BoxDecoration(color: Colors.teal.shade900.withAlpha(120), shape: BoxShape.circle))),
          Positioned(top: 250, right: 20, child: Container(width: 200, height: 200, decoration: BoxDecoration(color: Colors.purpleAccent.withAlpha(50), shape: BoxShape.circle))),
          Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75), child: Container(color: Colors.transparent))),
        ],
      ),
    );
  }

  Widget _buildFineCard(Map<String, dynamic> fine, bool isPending) {
    final isSelected = _selectedFines.contains(fine['id']);

    final gradientColors = isSelected
        ? [const Color(0xFF1A2980).withAlpha(45), const Color(0xFF1A2980).withAlpha(15)]
        : [Colors.white.withAlpha(20), Colors.white.withAlpha(6)];

    final borderColor = isSelected
        ? const Color(0xFF1A2980).withAlpha(150)
        : Colors.white.withAlpha(40);

    return GestureDetector(
      onTap: isPending ? () => _toggleSelection(fine['id']) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.0),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 25, offset: const Offset(0, 8))],
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
                          if (isPending) ...[
                            Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? Colors.white : Colors.white60, size: 22),
                            const SizedBox(width: 10),
                          ],
                          Text(_formatId(fine['id']), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16, letterSpacing: 1.0)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: isPending ? Colors.red.withAlpha(30) : Colors.green.withAlpha(30), borderRadius: BorderRadius.circular(12), border: Border.all(color: isPending ? Colors.red.withAlpha(80) : Colors.green.withAlpha(80))),
                        child: Text(fine['status'], style: TextStyle(color: isPending ? Colors.red.shade300 : Colors.green.shade300, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildIconTextRow(Icons.calendar_month_rounded, _formatDate(fine['date'])),
                  const SizedBox(height: 8),
                  _buildIconTextRow(Icons.location_on_rounded, fine['location']),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Container(height: 1, color: Colors.white.withAlpha(40)),
                  ),
                  const Text('OFFENSES', style: TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  ...List.generate(fine['offenses'].length, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orangeAccent),
                        const SizedBox(width: 8),
                        Text(fine['offenses'][index], style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOTAL AMOUNT', style: TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                          const SizedBox(height: 2),
                          Text('Rs. ${fine['amount'].toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isPending ? Colors.redAccent : Colors.teal.shade300)),
                        ],
                      ),
                      if (isPending && !isSelected)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(25),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            elevation: 0,
                            side: BorderSide(color: Colors.white.withAlpha(60), width: 1.0),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _showPaymentDialog([fine]);
                          },
                          child: const Text('PAY NOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
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

  Widget _buildIconTextRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white.withAlpha(15), shape: BoxShape.circle),
          child: Icon(icon, size: 14, color: Colors.white70),
        ),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Widget _buildBulkPaymentBar() {
    final total = _selectedFines.isEmpty ? 0.0 : _calculateTotalSelectedAmount();
    final finesToPay = _pendingFines.where((f) => _selectedFines.contains(f['id'])).toList();

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
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2980).withAlpha(150),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: Colors.white.withAlpha(60), width: 1.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${_selectedFines.length} Selected', style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('Rs. ${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha(40),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withAlpha(60))),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        elevation: 0,
                        minimumSize: const Size(0, 36),
                      ),
                      onPressed: () => _showPaymentDialog(finesToPay),
                      child: const Text('PAY SELECTED', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildGlassBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF0B0F19).withAlpha(120),
            flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), child: Container(color: Colors.transparent))),
            title: const Text('Traffic Fines', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.cyanAccent,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.cyanAccent,
              indicatorWeight: 3,
              tabs: const [Tab(text: 'PENDING'), Tab(text: 'PAID')],
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _errorMessage.isNotEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 50),
                const SizedBox(height: 16),
                Text(_errorMessage, style: const TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withAlpha(30)), onPressed: _fetchFines, child: const Text('Retry', style: TextStyle(color: Colors.white)))
              ],
            ),
          )
              : Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  _pendingFines.isEmpty
                      ? const Center(child: Text("No pending fines available.", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)))
                      : ListView.builder(
                    padding: const EdgeInsets.only(top: kToolbarHeight + kTextTabBarHeight + 40, left: 16, right: 16, bottom: 100),
                    itemCount: _pendingFines.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) => _buildFineCard(_pendingFines[index], true),
                  ),
                  _paidFines.isEmpty
                      ? const Center(child: Text("No paid fines history.", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)))
                      : ListView.builder(
                    padding: const EdgeInsets.only(top: kToolbarHeight + kTextTabBarHeight + 40, left: 16, right: 16, bottom: 100),
                    itemCount: _paidFines.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) => _buildFineCard(_paidFines[index], false),
                  ),
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
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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