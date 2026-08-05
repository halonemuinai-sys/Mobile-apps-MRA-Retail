import 'package:flutter/material.dart';
import '../../models/profile.dart';
import '../../models/traffic.dart';
import '../../services/traffic_service.dart';

class CrmDetailScreen extends StatefulWidget {
  final CrmProfile profile;
  const CrmDetailScreen({super.key, required this.profile});

  @override
  State<CrmDetailScreen> createState() => _CrmDetailScreenState();
}

class _CrmDetailScreenState extends State<CrmDetailScreen> {
  List<TrafficRow> _trafficRows = [];
  bool _trafficLoading = true;

  @override
  void initState() {
    super.initState();
    TrafficService.getTrafficByCustomer(
      widget.profile.namaLengkap,
      noHp: widget.profile.noHp,
    ).then((rows) {
      if (mounted) setState(() { _trafficRows = rows; _trafficLoading = false; });
    }).catchError((_) {
      if (mounted) setState(() => _trafficLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(p.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A1628), Color(0xFF1E3A5F)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              CircleAvatar(
                radius: 28, backgroundColor: const Color(0xFFD4AF37),
                child: Text(p.initials,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.displayName, style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 16)),
                if (p.namaPanggilan.isNotEmpty)
                  Text('Panggilan: ${p.namaPanggilan}',
                    style: const TextStyle(color: Color(0xFF8899AA), fontSize: 12)),
                const SizedBox(height: 4),
                Row(children: [
                  _StoreBadge(p.lokasiStore),
                  if (p.statusPelanggan.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
                      ),
                      child: Text(p.statusPelanggan,
                        style: const TextStyle(color: Color(0xFFD97706), fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ]),
              ])),
            ]),
          ),
          const SizedBox(height: 16),

          _Section('Kontak & Identitas', Icons.phone_outlined, [
            _F('No. HP',       p.noHp),
            _F('Email',        p.email),
            _F('CA',           p.customerAdvisor),
            _F('Store',        p.lokasiStore),
            _F('Tgl Lahir',    p.tanggalLahir ?? '—'),
            _F('Umur',         p.umur),
            _F('KTP/Passport', p.ktpPassport),
          ]),

          _Section('Demografi', Icons.public_outlined, [
            _F('Etnis',          p.etnis),
            _F('Agama',          p.agama),
            _F('Domisili',       p.domisili),
            _F('Domisili LN',    p.domisiliLuarNegeri),
            _F('Kewarganegaraan', p.kewarganegaraan),
            _F('Status Nikah',   p.statusPernikahan),
            _F('Tgl Pernikahan', p.tanggalPernikahan ?? ''),
            _F('Punya Anak',     p.memilikiAnak),
            _F('Jumlah Anak',    p.jumlahAnak),
          ]),

          _Section('Pekerjaan & Lifestyle', Icons.work_outline, [
            _F('Pekerjaan',      p.pekerjaan),
            _F('Fashion Style',  p.fashionStyle),
            _F('Warna Favorit',  p.warnaFavorit),
            _F('Karakter',       p.karakter),
            _F('Topik Favorit',  p.topikPembicaraanFavorit),
          ]),

          _Section('Hobby & Minat', Icons.favorite_outline, [
            _F('Hobby',          p.hobby),
            _F('Kategori',       p.hobbyKategori),
            _F('Sub Hobby',      p.hobbySub),
            _F('Tempat Liburan', p.tempatLiburanFavorit),
            _F('Barang Antusias', p.barangAntusias),
            _F('Faktor Pemicu',  p.faktorPemicuPembelian),
          ]),

          _Section('Makanan & Minuman', Icons.restaurant_outlined, [
            _F('Makanan',   p.makananFavorit),
            _F('Minuman',   p.minumanFavorit),
            _F('Kue Favorit', p.cakeFavorit),
            _F('Alergi',    p.alergiMakanan),
          ]),

          _Section('Sosial Media', Icons.alternate_email, [
            _F('Instagram', p.instagram),
            _F('TikTok',    p.tiktok),
          ]),

          // Traffic breakdown
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.store_mall_directory_outlined, size: 15, color: Color(0xFF1E40AF)),
                ),
                const SizedBox(width: 8),
                const Text('Riwayat Kunjungan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                  color: Color(0xFF374151), letterSpacing: 0.5)),
              ]),
            ),
            if (_trafficLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else if (_trafficRows.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
                child: const Center(child: Text('Belum ada riwayat kunjungan',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))),
              )
            else
              Column(
                children: _trafficRows.map((t) => _TrafficCard(t)).toList(),
              ),
            const SizedBox(height: 14),
          ]),
        ],
      ),
    );
  }
}

class _StoreBadge extends StatelessWidget {
  final String store;
  const _StoreBadge(this.store);

  @override
  Widget build(BuildContext context) {
    Color c;
    if (store.contains('Intermark')) {
      c = const Color(0xFF1E40AF);
    } else if (store.contains('Senayan') || store.contains('Superstore')) {
      c = const Color(0xFF7C3AED);
    } else if (store.toLowerCase().contains('bali')) {
      c = const Color(0xFF059669);
    } else {
      c = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Text(store.isEmpty ? '—' : store,
        style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_F> fields;
  const _Section(this.title, this.icon, this.fields);

  @override
  Widget build(BuildContext context) {
    final nonEmpty = fields.where((f) => f.value.isNotEmpty && f.value != '—').toList();
    if (nonEmpty.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: const Color(0xFF1E40AF)),
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
            color: Color(0xFF374151), letterSpacing: 0.5)),
        ]),
      ),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
        child: Column(
          children: nonEmpty.asMap().entries.map((entry) {
            final isLast = entry.key == nonEmpty.length - 1;
            final f = entry.value;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 110, child: Text(f.label,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600))),
                  Expanded(child: Text(f.value,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w500))),
                ]),
              ),
              if (!isLast) const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16),
            ]);
          }).toList(),
        ),
      ),
      const SizedBox(height: 14),
    ]);
  }
}

class _F {
  final String label, value;
  const _F(this.label, this.value);
}

class _TrafficCard extends StatelessWidget {
  final TrafficRow t;
  const _TrafficCard(this.t);

  Color get _statusColor {
    final s = t.status.toLowerCase();
    if (s.contains('walk')) return const Color(0xFF2563EB);
    if (s.contains('follow')) return const Color(0xFF7C3AED);
    if (s.contains('delivery') || s.contains('showing')) return const Color(0xFF059669);
    if (s.contains('repair') || s.contains('service')) return const Color(0xFFD97706);
    if (s.contains('online')) return const Color(0xFF0891B2);
    return const Color(0xFF64748B);
  }

  Color get _prospekColor {
    final p = t.prospectItem.toLowerCase();
    if (p.contains('berhasil')) return const Color(0xFF059669);
    if (p.contains('gagal')) return const Color(0xFFDC2626);
    if (p.contains('negosiasi')) return const Color(0xFFD97706);
    if (p.contains('menunggu')) return const Color(0xFF7C3AED);
    return const Color(0xFF64748B);
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Detail Kunjungan', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _DetailRow(Icons.calendar_today_rounded, 'Tanggal', t.tanggalBerkunjung),
          _DetailRow(Icons.directions_walk_rounded, 'Tipe', t.status),
          if (t.prospectItem.isNotEmpty) _DetailRow(Icons.flag_rounded, 'Prospek Level', t.prospectItem),
          if (t.statusPelanggan.isNotEmpty) _DetailRow(Icons.star_rounded, 'Status', t.statusPelanggan),
          if (t.location.isNotEmpty) _DetailRow(Icons.store_rounded, 'Store', t.location),
          if (t.customerAdvisor.isNotEmpty) _DetailRow(Icons.person_rounded, 'Advisor', t.customerAdvisor),
          if (t.notes.isNotEmpty) _DetailRow(Icons.notes_rounded, 'Notes', t.notes),
          if (t.barangDiminati.isNotEmpty) ...[
            const Divider(height: 20),
            const Text('Barang Diminati', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            ...t.barangDiminati.split('; ').where((s) => s.trim().isNotEmpty).map((item) =>
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(children: [
                  const Icon(Icons.diamond_outlined, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.trim(),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B), fontWeight: FontWeight.w500))),
                ]),
              ),
            ),
          ],
          if (t.netSales > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(children: [
                const Text('Total Estimasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const Spacer(),
                Text(_formatRpDetail(t.netSales),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
              ]),
            ),
          ],
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: _statusColor, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.calendar_month_rounded, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(t.tanggalBerkunjung,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(t.status.isEmpty ? 'Kunjungan' : t.status,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor)),
                ),
                if (t.prospectItem.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _prospekColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(t.prospectItem,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _prospekColor)),
                  ),
                ],
              ]),
              if (t.location.isNotEmpty || t.customerAdvisor.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    [if (t.location.isNotEmpty) t.location, if (t.customerAdvisor.isNotEmpty) t.customerAdvisor].join(' · '),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ),
              if (t.barangDiminati.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(children: [
                    const Icon(Icons.diamond_outlined, size: 11, color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Text(
                      '${t.barangDiminati.split('; ').where((s) => s.trim().isNotEmpty).length} barang diminati${t.netSales > 0 ? '  ·  ${_formatRpDetail(t.netSales)}' : ''}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
            ])),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCBD5E1)),
          ]),
        ),
      ),
    );
  }
}

String _formatRpDetail(double amount) {
  if (amount == 0) return 'Rp 0';
  final n = amount.toInt();
  final str = n.toString();
  final buf = StringBuffer('Rp ');
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
    buf.write(str[i]);
  }
  return buf.toString();
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
      const SizedBox(width: 10),
      SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w500))),
    ]),
  );
}
