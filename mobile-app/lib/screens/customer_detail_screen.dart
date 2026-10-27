import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/customer_model.dart';
import '../providers/customer_provider.dart';
import '../providers/ledger_provider.dart';
import '../services/api_service.dart';
import '../services/text_to_speech_service.dart';
import '../widgets/tiffin_logo.dart';

class CustomerDetailScreen extends StatefulWidget {
  final CustomerModel customer;

  const CustomerDetailScreen({Key? key, required this.customer}) : super(key: key);

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final ApiService _apiService = ApiService();
  final TextToSpeechService _tts = TextToSpeechService();

  Map<String, dynamic>? _balanceData;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingTransactions = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _balanceData = {
      'customerId': widget.customer.id,
      'customerName': widget.customer.name,
      'phoneNumber': widget.customer.phoneNumber,
      'outstandingBalancePaise': widget.customer.outstandingBalancePaise,
      'balanceInRupees': widget.customer.balanceInRupees,
      'totalCreditsPaise': widget.customer.outstandingBalancePaise,
      'totalPaymentsPaise': 0,
      'totalDiscountsPaise': 0,
    };
    _loadData();
    _tts.initialize();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingTransactions = true;
      _errorMessage = null;
    });

    try {
      final balFuture = _apiService.getCustomerBalance(widget.customer.id);
      final txFuture = _apiService.getCustomerTransactions(widget.customer.id);

      final results = await Future.wait([balFuture, txFuture]);

      if (mounted) {
        setState(() {
          _balanceData = results[0] as Map<String, dynamic>;
          _transactions = results[1] as List<Map<String, dynamic>>;
          _isLoadingTransactions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _confirmDeleteCustomer() async {
    final balancePaise = _balanceData?['outstandingBalancePaise'] ?? widget.customer.outstandingBalancePaise;
    final isDebtor = balancePaise > 0;
    final balanceRupees = (balancePaise / 100).toStringAsFixed(2);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'కస్టమర్‌ను తొలగించాలా?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'మీరు నిజంగా "${widget.customer.name}" గారి ఖాతాను శాశ్వతంగా తొలగించాలనుకుంటున్నారా?',
              style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
            ),
            if (isDebtor) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFE11D48), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'హెచ్చరిక: ఈ కస్టమర్‌కి ఇంకా ₹$balanceRupees బాకీ ఉంది! ఖాతా తొలగిస్తే లావాదేవీల రికార్డులు కూడా శాశ్వతంగా తొలగించబడతాయి.',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF9F1239), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('రద్దు (Cancel)', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('శాశ్వతంగా తొలగించు (Delete)'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final ledgerProvider = Provider.of<LedgerProvider>(context, listen: false);

      await customerProvider.deleteCustomer(widget.customer.id);
      await ledgerProvider.fetchTodaySummary();

      await _tts.speakTelugu("${widget.customer.name} గారి ఖాతా విజయవంతంగా తొలగించబడింది.");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE11D48),
            content: Text("'${widget.customer.name}' ఖాతా విజయవంతంగా తొలగించబడింది!"),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('తొలగించడంలో లోపం: $e'),
          ),
        );
      }
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Date not recorded';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('dd-MMM-yyyy, hh:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  String _formatTxType(String? type) {
    switch (type) {
      case 'CREDIT':
        return 'అప్పు (Credit +)';
      case 'PAYMENT':
        return 'చెల్లింపు (Payment -)';
      case 'OPENING_BALANCE':
        return 'పాత పుస్తకం బాకీ (Notebook Debt)';
      case 'DISCOUNT':
        return 'రాయితీ (Discount)';
      case 'REVERSAL':
        return 'రద్దు చేసినది (Reversal)';
      default:
        return type ?? 'లావాదేవీ';
    }
  }

  Color _getTxColor(String? type) {
    switch (type) {
      case 'CREDIT':
        return const Color(0xFFE11D48); // Red
      case 'PAYMENT':
        return const Color(0xFF059669); // Green
      case 'OPENING_BALANCE':
        return const Color(0xFFD97706); // Amber
      case 'DISCOUNT':
        return const Color(0xFF2563EB); // Blue
      default:
        return const Color(0xFF475569);
    }
  }

  void _showEditCustomerDialog() {
    final nameController = TextEditingController(text: widget.customer.name);
    final phoneController = TextEditingController(text: widget.customer.phoneNumber ?? '');
    final aliasesController = TextEditingController(text: widget.customer.aliases.join(', '));
    final notesController = TextEditingController(text: widget.customer.notes ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
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
                const Text(
                  'కస్టమర్ వివరాల సవరణ (Edit Customer)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'కస్టమర్ పేరు (Name) *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'ఫోన్ నంబర్ (Phone Number)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: aliasesController,
                  decoration: const InputDecoration(
                    labelText: 'మారుపేర్లు (Aliases, comma separated)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'గమనికలు (Notes)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('పేరు తప్పనిసరి')),
                              );
                              return;
                            }
                            final aliasList = aliasesController.text
                                .split(',')
                                .map((a) => a.trim())
                                .where((a) => a.isNotEmpty)
                                .toList();

                            setSheetState(() => isSaving = true);
                            try {
                              await _apiService.updateCustomer(
                                widget.customer.id,
                                name: name,
                                phoneNumber: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                                aliases: aliasList,
                                notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                              );
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('కస్టమర్ వివరాలు నవీకరించబడ్డాయి!')),
                                );
                              }
                              _loadData();
                              Provider.of<CustomerProvider>(context, listen: false).searchCustomers('');
                            } catch (e) {
                              setSheetState(() => isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('నవీకరణ విఫలమైంది: ${e.toString().replaceAll('Exception: ', '')}')),
                                );
                              }
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('సేవ్ చేయండి (Save Changes)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanceRupees = _balanceData != null
        ? (_balanceData!['balanceInRupees'] as num).toDouble()
        : widget.customer.balanceInRupees;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.customer.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
            ),
            const Text(
              'కస్టమర్ వివరాలు & బాకీల రికార్డు (Customer Details & Proof)',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB)),
            tooltip: 'సవరించండి (Edit Details)',
            onPressed: _showEditCustomerDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE11D48)),
            tooltip: 'ఖాతాను తొలగించండి (Delete Customer)',
            onPressed: _confirmDeleteCustomer,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF475569)),
            tooltip: 'రీఫ్రెష్ (Refresh)',
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFE4E6)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFE11D48), fontSize: 13),
                        ),
                      ),
                    ],

                    // Current Balance Card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: balanceRupees > 0 ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: balanceRupees > 0 ? const Color(0xFFFFE4E6) : const Color(0xFFD1FAE5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                balanceRupees > 0 ? Icons.error_outline : Icons.check_circle_outline,
                                size: 18,
                                color: balanceRupees > 0 ? const Color(0xFFE11D48) : const Color(0xFF059669),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ప్రస్తుత మొత్తం బాకీ (Outstanding Debt)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: balanceRupees > 0 ? const Color(0xFFBE123C) : const Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${balanceRupees.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: balanceRupees > 0 ? const Color(0xFFE11D48) : const Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Voice Speaker Announcement Button
                          ElevatedButton.icon(
                            icon: const Icon(Icons.volume_up, size: 20),
                            label: const Text(
                              '🔊 బాకీ వినండి (Hear Debt Aloud via Speaker)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            onPressed: () {
                              if (_balanceData != null && _balanceData!['teluguSpeechMessage'] != null) {
                                _tts.speakTelugu(_balanceData!['teluguSpeechMessage']);
                              } else {
                                final rupees = balanceRupees.toInt();
                                _tts.speakTelugu("${widget.customer.name} గారి ఖాతా ఉంది. వారి ప్రస్తుత మొత్తం బాకీ $rupees రూపాయలు.");
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Customer Profile Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'కస్టమర్ సమాచారం (Profile)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 10),
                          _buildMetaRow('ఫోన్ నంబర్ (Phone):', widget.customer.phoneNumber ?? 'Not provided'),
                          const Divider(height: 16),
                          _buildMetaRow(
                            'మారుపేర్లు (Voice Aliases):',
                            widget.customer.aliases.isNotEmpty ? widget.customer.aliases.join(', ') : 'None',
                          ),
                          if (widget.customer.notes != null && widget.customer.notes!.isNotEmpty) ...[
                            const Divider(height: 16),
                            _buildMetaRow('గమనికలు (Notes):', widget.customer.notes!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Transactions & Debts Date for Proof Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long, color: Color(0xFFD97706), size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'బాకీల తేదీ & ఆధారాలు (Debts Date for Proof)',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_transactions.length} రికార్డులు',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Transactions List
                    if (_isLoadingTransactions && _transactions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(color: Color(0xFFD97706), strokeWidth: 2.5),
                        ),
                      )
                    else if (_transactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.history_toggle_off, size: 40, color: Color(0xFF94A3B8)),
                            SizedBox(height: 8),
                            Text('ఎటువంటి పాత లావాదేవీలు లేవు', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                            Text('కొత్త అప్పు లేదా పేమెంట్ నమోదు చేసినప్పుడు ఇక్కడ తేదీతో సహా కనిపిస్తాయి.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final tx = _transactions[idx];
                          final type = tx['type'] as String?;
                          final amountRupees = (tx['amountInRupees'] as num?)?.toDouble() ??
                              ((tx['amountPaise'] as num? ?? 0) / 100.0);
                          final color = _getTxColor(type);
                          final effectiveAt = tx['effectiveAt'] as String? ?? tx['createdAt'] as String?;
                          final description = tx['description'] as String?;
                          final createdBy = tx['createdBy'] as String? ?? 'Owner';
                          final isCredit = type == 'CREDIT' || type == 'OPENING_BALANCE';

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Transaction Type Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _formatTxType(type),
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    // Amount
                                    Text(
                                      '${isCredit ? '+' : '-'}₹${amountRupees.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Date for Proof (Exact timestamp)
                                Row(
                                  children: [
                                    const Icon(Icons.event, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'తేదీ (Proof Date): ${_formatDateTime(effectiveAt)}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                    ),
                                  ],
                                ),

                                if (description != null && description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.notes, size: 14, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          description,
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 6),
                                // Verification Tag
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Verified by: $createdBy',
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }
}
