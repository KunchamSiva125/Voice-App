import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/customer_model.dart';
import '../services/api_service.dart';
import '../services/text_to_speech_service.dart';
import '../widgets/app_drawer.dart';

class NotebookMigrationScreen extends StatefulWidget {
  final String? initialCustomerId;
  const NotebookMigrationScreen({Key? key, this.initialCustomerId}) : super(key: key);

  @override
  State<NotebookMigrationScreen> createState() => _NotebookMigrationScreenState();
}

class _NotebookMigrationScreenState extends State<NotebookMigrationScreen> {
  final ApiService _apiService = ApiService();
  final TextToSpeechService _tts = TextToSpeechService();

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _pageController = TextEditingController();
  final _notesController = TextEditingController();

  List<CustomerModel> _customers = [];
  CustomerModel? _selectedCustomer;
  DateTime _debtDate = DateTime.now();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tts.initialize();
    _loadCustomers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _pageController.dispose();
    _notesController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.searchCustomers('');
      if (mounted) {
        setState(() {
          _customers = list;
          if (widget.initialCustomerId != null) {
            _selectedCustomer = list.firstWhere(
              (c) => c.id == widget.initialCustomerId,
              orElse: () => list.first,
            );
          }
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

  Future<void> _pickDebtDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _debtDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
      setState(() => _debtDate = picked);
    }
  }

  Future<void> _submitMigration() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      setState(() => _errorMessage = 'దయచేసి ఒక కస్టమర్‌ను ఎంచుకోండి');
      return;
    }

    final rupees = double.tryParse(_amountController.text.trim()) ?? 0;
    final amountPaise = (rupees * 100).round();

    if (amountPaise <= 0) {
      setState(() => _errorMessage = 'సరైన మొత్తాన్ని నమోదు చేయండి');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _successMessage = null;
      _errorMessage = null;
    });

    try {
      final openingDateIso = _debtDate.toIso8601String();
      final res = await _apiService.importOpeningBalance(
        customerId: _selectedCustomer!.id,
        amountPaise: amountPaise,
        notebookPageNumber: _pageController.text.trim().isNotEmpty ? _pageController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        openingDate: openingDateIso,
      );

      final speech = res['teluguSpeechMessage'] ??
          '${_selectedCustomer!.name} గారి పాత బాకీ ₹${rupees.toStringAsFixed(2)} విజయవంతంగా నమోదయింది.';

      _tts.speak(speech);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _successMessage = speech;
          _amountController.clear();
          _pageController.clear();
          _notesController.clear();
          _debtDate = DateTime.now();
        });
        _loadCustomers(); // refresh balances
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(currentItem: AppDrawerItem.notebookMigration),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'పుస్తకం బాకీల నమోదు',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Physical Notebook Balance Migration',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFFD97706),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD97706)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intro Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.menu_book_rounded, color: Color(0xFFD97706), size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'పాత బాకీల చిట్టా పుస్తకం బదిలీ',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'హోటల్ లోని పాత చిట్టా పుస్తకంలోని బాకీలను పేజీ నంబర్‌తో సహా డిజిటల్ లెడ్జర్‌లోకి నమోదు చేయండి.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309), height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_successMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: const TextStyle(color: Color(0xFF065F46), fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Color(0xFF9F1239), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Customer Selection
                    const Text(
                      'కస్టమర్‌ను ఎంచుకోండి (Select Customer) *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CustomerModel>(
                          value: _selectedCustomer,
                          isExpanded: true,
                          hint: const Text('ఖాతాదారుని పేరును ఎంచుకోండి...', style: TextStyle(fontSize: 13)),
                          items: _customers.map((c) {
                            return DropdownMenuItem<CustomerModel>(
                              value: c,
                              child: Text(
                                '${c.name} ${c.phoneNumber != null ? "(${c.phoneNumber})" : ""} • ప్రస్తుత బాకీ: ₹${c.balanceInRupees.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCustomer = val;
                              _errorMessage = null;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Amount Field
                    const Text(
                      'పుస్తకంలోని బాకీ మొత్తం (Amount in ₹) *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.currency_rupee, size: 20, color: Color(0xFFD97706)),
                        hintText: 'ఉదా: 350.00',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'మొత్తం తప్పనిసరిగా నమోదు చేయాలి';
                        final num = double.tryParse(val.trim());
                        if (num == null || num <= 0) return 'సరైన ధనాత్మక సంఖ్యను ఇవ్వండి';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Notebook Page Number
                    const Text(
                      'పుస్తకం పేజీ నంబర్ (Notebook Page / Reference)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _pageController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.book_rounded, size: 20, color: Color(0xFF64748B)),
                        hintText: 'ఉదా: పేజీ 14, లైన్ 3',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Date Picker
                    const Text(
                      'పాత అప్పు తేదీ (Original Debt Date)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDebtDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF64748B)),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('dd MMMM yyyy').format(_debtDate),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                            ),
                            const Spacer(),
                            const Text('మార్చండి >', style: TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notes
                    const Text(
                      'అదనపు వివరాలు / గమనికలు (Notes)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'ఉదా: కిరాణా సరుకులు & టిఫిన్ బాకీ',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        onPressed: _isSubmitting ? null : _submitMigration,
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'నమోదు చేయండి (Import Opening Balance)',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
