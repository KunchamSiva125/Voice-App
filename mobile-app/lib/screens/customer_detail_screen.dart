import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../services/api_service.dart';
import '../services/text_to_speech_service.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  void _loadBalance() async {
    try {
      final data = await _apiService.getCustomerBalance(widget.customer.id);
      setState(() {
        _balanceData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceRupees = _balanceData != null
        ? (_balanceData!['balanceInRupees'] as num).toDouble()
        : widget.customer.balanceInRupees;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.customer.name),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Balance Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: balanceRupees > 0 ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: balanceRupees > 0 ? const Color(0xFFFFE4E6) : const Color(0xFFD1FAE5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'మొత్తం బాకీ (Outstanding Debt)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: balanceRupees > 0 ? const Color(0xFFBE123C) : const Color(0xFF047857),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${balanceRupees.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: balanceRupees > 0 ? const Color(0xFFE11D48) : const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.volume_up, size: 18),
                          label: const Text('బాకీ వినండి (Speak Balance)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            if (_balanceData != null && _balanceData!['teluguSpeechMessage'] != null) {
                              _tts.speakTelugu(_balanceData!['teluguSpeechMessage']);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Customer Meta
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetaRow('ఫోన్ నంబర్ (Phone):', widget.customer.phoneNumber ?? 'Not provided'),
                        const Divider(height: 16),
                        _buildMetaRow('మారుపేర్లు (Aliases):', widget.customer.aliases.isNotEmpty ? widget.customer.aliases.join(', ') : 'None'),
                        if (widget.customer.notes != null) ...[
                          const Divider(height: 16),
                          _buildMetaRow('గమనికలు (Notes):', widget.customer.notes!),
                        ],
                      ],
                    ),
                  ),
                ],
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
