import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer_model.dart';
import '../providers/customer_provider.dart';
import '../providers/ledger_provider.dart';
import '../services/speech_recognition_service.dart';
import '../services/text_to_speech_service.dart';

class VoiceRemoveCustomerSheet extends StatefulWidget {
  final Function(CustomerModel customer)? onCustomerDeleted;

  const VoiceRemoveCustomerSheet({Key? key, this.onCustomerDeleted}) : super(key: key);

  static Future<CustomerModel?> show(
    BuildContext context, {
    Function(CustomerModel customer)? onCustomerDeleted,
  }) {
    return showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceRemoveCustomerSheet(onCustomerDeleted: onCustomerDeleted),
    );
  }

  @override
  State<VoiceRemoveCustomerSheet> createState() => _VoiceRemoveCustomerSheetState();
}

class _VoiceRemoveCustomerSheetState extends State<VoiceRemoveCustomerSheet> {
  final ISpeechRecognitionProvider _speech = AndroidNativeSpeechProvider();
  final TextToSpeechService _tts = TextToSpeechService();

  bool _isListening = false;
  bool _isDeleting = false;
  String _transcript = '';
  CustomerModel? _selectedCustomer;
  List<CustomerModel> _matchedCustomers = [];
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tts.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startVoiceInput();
    });
  }

  @override
  void dispose() {
    _speech.stopListening();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startVoiceInput() async {
    setState(() {
      _isListening = true;
      _errorMessage = null;
      _transcript = '';
      _selectedCustomer = null;
      _matchedCustomers = [];
    });

    final ready = await _speech.initialize();
    if (!ready) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _errorMessage = 'మైక్రోఫోన్ అనుమతి లేదా స్పీచ్ సర్వీస్ అందుబాటులో లేదు.';
        });
      }
      return;
    }

    await _speech.startListening(
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() {
          _transcript = text;
          _searchController.text = _extractCustomerName(text);
          _findMatchingCustomers(_searchController.text);
          if (isFinal) {
            _isListening = false;
          }
        });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _errorMessage = 'వాయిస్ గుర్తుపట్టడంలో లోపం: $err';
        });
      },
    );
  }

  Future<void> _stopVoiceInput() async {
    await _speech.stopListening();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  String _extractCustomerName(String text) {
    if (text.trim().isEmpty) return '';

    String cleaned = text
        .replaceAll(RegExp(r'\b(remove|delete|chey|thesey|theesey|tesey|khata|account|customer|baki|appu)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'(తొలగించు|తొలగించండి|డిలీట్|తీసేయి|తీసెయ్|తీసేయండి|కస్టమర్‌ను|కస్టమర్ను|కస్టమర్|ఖాతాను|ఖాతా|అకౌంట్|చేయి|చేయండి|వద్దు)', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\b(ki|ku|gari|gariki|ni|nu)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'[^\w\s\u0C00-\u0C7F]'), ' ')
        .trim();

    // Strip trailing suffixes like "గారి", "కి", "కు", "ని", "ను"
    final words = cleaned.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
    if (words.isNotEmpty) {
      List<String> validWords = [];
      for (int i = 0; i < words.length; i++) {
        String w = words[i].trim();
        if (i == words.length - 1 &&
            (w.endsWith('కి') || w.endsWith('కు') || w.endsWith('ని') || w.endsWith('ను') || w.endsWith('గారి')) &&
            w.length > 3) {
          if (w.endsWith('గారి')) {
            w = w.substring(0, w.length - 4);
          } else {
            w = w.substring(0, w.length - 2);
          }
        }
        if (w.isNotEmpty) {
          if (RegExp(r'^[a-zA-Z]+$').hasMatch(w)) {
            w = w[0].toUpperCase() + w.substring(1).toLowerCase();
          }
          validWords.add(w);
        }
      }
      return validWords.join(' ');
    }
    return cleaned;
  }

  void _findMatchingCustomers(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      _matchedCustomers = [];
      _selectedCustomer = null;
      return;
    }

    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final all = customerProvider.customers;

    // First try exact or high-confidence match
    final matches = all.where((c) {
      final nameLower = c.name.toLowerCase();
      final phone = c.phoneNumber?.toLowerCase() ?? '';
      final aliases = c.aliases.map((a) => a.toLowerCase()).toList();

      if (nameLower == trimmed || aliases.contains(trimmed)) return true;
      if (nameLower.contains(trimmed) || trimmed.contains(nameLower)) return true;
      if (phone.isNotEmpty && phone.contains(trimmed)) return true;
      return aliases.any((a) => a.contains(trimmed) || trimmed.contains(a));
    }).toList();

    _matchedCustomers = matches;
    if (matches.length == 1) {
      _selectedCustomer = matches.first;
    } else {
      _selectedCustomer = null;
    }
  }

  Future<void> _confirmAndDelete(CustomerModel customer) async {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final ledgerProvider = Provider.of<LedgerProvider>(context, listen: false);
    final isDebtor = customer.outstandingBalancePaise > 0;
    final balanceRupees = (customer.outstandingBalancePaise / 100).toStringAsFixed(2);

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
              'మీరు నిజంగా "${customer.name}" గారి ఖాతాను శాశ్వతంగా తొలగించాలనుకుంటున్నారా?',
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

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await customerProvider.deleteCustomer(customer.id);
      await ledgerProvider.fetchTodaySummary();

      final teluguSpeech = "${customer.name} గారి ఖాతా విజయవంతంగా తొలగించబడింది.";
      await _tts.speakTelugu(teluguSpeech);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE11D48),
            content: Row(
              children: [
                const Icon(Icons.delete_sweep, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("'${customer.name}' ఖాతా విజయవంతంగా తొలగించబడింది!"),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        if (widget.onCustomerDeleted != null) {
          widget.onCustomerDeleted!(customer);
        }
        Navigator.pop(context, customer);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_remove, color: Color(0xFFE11D48), size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'కస్టమర్‌ను తొలగించండి (Remove Customer)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'మైక్ నొక్కి కస్టమర్ పేరు చెప్పండి (Say name to remove)',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Error banner
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE4E6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFE11D48), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFFBE123C)),
                    ),
                  ),
                ],
              ),
            ),

          // Live Voice / Search Feedback Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _isListening ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isListening ? const Color(0xFFFECDD3) : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  _isListening
                      ? 'వినబడుతోంది... ఎవరి ఖాతా తొలగించాలో చెప్పండి 🎙️'
                      : _transcript.isNotEmpty
                          ? 'మీరు చెప్పిన పేరు: "$_transcript"'
                          : 'మైక్ బటన్ నొక్కి కస్టమర్ పేరు చెప్పండి',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isListening
                        ? const Color(0xFFE11D48)
                        : _transcript.isNotEmpty
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Central Pulsing Mic Button
          GestureDetector(
            onTap: _isDeleting
                ? null
                : () {
                    if (_isListening) {
                      _stopVoiceInput();
                    } else {
                      _startVoiceInput();
                    }
                  },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isListening
                      ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                      : [const Color(0xFFE11D48), const Color(0xFFBE123C)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE11D48).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isListening ? 'ఆపడానికి నొక్కండి (Tap to stop)' : 'మళ్ళీ మాట్లాడటానికి నొక్కండి (Tap to speak)',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // Quick Filter/Search Text Field (fallback)
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'లేదా పేరు / ఫోన్ నంబర్ టైప్ చేయండి...',
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _transcript = '';
                          _selectedCustomer = null;
                          _matchedCustomers = [];
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _findMatchingCustomers(val);
              });
            },
          ),
          const SizedBox(height: 14),

          // MATCHED CUSTOMER CARD (Single Match)
          if (_selectedCustomer != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECDD3), width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFE11D48),
                        child: Text(
                          _selectedCustomer!.name.isNotEmpty ? _selectedCustomer!.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedCustomer!.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            if (_selectedCustomer!.phoneNumber != null && _selectedCustomer!.phoneNumber!.isNotEmpty)
                              Text(
                                'ఫోన్: ${_selectedCustomer!.phoneNumber}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                          ],
                        ),
                      ),
                      // Balance Pill
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _selectedCustomer!.outstandingBalancePaise > 0
                                ? '₹${(_selectedCustomer!.outstandingBalancePaise / 100).toStringAsFixed(2)}'
                                : 'బాకీ లేదు',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: _selectedCustomer!.outstandingBalancePaise > 0
                                  ? const Color(0xFFE11D48)
                                  : const Color(0xFF059669),
                            ),
                          ),
                          Text(
                            _selectedCustomer!.outstandingBalancePaise > 0 ? 'ప్రస్తుత బాకీ' : '₹0.00',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (_selectedCustomer!.outstandingBalancePaise > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ఈ ఖాతాలో ₹${(_selectedCustomer!.outstandingBalancePaise / 100).toStringAsFixed(2)} బాకీ ఉంది.',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                      ),
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.delete_forever, size: 20),
                      label: Text(
                        _isDeleting ? 'తొలగిస్తోంది...' : 'ఈ ఖాతాను పూర్తిగా తొలగించండి (Delete)',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isDeleting ? null : () => _confirmAndDelete(_selectedCustomer!),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_matchedCustomers.length > 1) ...[
            // MULTIPLE MATCHES (Disambiguation)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              alignment: Alignment.centerLeft,
              child: Text(
                '${_matchedCustomers.length} కస్టమర్లు సరిపోలారు. సరైన ఖాతాను ఎంచుకోండి:',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _matchedCustomers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final c = _matchedCustomers[idx];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFE2E8F0),
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      c.phoneNumber ?? (c.aliases.isNotEmpty ? c.aliases.join(', ') : 'No phone'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${(c.outstandingBalancePaise / 100).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: c.outstandingBalancePaise > 0 ? const Color(0xFFE11D48) : const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFE11D48), size: 20),
                          onPressed: () => _confirmAndDelete(c),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCustomer = c;
                      });
                    },
                  );
                },
              ),
            ),
          ] else if (_searchController.text.trim().isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "'${_searchController.text.trim()}' పేరుతో కస్టమర్ ఎవరూ కనపడలేదు.",
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
