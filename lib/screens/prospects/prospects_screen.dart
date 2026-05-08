import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/advisor.dart';
import '../../models/traffic.dart';
import '../../services/traffic_service.dart';
import 'traffic_input_screen.dart';
import '../../theme.dart';

class ProspectsScreen extends StatefulWidget {
  final Advisor advisor;
  final int month;
  final int year;
  const ProspectsScreen({super.key, required this.advisor, required this.month, required this.year});

  @override
  State<ProspectsScreen> createState() => _ProspectsScreenState();
}

class _ProspectsScreenState extends State<ProspectsScreen> {
  bool _loading = true;
  List<TrafficRow> _rows = [];
  ProspectCounts _counts = const ProspectCounts();

  static const _mNames = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];

  @override
  void initState() { super.initState(); _load(); }

  @override
  void didUpdateWidget(covariant ProspectsScreen old) {
    super.didUpdateWidget(old);
    if (old.month != widget.month || old.year != widget.year) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final adv = widget.advisor;
    final rows = await TrafficService.getProspects(
      advisorName: adv.name, isManager: adv.isManager,
      store: adv.store, month: widget.month, year: widget.year);
    final counts = await TrafficService.getProspectCounts(
      advisorName: adv.name, isManager: adv.isManager,
      store: adv.store, month: widget.month, year: widget.year);
    setState(() { _rows = rows; _counts = counts; _loading = false; });
  }

  String _fmtDate(String s) {
    if (s.isEmpty) return '—';
    try {
      final d = DateTime.parse(s);
      return '${d.day.toString().padLeft(2,'0')} ${_mNames[d.month - 1]} ${d.year}';
    } catch (_) { return s; }
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('walk'))    return const Color(0xFF2563EB);
    if (s.contains('follow'))  return const Color(0xFF7C3AED);
    if (s.contains('delivery') || s.contains('showing')) return const Color(0xFF0D9488);
    if (s.contains('service') || s.contains('repair'))   return const Color(0xFFD97706);
    if (s.contains('online'))  return const Color(0xFF475569);
    return const Color(0xFF64748B);
  }

  Color _prospectColor(String level) {
    final l = level.toLowerCase();
    if (l.contains('berhasil'))  return const Color(0xFF059669);
    if (l.contains('gagal'))     return const Color(0xFFDC2626);
    if (l.contains('negosiasi')) return const Color(0xFFD97706);
    if (l.contains('menunggu'))  return const Color(0xFF2563EB);
    if (l.contains('potensial') || l.contains('baru')) return const Color(0xFF7C3AED);
    return const Color(0xFF94A3B8);
  }

  Future<void> _openWa(String phone, String name) async {
    if (phone.isEmpty) return;
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final msg = Uri.encodeComponent('Halo $name, saya dari Bvlgari ingin menginfokan...');
    final uri = Uri.parse('https://wa.me/$cleaned?text=$msg');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
        : Scaffold(
            backgroundColor: Colors.transparent,
            body: RefreshIndicator(
              onRefresh: _load,
              child: Column(children: [
                // Stats row
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(children: [
                    _S('${_counts.total}',     'Total',    const Color(0xFF1E293B)),
                    _S('${_counts.walkIn}',    'Walk-in',  const Color(0xFF2563EB)),
                    _S('${_counts.followUp}',  'Follow Up',const Color(0xFF7C3AED)),
                    _S('${_counts.delivery}',  'Delivery', const Color(0xFF0D9488)),
                    _S('${_counts.newProfile}','Baru',     const Color(0xFF059669)),
                  ]),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // List
                Expanded(
                  child: _rows.isEmpty
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('Tidak ada prospek bulan ini',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                        ]))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                          itemCount: _rows.length,
                          itemBuilder: (ctx, i) {
                            final r = _rows[i];
                            final sc = _statusColor(r.status);
                            final pc = _prospectColor(r.prospectItem);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(children: [
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(r.status.isEmpty ? '—' : r.status.toUpperCase(),
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                                        color: sc, letterSpacing: 1)),
                                    const SizedBox(height: 2),
                                    Text(r.customerName.isEmpty ? '—' : r.customerName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                                        color: Color(0xFF1E293B))),
                                    const SizedBox(height: 2),
                                    Text(_fmtDate(r.tanggalBerkunjung),
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                    if (widget.advisor.isManager && r.customerAdvisor.isNotEmpty)
                                      Text('CA: ${r.customerAdvisor}',
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                  ])),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    if (r.prospectItem.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: pc.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(r.prospectItem,
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: pc)),
                                      ),
                                    const SizedBox(height: 8),
                                    if (r.noHp.isNotEmpty)
                                      GestureDetector(
                                        onTap: () => _openWa(r.noHp, r.customerName),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.chat_bubble_outline,
                                            size: 18, color: Color(0xFF16A34A)),
                                        ),
                                      ),
                                  ]),
                                ]),
                              ),
                            );
                          },
                        ),
                ),
              ]),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'fab_prospects',
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TrafficInputScreen(advisor: widget.advisor)),
                );
                if (res == true) _load();
              },
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
  }
}

class _S extends StatelessWidget {
  final String value, label;
  final Color color;
  const _S(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w700), textAlign: TextAlign.center),
    ]),
  );
}
