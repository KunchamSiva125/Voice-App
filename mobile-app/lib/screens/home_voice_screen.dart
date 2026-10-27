import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/voice_command_provider.dart';
import '../widgets/voice_wave_visualizer.dart';
import '../widgets/quick_stat_card.dart';
import '../widgets/add_customer_dialog.dart';
import '../widgets/voice_add_customer_sheet.dart';
import '../widgets/voice_remove_customer_sheet.dart';
import '../services/text_to_speech_service.dart';
import 'customer_list_screen.dart';
import 'customer_detail_screen.dart';
import 'manual_entry_screen.dart';
import 'disambiguation_sheet.dart';
import 'login_screen.dart';
import '../widgets/tiffin_logo.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';

class HomeVoiceScreen extends StatefulWidget {
  const HomeVoiceScreen({Key? key}) : super(key: key);

  @override
  State<HomeVoiceScreen> createState() => _HomeVoiceScreenState();
}

class _HomeVoiceScreenState extends State<HomeVoiceScreen> with WidgetsBindingObserver {
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAll();
    });
    // Auto-sync every 20 seconds while app is in foreground so updates made by another owner show up automatically!
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _syncAll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When owner switches back to app or unlocks phone, immediately fetch latest updates from other devices
    if (state == AppLifecycleState.resumed) {
      _syncAll();
    }
  }

  Future<void> _syncAll() async {
    if (!mounted) return;
    try {
      await Future.wait([
        Provider.of<LedgerProvider>(context, listen: false).fetchTodaySummary(),
        Provider.of<CustomerProvider>(context, listen: false).searchCustomers(''),
      ]);
    } catch (_) {}
  }

  void _showOlderCustomerBalancePicker(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final voice = Provider.of<VoiceCommandProvider>(context, listen: false);
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final query = searchController.text.trim().toLowerCase();
          final filtered = customerProvider.customers.where((c) {
            if (query.isEmpty) return true;
            final nameMatch = c.name.toLowerCase().contains(query);
            final phoneMatch = c.phoneNumber?.contains(query) ?? false;
            final aliasMatch = c.aliases.any((a) => a.toLowerCase().contains(query));
            return nameMatch || phoneMatch || aliasMatch;
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Sheet Handle & Header
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.volume_up, color: Color(0xFFD97706), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'పాత కస్టమర్ల బాకీలు (Older Customers)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'స్పీకర్ బటన్ నొక్కి బాకీ వినండి (Tap speaker to hear balance aloud)',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'పేరు లేదా ఫోన్ ద్వారా వెతకండి...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                ),
                const SizedBox(height: 8),

                // Customer list with speaker buttons
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline, size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 12),
                              const Text('కస్టమర్లు కనపడలేదు', style: TextStyle(color: Color(0xFF64748B))),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.person_add, size: 16),
                                label: const Text('+ కొత్త కస్టమర్ నమోదు'),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  AddCustomerDialog.show(context);
                                },
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final c = filtered[idx];
                            final isDebtor = c.outstandingBalancePaise > 0;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: isDebtor ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
                                child: Text(
                                  c.name.isNotEmpty ? c.name.substring(0, 1).toUpperCase() : 'C',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDebtor ? const Color(0xFFE11D48) : const Color(0xFF059669),
                                  ),
                                ),
                              ),
                              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                c.phoneNumber ?? (c.aliases.isNotEmpty ? c.aliases.join(', ') : 'No phone'),
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
                                        '₹${c.balanceInRupees.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isDebtor ? const Color(0xFFE11D48) : const Color(0xFF059669),
                                        ),
                                      ),
                                      const Text('బాకీ', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  // Voice Speaker Button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.volume_up, color: Color(0xFFD97706)),
                                      tooltip: 'బాకీ వినండి (Speak Balance)',
                                      onPressed: () {
                                        voice.queryCustomerBalanceDirectly(c);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${c.name} గారి బాకీ స్పీకర్ ద్వారా చెప్పబడుతోంది...'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: c)),
                                );
                              },
                            );
                          },
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
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mahima Tiffin Centre',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: 0.2,
              ),
            ),
            Row(
              children: [
                const Text(
                  'మహిమ టిఫిన్ సెంటర్ • ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: ledger.isOnline ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  ledger.isOnline ? 'ఆన్‌లైన్' : 'ఆఫ్‌లైన్',
                  style: TextStyle(
                    fontSize: 10,
                    color: ledger.isOnline ? const Color(0xFF059669) : const Color(0xFFE11D48),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Add New Customer Action Button in Header
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Color(0xFFD97706)),
            tooltip: 'కొత్త కస్టమర్ (+ Add Customer)',
            onPressed: () => VoiceAddCustomerSheet.show(context),
          ),
          // Remove Customer Action Button in Header
          IconButton(
            icon: const Icon(Icons.person_remove, color: Color(0xFFE11D48)),
            tooltip: 'కస్టమర్‌ను తొలగించండి (Remove Customer)',
            onPressed: () => VoiceRemoveCustomerSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.sync, color: Color(0xFFD97706)),
            tooltip: 'తాజా వివరాలు రీఫ్రెష్ (Sync Latest)',
            onPressed: () {
              _syncAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('తాజా వివరాలు సింక్ చేయబడ్డాయి (Synced with cloud)!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.people_outline, color: Color(0xFF475569)),
            tooltip: 'కస్టమర్ల జాబితా (Customers List)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomerListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Color(0xFFF59E0B)),
            tooltip: 'అడ్మిన్ పోర్టల్ (Admin Portal)',
            onPressed: () async {
              final uri = Uri.parse(ApiConfig.adminPortalUrl);
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (_) {
                try {
                  await launchUrl(uri);
                } catch (e) {
                  debugPrint('Could not launch admin portal: $e');
                }
              }
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
      body: RefreshIndicator(
        color: const Color(0xFFD97706),
        onRefresh: _syncAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Everyday Total Debts Across All Customers (Changes Day to Day)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.account_balance, color: Color(0xFFF59E0B), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'హోటల్ మొత్తం బాకీ (Total Outstanding Debt)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF1F5F9),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ledger.dailyReport?.businessDate != null && ledger.dailyReport!.businessDate.isNotEmpty
                                ? '📅 ${ledger.dailyReport!.businessDate}'
                                : '📅 ఈ రోజు',
                            style: const TextStyle(fontSize: 11, color: Color(0xFFFCD34D), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${(ledger.dailyReport?.totalOutstandingDebtInRupees ?? 0.0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFCD34D),
                          ),
                        ),
                        Text(
                          'ఖాతాదారులు: ${ledger.dailyReport?.activeCustomersCount ?? 0} మంది',
                          style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ప్రతి ఒక్కరి పాత & కొత్త బాకీలతో కలిపి మొత్తం లెక్క (Daily Total Debts)',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),

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
              const SizedBox(height: 20),

              // Live Voice Status Banner with Speaker Button
              if (voice.lastServerConfirmedMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD1FAE5)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF059669), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          voice.lastServerConfirmedMessage!,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                        ),
                      ),
                      // Repeat Aloud Speaker Button
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Color(0xFF059669)),
                        tooltip: 'మళ్లీ వినండి (Hear Again via Speaker)',
                        onPressed: () => voice.repeatLastVoiceMessage(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                        tooltip: 'Dismiss',
                        onPressed: () => voice.clearMessages(),
                      ),
                    ],
                  ),
                ),

              // Voice Delete Customer Confirmation Card
              if (voice.needsDeleteConfirmation && voice.deleteCandidate != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFECDD3), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "'${voice.deleteCandidate!.name}' ఖాతాను తొలగించాలా?",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                            onPressed: () => voice.cancelDeleteCandidate(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        voice.deleteCandidate!.outstandingBalancePaise > 0
                            ? "హెచ్చరిక: ఈ కస్టమర్‌కి ఇంకా ₹${(voice.deleteCandidate!.outstandingBalancePaise / 100).toStringAsFixed(2)} బాకీ ఉంది! ఖాతా తొలగిస్తే లావాదేవీల రికార్డులు కూడా శాశ్వతంగా తొలగించబడతాయి."
                            : "ఈ కస్టమర్ ఖాతాను మరియు లావాదేవీలను శాశ్వతంగా తొలగించడానికి నిర్ధారించండి.",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: voice.deleteCandidate!.outstandingBalancePaise > 0
                              ? const Color(0xFF9F1239)
                              : const Color(0xFF475569),
                          fontWeight: voice.deleteCandidate!.outstandingBalancePaise > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => voice.cancelDeleteCandidate(),
                              child: const Text('రద్దు (Cancel)', style: TextStyle(color: Color(0xFF64748B))),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE11D48),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.delete_forever, size: 18),
                              label: const Text('ఖాతాను తొలగించు'),
                              onPressed: () async {
                                final name = voice.deleteCandidate!.name;
                                await voice.confirmDeleteCandidate();
                                if (context.mounted) {
                                  await Provider.of<LedgerProvider>(context, listen: false).fetchTodaySummary();
                                  await Provider.of<CustomerProvider>(context, listen: false).searchCustomers('');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFFE11D48),
                                      content: Text("'$name' ఖాతా విజయవంతంగా తొలగించబడింది!"),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Unmatched Customer or Error Banner with Instant Add Button
              if (voice.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFE4E6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFE11D48), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              voice.errorMessage!,
                              style: const TextStyle(fontSize: 13, color: Color(0xFFBE123C), fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up, color: Color(0xFFBE123C), size: 20),
                            tooltip: 'మళ్లీ వినండి',
                            onPressed: () => voice.repeatLastVoiceMessage(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                            tooltip: 'Dismiss',
                            onPressed: () => voice.clearMessages(),
                          ),
                        ],
                      ),
                      // If customer was recognized in voice but not found in DB, offer instant Add button
                      if (voice.unmatchedCustomerName != null) ...[
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 1,
                          ),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: Text(
                            "+ '${voice.unmatchedCustomerName}' ను కొత్త కస్టమర్‌గా చేర్చండి (+ Add Customer)",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            final name = voice.unmatchedCustomerName;
                            final debt = voice.unmatchedAmount;
                            if (name == null || name.isEmpty) return;
                            voice.clearMessages();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    ),
                                    const SizedBox(width: 10),
                                    Text("'$name' ఖాతా నమోదవుతోంది..."),
                                  ],
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );

                            try {
                              final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
                              final ledgerProvider = Provider.of<LedgerProvider>(context, listen: false);

                              final created = await customerProvider.createCustomer(
                                name: name,
                                aliases: [name],
                                initialDebtPaise: debt != null && debt > 0 ? (debt * 100).round() : 0,
                              );

                              await ledgerProvider.fetchTodaySummary();
                              await customerProvider.searchCustomers('');

                              final tts = TextToSpeechService();
                              await tts.initialize();
                              String speech = "${created.name} గారి ఖాతా విజయవంతంగా చేర్చబడింది.";
                              if (debt != null && debt > 0) {
                                speech += " ${debt.toInt()} రూపాయలు అప్పు నమోదైంది.";
                              }
                              await tts.speakTelugu(speech);

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
                                            debt != null && debt > 0
                                                ? "'${created.name}' ఖాతా చేర్చబడింది (అప్పు: ₹${debt.toInt()})!"
                                                : "'${created.name}' ఖాతా విజయవంతంగా చేర్చబడింది!",
                                          ),
                                        ),
                                      ],
                                    ),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFFE11D48),
                                    content: Text("కస్టమర్ నమోదు కాలేదు: $e"),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),

              // Center Microphone Voice Interaction Hub
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: voice.isListening ? const Color(0xFFD97706) : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Clear Examples for the Hotel Owner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('🔊 బాకీ ధృవీకరణ: "రమేష్ కి అకౌంట్ ఉందా?" లేదా "రమేష్ బాకీ ఎంత?"', style: TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text('💳 ఖాతా నుండి తీసేయి: "రమేష్ అకౌంట్ లో నుంచి 100 రూపాయలు తీసేయి"', style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text('➕ కొత్త అప్పు రాయి: "రమేష్ కి 100 రూపాయలు అప్పు రాయి"', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

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
                      const SizedBox(height: 16),
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
              const SizedBox(height: 20),

              // Action Buttons: "+ కొత్త కస్టమర్" & "కస్టమర్ వివరాలు (Customer Details)"
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1, size: 20),
                      label: const Text(
                        '+ కొత్త కస్టమర్',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      onPressed: () => VoiceAddCustomerSheet.show(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.receipt_long, size: 20),
                      label: const Text(
                        'కస్టమర్ వివరాలు',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CustomerListScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  // Older Customer Voice Speaker Balance Button
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.volume_up, color: Color(0xFF059669), size: 18),
                      label: const Text(
                        '🔊 పాత కస్టమర్ బాకీ',
                        style: TextStyle(color: Color(0xFF059669), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFF059669)),
                        backgroundColor: const Color(0xFFECFDF5),
                      ),
                      onPressed: () => _showOlderCustomerBalancePicker(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Manual Entry Button
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_note, color: Color(0xFF475569), size: 18),
                      label: const Text(
                        'మాన్యువల్ ఎంట్రీ',
                        style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                        backgroundColor: Colors.white,
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
              const SizedBox(height: 12),

              // Dedicated Remove Customer by Voice Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_remove_outlined, color: Color(0xFFE11D48), size: 20),
                  label: const Text(
                    '🗑️ కస్టమర్‌ను తొలగించండి (వాయిస్ / Remove Customer)',
                    style: TextStyle(
                      color: Color(0xFFE11D48),
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0xFFFDA4AF)),
                    backgroundColor: const Color(0xFFFFF1F2),
                  ),
                  onPressed: () => VoiceRemoveCustomerSheet.show(context),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
