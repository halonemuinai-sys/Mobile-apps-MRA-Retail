import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/advisor.dart';
import '../../models/traffic.dart';
import '../../services/traffic_service.dart';

class ProspectsScreen extends StatefulWidget {
  final Advisor advisor;
  const ProspectsScreen({super.key, required this.advisor});

  @override
  State<ProspectsScreen> createState() => _ProspectsScreenState();
}

class _ProspectsScreenState extends State<ProspectsScreen> {
  final now = DateTime.now();
  bool _loading = true;
  List<TrafficRow> _all = [];
  String _filter = 'Semua';

  static const _filters = ['Semua', 'Walk-in', 'Follow Up', 'Delivery', 'Service', 'Online'];

  static const _statusColors = {
    'Walk-in':   Color(0xFF1E40AF),
    'Follow Up': Color(0xFF7C3AED),
    'Delivery':  Color(0xFF0D9488),
    'Service':   Color(0xFFD97706),
    'Online':    Color(0xFF475569),
  };

  static const _prospectColors = {
    'Berhasil':  Color(0xFF059669),
    'Gagal':     Color(0xFFDC2626),
    'Negosiasi': Color(0xFFD97706),
    'Menunggu':  Color(0xFF2563EB),
    'Potensial': Color(0xFF7C3AED),
  };

  String _fmtDate(String s) {
    if (s.isEmpty) return '—';
    try {
      final d = DateTime.parse(s);
      return DateFormat('d MMM yyyy').format(d);
    } catch (_) { return s; }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final adv = widget.advisor;
    final data = await TrafficService.getProspects(
      advisorName: adv.name, isManager: adv.isManager,
      store: adv.store, month: now.month, year: now.year);
    setState(() { _all = data; _loading = false; });
  }

  List<TrafficRow> get _filtered {
    if (_filter == 'Semua') return _all;
    return _all.where((r) => r.status.toLowerCase().contains(_filter.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final conversion = _all.isNotEmpty
        ? (_all.where((r) => r.netSales > 0).length / _all.length * 100)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E40AF)))
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  // Stats bar
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        _StatChip('Total', '${_all.length}', const Color(0xFF1E40AF)),
                        const SizedBox(width: 8),
                        _StatChip('Berhasil', '${_all.where((r) => r.netSales > 0).length}', const Color(0xFF059669)),
                        const SizedBox(width: 8),
                        _StatChip('Konversi', '${conversion.toStringAsFixed(1)}%', const Color(0xFF7C3AED)),
                      ],
                    ),
                  ),
                  // Filter chips
                  Container(
                    color: Colors.white,
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: _filters.map((f) {
                        final active = f == _filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: active ? const Color(0xFF1E40AF) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: Text(f, style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: active ? Colors.white : const Color(0xFF64748B))),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  // List
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('Tidak ada data', style: TextStyle(color: Color(0xFF94A3B8))))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final r = filtered[i];
                              final sc = _statusColors[r.status] ?? const Color(0xFF64748B);
                              final pc = _prospectColors.entries
                                .firstWhere((e) => r.prospectItem.toLowerCase().contains(e.key.toLowerCase()),
                                  orElse: () => const MapEntry('', Color(0xFF94A3B8)))
                                .value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border(left: BorderSide(color: sc, width: 3)),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 1))],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        Expanded(child: Text(
                                          r.customerName.isEmpty ? '—' : r.customerName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        )),
                                        if (r.prospectItem.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: pc.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: pc.withOpacity(0.3)),
                                            ),
                                            child: Text(r.prospectItem,
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: pc)),
                                          ),
                                      ]),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: sc.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(r.status,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sc)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(_fmtDate(r.tanggalBerkunjung),
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                        if (widget.advisor.isManager) ...[
                                          const SizedBox(width: 8),
                                          Text('CA: ${r.customerAdvisor}',
                                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                        ],
                                      ]),
                                      if (r.noHp.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text('📱 ${r.noHp}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Text(value, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}
