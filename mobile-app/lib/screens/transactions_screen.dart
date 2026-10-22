import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final ApiService _apiService = ApiService();

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedType = 'ALL';
  String _searchQuery = '';

  List<TransactionModel> _allTransactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final startIso = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null;
      final endIso = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

      final data = await _apiService.getTransactionsByRange(
        startDate: startIso,
        endDate: endIso,
        page: 0,
        size: 100,
      );

      if (mounted) {
        setState(() {
          _allTransactions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 30)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD97706),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadTransactions();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadTransactions();
  }

  Future<void> _exportCsv() async {
    final startIso = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null;
    final endIso = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;
    final url = _apiService.getExportTransactionsUrl(startDate: startIso, endDate: endIso);

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open CSV download link')),
        );
      }
    }
  }

  void _showTransactionDetails(TransactionModel tx) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final isReversed = tx.status == 'REVERSED' || tx.type == 'REVERSAL';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tx.customerName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  currencyFormat.format(tx.amountInRupees),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: tx.type == 'PAYMENT' ? const Color(0xFF059669) : const Color(0xFFE11D48),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'లావాదేవీ రకం: ${tx.type}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
            const Divider(height: 24),
            _buildDetailRow('లావాదేవీ ఐడీ (ID)', tx.id),
            _buildDetailRow('సమయం (Date & Time)', tx.effectiveAt),
            _buildDetailRow('నమోదు చేసినవారు (Created By)', tx.createdBy),
            _buildDetailRow('స్టేటస్ (Status)', tx.status),
            if (tx.description != null && tx.description!.isNotEmpty)
              _buildDetailRow('వివరణ (Notes)', tx.description!),
            if (tx.correctionReason != null && tx.correctionReason!.isNotEmpty)
              _buildDetailRow('సరిదిద్దిన కారణం (Correction Reason)', tx.correctionReason!),
            const SizedBox(height: 20),
            if (!isReversed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF1F2),
                    foregroundColor: const Color(0xFFE11D48),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('తప్పు సరిదిద్దండి (Reverse Entry)', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _promptReversal(tx);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _promptReversal(TransactionModel tx) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48)),
            SizedBox(width: 8),
            Text('లావాదేవీ రద్దు (Reversal)', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'మీరు నిజంగా "${tx.customerName}" గారి ₹${tx.amountInRupees.toStringAsFixed(2)} లావాదేవీని రద్దు చేయాలనుకుంటున్నారా?',
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 12),
            const Text(
              'ఆడిట్ కారణం (Audit Justification Strictly Required) *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'ఉదా: తప్పు ఖాతాలో ₹100 అప్పు నమోదు చేశాము',
                hintStyle: TextStyle(fontSize: 12),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('రద్దు (Cancel)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('కారణం తప్పనిసరిగా నమోదు చేయాలి')),
                );
                return;
              }

              Navigator.pop(ctx);
              try {
                await _apiService.reverseTransaction(tx.id, reason);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('లావాదేవీ విజయవంతంగా రద్దయింది!')),
                  );
                }
                _loadTransactions();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('విఫలమైంది: ${e.toString().replaceAll('Exception: ', '')}')),
                  );
                }
              }
            },
            child: const Text('ఖరారు చేయండి (Confirm)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    final filteredTransactions = _allTransactions.where((t) {
      if (_selectedType != 'ALL' && t.type != _selectedType) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = t.customerName.toLowerCase().contains(query);
        final descMatch = t.description?.toLowerCase().contains(query) ?? false;
        return nameMatch || descMatch;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(currentItem: AppDrawerItem.transactions),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'లావాదేవీల చిట్టా (General Ledger)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'అన్ని హోటల్ లావాదేవీలు & చిట్టా',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFFD97706),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download_rounded, color: Color(0xFF059669)),
            tooltip: 'CSV ఎగుమతి (Export CSV)',
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: 'రీఫ్రెష్ (Refresh)',
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search Controls
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'కస్టమర్ పేరు లేదా వివరాలతో శోధించండి...',
                    hintStyle: const TextStyle(fontSize: 12.5),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Date Range and Filter Bar
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDateRange,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(8),
                            color: _startDate != null ? const Color(0xFFFEF3C7) : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 16,
                                color: _startDate != null ? const Color(0xFFD97706) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _startDate != null && _endDate != null
                                      ? '${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}'
                                      : 'తేదీ ఎంచుకోండి (Date Range)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: _startDate != null ? FontWeight.bold : FontWeight.normal,
                                    color: _startDate != null ? const Color(0xFF92400E) : const Color(0xFF475569),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_startDate != null)
                                GestureDetector(
                                  onTap: _clearDateFilter,
                                  child: const Icon(Icons.close, size: 16, color: Color(0xFF92400E)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Type dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedType,
                          isDense: true,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text('అన్నీ (All)')),
                            DropdownMenuItem(value: 'CREDIT', child: Text('అప్పు (Credit)')),
                            DropdownMenuItem(value: 'PAYMENT', child: Text('చెల్లింపు (Payment)')),
                            DropdownMenuItem(value: 'DISCOUNT', child: Text('రాయితీ (Discount)')),
                            DropdownMenuItem(value: 'OPENING_BALANCE', child: Text('పాత బాకీ (Opening)')),
                            DropdownMenuItem(value: 'REVERSAL', child: Text('రద్దు (Reversal)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedType = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Transactions Count Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF1F5F9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'మొత్తం లావాదేవీలు: ${filteredTransactions.length}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
                const Text(
                  'వివరాల కోసం తాకండి (Tap for info)',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD97706)))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 40, color: Color(0xFFE11D48)),
                              const SizedBox(height: 8),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFE11D48))),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _loadTransactions, child: const Text('రీట్రై')),
                            ],
                          ),
                        ),
                      )
                    : filteredTransactions.isEmpty
                        ? const Center(
                            child: Text(
                              'ఎలాంటి లావాదేవీలు కనుగొనబడలేదు.',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadTransactions,
                            color: const Color(0xFFD97706),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              itemCount: filteredTransactions.length,
                              itemBuilder: (context, index) {
                                final tx = filteredTransactions[index];
                                final isCredit = tx.type == 'CREDIT' || tx.type == 'OPENING_BALANCE';
                                final isPayment = tx.type == 'PAYMENT';
                                final isDiscount = tx.type == 'DISCOUNT';
                                final isReversal = tx.type == 'REVERSAL' || tx.status == 'REVERSED';

                                Color typeColor = isPayment
                                    ? const Color(0xFF059669)
                                    : isDiscount
                                        ? const Color(0xFF2563EB)
                                        : isReversal
                                            ? const Color(0xFF7C3AED)
                                            : const Color(0xFFE11D48);

                                String dateStr = tx.effectiveAt;
                                try {
                                  final dt = DateTime.parse(tx.effectiveAt).toLocal();
                                  dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
                                } catch (_) {}

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  child: InkWell(
                                    onTap: () => _showTransactionDetails(tx),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: typeColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              isPayment
                                                  ? Icons.call_received_rounded
                                                  : isCredit
                                                      ? Icons.call_made_rounded
                                                      : isDiscount
                                                          ? Icons.local_offer_rounded
                                                          : Icons.undo_rounded,
                                              color: typeColor,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tx.customerName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  dateStr,
                                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                                ),
                                                if (tx.description != null && tx.description!.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 2),
                                                    child: Text(
                                                      tx.description!,
                                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${isCredit ? "+" : isPayment || isDiscount ? "-" : ""}${currencyFormat.format(tx.amountInRupees)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 14,
                                                  color: isPayment ? const Color(0xFF059669) : const Color(0xFFE11D48),
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: typeColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  tx.type,
                                                  style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.bold),
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
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
