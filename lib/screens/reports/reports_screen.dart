import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/advisor.dart';
import '../../services/sales_service.dart';
import '../../services/traffic_service.dart';
import '../../theme.dart';

class ReportsScreen extends StatefulWidget {
  final Advisor advisor;
  final int month;
  final int year;
  const ReportsScreen({super.key, required this.advisor, required this.month, required this.year});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _loading = true;
  Map<String, Map<String, dynamic>> _categories = {};
  List<Map<String, dynamic>> _leaderboard = [];
  Map<String, int> _trafficBreakdown = {};
  List<double> _monthly = List.filled(12, 0);

  static const _mNamesFull = ['January','February','March','April','May','June',
    'July','August','September','October','November','December'];

  @override
  void initState() { super.initState(); _load(); }

  @override
  void didUpdateWidget(covariant ReportsScreen old) {
    super.didUpdateWidget(old);
    if (old.month != widget.month || old.year != widget.year) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final adv = widget.advisor;
    final results = await Future.wait([
      SalesService.getCategoryBreakdown(advisorName: adv.name, isManager: adv.isManager,
        store: adv.store, month: widget.month, year: widget.year),
      SalesService.getMonthlyChart(advisorName: adv.name, isManager: adv.isManager,
        store: adv.store, year: widget.year),
      TrafficService.getTrafficBreakdown(advisorName: adv.name, isManager: adv.isManager,
        store: adv.store, month: widget.month, year: widget.year),
    ]);

    List<Map<String, dynamic>> lb = [];
    if (adv.isManager) {
      lb = await SalesService.getLeaderboard(store: adv.store, month: widget.month, year: widget.year);
    }

    setState(() {
      _categories      = results[0] as Map<String, Map<String, dynamic>>;
      _monthly         = results[1] as List<double>;
      _trafficBreakdown = results[2] as Map<String, int>;
      _leaderboard     = lb;
      _loading         = false;
    });
  }

  String _fmt(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final adv = widget.advisor;
    final sortedCats = _categories.entries.toList()
      ..sort((a, b) => (b.value['net'] as double).compareTo(a.value['net'] as double));
    final totalNet = sortedCats.fold<double>(0, (s, e) => s + (e.value['net'] as double));
    final totalQty = sortedCats.fold<int>(0, (s, e) => s + (e.value['qty'] as int));
    final ytd = _monthly.fold<double>(0, (s, v) => s + v);
    final bestMonthIdx = _monthly.indexWhere((v) => v == _monthly.reduce((a, b) => a > b ? a : b));
    final avgMonthly = _monthly.where((v) => v > 0).isEmpty ? 0.0
        : _monthly.where((v) => v > 0).fold<double>(0, (s, v) => s + v) / _monthly.where((v) => v > 0).length;

    return _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // ── LEADERBOARD (manager only) ──
                if (adv.isManager && _leaderboard.isNotEmpty) ...[
                  _SectionLabel('📊 STAFF LEADERBOARD'),
                  const SizedBox(height: 8),
                  _Card(child: Column(
                    children: _leaderboard.take(10).toList().asMap().entries.map((e) {
                      final rank = e.key + 1;
                      final item = e.value;
                      final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        child: Row(children: [
                          SizedBox(width: 30, child: Text(medal,
                            style: const TextStyle(fontSize: 16), textAlign: TextAlign.center)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(item['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                          Text('IDR ${_fmt(item['net'] as double)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                              color: Color(0xFF2563EB))),
                        ]),
                      );
                    }).toList(),
                  )),
                  const SizedBox(height: 16),
                ],

                // ── CATEGORY BREAKDOWN ──
                _SectionLabel('PENJUALAN PER MAIN CATEGORY (BULAN INI)'),
                const SizedBox(height: 8),
                _Card(child: Column(children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                    child: Row(children: const [
                      Expanded(child: Text('KATEGORI', style: TextStyle(fontSize: 9,
                        fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1))),
                      SizedBox(width: 40, child: Text('QTY', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                          color: Color(0xFF94A3B8), letterSpacing: 1))),
                      SizedBox(width: 80, child: Text('NET SALES', textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                          color: Color(0xFF94A3B8), letterSpacing: 1))),
                    ]),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ...sortedCats.map((e) {
                    final pct = totalNet > 0 ? (e.value['net'] as double) / totalNet : 0.0;
                    return Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        child: Column(children: [
                          Row(children: [
                            Expanded(child: Text(e.key,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                            SizedBox(width: 40, child: Text('${e.value['qty']}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                            SizedBox(width: 80, child: Text(_fmt(e.value['net'] as double),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                          ]),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct, minHeight: 4,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB))),
                          ),
                        ]),
                      ),
                      const Divider(height: 1, color: Color(0xFFF8FAFC)),
                    ]);
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Row(children: [
                      const Expanded(child: Text('TOTAL', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w900))),
                      SizedBox(width: 40, child: Text('$totalQty', textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))),
                      SizedBox(width: 80, child: Text(_fmt(totalNet), textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900,
                          color: Color(0xFF2563EB)))),
                    ]),
                  ),
                ])),
                const SizedBox(height: 16),

                // ── TRAFFIC BREAKDOWN ──
                if (_trafficBreakdown.isNotEmpty) ...[
                  _SectionLabel('LAPORAN TRAFFIC CRM (BULAN INI)'),
                  const SizedBox(height: 8),
                  _Card(child: Column(
                    children: _trafficBreakdown.entries.map((e) {
                      final total = _trafficBreakdown.values.fold<int>(0, (s, v) => s + v);
                      final pct = total > 0 ? e.value / total : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Text('${e.value}', style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            ]),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct, minHeight: 4,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: const AlwaysStoppedAnimation(Color(0xFF7C3AED))),
                            ),
                          ])),
                        ]),
                      );
                    }).toList(),
                  )),
                  const SizedBox(height: 16),
                ],

                // ── MONTHLY CHART ──
                _MonthlyChart(monthly: _monthly, currentMonth: widget.month, year: widget.year),
                const SizedBox(height: 16),

                // ── ANNUAL SUMMARY ──
                _SectionLabel('RINGKASAN TAHUNAN'),
                const SizedBox(height: 8),
                _Card(child: Column(children: [
                  _SummaryRow('YTD Total', 'IDR ${_fmt(ytd)}'),
                  _SummaryRow('Bulan Terbaik',
                    bestMonthIdx >= 0 ? '${_mNamesFull[bestMonthIdx]} (IDR ${_fmt(_monthly[bestMonthIdx])})' : '—'),
                  _SummaryRow('Rata-rata Bulanan', 'IDR ${_fmt(avgMonthly)}', isLast: true),
                ])),
              ],
            ),
          );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(
    fontSize: 10, fontWeight: FontWeight.w900,
    color: Color(0xFF94A3B8), letterSpacing: 1));
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
    ),
    child: child,
  );
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool isLast;
  const _SummaryRow(this.label, this.value, {this.isLast = false});

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B))),
      ]),
    ),
    if (!isLast) const Divider(height: 1, color: Color(0xFFF1F5F9)),
  ]);
}

class _MonthlyChart extends StatefulWidget {
  final List<double> monthly;
  final int currentMonth;
  final int year;
  const _MonthlyChart({required this.monthly, required this.currentMonth, required this.year});

  @override
  State<_MonthlyChart> createState() => _MonthlyChartState();
}

class _MonthlyChartState extends State<_MonthlyChart> {
  int? _touchedIndex;
  static const _mNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  String _fmtAxis(double m) {
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(0)}B';
    if (m >= 1)    return '${m.toStringAsFixed(0)}M';
    return '';
  }

  String _fmtTip(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = widget.monthly.fold(0.0, (a, b) => a > b ? a : b);
    final maxY    = maxVal > 0 ? ((maxVal / 1e6) * 1.3).ceilToDouble() : 100.0;
    final interval = (maxY / 4).ceilToDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(left: 4),
          child: Text('NET SALES PER BULAN (${widget.year})',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8), letterSpacing: 1))),
        const SizedBox(height: 14),
        SizedBox(height: 190, child: BarChart(BarChartData(
          maxY: maxY,
          gridData: FlGridData(show: true, drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1E293B),
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${_mNames[group.x]}\nIDR ${_fmtTip(widget.monthly[group.x])}',
                const TextStyle(color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.w600, height: 1.5)),
            ),
            touchCallback: (event, response) => setState(() {
              _touchedIndex = response?.spot == null ? null
                  : response!.spot!.touchedBarGroupIndex;
            }),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 40, interval: interval,
              getTitlesWidget: (v, _) => v == 0 ? const SizedBox() : Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(_fmtAxis(v),
                  style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                  textAlign: TextAlign.right)),
            )),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 22,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                final active = i == widget.currentMonth - 1;
                return Padding(padding: const EdgeInsets.only(top: 4),
                  child: Text(_mNames[i], style: TextStyle(fontSize: 9,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w400,
                    color: active ? AppTheme.primary : const Color(0xFF94A3B8))));
              },
            )),
          ),
          barGroups: List.generate(12, (i) {
            final active  = i == widget.currentMonth - 1;
            final touched = i == _touchedIndex;
            return BarChartGroupData(x: i, barRods: [BarChartRodData(
              toY: widget.monthly[i] / 1e6,
              width: touched ? 18 : 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              color: active ? AppTheme.primary
                  : touched ? AppTheme.secondary : const Color(0xFFE0E7FF),
              backDrawRodData: BackgroundBarChartRodData(
                show: true, toY: maxY, color: const Color(0xFFF8FAFC)),
            )]);
          }),
        ))),
      ]),
    );
  }
}
