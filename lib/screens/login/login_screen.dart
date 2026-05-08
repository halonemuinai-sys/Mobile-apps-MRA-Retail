import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/advisor.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final void Function(Advisor advisor) onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Brand colors from GAS
  static const kDark = Color(0xFF1E293B);
  static const kBlue = Color(0xFF2563EB);
  static const kGold = Color(0xFFD4AF37);

  List<String> _stores    = [];
  List<String> _advisors  = [];
  String? _selectedStore;
  String? _selectedAdvisor;
  final _pinCtrl = TextEditingController();
  bool _loadingStores  = true;
  bool _loadingAdvisors = false;
  bool _loggingIn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    try {
      final stores = await AuthService.getStores();
      setState(() { _stores = stores; _loadingStores = false; });
    } catch (_) {
      setState(() { _loadingStores = false; _error = 'Gagal memuat daftar store'; });
    }
  }

  Future<void> _onStoreChange(String store) async {
    setState(() {
      _selectedStore   = store;
      _selectedAdvisor = null;
      _advisors        = [];
      _loadingAdvisors = true;
      _error           = null;
    });
    try {
      final advisors = await AuthService.getAdvisorNamesByStore(store);
      setState(() { _advisors = advisors; _loadingAdvisors = false; });
    } catch (_) {
      setState(() { _loadingAdvisors = false; });
    }
  }

  Future<void> _login() async {
    if (_selectedAdvisor == null) {
      setState(() => _error = 'Pilih nama advisor terlebih dahulu'); return;
    }
    if (_pinCtrl.text.length < 4) {
      setState(() => _error = 'Masukkan PIN 4 digit'); return;
    }
    setState(() { _loggingIn = true; _error = null; });
    try {
      final advisor = await AuthService.login(_selectedAdvisor!, _pinCtrl.text);
      if (advisor == null) {
        setState(() { _error = 'Nama atau PIN salah.'; _loggingIn = false; });
      } else {
        widget.onLogin(advisor);
      }
    } catch (e) {
      setState(() { _error = 'Error: $e'; _loggingIn = false; });
    }
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w600),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.8))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.8))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: kBlue, width: 2)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, -0.8),
            radius: 1.2,
            colors: [Color(0xFFE0F2FE), Color(0xFFEFF6FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo — Playfair Display bold
                  const Text('BVLGARI', style: TextStyle(
                    fontSize: 36, fontWeight: FontWeight.w900,
                    color: kDark, letterSpacing: 6,
                    fontFamily: 'Georgia', // closest to Playfair
                  )),
                  const SizedBox(height: 6),
                  const Text('ADVISOR PORTAL', style: TextStyle(
                    fontSize: 11, letterSpacing: 4,
                    color: Color(0xFF64748B), fontWeight: FontWeight.w500,
                  )),
                  const SizedBox(height: 40),

                  // Glass card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 40, offset: const Offset(0, 16)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store selector
                        _Label('LOKASI STORE'),
                        const SizedBox(height: 6),
                        _loadingStores
                            ? const _LoadingField()
                            : DropdownButtonFormField<String>(
                                value: _selectedStore,
                                decoration: _inputDec('Pilih Lokasi...'),
                                style: const TextStyle(color: kDark, fontSize: 14, fontWeight: FontWeight.w600),
                                dropdownColor: Colors.white,
                                icon: const Icon(Icons.keyboard_arrow_down, color: kBlue),
                                items: _stores.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                onChanged: (v) { if (v != null) _onStoreChange(v); },
                              ),
                        const SizedBox(height: 16),

                        // Advisor selector
                        _Label('NAMA ADVISOR'),
                        const SizedBox(height: 6),
                        _loadingAdvisors
                            ? const _LoadingField()
                            : DropdownButtonFormField<String>(
                                value: _selectedAdvisor,
                                decoration: _inputDec(_selectedStore == null
                                    ? 'Pilih Lokasi Dulu' : 'Pilih Advisor'),
                                style: const TextStyle(color: kDark, fontSize: 14, fontWeight: FontWeight.w600),
                                dropdownColor: Colors.white,
                                icon: const Icon(Icons.keyboard_arrow_down, color: kBlue),
                                items: _advisors.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                                onChanged: _selectedStore == null ? null : (v) => setState(() => _selectedAdvisor = v),
                              ),
                        const SizedBox(height: 16),

                        // PIN
                        _Label('PIN AKSES'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _pinCtrl,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, letterSpacing: 10,
                            fontWeight: FontWeight.bold, color: kDark),
                          decoration: _inputDec('••••').copyWith(
                            counterText: '',
                            hintStyle: const TextStyle(fontSize: 20, letterSpacing: 6,
                              color: Color(0xFFCBD5E1)),
                          ),
                          onSubmitted: (_) => _login(),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(_error!,
                              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loggingIn ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              shadowColor: Colors.black.withValues(alpha: 0.2),
                            ),
                            child: _loggingIn
                                ? const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('MASUK', style: TextStyle(
                                    fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 14)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text('Hubungi IT jika lupa PIN Anda',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('MRA Retail | Created By Aris Setiyono',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(
    fontSize: 10, fontWeight: FontWeight.w800,
    color: Color(0xFF64748B), letterSpacing: 2,
  ));
}

class _LoadingField extends StatelessWidget {
  const _LoadingField();

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
    ),
    child: const Center(child: SizedBox(width: 18, height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)))),
  );
}
