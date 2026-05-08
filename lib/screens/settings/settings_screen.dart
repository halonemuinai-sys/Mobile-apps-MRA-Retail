import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/advisor.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class SettingsScreen extends StatefulWidget {
  final Advisor advisor;
  final VoidCallback onLogout;
  const SettingsScreen({super.key, required this.advisor, required this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _oldPin  = TextEditingController();
  final _newPin  = TextEditingController();
  final _confPin = TextEditingController();
  bool _changingPin = false;

  Future<void> _changePin() async {
    if (_newPin.text != _confPin.text) {
      _showSnack('PIN baru tidak cocok', error: true); return;
    }
    if (_newPin.text.length < 4) {
      _showSnack('PIN minimal 4 digit', error: true); return;
    }
    setState(() => _changingPin = true);
    final ok = await AuthService.changePin(widget.advisor.name, _oldPin.text, _newPin.text);
    setState(() => _changingPin = false);
    if (ok) {
      _oldPin.clear(); _newPin.clear(); _confPin.clear();
      _showSnack('PIN berhasil diubah');
    } else {
      _showSnack('PIN lama salah', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFDC2626) : const Color(0xFF059669),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _pinField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adv = widget.advisor;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.gradient,
              borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: Text(adv.name.isNotEmpty ? adv.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(adv.name, style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 16)),
                Text(adv.store, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12)),
                  child: Text(adv.role.toUpperCase().replaceAll('_', ' '),
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              ])),
            ]),
          ),
          const SizedBox(height: 24),

          // Change PIN
          const Text('GANTI PIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
            color: Color(0xFF94A3B8), letterSpacing: 1)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
            child: Column(children: [
              _pinField(_oldPin,  'PIN Lama'),
              const SizedBox(height: 12),
              _pinField(_newPin,  'PIN Baru'),
              const SizedBox(height: 12),
              _pinField(_confPin, 'Konfirmasi PIN Baru'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _changingPin ? null : _changePin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _changingPin
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Simpan PIN', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await AuthService.logout();
                widget.onLogout();
              },
              icon: const Icon(Icons.logout, size: 18, color: Color(0xFFDC2626)),
              label: const Text('Keluar', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFDC2626)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Center(child: Text('MPI Advisor Portal v1.0.0\n© 2026 MPI Retail',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1), height: 1.8))),
        ],
      ),
    );
  }
}
