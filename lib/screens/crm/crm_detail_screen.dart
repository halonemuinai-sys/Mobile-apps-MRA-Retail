import 'package:flutter/material.dart';
import '../../models/profile.dart';

class CrmDetailScreen extends StatelessWidget {
  final CrmProfile profile;
  const CrmDetailScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final p = profile;
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
                        color: const Color(0xFFD97706).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD97706).withOpacity(0.4)),
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
          ]),

          _Section('Demografi', Icons.public_outlined, [
            _F('Domisili',       p.domisili),
            _F('Kewarganegaraan', p.kewarganegaraan),
            _F('Status Nikah',  p.statusPernikahan),
          ]),

          _Section('Pekerjaan & Lifestyle', Icons.work_outline, [
            _F('Pekerjaan',      p.pekerjaan),
            _F('Fashion Style',  p.fashionStyle),
            _F('Warna Favorit',  p.warnaFavorit),
            _F('Karakter',       p.karakter),
          ]),

          _Section('Hobby & Minat', Icons.favorite_outline, [
            _F('Hobby',         p.hobby),
            _F('Kategori',      p.hobbyKategori),
            _F('Tempat Liburan', p.tempatLiburanFavorit),
            _F('Barang Antusias', p.barangAntusias),
            _F('Faktor Pemicu', p.faktorPemicuPembelian),
          ]),

          _Section('Makanan & Minuman', Icons.restaurant_outlined, [
            _F('Makanan',   p.makananFavorit),
            _F('Minuman',   p.minumanFavorit),
            _F('Alergi',    p.alergiMakanan),
          ]),

          _Section('Sosial Media', Icons.alternate_email, [
            _F('Instagram', p.instagram),
            _F('TikTok',    p.tiktok),
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
    if (store.contains('Intermark')) c = const Color(0xFF1E40AF);
    else if (store.contains('Senayan') || store.contains('Superstore')) c = const Color(0xFF7C3AED);
    else if (store.toLowerCase().contains('bali')) c = const Color(0xFF059669);
    else c = const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.4)),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
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
