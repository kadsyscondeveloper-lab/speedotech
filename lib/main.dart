// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_shell.dart';
import 'theme/app_theme.dart';
import 'views/auth/login_screen.dart';
import 'core/storage_service.dart';
import 'services/tech_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const SpeedonetTechApp());
}

class SpeedonetTechApp extends StatelessWidget {
  const SpeedonetTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                      'Speedonet Tech',
      debugShowCheckedModeBanner: false,
      theme:                      AppTheme.theme,
      home:                       const _AuthGate(),
    );
  }
}

// ── Auth gate — same pattern as customer app ──────────────────────────────────

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _storage = StorageService();
  final _auth    = TechAuthService();

  bool _isChecking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    if (_storage.hasToken) {
      final tech = await _auth.getMe();
      if (mounted) {
        setState(() {
          _isLoggedIn = tech != null;
          _isChecking = false;
        });
      }
    } else {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _onLoginSuccess() => setState(() => _isLoggedIn = true);
  void _onLogout()       => setState(() => _isLoggedIn = false);

  @override
  Widget build(BuildContext context) {
    // ── Splash ─────────────────────────────────────────────────────────────
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.engineering_rounded, color: Colors.white, size: 72),
              SizedBox(height: 20),
              Text(
                'SPEEDONET',
                style: TextStyle(
                  color:         Colors.white,
                  fontSize:      24,
                  fontWeight:    FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Technician Portal',
                style: TextStyle(
                  color:    Colors.white70,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                color:       Colors.white,
                strokeWidth: 2.5,
              ),
            ],
          ),
        ),
      );
    }

    // ── Main app or login ──────────────────────────────────────────────────
    return _isLoggedIn
        ? AppShell(onLogout: _onLogout)
        : LoginScreen(onLoginSuccess: _onLoginSuccess);
  }
}
