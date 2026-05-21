import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/traffic.dart';
import '../../theme.dart';

class ProspectDetailSheet extends StatelessWidget {
  final TrafficRow prospect;
  final Color statusColor;
  final Color levelColor;

  const ProspectDetailSheet({
    super.key,
    required this.prospect,
    required this.statusColor,
    required this.levelColor,
  });

  String _fmtDate(String s) {
    if (s.isEmpty) return '—';
    try {
      final d = DateTime.parse(s);
      const mNames = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
      return '${d.day.toString().padLeft(2,'0')} ${mNames[d.month - 1]} ${d.year}';
    } catch (_) {
      return s;
    }
  }

  String _fmtCurrency(double v) {
    if (v == 0) return '—';
    if (v >= 1e9) return 'IDR ${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) {
      final m = v / 1e6;
      return 'IDR ${m.toStringAsFixed(m >= 100 ? 0 : 1)}M';
    }
    final formatted = v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'IDR $formatted';
  }

  Future<void> _openWa(BuildContext context) async {
    final phone = prospect.noHp;
    if (phone.isEmpty) return;
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final msg = Uri.encodeComponent('Halo ${prospect.customerName}, saya dari Bvlgari ingin menginfokan...');
    final uri = Uri.parse('https://wa.me/$cleaned?text=$msg');
    
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!context.mounted) return;
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    } catch (e) {
      debugPrint('Error launching WA: $e');
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke papan klip'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppTheme.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header Profile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: levelColor.withValues(alpha: 0.15),
                  child: Text(
                    prospect.customerName.isNotEmpty
                        ? prospect.customerName.trim().substring(0, 1).toUpperCase()
                        : 'P',
                    style: TextStyle(
                      color: levelColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prospect.customerName.isEmpty ? 'Customer Baru' : prospect.customerName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (prospect.status.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                prospect.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: statusColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          if (prospect.prospectItem.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: levelColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: levelColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                prospect.prospectItem.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: levelColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          const Divider(height: 20, color: Color(0xFFE2E8F0)),

          // Content body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Info Cards Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.5,
                  children: [
                    _buildInfoCard(
                      'Advisor',
                      prospect.customerAdvisor.isEmpty ? '—' : prospect.customerAdvisor,
                      Icons.person_outline,
                    ),
                    _buildInfoCard(
                      'Lokasi Butik',
                      prospect.location.isEmpty ? '—' : prospect.location,
                      Icons.storefront,
                    ),
                    _buildInfoCard(
                      'Tanggal Kunjungan',
                      _fmtDate(prospect.tanggalBerkunjung),
                      Icons.calendar_today_outlined,
                    ),
                    _buildInfoCard(
                      'Status Pelanggan',
                      prospect.statusPelanggan.isEmpty ? 'Regular' : prospect.statusPelanggan,
                      Icons.verified_user_outlined,
                    ),
                  ],
                ),
                
                if (prospect.netSales > 0) ...[
                  const SizedBox(height: 12),
                  _buildLtvCard(),
                ],

                const SizedBox(height: 16),

                // Contacts Section
                Text(
                  'INFORMASI KONTAK',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                _buildContactItem(
                  context,
                  label: 'No. WhatsApp',
                  value: prospect.noHp,
                  icon: Icons.phone_android,
                  onAction: () => _openWa(context),
                  actionIcon: Icons.chat_bubble_outline,
                  actionColor: const Color(0xFF16A34A),
                  actionBgColor: const Color(0xFFDCFCE7),
                ),
                const SizedBox(height: 8),
                _buildContactItem(
                  context,
                  label: 'Alamat Email',
                  value: prospect.email,
                  icon: Icons.mail_outline,
                  onAction: () => _copyToClipboard(context, prospect.email, 'Email'),
                  actionIcon: Icons.copy,
                  actionColor: const Color(0xFF2563EB),
                  actionBgColor: const Color(0xFFDBEAFE),
                ),

                const SizedBox(height: 20),

                // Notes Section
                Text(
                  'CATATAN KUNJUNGAN',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote_rounded, color: Color(0xFFCBD5E1), size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          prospect.notes.isEmpty
                              ? 'Tidak ada catatan untuk kunjungan ini.'
                              : prospect.notes,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.5,
                            color: const Color(0xFF334155),
                            fontStyle: prospect.notes.isEmpty ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLtvCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'POTENSI TRANSAKSI',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Net Sales Terestimasi',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          Text(
            _fmtCurrency(prospect.netSales),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onAction,
    required IconData actionIcon,
    required Color actionColor,
    required Color actionBgColor,
  }) {
    final hasVal = value.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  hasVal ? value : 'Tidak ada data',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: hasVal ? FontWeight.bold : FontWeight.normal,
                    color: hasVal ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          if (hasVal)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: actionBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  actionIcon,
                  size: 16,
                  color: actionColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
