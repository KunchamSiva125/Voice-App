import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/home_voice_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/customer_list_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/corrections_screen.dart';
import '../screens/notebook_migration_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/user_management_screen.dart';
import '../screens/audit_logs_screen.dart';
import '../screens/exports_screen.dart';
import '../screens/login_screen.dart';
import 'tiffin_logo.dart';

enum AppDrawerItem {
  voiceCounter,
  dashboard,
  customers,
  transactions,
  corrections,
  notebookMigration,
  reports,
  userManagement,
  auditLogs,
  exports,
}

class AppDrawer extends StatelessWidget {
  final AppDrawerItem currentItem;

  const AppDrawer({Key? key, required this.currentItem}) : super(key: key);

  void _navigate(BuildContext context, Widget screen, AppDrawerItem targetItem) {
    Navigator.pop(context); // close drawer
    if (currentItem == targetItem) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final role = user?.role ?? 'FAMILY_MEMBER';
    final isOwnerOrAdmin = role == 'OWNER' || role == 'ADMIN';

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB45309), Color(0xFFD97706), Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const TiffinLogo(size: 46, withGlow: true),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'మహిమ టిఫిన్ సెంటర్',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            Text(
                              'Mahima Tiffin Centre',
                              style: TextStyle(
                                color: Color(0xFFFEF3C7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_circle, color: Colors.white, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '@${user?.username ?? ''}',
                                style: const TextStyle(
                                  color: Color(0xFFFEF3C7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: role == 'OWNER'
                                ? const Color(0xFF7C3AED)
                                : role == 'ADMIN'
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Menu List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.mic_rounded,
                    title: 'కౌంటర్ & వాయిస్',
                    subtitle: 'Voice & Quick Counter',
                    item: AppDrawerItem.voiceCounter,
                    onTap: () => _navigate(context, const HomeVoiceScreen(), AppDrawerItem.voiceCounter),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.dashboard_rounded,
                    title: 'అడ్మిన్ డ్యాష్‌బోర్డ్',
                    subtitle: 'Financial Dashboard & KPIs',
                    item: AppDrawerItem.dashboard,
                    onTap: () => _navigate(context, const AdminDashboardScreen(), AppDrawerItem.dashboard),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.people_alt_rounded,
                    title: 'ఖాతాదారులు',
                    subtitle: 'Customer Accounts & Ledgers',
                    item: AppDrawerItem.customers,
                    onTap: () => _navigate(context, const CustomerListScreen(), AppDrawerItem.customers),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.receipt_long_rounded,
                    title: 'లావాదేవీల చిట్టా',
                    subtitle: 'General Ledger Transactions',
                    item: AppDrawerItem.transactions,
                    onTap: () => _navigate(context, const TransactionsScreen(), AppDrawerItem.transactions),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.published_with_changes_rounded,
                    title: 'తప్పుల సరిదిద్దుట',
                    subtitle: 'Corrections & Reversals',
                    item: AppDrawerItem.corrections,
                    onTap: () => _navigate(context, const CorrectionsScreen(), AppDrawerItem.corrections),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.menu_book_rounded,
                    title: 'పుస్తకం బాకీల నమోదు',
                    subtitle: 'Notebook Balance Migration',
                    item: AppDrawerItem.notebookMigration,
                    onTap: () => _navigate(context, const NotebookMigrationScreen(), AppDrawerItem.notebookMigration),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.analytics_rounded,
                    title: 'వ్యాపార నివేదికలు',
                    subtitle: 'Daily & Outstanding Reports',
                    item: AppDrawerItem.reports,
                    onTap: () => _navigate(context, const ReportsScreen(), AppDrawerItem.reports),
                  ),

                  // Admin & Owner Only Section
                  if (isOwnerOrAdmin) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                      child: Row(
                        children: [
                          Text(
                            'అడ్మినిస్ట్రేషన్ (ADMINISTRATION)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                        ],
                      ),
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.manage_accounts_rounded,
                      title: 'కుటుంబ సభ్యులు & సిబ్బంది',
                      subtitle: 'User Management & Roles',
                      item: AppDrawerItem.userManagement,
                      onTap: () => _navigate(context, const UserManagementScreen(), AppDrawerItem.userManagement),
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.shield_rounded,
                      title: 'ఆడిట్ లాగ్',
                      subtitle: 'Immutable Audit Trail',
                      item: AppDrawerItem.auditLogs,
                      onTap: () => _navigate(context, const AuditLogsScreen(), AppDrawerItem.auditLogs),
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.cloud_download_rounded,
                      title: 'డేటా ఎగుమతులు & బ్యాకప్',
                      subtitle: 'CSV Exports & Database Backup',
                      item: AppDrawerItem.exports,
                      onTap: () => _navigate(context, const ExportsScreen(), AppDrawerItem.exports),
                    ),
                  ],
                ],
              ),
            ),

            // Footer Logout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  const Text(
                    'v1.0 • Android First',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE11D48),
                    ),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('లాగౌట్', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('లాగౌట్ అవ్వాలా?'),
                          content: const Text('మీరు నిజంగా లాగౌట్ అవ్వాలనుకుంటున్నారా?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('రద్దు (Cancel)'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE11D48),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('లాగౌట్ (Logout)'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required AppDrawerItem item,
    required VoidCallback onTap,
  }) {
    final isSelected = currentItem == item;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: isSelected ? const Color(0xFFFEF3C7) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? const Color(0xFFD97706) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? const Color(0xFFB45309) : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isSelected ? const Color(0xFFB45309) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD97706),
                      shape: BoxShape.circle,
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
