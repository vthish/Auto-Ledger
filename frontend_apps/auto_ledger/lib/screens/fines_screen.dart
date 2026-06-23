import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  final List<Map<String, dynamic>> _hardcodedFines = const [
    {
      'id': 'a1b2c3d4-1234-5678-90ab-cdef12345678',
      'date': '2026-06-20T10:30:00Z',
      'amount': 3500.0,
      'offenses': ['Speeding (Above 20kmph)', 'No Seatbelt'],
      'status': 'PENDING',
      'officer': 'A. Perera (TRF-102)',
      'location': 'Galle Road, Colombo 03',
      'dueDate': '2026-07-04T10:30:00Z',
    },
    {
      'id': 'f8e7d6c5-4321-8765-ba09-87654321fedc',
      'date': '2026-06-18T14:15:00Z',
      'amount': 1000.0,
      'offenses': ['Illegal Parking'],
      'status': 'PENDING',
      'officer': 'K. Silva (TRF-045)',
      'location': 'Marine Drive',
      'dueDate': '2026-07-02T14:15:00Z',
    },
    {
      'id': '99aa88bb-77cc-66dd-55ee-44ff33ee22dd',
      'date': '2026-05-10T09:00:00Z',
      'amount': 2500.0,
      'offenses': ['Disobeying Traffic Light'],
      'status': 'PAID',
      'officer': 'M. Fernando (TRF-088)',
      'location': 'Bauddhaloka Mawatha',
      'dueDate': '2026-05-24T09:00:00Z',
    },
  ];

  late final List<Map<String, dynamic>> _pendingFines;
  late final List<Map<String, dynamic>> _paidFines;

  @override
  void initState() {
    super.initState();
    _pendingFines = _hardcodedFines.where((f) => f['status'] == 'PENDING').toList();
    _paidFines = _hardcodedFines.where((f) => f['status'] == 'PAID').toList();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
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
      widget.onSelectionModeChanged(!_selectedFines.isEmpty);
    }
  }

  double _calculateTotalSelectedAmount() {
    return _hardcodedFines
        .where((fine) => _selectedFines.contains(fine['id']))
        .fold(0, (sum, fine) => sum + fine['amount']);
  }

  void _showPaymentBottomSheet(List<Map<String, dynamic>> finesToPay) {
    final double totalAmount = finesToPay.fold(0, (sum, item) => sum + item['amount']);
    final bool isBulk = finesToPay.length > 1;

    widget.onLogActivity('Initiated ${isBulk ? 'Bulk ' : ''}Payment', Icons.payment);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              border: Border.all(color: Colors.white.withAlpha(60), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 40, offset: const Offset(0, -10))],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white.withAlpha(100), borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha(80), width: 1.0),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 20, offset: const Offset(0, 5))],
                    ),
                    padding: const EdgeInsets.all(16),
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
                                  false,
                                  inputFormatters: [LengthLimitingTextInputFormatter(5)],
                                )
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildPaymentTextField(
                                  'CVV',
                                  Icons.lock_outline_rounded,
                                  true,
                                  isObscure: true,
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
                            onTap: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              HapticFeedback.heavyImpact();
                              widget.onLogActivity('Successfully Paid Rs. ${totalAmount.toStringAsFixed(2)}', Icons.check_circle);

                              setState(() => _selectedFines.clear());
                              widget.onSelectionModeChanged(false);

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.green.shade800,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  content: const Text('Payment Successful!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              );
                            },
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
        );
      },
    );
  }

  Widget _buildPaymentTextField(String label, IconData icon, bool isNumber, {bool isObscure = false, List<TextInputFormatter>? inputFormatters}) {
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
        style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87, fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12),
          prefixIcon: Icon(icon, color: Colors.blue.shade800, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
                            _showPaymentBottomSheet([fine]);
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
    final finesToPay = _hardcodedFines.where((f) => _selectedFines.contains(f['id'])).toList();

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
                      onPressed: () => _showPaymentBottomSheet(finesToPay),
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
          body: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100),
                    itemCount: _pendingFines.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) => _buildFineCard(_pendingFines[index], true),
                  ),
                  ListView.builder(
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
        buffer.write(' ');
      }
    }
    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}