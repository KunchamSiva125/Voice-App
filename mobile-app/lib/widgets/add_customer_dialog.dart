import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer_model.dart';
import '../providers/customer_provider.dart';
import '../providers/ledger_provider.dart';
import '../services/text_to_speech_service.dart';

class AddCustomerDialog extends StatefulWidget {
  final String? prefilledName;
  final double? prefilledDebt;
  final Function(CustomerModel customer)? onCustomerCreated;

  const AddCustomerDialog({
    Key? key,
    this.prefilledName,
    this.prefilledDebt,
    this.onCustomerCreated,
  }) : super(key: key);

  static Future<CustomerModel?> show(
    BuildContext context, {
    String? prefilledName,
    double? prefilledDebt,
    Function(CustomerModel customer)? onCustomerCreated,
  }) {
    return showDialog<CustomerModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddCustomerDialog(
        prefilledName: prefilledName,
        prefilledDebt: prefilledDebt,
        onCustomerCreated: onCustomerCreated,
      ),
    );
  }

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aliasController = TextEditingController();
  final _balanceController = TextEditingController();
  final _notesController = TextEditingController();
  final TextToSpeechService _tts = TextToSpeechService();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledName != null && widget.prefilledName!.isNotEmpty) {
      _nameController.text = widget.prefilledName!;
      // Also prefill alias with the same name
      _aliasController.text = widget.prefilledName!;
    }
    if (widget.prefilledDebt != null && widget.prefilledDebt! > 0) {
      _balanceController.text = widget.prefilledDebt!.toStringAsFixed(0);
    }
    _tts.initialize();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _aliasController.dispose();
    _balanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'దయచేసి కస్టమర్ పేరు నమోదు చేయండి (Customer Name required)');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final List<String> aliases = _aliasController.text
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();

    // Make sure the primary name is also in aliases if not already
    if (!aliases.contains(name)) {
      aliases.add(name);
    }

    final double openingRupees = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    final int openingPaise = (openingRupees * 100).round();

    try {
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final created = await customerProvider.createCustomer(
        name: name,
        aliases: aliases,
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        initialDebtPaise: openingPaise,
      );

      // Refresh today's summary if initial debt was recorded
      if (openingPaise > 0 && mounted) {
        Provider.of<LedgerProvider>(context, listen: false).fetchTodaySummary();
      }

      if (mounted) {
        // Voice announcement
        _tts.speakTelugu("${created.name} గారి ఖాతా విజయవంతంగా చేర్చబడింది.");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('కస్టమర్ "${created.name}" విజయవంతంగా నమోదయ్యారు!')),
              ],
            ),
          ),
        );

        if (widget.onCustomerCreated != null) {
          widget.onCustomerCreated!(created);
        }

        Navigator.of(context).pop(created);
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_add_alt_1, color: Color(0xFFD97706), size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'కొత్త కస్టమర్ నమోదు',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Add New Customer to Ledger',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE4E6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFE11D48), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFBE123C), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Customer Name Field
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'కస్టమర్ పేరు (Customer Name) *',
                  hintText: 'e.g. Ramesh / రమేష్',
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFD97706)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD97706), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 12),

              // Phone Number Field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'ఫోన్ నంబర్ (Phone Number)',
                  hintText: 'e.g. 9848012345 (Optional)',
                  prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF64748B)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 12),

              // Spoken Nicknames / Aliases
              TextField(
                controller: _aliasController,
                decoration: InputDecoration(
                  labelText: 'మారుపేర్లు / వాయిస్ పేర్లు (Voice Aliases)',
                  hintText: 'e.g. రమేష్, Auto Ramesh, Master',
                  helperText: 'వాయిస్ గుర్తుపట్టడానికి కామాతో వేరు చేయండి',
                  helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  prefixIcon: const Icon(Icons.record_voice_over_outlined, color: Color(0xFF64748B)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 12),

              // Opening Debt Balance
              TextField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'ప్రారంభ బాకీ (Opening Debt ₹)',
                  hintText: '0.00',
                  helperText: 'పాత నోట్‌బుక్ లో ఉన్న బాకీ (ఉంటే)',
                  helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFFE11D48)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 12),

              // Notes
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'గుర్తులు / గమనికలు (Notes)',
                  hintText: 'e.g. Auto driver, morning parcel regular',
                  prefixIcon: const Icon(Icons.notes, color: Color(0xFF64748B)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('రద్దు (Cancel)', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD97706),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
          ),
          onPressed: _isSaving ? null : _handleSave,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check, size: 18),
          label: Text(
            _isSaving ? 'భద్రపరుస్తోంది...' : 'ఖాతా సృష్టించండి (Save Customer)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
