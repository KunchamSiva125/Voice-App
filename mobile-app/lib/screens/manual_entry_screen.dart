import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer_model.dart';
import '../providers/customer_provider.dart';
import '../providers/ledger_provider.dart';
import '../services/api_service.dart';
import '../services/text_to_speech_service.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({Key? key}) : super(key: key);

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final ApiService _apiService = ApiService();
  final TextToSpeechService _tts = TextToSpeechService();

  String? _selectedCustomerId;
  String _transactionType = 'CREDIT'; // CREDIT or PAYMENT
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMsg;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_selectedCustomerId == null) {
      setState(() => _errorMsg = 'దయచేసి కస్టమర్‌ను ఎంచుకోండి (Select customer)');
      return;
    }

    final amountRupees = double.tryParse(_amountController.text.trim());
    if (amountRupees == null || amountRupees <= 0) {
      setState(() => _errorMsg = 'సరైన మొత్తాన్ని నమోదు చేయండి (Enter valid amount)');
      return;
    }

    final amountPaise = (amountRupees * 100).round();
    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
    });

    try {
      Map<String, dynamic> res;
      if (_transactionType == 'CREDIT') {
        res = await _apiService.recordCredit(
          _selectedCustomerId!,
          amountPaise,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : 'Manual Entry',
        );
      } else {
        res = await _apiService.recordPayment(
          _selectedCustomerId!,
          amountPaise,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : 'Manual Payment',
        );
      }

      if (mounted) {
        Provider.of<LedgerProvider>(context, listen: false).fetchTodaySummary();
        Provider.of<CustomerProvider>(context, listen: false).refresh();

        if (res['teluguSpeechMessage'] != null) {
          _tts.speakTelugu(res['teluguSpeechMessage']);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['teluguSpeechMessage'] ?? 'లావాదేవీ విజయవంతంగా నమోదైంది.'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMsg = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('మాన్యువల్ ఎంట్రీ (Manual Entry)'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFE4E6)),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(fontSize: 13, color: Color(0xFFE11D48)),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Customer Dropdown
              const Text(
                'కస్టమర్ (Customer) *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCustomerId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                hint: const Text('ఎంచుకోండి (Choose customer)'),
                items: customerProvider.customers.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.name} (బాకీ: ₹${c.balanceInRupees.toStringAsFixed(2)})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCustomerId = val),
              ),
              const SizedBox(height: 18),

              // Transaction Type Selector
              const Text(
                'లావాదేవీ రకం (Transaction Type) *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('అప్పు (Credit +)')),
                      selected: _transactionType == 'CREDIT',
                      selectedColor: const Color(0xFFFEF3C7),
                      onSelected: (val) => setState(() => _transactionType = 'CREDIT'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('చెల్లింపు (Payment -)')),
                      selected: _transactionType == 'PAYMENT',
                      selectedColor: const Color(0xFFD1FAE5),
                      onSelected: (val) => setState(() => _transactionType = 'PAYMENT'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Amount Field
              const Text(
                'మొత్తం రూపాయలు (Amount in INR) *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: '0.00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),

              // Description
              const Text(
                'వివరాలు (Description)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'e.g. 2 Idli, 1 Vada, Tea parcel',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _transactionType == 'CREDIT' ? const Color(0xFFD97706) : const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _transactionType == 'CREDIT' ? 'అప్పు నమోదు చేయి (Save Credit)' : 'చెల్లింపు నమోదు చేయి (Save Payment)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
