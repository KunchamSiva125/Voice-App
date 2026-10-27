import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../services/text_to_speech_service.dart';
import '../widgets/voice_add_customer_sheet.dart';
import '../widgets/voice_remove_customer_sheet.dart';
import '../widgets/tiffin_logo.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  final String? initialSearch;
  const CustomerListScreen({Key? key, this.initialSearch}) : super(key: key);

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _searchController = TextEditingController();
  final TextToSpeechService _tts = TextToSpeechService();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearch ?? '';
    _tts.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false)
          .searchCustomers(widget.initialSearch ?? '');
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _tts.stop();
    super.dispose();
  }

  void _showAddCustomerDialog() {
    VoiceAddCustomerSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            TiffinLogo(size: 34, withGlow: false),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'కస్టమర్ వివరాలు (Customer Details)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Mahima Tiffin Centre / మహిమ టిఫిన్ సెంటర్',
                  style: TextStyle(fontSize: 10, color: Color(0xFFD97706), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_remove, color: Color(0xFFE11D48)),
            tooltip: 'కస్టమర్‌ను తొలగించండి (Remove Customer)',
            onPressed: () => VoiceRemoveCustomerSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFFD97706)),
            tooltip: 'కొత్త కస్టమర్ (New Customer)',
            onPressed: () => _showAddCustomerDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('కొత్త కస్టమర్ (Add Customer)', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddCustomerDialog(),
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, alias or phone / పేరు, ఫోన్ ద్వారా వెతకండి...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          customerProvider.searchCustomers('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (val) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  customerProvider.searchCustomers(val);
                });
              },
            ),
          ),

          // List View
          Expanded(
            child: (customerProvider.isLoading && customerProvider.customers.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : customerProvider.customers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.people_outline, size: 52, color: Color(0xFFD97706)),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'ఇంకా కస్టమర్లు లేరు (No Customers Yet)',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'క్రింది బటన్ నొక్కి కొత్త కస్టమర్‌ను నమోదు చేయండి లేదా వాయిస్ ద్వారా మాట్లాడండి.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.person_add),
                                label: const Text('+ కొత్త కస్టమర్‌ను చేర్చండి (+ Add Customer)'),
                                onPressed: () => _showAddCustomerDialog(),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: customerProvider.customers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final customer = customerProvider.customers[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFFEF3C7),
                                child: Text(
                                  customer.name.isNotEmpty ? customer.name.substring(0, 1).toUpperCase() : 'C',
                                  style: const TextStyle(
                                    color: Color(0xFFB45309),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                customer.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Text(
                                customer.phoneNumber ?? (customer.notes ?? 'No phone'),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${customer.balanceInRupees.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: customer.outstandingBalancePaise > 0
                                              ? const Color(0xFFE11D48)
                                              : const Color(0xFF059669),
                                        ),
                                      ),
                                      const Text(
                                        'మొత్తం బాకీ',
                                        style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.volume_up, color: Color(0xFFD97706)),
                                    tooltip: 'బాకీ వినండి (Speak Balance)',
                                    onPressed: () {
                                      final rupees = customer.balanceInRupees.toInt();
                                      _tts.speakTelugu("${customer.name} గారి ప్రస్తుత బాకీ $rupees రూపాయలు.");
                                    },
                                  ),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      side: const BorderSide(color: Color(0xFFD97706)),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CustomerDetailScreen(customer: customer),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'వివరాలు',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CustomerDetailScreen(customer: customer),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
