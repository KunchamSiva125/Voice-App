import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_report_model.dart';
import '../models/outstanding_report_model.dart';
import '../models/customer_model.dart';
import '../services/api_service.dart';
import '../services/text_to_speech_service.dart';
import '../widgets/app_drawer.dart';
import 'customer_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiService _apiService = ApiService();
  final TextToSpeechService _tts = TextToSpeechService();

  DateTime _selectedDate = DateTime.now();
  DailyReportModel? _report;
  OutstandingReportModel? _outstanding;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tts.initialize();
    _loadReport();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final results = await Future.wait([
        _apiService.getDailyReport(date: dateStr),
        _apiService.getOutstandingReport(top: 15),
      ]);

      if (mounted) {
        setState(() {
          _report = results[0] as DailyReportModel;
          _outstanding = results[1] as OutstandingReportModel;
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
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
      setState(() => _selectedDate = picked);
      _loadReport();
    }
  }

  void _speakSummary() {
    if (_report?.teluguSummary != null && _report!.teluguSummary.isNotEmpty) {
      _tts.speak(_report!.teluguSummary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(currentItem: AppDrawerItem.reports),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'వ్యాపార నివేదికలు (Financial Reports)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Business Accounting & Debt Reconciliation',
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
            tooltip: 'రీఫ్రెష్',
            onPressed: _loadReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD97706)))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 40, color: Color(0xFFE11D48)),
                        const SizedBox(height: 8),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFE11D48))),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadReport, child: const Text('రీట్రై')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReport,
                  color: const Color(0xFFD97706),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Date Selector Header
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_note_rounded, color: Color(0xFFD97706), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('dd MMMM yyyy (EEEE)').format(_selectedDate),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    isToday ? 'ఈ రోజు నివేదిక (Today)' : 'చారిత్రక నివేదిక (Historical)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isToday ? const Color(0xFF059669) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFEF3C7),
                                foregroundColor: const Color(0xFFB45309),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                              label: const Text('తేదీ మార్చండి', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: _pickDate,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Telugu Voice Summary Bar
                      if (_report?.teluguSummary != null && _report!.teluguSummary.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.volume_up_rounded, color: Color(0xFFD97706), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _report!.teluguSummary,
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFD97706), size: 28),
                                onPressed: _speakSummary,
                                tooltip: 'వినండి (Speak)',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // 4 Primary Metric Cards for Selected Date
                      Row(
                        children: [
                          Expanded(
                            child: _buildReportMetricCard(
                              title: 'నగదు వసూలు',
                              sub: 'Collections on Date',
                              amount: currencyFormat.format(_report?.totalPaymentsInRupees ?? 0),
                              color: const Color(0xFF059669),
                              bgColor: const Color(0xFFECFDF5),
                              icon: Icons.arrow_downward_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildReportMetricCard(
                              title: 'కొత్త అప్పు',
                              sub: 'Credits on Date',
                              amount: currencyFormat.format(_report?.totalCreditsInRupees ?? 0),
                              color: const Color(0xFFE11D48),
                              bgColor: const Color(0xFFFFF1F2),
                              icon: Icons.arrow_upward_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildReportMetricCard(
                              title: 'రాయితీలు (Waivers)',
                              sub: 'Discounts on Date',
                              amount: currencyFormat.format(_report?.totalDiscountsInRupees ?? 0),
                              color: const Color(0xFF2563EB),
                              bgColor: const Color(0xFFEFF6FF),
                              icon: Icons.local_offer_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildReportMetricCard(
                              title: 'నికర మార్పు (Net)',
                              sub: 'Net Debt Change',
                              amount: currencyFormat.format(_report?.netChangeInRupees ?? 0),
                              color: const Color(0xFF0F172A),
                              bgColor: const Color(0xFFF1F5F9),
                              icon: Icons.swap_vert_rounded,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Outstanding Debt Overview Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'మొత్తం హోటల్ బాకీ (Total Outstanding)',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormat.format(_outstanding?.totalOutstandingDebtInRupees ?? 0),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${_outstanding?.totalDebtorsCount ?? 0}',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    'ఖాతాదారులు',
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Top Debtors Ranking
                      const Text(
                        'ఎక్కువ బాకీ ఉన్న ఖాతాదారుల జాబితా (Top Debtors Ranking)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 10),
                      if (_outstanding?.topDebtors == null || _outstanding!.topDebtors.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Center(
                            child: Text('బాకీలు ఏమీ లేవు.', style: TextStyle(color: Color(0xFF94A3B8))),
                          ),
                        )
                      else
                        ..._outstanding!.topDebtors.asMap().entries.map((entry) {
                          final rank = entry.key + 1;
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
                                radius: 16,
                                backgroundColor: rank <= 3 ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                                child: Text(
                                  '$rank',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: rank <= 3 ? const Color(0xFFE11D48) : const Color(0xFF64748B),
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
                              trailing: Text(
                                currencyFormat.format(debtor.balanceInRupees),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.5,
                                  color: Color(0xFFE11D48),
                                ),
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildReportMetricCard({
    required String title,
    required String sub,
    required String amount,
    required Color color,
    required Color bgColor,
    required IconData icon,
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
          Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
