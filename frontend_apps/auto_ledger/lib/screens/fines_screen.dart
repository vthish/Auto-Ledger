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

    _fetchFines(); // Fetch from backend on load
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

        // Extract offenses and calculate total amount
        if (f['offenses'] != null) {
          for (var o in f['offenses']) {
            final category = o['offenceCategory'];
            if (category != null) {
              totalAmount += (category['amount'] ?? 0).toDouble();
              offenseNames.add(category['name'].toString());
            }
          }
        }

        // Format officer name
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
          'location': 'Not Specified', // Location is not stored in Fine model directly
          'dueDate': f['due_Date'],
        };

        // PENDING, OVERDUE, COURT_CASE goes to Pending tab. PAID goes to Paid tab.
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
    // Hide keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      if (finesToPay.length == 1) {
        // Single payment
        await ApiService.dio.post('/fines/${finesToPay.first['id']}/pay', data: {'amount': totalAmount});
      } else {
        // Bulk payment
        final ids = finesToPay.map((f) => f['id'].toString()).toList();
        await ApiService.dio.post('/fines/pay-bulk', data: {'fineIds': ids, 'totalAmount': totalAmount});
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Close payment bottom sheet/dialog

      HapticFeedback.heavyImpact();
      widget.onLogActivity('Successfully Paid Rs. ${totalAmount.toStringAsFixed(2)}', Icons.check_circle);

      setState(() => _selectedFines.clear());
      widget.onSelectionModeChanged(false);

      // Show Success Dialog
      showDialog(
        context: context,
        barrierColor: Colors.black.withAlpha(80),
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withAlpha(80), width: 1.5),
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
                              color: Colors.greenAccent.withAlpha(40),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.greenAccent.withAlpha(100), width: 2),
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
            ),
          );
        },
      );

      // Close success dialog after 2 seconds and refresh fines
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          Navigator.pop(context); // Close success dialog
          _fetchFines(); // Refresh lists
        }
      });

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          content: const Text('Payment Failed! Please try again.', style: TextStyle(color: Colors.white)),
        ),
      );
    }
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
      if (!_selectedFines.remove(id)) _selectedFines.add(id);
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
      barrierColor: Colors.black.withAlpha(150),
      builder: (BuildContext context) {
        bool isCvvObscured = true;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withAlpha(100), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 25, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.payment_rounded, size: 40, color: Colors.blue.shade900),
                        const SizedBox(height: 12),
                        Text(
                          isBulk ? 'Bulk Payment' : 'Pay Fine',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                        ),
                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(60),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withAlpha(120), width: 1),
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
                                        style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isBulk ? '${finesToPay.length} Fines Selected' : 'ID: ${_formatId(finesToPay.first['id'])}',
                                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Rs. ${totalAmount.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.red.shade900),
                                  ),
                                ],
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  children: List.generate(
                                      30,
                                          (index) => Expanded(child: Container(height: 1.2, color: index % 2 == 0 ? Colors.white.withAlpha(150) : Colors.transparent))
                                  ),
                                ),
                              ),

                              _buildPaymentTextField(
                                'Card Number',
                                Icons.credit_card_rounded,
                                true,
                                fontSize: 16,
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
                                            color: Colors.blue.shade800,
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
                              flex: 1,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(20),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withAlpha(80), width: 1.2),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _processPayment(finesToPay, totalAmount),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(50),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withAlpha(120), width: 1.2),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.verified_user_rounded, color: Colors.blue.shade900, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          'CONFIRM',
                                          style: TextStyle(color: Colors.blue.shade900, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
        color: Colors.white.withAlpha(70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(150), width: 1.0),
      ),
      child: TextField(
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        obscureText: isObscure,
        inputFormatters: inputFormatters,
        style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87, fontSize: fontSize ?? 15),
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12),
          prefixIcon: Icon(icon, color: Colors.blue.shade800, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildGlassBackground() {
    return RepaintBoundary(
      child: Stack(
        children: [
          Container(color: const Color(0xFFF0F4FF)),
          Positioned(top: -100, left: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(color: const Color(0xFF1A2980).withAlpha(100), shape: BoxShape.circle))),
          Positioned(bottom: 50, right: -100, child: Container(width: 350, height: 350, decoration: BoxDecoration(color: Colors.greenAccent.withAlpha(80), shape: BoxShape.circle))),
          Positioned(top: 250, right: 20, child: Container(width: 200, height: 200, decoration: BoxDecoration(color: Colors.purpleAccent.withAlpha(60), shape: BoxShape.circle))),
          Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent))),
        ],
      ),
    );
  }

  Widget _buildFineCard(Map<String, dynamic> fine, bool isPending) {
    final isSelected = _selectedFines.contains(fine['id']);

    final gradientColors = isSelected
        ? [const Color(0xFF1A2980).withAlpha(60), const Color(0xFF1A2980).withAlpha(20)]
        : isPending
        ? [Colors.white.withAlpha(160), Colors.white.withAlpha(80)]
        : [Colors.cyanAccent.withAlpha(40), Colors.blueAccent.withAlpha(20)];

    final borderColor = isSelected
        ? const Color(0xFF1A2980).withAlpha(180)
        : isPending
        ? Colors.white.withAlpha(255)
        : Colors.cyanAccent.withAlpha(100);

    return GestureDetector(
      onTap: isPending ? () => _toggleSelection(fine['id']) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.5),
                boxShadow: [if (isPending) BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 25, offset: const Offset(0, 10))],
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
                            Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? const Color(0xFF1A2980) : Colors.black38, size: 22),
                            const SizedBox(width: 10),
                          ],
                          Text(_formatId(fine['id']), style: TextStyle(fontWeight: FontWeight.w900, color: isPending ? const Color(0xFF1A2980) : Colors.blue.shade900, fontSize: 16, letterSpacing: 1.0)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: isPending ? Colors.red.withAlpha(30) : Colors.green.withAlpha(30), borderRadius: BorderRadius.circular(12), border: Border.all(color: isPending ? Colors.red.withAlpha(100) : Colors.green.withAlpha(100))),
                        child: Text(fine['status'], style: TextStyle(color: isPending ? Colors.red.shade900 : Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildIconTextRow(Icons.calendar_month_rounded, _formatDate(fine['date']), isPending),
                  const SizedBox(height: 8),
                  _buildIconTextRow(Icons.location_on_rounded, fine['location'], isPending),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Container(height: 1, color: isPending ? Colors.black.withAlpha(20) : Colors.blue.withAlpha(30)),
                  ),
                  Text('OFFENSES', style: TextStyle(fontSize: 10, color: isPending ? Colors.black54 : Colors.blue.shade800, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  ...List.generate(fine['offenses'].length, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: isPending ? Colors.orange : Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Text(fine['offenses'][index], style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 13)),
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
                          Text('TOTAL AMOUNT', style: TextStyle(fontSize: 10, color: isPending ? Colors.black54 : Colors.blue.shade800, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                          const SizedBox(height: 2),
                          Text('Rs. ${fine['amount'].toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isPending ? Colors.redAccent : Colors.teal.shade800)),
                        ],
                      ),
                      if (isPending && !isSelected)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(150),
                            foregroundColor: const Color(0xFF1A2980),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            elevation: 0,
                            side: BorderSide(color: const Color(0xFF1A2980).withAlpha(40), width: 1.5),
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

  Widget _buildIconTextRow(IconData icon, String text, bool isPending) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white.withAlpha(isPending ? 150 : 80), shape: BoxShape.circle),
          child: Icon(icon, size: 14, color: isPending ? const Color(0xFF1A2980) : Colors.blue.shade800),
        ),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
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
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2980).withAlpha(180),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: Colors.white.withAlpha(60), width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${_selectedFines.length} Selected', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('Rs. ${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha(220),
                        foregroundColor: const Color(0xFF1A2980),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF1A2980).withAlpha(180),
            flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: Container(color: Colors.transparent))),
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
                ElevatedButton(onPressed: _fetchFines, child: const Text('Retry'))
              ],
            ),
          )
              : Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  _pendingFines.isEmpty
                      ? const Center(child: Text("No pending fines available.", style: TextStyle(color: Colors.black87)))
                      : ListView.builder(
                    padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100),
                    itemCount: _pendingFines.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) => _buildFineCard(_pendingFines[index], true),
                  ),
                  _paidFines.isEmpty
                      ? const Center(child: Text("No paid fines history.", style: TextStyle(color: Colors.black87)))
                      : ListView.builder(
                    padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100),
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