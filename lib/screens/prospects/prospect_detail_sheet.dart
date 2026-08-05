import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/traffic.dart';
import '../../theme.dart';

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem(this.icon, this.label, this.value);
}

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
      const m = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
      return '${d.day.toString().padLeft(2,'0')} ${m[d.month - 1]} ${d.year}';
    } catch (_) { return s; }
  }

  String _fmtCurrency(double v) {
    if (v == 0) return '—';
    if (v >= 1e9) return 'IDR ${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) {
      final m = v / 1e6;
      return 'IDR ${m.toStringAsFixed(m >= 100 ? 0 : 1)}M';
    }
    final f = v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'IDR $f';
  }

  Future<void> _openWa(BuildContext context) async {
    final phone = prospect.noHp;
    if (phone.isEmpty) return;
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final msg = Uri.encodeComponent('Halo ${prospect.customerName}, saya dari Bvlgari ingin menginfokan...');
    final uri = Uri.parse('https://wa.me/$cleaned?text=$msg');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    } catch (e) { debugPrint('WA error: $e'); }
  }

  void _copyEmail(BuildContext context) {
    if (prospect.email.isEmpty) return;
    Clipboard.setData(ClipboardData(text: prospect.email));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Email berhasil disalin'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppTheme.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasWa = prospect.noHp.isNotEmpty;
    final hasEmail = prospect.email.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _buildDragHandle(),
          _buildHeader(context),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              children: [
                _buildInfoGrid(),
                if (prospect.netSales > 0) ...[
                  const SizedBox(height: 14),
                  _buildLtvCard(),
                ],
                ..._buildDetailKunjungan(),
                if (prospect.buktiChat.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _buildSectionLabel('BUKTI CHAT / APPOINTMENT', Icons.camera_alt_outlined, const Color(0xFF7C3AED)),
                  const SizedBox(height: 10),
                  _buildBuktiChat(),
                ],
                const SizedBox(height: 22),
                _buildSectionLabel('INFORMASI KONTAK', Icons.contacts_outlined, const Color(0xFF0891B2)),
                const SizedBox(height: 10),
                _buildContactCard(
                  context,
                  icon: Icons.phone_android_outlined,
                  label: 'No. WhatsApp',
                  value: prospect.noHp,
                  actionIcon: Icons.chat_bubble_rounded,
                  actionColor: const Color(0xFF16A34A),
                  actionBg: const Color(0xFFDCFCE7),
                  onAction: hasWa ? () => _openWa(context) : null,
                ),
                const SizedBox(height: 8),
                _buildContactCard(
                  context,
                  icon: Icons.mail_outlined,
                  label: 'Alamat Email',
                  value: prospect.email,
                  actionIcon: Icons.copy_rounded,
                  actionColor: const Color(0xFF2563EB),
                  actionBg: const Color(0xFFDBEAFE),
                  onAction: hasEmail ? () => _copyEmail(context) : null,
                ),
                const SizedBox(height: 22),
                _buildSectionLabel('CATATAN KUNJUNGAN', Icons.notes_rounded, const Color(0xFFD97706)),
                const SizedBox(height: 10),
                _buildNotes(),
                const SizedBox(height: 28),
              ],
            ),
          ),
          if (hasWa || hasEmail) _buildBottomBar(context, hasWa: hasWa, hasEmail: hasEmail),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final initials = prospect.customerName.isNotEmpty
        ? prospect.customerName.trim().substring(0, 1).toUpperCase()
        : 'P';
    final panggilan = prospect.namaPanggilan;
    final level = prospect.prospekLevel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gradient avatar with glow
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  levelColor,
                  levelColor.withValues(alpha: 0.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: levelColor.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name + subtitle + badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prospect.customerName.isEmpty ? 'Customer Baru' : prospect.customerName,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (panggilan.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Panggil: $panggilan',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    if (prospect.status.isNotEmpty)
                      _chip(prospect.status.toUpperCase(), statusColor),
                    if (level.isNotEmpty)
                      _chip(level.toUpperCase(), levelColor),
                    if (prospect.prospectItem.isNotEmpty)
                      _chip(prospect.prospectItem.toUpperCase(), const Color(0xFF7C3AED)),
                  ],
                ),
              ],
            ),
          ),
          // Close button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.close, color: Color(0xFF64748B), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoTile(
                'Served By',
                prospect.servedBy.isNotEmpty ? prospect.servedBy
                    : prospect.customerAdvisor.isNotEmpty ? prospect.customerAdvisor : '—',
                Icons.person_outline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInfoTile(
                'Lokasi Butik',
                prospect.location.isEmpty ? '—' : prospect.location,
                Icons.storefront_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildInfoTile(
                'Tanggal Kunjungan',
                _fmtDate(prospect.tanggalBerkunjung),
                Icons.calendar_today_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInfoTile(
                'Status Pelanggan',
                prospect.statusPelanggan.isEmpty ? 'Regular' : prospect.statusPelanggan,
                Icons.verified_user_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'POTENSI TRANSAKSI',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF64748B),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Net Sales Terestimasi',
                  style: TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ),
          Text(
            _fmtCurrency(prospect.netSales),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon, Color accentColor) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 13, color: accentColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF64748B),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDetailKunjungan() {
    final rows = <_DetailItem>[
      if (prospect.siapa.isNotEmpty)
        _DetailItem(Icons.people_outline, 'Tipe Pengunjung', prospect.siapa),
      if (prospect.aksesMasuk.isNotEmpty)
        _DetailItem(Icons.door_sliding_outlined, 'Akses Masuk', prospect.aksesMasuk),
      if (prospect.minatBarang.isNotEmpty)
        _DetailItem(Icons.category_outlined, 'Minat Barang', prospect.minatBarang),
      if (prospect.faktorPemicu.isNotEmpty)
        _DetailItem(Icons.bolt_outlined, 'Faktor Pemicu', prospect.faktorPemicu),
      if (prospect.groupSize.isNotEmpty)
        _DetailItem(Icons.group_outlined, 'Jumlah Grup', '${prospect.groupSize} orang'),
      if (prospect.diskonPct > 0)
        _DetailItem(Icons.percent_rounded, 'Estimasi Diskon', '${prospect.diskonPct.toStringAsFixed(0)}%'),
    ];
    if (rows.isEmpty) return [];

    return [
      const SizedBox(height: 22),
      _buildSectionLabel('DETAIL KUNJUNGAN', Icons.info_outline_rounded, const Color(0xFF0891B2)),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            final item = e.value;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(children: [
                  Icon(item.icon, size: 15, color: const Color(0xFF2563EB)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 112,
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.value,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ]),
              ),
              if (!isLast) const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 38),
            ]);
          }).toList(),
        ),
      ),
    ];
  }

  Widget _buildBuktiChat() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        prospect.buktiChat,
        width: double.infinity,
        height: 190,
        fit: BoxFit.cover,
        errorBuilder: (ctx, e, st) => Container(
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              'Gambar tidak tersedia',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required IconData actionIcon,
    required Color actionColor,
    required Color actionBg,
    required VoidCallback? onAction,
  }) {
    final hasVal = value.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: actionColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  hasVal ? value : 'Tidak ada data',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: hasVal ? FontWeight.w600 : FontWeight.normal,
                    color: hasVal ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ),
          if (hasVal && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: actionBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(actionIcon, size: 16, color: actionColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    final isEmpty = prospect.notes.isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded, color: Color(0xFFCBD5E1), size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isEmpty ? 'Tidak ada catatan untuk kunjungan ini.' : prospect.notes,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.6,
                color: isEmpty ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, {required bool hasWa, required bool hasEmail}) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (hasWa)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openWa(context),
                icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                label: Text(
                  'WhatsApp',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          if (hasWa && hasEmail) const SizedBox(width: 10),
          if (hasEmail)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copyEmail(context),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: Text(
                  'Salin Email',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
