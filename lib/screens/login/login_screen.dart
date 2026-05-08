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
  List<String> _advisorNames = [];
  String? _selectedName;
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  bool _loadingNames = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    try {
      final names = await AuthService.getAdvisorNames();
      setState(() { _advisorNames = names; _loadingNames = false; });
    } catch (_) {
      setState(() { _loadingNames = false; _error = 'Gagal memuat daftar advisor'; });
    }
  }

  Future<void> _login() async {
    if (_selectedName == null || _pinCtrl.text.length < 4) {
      setState(() => _error = 'Pilih nama dan masukkan PIN 4 digit');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final advisor = await AuthService.login(_selectedName!, _pinCtrl.text);
      if (advisor == null) {
        setState(() { _error = 'PIN salah. Coba lagi.'; _loading = false; });
      } else {
        widget.onLogin(advisor);
      }
    } catch (e) {
      setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                  ),
                  child: const Icon(Icons.diamond_outlined, color: Color(0xFFD4AF37), size: 36),
                ),
                const SizedBox(height: 16),
                const Text('BVLGARI', style: TextStyle(
                  color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.w900, letterSpacing: 6,
                )),
                const Text('ROMA', style: TextStyle(
                  color: Color(0xFFD4AF37), fontSize: 10,
                  fontWeight: FontWeight.bold, letterSpacing: 4,
                )),
                const SizedBox(height: 6),
                const Text('Advisor Portal', style: TextStyle(
                  color: Color(0xFF8899AA), fontSize: 13, letterSpacing: 1,
                )),
                const SizedBox(height: 40),

                // Name Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2D5080)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _loadingNames
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Center(child: SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)))),
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedName,
                            isExpanded: true,
                            hint: const Text('Pilih Nama Advisor', style: TextStyle(color: Color(0xFF8899AA))),
                            dropdownColor: const Color(0xFF1E3A5F),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFD4AF37)),
                            items: _advisorNames.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                            onChanged: (v) => setState(() { _selectedName = v; _error = null; }),
                          ),
                        ),
                ),
                const SizedBox(height: 12),

                // PIN Input
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2D5080)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _pinCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 8),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: '● ● ● ●',
                      hintStyle: TextStyle(color: Color(0xFF8899AA), letterSpacing: 6),
                      border: InputBorder.none,
                      counterText: '',
                      prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFD4AF37), size: 18),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A1A1A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12)),
                  ),
                ],
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('MASUK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Default PIN: 1234\nGanti PIN di menu Settings setelah login',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF445566), fontSize: 11, height: 1.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
