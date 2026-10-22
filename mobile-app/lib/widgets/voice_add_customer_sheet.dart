import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer_model.dart';
import '../providers/customer_provider.dart';
import '../providers/ledger_provider.dart';
import '../services/speech_recognition_service.dart';
import '../services/text_to_speech_service.dart';
import '../services/telugu_voice_parser.dart';
import 'add_customer_dialog.dart';

class VoiceAddCustomerSheet extends StatefulWidget {
  final Function(CustomerModel customer)? onCustomerCreated;

  const VoiceAddCustomerSheet({Key? key, this.onCustomerCreated}) : super(key: key);

  static Future<CustomerModel?> show(
    BuildContext context, {
    Function(CustomerModel customer)? onCustomerCreated,
  }) {
    return showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceAddCustomerSheet(onCustomerCreated: onCustomerCreated),
    );
  }

  @override
  State<VoiceAddCustomerSheet> createState() => _VoiceAddCustomerSheetState();
}

class _VoiceAddCustomerSheetState extends State<VoiceAddCustomerSheet> {
  final ISpeechRecognitionProvider _speech = AndroidNativeSpeechProvider();
  final TextToSpeechService _tts = TextToSpeechService();

  bool _isListening = false;
  bool _isSaving = false;
  bool _isEditingName = false;
  final TextEditingController _nameEditController = TextEditingController();
  String _transcript = '';
  String? _recognizedName;
  double? _recognizedDebt;
  String? _errorMessage;

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
    _nameEditController.dispose();
    super.dispose();
  }

  Future<void> _startVoiceInput() async {
    setState(() {
      _isListening = true;
      _errorMessage = null;
      _transcript = '';
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
          _parseSpokenNameAndDebt(text);
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

  void _parseSpokenNameAndDebt(String text) {
    if (text.trim().isEmpty) return;

    // Check for number (debt) - first try digits, then number words (e.g. "వంద", "hundred", "యాభై", "fifty")
    final numMatch = RegExp(r'\b(\d+)\b').firstMatch(text);
    if (numMatch != null) {
      _recognizedDebt = double.tryParse(numMatch.group(1)!);
    } else {
      for (final entry in TeluguVoiceParser.teluguNumbers.entries) {
        final pattern = RegExp('(^|[\\s.,!?:;])' + RegExp.escape(entry.key) + r'($|[\s.,!?:;])', caseSensitive: false);
        if (pattern.hasMatch(text)) {
          _recognizedDebt = entry.value.toDouble();
          break;
        }
      }
    }

    // Clean name - strip all recognized number words first so they never leak into the name
    String cleaned = text;
    for (final entry in TeluguVoiceParser.teluguNumbers.entries) {
      final pattern = RegExp('(^|[\\s.,!?:;])' + RegExp.escape(entry.key) + r'($|[\s.,!?:;])', caseSensitive: false);
      cleaned = cleaned.replaceAll(pattern, ' ');
    }

    cleaned = cleaned
        .replaceAll(RegExp(r'\b(kotha|kottha|new|add|customer|khata|account|rupayalu|rupees|rs|appu|baki)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'(కొత్త|కస్టమర్‌గా|కస్టమర్గా|కస్టమర్|ఖాతా|అకౌంట్|రూపాయలు|రూపాయల|అప్పు|బాకీ|పేరు|చేర్చు|చేర్చండి|తెరవండి|తెరువు)', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\b\d+\b'), ' ')
        .replaceAll(RegExp(r'[^\w\s\u0C00-\u0C7F]'), ' ')
        .trim();

    // Strip trailing postpositions
    cleaned = cleaned.replaceAll(RegExp(r'\b(ki|ku|gari|gariki|ni|nu)\b', caseSensitive: false), '').trim();

    final words = cleaned.split(RegExp(r'\s+')).where((w) => w.trim().length >= 2).toList();
    if (words.isNotEmpty) {
      List<String> validWords = [];
      for (int i = 0; i < words.length; i++) {
        String w = words[i].trim();
        // Strip trailing suffixes like "కి", "కు", "ని", "ను" attached without space on the last word
        if (i == words.length - 1 &&
            (w.endsWith('కి') || w.endsWith('కు') || w.endsWith('ని') || w.endsWith('ను')) &&
            w.length > 3) {
          w = w.substring(0, w.length - 2);
        }
        if (w.isNotEmpty) {
          // Capitalize if Latin
          if (RegExp(r'^[a-zA-Z]+$').hasMatch(w)) {
            w = w[0].toUpperCase() + w.substring(1).toLowerCase();
          }
          validWords.add(w);
        }
      }
      if (validWords.isNotEmpty) {
        _recognizedName = validWords.join(' ');
        _nameEditController.text = _recognizedName!;
      }
    }
  }

  Future<void> _handleSave() async {
    final name = _nameEditController.text.trim().isNotEmpty
        ? _nameEditController.text.trim()
        : _recognizedName;
    if (name == null || name.trim().isEmpty) {
      setState(() => _errorMessage = 'దయచేసి మైక్ నొక్కి కస్టమర్ పేరు చెప్పండి');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final ledgerProvider = Provider.of<LedgerProvider>(context, listen: false);

      final debtPaise = _recognizedDebt != null && _recognizedDebt! > 0
          ? (_recognizedDebt! * 100).round()
          : 0;

      final created = await customerProvider.createCustomer(
        name: name.trim(),
        aliases: [name.trim()],
        initialDebtPaise: debtPaise,
      );

      await ledgerProvider.fetchTodaySummary();
      await customerProvider.searchCustomers('');

      String speech = "${created.name} గారి ఖాతా విజయవంతంగా చేర్చబడింది.";
      if (_recognizedDebt != null && _recognizedDebt! > 0) {
        speech += " ${_recognizedDebt!.toInt()} రూపాయలు అప్పు నమోదైంది.";
      }
      await _tts.speakTelugu(speech);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _recognizedDebt != null && _recognizedDebt! > 0
                        ? "'${created.name}' ఖాతా చేర్చబడింది (అప్పు: ₹${_recognizedDebt!.toInt()})!"
                        : "'${created.name}' ఖాతా విజయవంతంగా చేర్చబడింది!",
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        if (widget.onCustomerCreated != null) {
          widget.onCustomerCreated!(created);
        }
        Navigator.pop(context, created);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
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
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.mic, color: Color(0xFFD97706), size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'వాయిస్ ద్వారా కొత్త ఖాతా',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'పేరు చెప్పండి - టైపింగ్ అవసరం లేదు! (Say name to save)',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
          const SizedBox(height: 20),

          // Error banner
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                      style: const TextStyle(fontSize: 13, color: Color(0xFFBE123C)),
                    ),
                  ),
                ],
              ),
            ),

          // Recognized Name Display Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _recognizedName != null ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _recognizedName != null ? const Color(0xFFBBF7D0) : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  _isListening
                      ? 'వినబడుతోంది... కస్టమర్ పేరు చెప్పండి 🎙️'
                      : _recognizedName != null
                          ? 'గుర్తించిన కస్టమర్ పేరు (Recognized Name):'
                          : 'మైక్ బటన్ నొక్కి కస్టమర్ పేరు చెప్పండి',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isListening
                        ? const Color(0xFFD97706)
                        : _recognizedName != null
                            ? const Color(0xFF15803D)
                            : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                if (_isEditingName) ...[
                  TextField(
                    controller: _nameEditController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'కస్టమర్ పూర్తి పేరు (Full Name)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check, color: Color(0xFF15803D)),
                        onPressed: () {
                          setState(() {
                            _recognizedName = _nameEditController.text.trim();
                            _isEditingName = false;
                          });
                        },
                      ),
                    ),
                    onSubmitted: (val) {
                      setState(() {
                        _recognizedName = val.trim();
                        _isEditingName = false;
                      });
                    },
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _recognizedName ?? (_isListening ? '...' : '(పేరు చెప్పలేదు)'),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: _recognizedName != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (_recognizedName != null) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF059669)),
                          tooltip: 'పేరు సవరించండి (Edit Name)',
                          onPressed: () {
                            setState(() {
                              _nameEditController.text = _recognizedName!;
                              _isEditingName = true;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ],
                if (_recognizedDebt != null && _recognizedDebt! > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ప్రారంభ అప్పు: ₹${_recognizedDebt!.toInt()}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
                if (_transcript.isNotEmpty && _transcript != _recognizedName) ...[
                  const SizedBox(height: 10),
                  Text(
                    '"$_transcript"',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Central Pulsing Mic Button
          GestureDetector(
            onTap: _isSaving
                ? null
                : () {
                    if (_isListening) {
                      _stopVoiceInput();
                    } else {
                      _startVoiceInput();
                    }
                  },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isListening
                      ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                      : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.red : Colors.amber).withOpacity(0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isListening ? 'ఆపడానికి నొక్కండి (Tap to stop)' : 'మళ్ళీ మాట్లాడటానికి నొక్కండి (Tap to speak)',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),

          // Direct Action Button: Save Customer
          if (_recognizedName != null && _recognizedName!.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle, size: 22),
                label: Text(
                  _isSaving
                      ? 'నమోదు అవుతోంది...'
                      : "ఖాతా చేర్చండి (+ Save '${_nameEditController.text.trim().isNotEmpty ? _nameEditController.text.trim() : _recognizedName}')",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _isSaving ? null : _handleSave,
              ),
            ),

          const SizedBox(height: 14),

          // Optional Manual fallback link
          TextButton.icon(
            icon: const Icon(Icons.keyboard_outlined, size: 16, color: Color(0xFF64748B)),
            label: const Text(
              'లేదా కీబోర్డ్ ద్వారా నమోదు చేయండి (Manual Text Entry)',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), decoration: TextDecoration.underline),
            ),
            onPressed: () {
              Navigator.pop(context);
              AddCustomerDialog.show(
                context,
                prefilledName: _recognizedName,
                prefilledDebt: _recognizedDebt,
                onCustomerCreated: widget.onCustomerCreated,
              );
            },
          ),
        ],
      ),
    );
  }
}
