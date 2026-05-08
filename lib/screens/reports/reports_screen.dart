import 'package:flutter/material.dart';
import '../../models/advisor.dart';
import '../../services/sales_service.dart';

class ReportsScreen extends StatefulWidget {
  final Advisor advisor;
  const ReportsScreen({super.key, required this.advisor});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final now = DateTime.now();
  bool _loading = true;
  Map<String, Map<String, dynamic>> _categories = {};
  List<Map<String, dynamic>> _leaderboard = [];

  String _fmtM(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    return v.toStringAsFixed(0);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final adv = widget.advisor;
    final results = await Future.wait([
      SalesService.getCategoryBreakdown(
        advisorName: adv.name, isManager: adv.isManager,
        store: adv.store, month: now.month, year: now.year),
      if (adv.isManager)
        SalesService.getLeaderboard(store: adv.store, month: now.month, year: now.year),
    ]);
    setState(() {
      _categories = results[0] as Map<String, Map<String, dynamic>>;
      if (adv.isManager && results.length > 1) {
        _leaderboard = results[1] as List<Map<String, dynamic>>;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adv = widget.advisor;
    final sortedCats = _categories.entries.toList()
      ..sort((a, b) => (b.value['net'] as double).compareTo(a.value['net'] as double));
    final totalNet = sortedCats.fold(0.0, (s, e) => s + (e.value['net'] as double));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E40AF)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Category Breakdown
                  _SectionTitle('Category Breakdown'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(children: const [
                            Expanded(child: Text('KATEGORI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                              color: Color(0xFF94A3B8), letterSpacing: 1))),
                            SizedBox(width: 50, child: Text('QTY', textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1))),
                            SizedBox(width: 80, child: Text('NET SALES', textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1))),
                          ]),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        ...sortedCats.map((e) {
                          final pct = totalNet > 0 ? (e.value['net'] as double) / totalNet : 0.0;
                          return Column(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Column(children: [
                                Row(children: [
                                  Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                  SizedBox(width: 50, child: Text('${e.value['qty']}', textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                                  SizedBox(width: 80, child: Text(_fmtM(e.value['net'] as double),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                                ]),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(value: pct, minHeight: 4,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    valueColor: const AlwaysStoppedAnimation(Color(0xFF1E40AF))),
                                ),
                              ]),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ]);
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(children: [
                            const Expanded(child: Text('TOTAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900))),
                            SizedBox(width: 50, child: Text(
                              '${sortedCats.fold(0, (s, e) => s + (e.value['qty'] as int))}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))),
                            SizedBox(width: 80, child: Text(_fmtM(totalNet),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)))),
                          ]),
                        ),
                      ],
                    ),
                  ),

                  // Leaderboard (manager only)
                  if (adv.isManager && _leaderboard.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionTitle('Staff Leaderboard'),
                    const SizedBox(height: 8),
                    ..._leaderboard.take(10).toList().asMap().entries.map((entry) {
                      final rank = entry.key + 1;
                      final item = entry.value;
                      final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: rank <= 3 ? Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)) : null,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                        ),
                        child: Row(children: [
                          SizedBox(width: 32, child: Text(medal,
                            style: const TextStyle(fontSize: 16), textAlign: TextAlign.center)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(item['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                          Text('IDR ${_fmtM(item['net'] as double)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                              color: Color(0xFF1E40AF))),
                        ]),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w900,
      color: Color(0xFF374151), letterSpacing: 0.5));
  }
}
