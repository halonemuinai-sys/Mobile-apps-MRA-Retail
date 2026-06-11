import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/advisor.dart';
import 'screens/login/login_screen.dart';
import 'screens/trial/trial_expired_screen.dart';
import 'services/auth_service.dart';
import 'services/trial_service.dart';
import 'services/device_log_service.dart';
import 'supabase_config.dart';
import 'theme.dart';
import 'main.dart' show MainShell;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const TrialAdvisorApp());
  // Jalankan setelah runApp agar tidak block UI — error disimpan ke SharedPreferences
  DeviceLogService.logIfFirstInstall();
}

class TrialAdvisorApp extends StatelessWidget {
  const TrialAdvisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MPI Advisor Trial',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const TrialAppRoot(),
    );
  }
}

class TrialAppRoot extends StatefulWidget {
  const TrialAppRoot({super.key});
  @override
  State<TrialAppRoot> createState() => _TrialAppRootState();
}

class _TrialAppRootState extends State<TrialAppRoot> with WidgetsBindingObserver {
  Advisor? _advisor;
  TrialStatus? _trialStatus;
  bool _checking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSession();
    _checkDeviceLogError();
  }

  Future<void> _checkDeviceLogError() async {
    final err = await DeviceLogService.getLastError();
    if (err != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Device log error: $err',
              style: GoogleFonts.robotoMono(fontSize: 11)),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () async {
                await DeviceLogService.resetFlag();
                DeviceLogService.logIfFirstInstall();
              },
            ),
          ));
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-cek trial tiap kali app dibuka kembali
    if (state == AppLifecycleState.resumed && _advisor != null) {
      _refreshTrial(_advisor!.name);
    }
  }

  Future<void> _checkSession() async {
    try {
      final advisor = await AuthService.getStoredAdvisor();
      if (advisor != null) {
        final status = await TrialService.checkAndInitTrial(advisor.name);
        if (mounted) setState(() { _advisor = advisor; _trialStatus = status; _checking = false; });
      } else {
        if (mounted) setState(() { _checking = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _checking = false; });
    }
  }

  Future<void> _refreshTrial(String advisorName) async {
    try {
      final status = await TrialService.checkAndInitTrial(advisorName);
      if (mounted) setState(() => _trialStatus = status);
    } catch (_) {}
  }

  Future<void> _handleLogin(Advisor advisor) async {
    setState(() => _checking = true);
    try {
      final status = await TrialService.checkAndInitTrial(advisor.name);
      if (mounted) setState(() { _advisor = advisor; _trialStatus = status; _checking = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _checking = false; });
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) setState(() { _advisor = null; _trialStatus = null; _error = null; });
  }

  @override
  Widget build(BuildContext context) {
    Widget activeScreen;

    if (_checking) {
      activeScreen = const Scaffold(
        key: ValueKey('checking'),
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    } else if (_error != null) {
      activeScreen = _ErrorScreen(
        key: const ValueKey('error'),
        message: _error!,
        onRetry: () => setState(() { _error = null; _checking = true; _checkSession(); }),
      );
    } else if (_advisor == null) {
      activeScreen = LoginScreen(
        key: const ValueKey('login'),
        onLogin: _handleLogin,
      );
    } else if (_trialStatus != null && !_trialStatus!.isActive) {
      activeScreen = TrialExpiredScreen(
        key: const ValueKey('expired'),
        onLogout: _handleLogout,
      );
    } else {
      activeScreen = _TrialShellWrapper(
        key: const ValueKey('shell'),
        advisor: _advisor!,
        trialStatus: _trialStatus!,
        onLogout: _handleLogout,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.0, 0.03), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: activeScreen,
    );
  }
}

/// Wrapper yang menambahkan banner trial di atas MainShell
class _TrialShellWrapper extends StatelessWidget {
  final Advisor advisor;
  final TrialStatus trialStatus;
  final VoidCallback onLogout;

  const _TrialShellWrapper({
    super.key,
    required this.advisor,
    required this.trialStatus,
    required this.onLogout,
  });

  Color get _bannerColor {
    if (trialStatus.daysRemaining <= 3) return const Color(0xFFDC2626);
    if (trialStatus.daysRemaining <= 7) return const Color(0xFFD97706);
    return const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Trial banner
        Material(
          color: _bannerColor,
          child: SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'TRIAL — ${trialStatus.daysRemaining} hari tersisa',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: MainShell(advisor: advisor, onLogout: onLogout),
        ),
      ],
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFF94A3B8)),
              const SizedBox(height: 16),
              Text(
                'Gagal memverifikasi status trial.\nPastikan koneksi internet aktif.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.robotoMono(fontSize: 11, color: const Color(0xFF475569)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Coba Lagi', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
