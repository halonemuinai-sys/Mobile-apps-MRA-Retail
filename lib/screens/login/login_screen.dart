import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/advisor.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class LoginScreen extends StatefulWidget {
  final void Function(Advisor advisor) onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  List<String> _stores   = [];
  List<String> _advisors = [];
  String? _selectedStore;
  String? _selectedAdvisor;
  final _pinCtrl = TextEditingController();
  bool _loadingStores   = true;
  bool _loadingAdvisors = false;
  bool _loggingIn = false;
  bool _pinVisible = false;
  String? _error;

  @override
  void initState() { super.initState(); _loadStores(); }

  Future<void> _loadStores() async {
    try {
      final s = await AuthService.getStores();
      setState(() { _stores = s; _loadingStores = false; });
    } catch (_) {
      setState(() { _loadingStores = false; _error = 'Gagal memuat daftar store'; });
    }
  }

  Future<void> _onStoreChange(String store) async {
    setState(() { _selectedStore = store; _selectedAdvisor = null;
      _advisors = []; _loadingAdvisors = true; _error = null; });
    try {
      final a = await AuthService.getAdvisorNamesByStore(store);
      setState(() { _advisors = a; _loadingAdvisors = false; });
    } catch (_) { setState(() => _loadingAdvisors = false); }
  }

  Future<void> _login() async {
    if (_selectedAdvisor == null) { setState(() => _error = 'Pilih nama advisor'); return; }
    if (_pinCtrl.text.length < 4) { setState(() => _error = 'PIN minimal 4 digit'); return; }
    setState(() { _loggingIn = true; _error = null; });
    try {
      final adv = await AuthService.login(_selectedAdvisor!, _pinCtrl.text);
      if (adv == null) setState(() { _error = 'Nama atau PIN salah.'; _loggingIn = false; });
      else widget.onLogin(adv);
    } catch (e) { setState(() { _error = '$e'; _loggingIn = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                // Logo area
                const SizedBox(height: 20),
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                const Text('MPI Advisor', style: TextStyle(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('Retail Intelligence Portal', style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75), fontSize: 13, fontWeight: FontWeight.w400)),
                const SizedBox(height: 36),

                // Login card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      blurRadius: 40, offset: const Offset(0, 20))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Selamat Datang 👋', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    const Text('Masuk ke portal advisor Anda', style: TextStyle(
                      fontSize: 13, color: Color(0xFF64748B))),
                    const SizedBox(height: 24),

                    // Store
                    _Label('Lokasi Store'),
                    const SizedBox(height: 6),
                    _loadingStores
                        ? const _FieldSkeleton()
                        : _DropDown<String>(
                            value: _selectedStore,
                            hint: 'Pilih store...',
                            items: _stores,
                            label: (s) => s,
                            onChanged: (v) { if (v != null) _onStoreChange(v); }),
                    const SizedBox(height: 14),

                    // Advisor
                    _Label('Nama Advisor'),
                    const SizedBox(height: 6),
                    _loadingAdvisors
                        ? const _FieldSkeleton()
                        : _DropDown<String>(
                            value: _selectedAdvisor,
                            hint: _selectedStore == null ? 'Pilih store dulu' : 'Pilih advisor...',
                            items: _advisors,
                            label: (s) => s,
                            enabled: _selectedStore != null && _advisors.isNotEmpty,
                            onChanged: (v) => setState(() { _selectedAdvisor = v; _error = null; })),
                    const SizedBox(height: 14),

                    // PIN
                    _Label('PIN Akses'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _pinCtrl,
                      obscureText: !_pinVisible,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, letterSpacing: 8,
                        fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '• • • •',
                        hintStyle: const TextStyle(fontSize: 18, letterSpacing: 6, color: Color(0xFFCBD5E1)),
                        filled: true, fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
                        suffixIcon: IconButton(
                          icon: Icon(_pinVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18, color: const Color(0xFF94A3B8)),
                          onPressed: () => setState(() => _pinVisible = !_pinVisible)),
                      ),
                      onSubmitted: (_) => _login(),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          const Icon(Icons.error_outline, size: 14, color: Color(0xFFEF4444)),
                          const SizedBox(width: 6),
                          Expanded(child: Text(_error!, style: const TextStyle(
                            color: Color(0xFFEF4444), fontSize: 12))),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loggingIn ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loggingIn
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Masuk', style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                Text('MPI Retail · Portal v1.0', style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                const SizedBox(height: 20),
              ]),
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
    fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)));
}

class _FieldSkeleton extends StatelessWidget {
  const _FieldSkeleton();
  @override
  Widget build(BuildContext context) => Container(
    height: 50, decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: const Center(child: SizedBox(width: 18, height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)))));
}

class _DropDown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T?> onChanged;
  final bool enabled;
  const _DropDown({required this.value, required this.hint, required this.items,
    required this.label, required this.onChanged, this.enabled = true});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    value: value,
    decoration: InputDecoration(
      filled: true, fillColor: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    hint: Text(hint, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
    dropdownColor: Colors.white,
    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
    items: enabled ? items.map((i) => DropdownMenuItem(value: i, child: Text(label(i)))).toList() : [],
    onChanged: enabled ? onChanged : null,
  );
}
