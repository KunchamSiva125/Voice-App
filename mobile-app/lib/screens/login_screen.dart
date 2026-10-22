import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/tiffin_logo.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import 'home_voice_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: '9014798120');
  final _passwordController = TextEditingController(text: '9014798120');

  void _fillAccount(String user, String pass) {
    setState(() {
      _usernameController.text = user;
      _passwordController.text = pass;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showServerSettingsDialog() {
    final controller = TextEditingController(text: ApiConfig.currentConfiguredUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.dns, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('సర్వర్ చిరునామా (Server URL)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ఫోన్‌లో ఎక్కడినుండైనా (4G/5G/Wi-Fi) వాడటానికి సర్వర్ URL నమోదు చేయండి:',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'e.g. https://xyz.ngrok-free.app or http://192.168.1.10:8080',
                labelText: 'Server Base URL',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '💡 చిట్కా: Cloud URL (ngrok/Cloudflare/Render) ఇస్తే ప్రపంచంలో ఎక్కడినుండైనా పనిచేస్తుంది.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ApiConfig.resetToDefault();
              if (mounted) setState(() {});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('డీఫాల్ట్ (Reset)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ApiConfig.setCustomBaseUrl(controller.text.trim());
                if (mounted) setState(() {});
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('సేవ్ చేయండి (Save)'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAdminPortal() async {
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
  }

  void _handleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeVoiceScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14, top: 4),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.admin_panel_settings, size: 18, color: Color(0xFFF59E0B)),
              label: const Text(
                'Admin Portal / అడ్మిన్',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFCD34D),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: const Color(0xFFFCD34D),
                side: const BorderSide(color: Color(0xFFF59E0B), width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 3,
              ),
              onPressed: _navigateToAdminPortal,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mahima Tiffin Centre Logo Emblem with Glow
                const TiffinLogo(size: 100, withGlow: true),
                const SizedBox(height: 18),

                const Text(
                  'Mahima Tiffin Centre',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFCD34D),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'మహిమ టిఫిన్ సెంటర్',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'బాకీల నిర్వహణ & వాయిస్ లెడ్జర్ (Voice Khata)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 32),

                // Login Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (auth.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFE4E6)),
                          ),
                          child: Text(
                            auth.errorMessage!,
                            style: const TextStyle(fontSize: 13, color: Color(0xFFE11D48)),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username / యూజర్‌నేమ్',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password / పాస్‌వర్డ్',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'ప్రవేశించండి (Log In)',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 10),
                      const Text(
                        'ఖాతా ఎంచుకోండి (Select Account):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            label: const Text('యజమాని 1 (Owner 1)', style: TextStyle(fontSize: 11)),
                            backgroundColor: const Color(0xFFFEF3C7),
                            onPressed: () => _fillAccount('9014798120', '9014798120'),
                          ),
                          ActionChip(
                            label: const Text('యజమాని 2 (Owner 2)', style: TextStyle(fontSize: 11)),
                            backgroundColor: const Color(0xFFFEF3C7),
                            onPressed: () => _fillAccount('9949795364', '9949795364'),
                          ),
                          ActionChip(
                            label: const Text('అడ్మిన్ (Admin)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            backgroundColor: const Color(0xFFE2E8F0),
                            onPressed: () => _fillAccount('siva', 'Siva@1250'),
                          ),
                          ActionChip(
                            label: const Text('మాస్టర్ ఓనర్ (owner@tiffin.local)', style: TextStyle(fontSize: 11)),
                            backgroundColor: const Color(0xFFEDE9FE),
                            onPressed: () => _fillAccount('owner@tiffin.local', 'Password123!'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Server Config Shortcut Button
                TextButton.icon(
                  icon: const Icon(Icons.settings_ethernet, size: 16, color: Color(0xFF94A3B8)),
                  label: Text(
                    'సర్వర్ సెట్టింగ్స్ (Server URL): ${ApiConfig.currentConfiguredUrl}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: _showServerSettingsDialog,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
