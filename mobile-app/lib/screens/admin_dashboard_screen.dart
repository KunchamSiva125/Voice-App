import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_report_model.dart';
import '../models/outstanding_report_model.dart';
import '../models/transaction_model.dart';
import '../models/customer_model.dart';
import '../services/api_service.dart';
import '../services/text_to_speech_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tiffin_logo.dart';
import '../widgets/voice_add_customer_sheet.dart';
import 'customer_detail_screen.dart';
import 'customer_list_screen.dart';
import 'transactions_screen.dart';
import 'notebook_migration_screen.dart';
import 'reports_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  final TextToSpeechService _tts = TextToSpeechService();

  DailyReportModel? _dailyReport;
  OutstandingReportModel? _outstandingReport;
  List<TransactionModel> _recentTransactions = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tts.initialize();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getDailyReport(),
        _apiService.getOutstandingReport(top: 5),
        _apiService.getTransactionsByRange(page: 0, size: 6),
      ]);

      if (mounted) {
        setState(() {
          _dailyReport = results[0] as DailyReportModel;
          _outstandingReport = results[1] as OutstandingReportModel;
          _recentTransactions = results[2] as List<TransactionModel>;
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

  void _speakSummary() {
    if (_dailyReport?.teluguSummary != null && _dailyReport!.teluguSummary.isNotEmpty) {
      _tts.speak(_dailyReport!.teluguSummary);
    } else {
      _tts.speak('ఈ రోజు లెక్కల వివరాలు ఇంకా అందుబాటులో లేవు.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(currentItem: AppDrawerItem.dashboard),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'అడ్మిన్ డ్యాష్‌బోర్డ్ (Dashboard)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Mahima Tiffin Centre • లెక్కల సారాంశం',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFFD97706),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: 'రీఫ్రెష్ (Refresh)',
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFD97706)),
                  SizedBox(height: 16),
                  Text(
                    'హోటల్ లెక్కల వివరాలు లోడ్ అవుతున్నాయి...',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Color(0xFFE11D48)),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFE11D48), fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadDashboardData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('మళ్ళీ ప్రయత్నించండి (Retry)'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  color: const Color(0xFFD97706),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Audio Voice Summary Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD97706),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ఈ రోజు లెక్కల సారాంశం (Daily Summary)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _dailyReport?.teluguSummary ?? 'వాయిస్ సారాంశం వినడానికి బటన్ నొక్కండి',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _speakSummary,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow, size: 16),
                                  SizedBox(width: 4),
                                  Text('వినండి', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Metrics Cards Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'మొత్తం బాకీ (Debt)',
                              subtitle: 'Total Outstanding',
                              amount: currencyFormat.format(_dailyReport?.totalOutstandingDebtInRupees ?? 0),
                              icon: Icons.currency_rupee,
                              color: const Color(0xFFE11D48),
                              bgColor: const Color(0xFFFFF1F2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'ఈ రోజు వసూలు',
                              subtitle: 'Collections Today',
                              amount: currencyFormat.format(_dailyReport?.totalPaymentsInRupees ?? 0),
                              icon: Icons.arrow_downward_rounded,
                              color: const Color(0xFF059669),
                              bgColor: const Color(0xFFECFDF5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'ఈ రోజు ఇచ్చిన అప్పు',
                              subtitle: 'Credits Today',
                              amount: currencyFormat.format(_dailyReport?.totalCreditsInRupees ?? 0),
                              icon: Icons.arrow_upward_rounded,
                              color: const Color(0xFFD97706),
                              bgColor: const Color(0xFFFFFBEB),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'ఖాతాదారులు',
                              subtitle: 'Active Customers',
                              amount: '${_dailyReport?.activeCustomersCount ?? 0}',
                              icon: Icons.people_alt_rounded,
                              color: const Color(0xFF2563EB),
                              bgColor: const Color(0xFFEFF6FF),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Quick Action Bar
                      const Text(
                        'త్వరిత చర్యలు (Quick Actions)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: Icons.menu_book_rounded,
                              label: 'పుస్తకం బాకీ',
                              subLabel: 'Notebook Import',
                              color: const Color(0xFF7C3AED),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NotebookMigrationScreen()),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: Icons.person_add_rounded,
                              label: 'కొత్త కస్టమర్',
                              subLabel: '+ Customer',
                              color: const Color(0xFFD97706),
                              onTap: () => VoiceAddCustomerSheet.show(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: Icons.receipt_long_rounded,
                              label: 'లావాదేవీలు',
                              subLabel: 'Ledger Txs',
                              color: const Color(0xFF059669),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: Icons.bar_chart_rounded,
                              label: 'నివేదికలు',
                              subLabel: 'Reports',
                              color: const Color(0xFF2563EB),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Top Debtors Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFE11D48)),
                              SizedBox(width: 6),
                              Text(
                                'ఎక్కువ బాకీ ఉన్నవారు (Top Debtors)',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CustomerListScreen()),
                              );
                            },
                            child: const Text('అందరినీ చూడండి >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (_outstandingReport?.topDebtors == null || _outstandingReport!.topDebtors.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Center(
                            child: Text(
                              'బాకీలు ఏమీ లేవు! (No outstanding debts)',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ..._outstandingReport!.topDebtors.asMap().entries.map((entry) {
                          final index = entry.key + 1;
                          final debtor = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: index <= 3 ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                                child: Text(
                                  '#$index',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: index <= 3 ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              title: Text(
                                debtor.customerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: debtor.phoneNumber != null
                                  ? Text(debtor.phoneNumber!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))
                                  : null,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormat.format(debtor.balanceInRupees),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: Color(0xFFE11D48),
                                    ),
                                  ),
                                  const Text(
                                    'బాకీ ఉంది',
                                    style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                              onTap: () {
                                final customer = CustomerModel(
                                  id: debtor.customerId,
                                  name: debtor.customerName,
                                  normalizedName: debtor.customerName.toLowerCase(),
                                  aliases: [],
                                  phoneNumber: debtor.phoneNumber,
                                  status: 'ACTIVE',
                                  outstandingBalancePaise: debtor.balancePaise,
                                  balanceInRupees: debtor.balanceInRupees,
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: customer)),
                                );
                              },
                            ),
                          );
                        }),

                      const SizedBox(height: 20),

                      // Recent Transactions Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ఇటీవలి లావాదేవీలు (Recent Activity)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                              );
                            },
                            child: const Text('పూర్తి చిట్టా >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (_recentTransactions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Center(
                            child: Text(
                              'ఈ రోజు లావాదేవీలు ఏమీ లేవు.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ..._recentTransactions.map((tx) => _buildTransactionCard(tx, currencyFormat)),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String subtitle,
    required String amount,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subLabel,
              style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx, NumberFormat currencyFormat) {
    final isCredit = tx.type == 'CREDIT' || tx.type == 'OPENING_BALANCE';
    final isPayment = tx.type == 'PAYMENT';
    final isDiscount = tx.type == 'DISCOUNT';
    final isReversal = tx.type == 'REVERSAL' || tx.status == 'REVERSED';

    Color typeColor = isPayment
        ? const Color(0xFF059669)
        : isDiscount
            ? const Color(0xFF2563EB)
            : isReversal
                ? const Color(0xFF7C3AED)
                : const Color(0xFFE11D48);

    String typeLabel = tx.type == 'CREDIT'
        ? 'అప్పు (Credit)'
        : tx.type == 'PAYMENT'
            ? 'చెల్లింపు (Payment)'
            : tx.type == 'DISCOUNT'
                ? 'రాయితీ (Discount)'
                : tx.type == 'OPENING_BALANCE'
                    ? 'పాత బాకీ (Opening)'
                    : 'రద్దు (Reversal)';

    String dateStr = tx.effectiveAt;
    try {
      final dt = DateTime.parse(tx.effectiveAt).toLocal();
      dateStr = DateFormat('dd MMM, hh:mm a').format(dt);
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPayment
                    ? Icons.call_received_rounded
                    : isCredit
                        ? Icons.call_made_rounded
                        : isDiscount
                            ? Icons.local_offer_rounded
                            : Icons.undo_rounded,
                color: typeColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(color: typeColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(dateStr, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? "+" : isPayment || isDiscount ? "-" : ""}${currencyFormat.format(tx.amountInRupees)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: isPayment ? const Color(0xFF059669) : const Color(0xFFE11D48),
                  ),
                ),
                if (tx.status == 'REVERSED')
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'రద్దయింది (REVERSED)',
                      style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
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
