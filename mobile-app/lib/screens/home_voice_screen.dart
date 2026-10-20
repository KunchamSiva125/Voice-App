import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/voice_command_provider.dart';
import '../widgets/voice_wave_visualizer.dart';
import '../widgets/quick_stat_card.dart';
import 'customer_list_screen.dart';
import 'customer_detail_screen.dart';
import 'manual_entry_screen.dart';
import 'disambiguation_sheet.dart';
import 'login_screen.dart';

class HomeVoiceScreen extends StatefulWidget {
  const HomeVoiceScreen({Key? key}) : super(key: key);

  @override
  State<HomeVoiceScreen> createState() => _HomeVoiceScreenState();
}

class _HomeVoiceScreenState extends State<HomeVoiceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LedgerProvider>(context, listen: false).fetchTodaySummary();
      Provider.of<CustomerProvider>(context, listen: false).searchCustomers('');
    });
  }

  @override
  Widget build(BuildContext context) {
    final voice = Provider.of<VoiceCommandProvider>(context);
    final ledger = Provider.of<LedgerProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    // Check if disambiguation bottom sheet should be presented
    if (voice.needsDisambiguation && voice.ambiguousCustomers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DisambiguationSheet(
            customers: voice.ambiguousCustomers,
            onSelect: (customer) {
              Navigator.pop(context);
              voice.selectDisambiguatedCustomer(customer);
            },
            onCancel: () {
              Navigator.pop(context);
              voice.cancelDisambiguation();
            },
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'తెలుగు టిఫిన్ ఖాటా',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ledger.isOnline ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  ledger.isOnline ? 'ఆన్‌లైన్ (Server Connected)' : 'ఆఫ్‌లైన్ (No Internet)',
                  style: TextStyle(
                    fontSize: 11,
                    color: ledger.isOnline ? const Color(0xFF059669) : const Color(0xFFE11D48),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline, color: Color(0xFF475569)),
            tooltip: 'Customers List',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomerListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF94A3B8)),
            tooltip: 'Logout',
            onPressed: () async {
              await auth.logout();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Today's Quick Financial Stat Cards
            Row(
              children: [
                Expanded(
                  child: QuickStatCard(
                    title: 'Collections Today',
                    teluguTitle: 'ఈ రోజు వసూళ్లు',
                    amount: '₹${(ledger.dailyReport?.totalPaymentsInRupees ?? 0.0).toStringAsFixed(2)}',
                    color: const Color(0xFF059669),
                    icon: Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: QuickStatCard(
                    title: 'Credits Given Today',
                    teluguTitle: 'ఈ రోజు అప్పులు',
                    amount: '₹${(ledger.dailyReport?.totalCreditsInRupees ?? 0.0).toStringAsFixed(2)}',
                    color: const Color(0xFFD97706),
                    icon: Icons.arrow_upward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Live Voice Status Banner
            if (voice.lastServerConfirmedMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1FAE5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF059669)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        voice.lastServerConfirmedMessage!,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                      ),
                    ),
                  ],
                ),
              ),

            if (voice.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE4E6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFE11D48)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        voice.errorMessage!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFBE123C)),
                      ),
                    ),
                  ],
                ),
              ),

            // Center Microphone Voice Interaction Hub
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
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
                  Text(
                    voice.isListening
                        ? 'వినబడుతోంది... (Listening...)'
                        : voice.isProcessing
                            ? 'నమోదు అవుతోంది... (Processing...)'
                            : 'మాట్లాడటానికి మైక్ బటన్ నొక్కండి',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: voice.isListening ? const Color(0xFFD97706) : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ఉదాహరణ: "రమేష్ కి 100 రూపాయలు అప్పు రాయి"',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),

                  // Animated Voice Waves
                  VoiceWaveVisualizer(isListening: voice.isListening),

                  // Large Microphone Action Button
                  GestureDetector(
                    onTap: voice.isProcessing ? null : () => voice.toggleListening(),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: voice.isListening
                              ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                              : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (voice.isListening ? Colors.red : Colors.amber).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          voice.isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                  ),

                  if (voice.currentTranscript.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '"${voice.currentTranscript}"',
                        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Color(0xFF1E293B)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Manual Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_note, color: Color(0xFFD97706)),
                    label: const Text(
                      'మాన్యువల్ ఎంట్రీ (Manual Entry)',
                      style: TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManualEntryScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
