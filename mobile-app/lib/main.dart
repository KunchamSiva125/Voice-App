import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/ledger_provider.dart';
import 'providers/voice_command_provider.dart';
import 'screens/home_voice_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TiffinKhataApp());
}

class TiffinKhataApp extends StatelessWidget {
  const TiffinKhataApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => LedgerProvider()),
        ChangeNotifierProvider(create: (_) => VoiceCommandProvider()),
      ],
      child: MaterialApp(
        title: 'తెలుగు టిఫిన్ ఖాటా',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD97706),
            primary: const Color(0xFFD97706),
            secondary: const Color(0xFF059669),
            error: const Color(0xFFE11D48),
            background: const Color(0xFFF8FAFC),
          ),
          fontFamily: 'NotoSansTelugu',
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.isAuthenticated) {
      return const HomeVoiceScreen();
    } else {
      return const LoginScreen();
    }
  }
}
