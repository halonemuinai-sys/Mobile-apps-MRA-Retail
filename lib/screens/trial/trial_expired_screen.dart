import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class TrialExpiredScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const TrialExpiredScreen({super.key, required this.onLogout});

  void _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/6285155140987?text=Halo%2C%20saya%20ingin%20aktivasi%20MPI%20Advisor');
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openEmail() async {
    final uri = Uri.parse('mailto:aris@mraretail.co.id?subject=Aktivasi%20MPI%20Advisor');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon expired
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.lock_clock_outlined, size: 48, color: Color(0xFFDC2626)),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Masa Trial Telah Berakhir',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Masa trial 14 hari Anda sudah habis.\nHubungi tim MRA Retail untuk melanjutkan akses.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF64748B),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),

              // WhatsApp button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openWhatsApp,
                  icon: const Icon(Icons.chat_rounded, size: 20),
                  label: Text(
                    'Hubungi via WhatsApp',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Email button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openEmail,
                  icon: const Icon(Icons.email_outlined, size: 20),
                  label: Text(
                    'Kirim Email',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Divider
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 20),

              // Logout
              TextButton(
                onPressed: onLogout,
                child: Text(
                  'Keluar dari akun',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
