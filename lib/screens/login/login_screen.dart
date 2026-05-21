import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/advisor.dart';
import '../../services/auth_service.dart';
import '../../widgets/fade_in_slide.dart';

class LoginScreen extends StatefulWidget {
  final void Function(Advisor advisor) onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  List<String> _stores = [];
  List<String> _advisors = [];
  String? _selectedStore;
  String? _selectedAdvisor;
  final _pinCtrl = TextEditingController();
  bool _loadingStores = true;
  bool _loadingAdvisors = false;
  bool _loggingIn = false;
  bool _pinVisible = false;
  String? _error;

  // Colors from HTML
  final Color portalNavy = const Color(0xFF002C5B);
  final Color portalBlue = const Color(0xFF0055FF);
  final Color portalBg = const Color(0xFFF8FAFC);
  final Color borderNavy = const Color(0xFF0A2540);

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    try {
      final s = await AuthService.getStores();
      setState(() {
        _stores = s;
        _loadingStores = false;
      });
    } catch (_) {
      setState(() {
        _loadingStores = false;
        _error = 'Gagal memuat daftar store';
      });
    }
  }

  Future<void> _onStoreChange(String store) async {
    setState(() {
      _selectedStore = store;
      _selectedAdvisor = null;
      _advisors = [];
      _loadingAdvisors = true;
      _error = null;
    });
    try {
      final a = await AuthService.getAdvisorNamesByStore(store);
      setState(() {
        _advisors = a;
        _loadingAdvisors = false;
      });
    } catch (_) {
      setState(() => _loadingAdvisors = false);
    }
  }

  Future<void> _login() async {
    if (_selectedAdvisor == null) {
      setState(() => _error = 'Pilih nama advisor');
      return;
    }
    if (_pinCtrl.text.length < 4) {
      setState(() => _error = 'PIN minimal 4 digit');
      return;
    }
    setState(() {
      _loggingIn = true;
      _error = null;
    });
    try {
      final adv = await AuthService.login(_selectedAdvisor!, _pinCtrl.text);
      if (adv == null) {
        setState(() {
          _error = 'Nama atau PIN salah.';
          _loggingIn = false;
        });
      } else {
        widget.onLogin(adv);
      }
    } catch (e) {
      setState(() {
        _error = '$e';
        _loggingIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: portalBg,
      body: Stack(
        children: [
          // Background Pattern
          Positioned.fill(
            child: CustomPaint(
              painter: GeometricBackgroundPainter(),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  children: [
                    // Main Card
                    FadeInSlide(
                      delay: const Duration(milliseconds: 100),
                      slideOffset: 30,
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 60,
                              offset: const Offset(0, 20),
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          // Logo Section
                          SizedBox(
                            height: 100,
                            width: 100,
                            child: CustomPaint(
                              painter: PortalLogoPainter(color: portalNavy),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Header Text
                          Text(
                            'Elite Advisor Portal',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              color: portalNavy,
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Masuk ke portal advisor Anda',
                            style: GoogleFonts.inter(
                              color: Colors.grey[500],
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Form Fields
                          _buildFieldLabel('Store Location'),
                          const SizedBox(height: 6),
                          _loadingStores
                              ? _buildSkeleton()
                              : _buildDropdown<String>(
                                  value: _selectedStore,
                                  hint: 'Pilih store...',
                                  items: _stores,
                                  onChanged: (v) {
                                    if (v != null) _onStoreChange(v);
                                  },
                                ),
                          const SizedBox(height: 16),

                          _buildFieldLabel('Advisor Name'),
                          const SizedBox(height: 6),
                          _loadingAdvisors
                              ? _buildSkeleton()
                              : _buildDropdown<String>(
                                  value: _selectedAdvisor,
                                  hint: _selectedStore == null
                                      ? 'Customer Advisor'
                                      : 'Pilih advisor...',
                                  items: _advisors,
                                  enabled: _selectedStore != null &&
                                      _advisors.isNotEmpty,
                                  onChanged: (v) => setState(() {
                                    _selectedAdvisor = v;
                                    _error = null;
                                  }),
                                ),
                          const SizedBox(height: 16),

                          _buildFieldLabel('PIN Akses'),
                          const SizedBox(height: 6),
                          _buildPinField(),

                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ],

                          const SizedBox(height: 32),
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loggingIn ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: portalBlue,
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor: portalBlue.withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              child: _loggingIn
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : Text(
                                      'Masuk',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                    // Footer
                    Opacity(
                      opacity: 0.8,
                      child: Text(
                        '© 2026 MRA Group',
                        style: GoogleFonts.inter(
                          color: Colors.grey[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: portalNavy,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: portalNavy, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: portalNavy, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      hint: Text(hint,
          style: TextStyle(color: Colors.grey[400], fontSize: 14)),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: portalNavy),
      items: enabled
          ? items
              .map((i) => DropdownMenuItem(value: i, child: Text(i.toString())))
              .toList()
          : [],
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _buildPinField() {
    return TextField(
      controller: _pinCtrl,
      obscureText: !_pinVisible,
      keyboardType: TextInputType.number,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: GoogleFonts.inter(
        fontSize: 16,
        letterSpacing: 4,
        fontWeight: FontWeight.w600,
        color: portalNavy,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: '••••',
        hintStyle: TextStyle(
            color: portalNavy.withValues(alpha: 0.3), letterSpacing: 4),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: portalNavy, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: portalNavy, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _pinVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
            color: portalNavy.withValues(alpha: 0.7),
          ),
          onPressed: () => setState(() => _pinVisible = !_pinVisible),
        ),
      ),
      onSubmitted: (_) => _login(),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        color: Colors.grey[50]!,
      ),
      child: const Center(
          child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF002C5B)))),
    );
  }
}

class GeometricBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const double spacing = 60;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        // Draw tiny dots
        canvas.drawCircle(Offset(x, y), 0.5, paint);
        
        // Draw subtle pattern similar to the HTML CSS pattern
        if ((x / spacing).floor() % 3 == 0 && (y / spacing).floor() % 2 == 0) {
          final path = Path()
            ..moveTo(x, y)
            ..lineTo(x + 10, y - 10)
            ..lineTo(x + 20, y);
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PortalLogoPainter extends CustomPainter {
  final Color color;
  PortalLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path1 = Path();
    double sx = size.width / 100;
    double sy = size.height / 120;

    path1.moveTo(25 * sx, 15 * sy);
    path1.lineTo(25 * sx, 105 * sy);
    path1.lineTo(50 * sx, 105 * sy);
    path1.cubicTo(70 * sx, 105 * sy, 85 * sx, 95 * sy, 85 * sx, 80 * sy);
    path1.cubicTo(85 * sx, 68 * sy, 77 * sx, 60 * sy, 65 * sx, 58 * sy);
    path1.cubicTo(75 * sx, 56 * sy, 80 * sx, 48 * sy, 80 * sx, 38 * sy);
    path1.cubicTo(80 * sx, 23 * sy, 65 * sx, 15 * sy, 45 * sx, 15 * sy);
    path1.close();
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(25 * sx, 65 * sy);
    path2.cubicTo(45 * sx, 35 * sy, 65 * sx, 35 * sy, 85 * sx, 55 * sy);
    canvas.drawPath(path2, paint);

    final paintThin = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(Offset(35 * sx, 15 * sy), Offset(35 * sx, 105 * sy), paintThin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
