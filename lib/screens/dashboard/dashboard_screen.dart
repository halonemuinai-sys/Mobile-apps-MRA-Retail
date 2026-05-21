import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/advisor.dart';
import '../../services/sales_service.dart';
import '../../services/traffic_service.dart';
import '../reports/transaction_list_screen.dart';
import '../../theme.dart';
import '../../widgets/fade_in_slide.dart';
import '../../widgets/hover_card.dart';

class DashboardScreen extends StatefulWidget {
  final Advisor advisor;
  final int month;
  final int year;
  final VoidCallback onNavProspect;
  final VoidCallback onNavLaporan;
  const DashboardScreen({
    super.key, required this.advisor,
    required this.month, required this.year,
    required this.onNavProspect, required this.onNavLaporan,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  static const kDark = AppTheme.dark;
  static const kBlue = AppTheme.primary;

  bool _loading = true;
  double _mtd = 0, _target = 0, _prevMtd = 0;
  int _txCount = 0;
  int _prospectCount = 0, _followUpCount = 0;
  List<double> _monthly = List.filled(12, 0);
  List<Map<String, dynamic>> _storeComparison = [];

  static const _mNamesFull = ['January','February','March','April','May','June',
    'July','August','September','October','November','December'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen old) {
    super.didUpdateWidget(old);
    if (old.month != widget.month || old.year != widget.year || old.advisor.store != widget.advisor.store) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final adv = widget.advisor;
    final m = widget.month;
    final y = widget.year;

    // Previous month
    int pm = m - 1, py = y;
    if (pm < 1) { pm = 12; py = y - 1; }

    final results = await Future.wait([
      SalesService.getMtdNetSales(advisorName: adv.name, isManager: adv.isManager, store: adv.store, month: m, year: y),
      SalesService.getTarget(advisorName: adv.name, isManager: adv.isManager, store: adv.store, month: m, year: y),
      SalesService.getMtdNetSales(advisorName: adv.name, isManager: adv.isManager, store: adv.store, month: pm, year: py),
      SalesService.getMtdTransactionCount(advisorName: adv.name, isManager: adv.isManager, store: adv.store, month: m, year: y).then((v) => v.toDouble()),
      SalesService.getMonthlyChart(advisorName: adv.name, isManager: adv.isManager, store: adv.store, year: y).then((_) => 0.0),
      TrafficService.getProspectCounts(advisorName: adv.name, isManager: adv.isManager, store: adv.store, month: m, year: y).then((_) => 0.0),
    ]);

    final chart = await SalesService.getMonthlyChart(advisorName: adv.name, isManager: adv.isManager, store: adv.store, year: y);
    final counts = await TrafficService.getProspectCounts(advisorName: adv.name, isManager: adv.isManager, store: adv.store, month: m, year: y);

    // Load store comparison if OpsManager viewing All Stores
    List<Map<String, dynamic>> storeComp = [];
    if (adv.isOpsManager && adv.store == 'All Stores') {
      storeComp = await SalesService.getStoreComparison(month: m, year: y);
    }

    setState(() {
      _mtd        = results[0];
      _target     = results[1];
      _prevMtd    = results[2];
      _txCount    = results[3].toInt();
      _monthly    = chart;
      _prospectCount  = counts.total;
      _followUpCount  = counts.followUp;
      _storeComparison = storeComp;
      _loading    = false;
    });
  }

  String _fmt(double v) {
    return NumberFormat('#,###', 'id_ID').format(v.toInt());
  }

  @override
  Widget build(BuildContext context) {
    final adv = widget.advisor;
    final ach = _target > 0 ? (_mtd / _target) : 0.0;
    final achPct = (ach * 100).clamp(0.0, 999.0);
    final growth = _prevMtd > 0 ? ((_mtd - _prevMtd) / _prevMtd * 100) : (_mtd > 0 ? 100.0 : 0.0);
    final remaining = (_target - _mtd).clamp(0, double.infinity);

    return _loading
        ? const Center(child: CircularProgressIndicator(color: kBlue))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // ── MY PERFORMANCE CARD ──
                FadeInSlide(
                  delay: Duration.zero,
                  child: HoverCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 20,
                    child: Stack(children: [
                      Positioned(right: -24, top: -24, child: Container(
                        width: 112, height: 112,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primary.withValues(alpha: 0.12), AppTheme.secondary.withValues(alpha: 0.06)],
                          ),
                          shape: BoxShape.circle),
                      )),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(
                            adv.isOpsManager && adv.store == 'All Stores'
                              ? 'REGIONAL PERFORMANCE (MTD)'
                              : adv.isManager ? 'STORE PERFORMANCE (MTD)' : 'MY PERFORMANCE (MTD)',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                              color: AppTheme.primary, letterSpacing: 1.5),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_mNamesFull[widget.month - 1]} ${widget.year}',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF93C5FD)),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('IDR ${_fmt(_mtd)}',
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold,
                              color: kDark, letterSpacing: -0.5)),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text('Net Sales', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                          ),
                        ]),
  
                        // Growth badge
                        if (_prevMtd > 0 || _mtd > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: growth >= 0 ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${growth >= 0 ? '▲' : '▼'} ${growth.abs().toStringAsFixed(1)}% vs bulan lalu',
                              style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold,
                                color: growth >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
  
                        // Achievement bar
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Target Achievement',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          Text('${achPct.toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                              color: ach >= 1.0 ? const Color(0xFF16A34A) : kBlue)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: ach.clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation(
                              ach >= 1.0 ? const Color(0xFF16A34A) : kBlue),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Target: IDR ${_fmt(_target)}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                          Text('Sisa: IDR ${_fmt(remaining.toDouble())}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        ]),
                      ]),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                // ── QUICK STATS ──
                FadeInSlide(
                  delay: const Duration(milliseconds: 100),
                  child: Row(children: [
                    _StatCard('$_txCount',    'TRANSAKSI',  kDark, Icons.receipt_long_outlined),
                    const SizedBox(width: 10),
                    _StatCard('$_prospectCount',  'PROSPEK',    const Color(0xFF059669), Icons.people_outline),
                    const SizedBox(width: 10),
                    _StatCard('$_followUpCount',   'FOLLOW UP',  const Color(0xFFD97706), Icons.phone_forwarded_outlined),
                  ]),
                ),
                const SizedBox(height: 14),

                // ── STORE COMPARISON (Ops Manager only) ──
                if (adv.isOpsManager && _storeComparison.isNotEmpty) ...[
                  FadeInSlide(
                    delay: const Duration(milliseconds: 200),
                    child: HoverCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 20,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.store_rounded, size: 16, color: Color(0xFF7C3AED)),
                          ),
                          const SizedBox(width: 10),
                          const Text('STORE RANKING', style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w900,
                            color: Color(0xFF94A3B8), letterSpacing: 1)),
                        ]),
                        const SizedBox(height: 14),
                        ..._storeComparison.asMap().entries.map((e) {
                          final idx = e.key;
                          final s = e.value;
                          final sales = s['sales'] as double;
                          final target = s['target'] as double;
                          final ach = s['ach'] as double;
                          final g = s['growth'] as double;
                          final isUp = g >= 0;
                          final medal = idx == 0 ? '🥇' : idx == 1 ? '🥈' : '🥉';
                          final maxSales = _storeComparison.isNotEmpty
                              ? (_storeComparison[0]['sales'] as double)
                              : 1.0;
                          final barPct = maxSales > 0 ? (sales / maxSales) : 0.0;
  
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Text(medal, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(s['label'] as String,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isUp ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    '${isUp ? '▲' : '▼'} ${g.abs().toStringAsFixed(0)}%',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                      color: isUp ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Row(children: [
                                Expanded(child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: barPct.clamp(0.0, 1.0), minHeight: 8,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    valueColor: AlwaysStoppedAnimation(
                                      ach >= 100 ? const Color(0xFF16A34A) : const Color(0xFF7C3AED)),
                                  ),
                                )),
                                const SizedBox(width: 10),
                                Text('${ach.toStringAsFixed(1)}%',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                                    color: ach >= 100 ? const Color(0xFF16A34A) : const Color(0xFF64748B))),
                              ]),
                              const SizedBox(height: 4),
                              Text('IDR ${_fmt(sales)} / ${_fmt(target)}',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                            ]),
                          );
                        }),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── QUICK ACTIONS ──
                FadeInSlide(
                  delay: const Duration(milliseconds: 300),
                  child: Row(children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.people_outline,
                        iconColor: const Color(0xFF0891B2),
                        iconBg: const Color(0xFFECFEFF),
                        label: 'Lihat Prospek',
                        onTap: widget.onNavProspect,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.bar_chart_outlined,
                        iconColor: const Color(0xFF7C3AED),
                        iconBg: const Color(0xFFF5F3FF),
                        label: 'Laporan Saya',
                        onTap: widget.onNavLaporan,
                      ),
                    ),
                    if (widget.advisor.canViewTransactions) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.receipt_long_outlined,
                          iconColor: const Color(0xFFEA580C),
                          iconBg: const Color(0xFFFFF7ED),
                          label: 'Transaksi',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionListScreen(
                                  advisor: widget.advisor,
                                  month: widget.month,
                                  year: widget.year,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(height: 14),
  
                // ── MONTHLY CHART ──
                FadeInSlide(
                  delay: const Duration(milliseconds: 400),
                  child: _MonthlyChart(monthly: _monthly, currentMonth: widget.month, year: widget.year),
                ),
              ],
            ),
          );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final Color color;
  final IconData icon;
  const _StatCard(this.value, this.label, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: HoverCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w800, letterSpacing: 0.8), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.iconColor,
    required this.iconBg, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      onTap: onTap,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Column(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
          color: Color(0xFF475569))),
      ]),
    );
  }
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

  String _fmtTooltip(double v) {
    return NumberFormat('#,###', 'id_ID').format(v.toInt());
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = widget.monthly.fold(0.0, (a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? ((maxVal / 1e6) * 1.3).ceilToDouble() : 100.0;
    final interval = (maxY / 4).ceilToDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('NET SALES PER BULAN (${widget.year})',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8), letterSpacing: 1)),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 190,
          child: BarChart(BarChartData(
            maxY: maxY,
            gridData: FlGridData(
              show: true, drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (_) =>
                const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF1E293B),
                tooltipRoundedRadius: 8,
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                  '${_mNames[group.x]}\nIDR ${_fmtTooltip(widget.monthly[group.x])}',
                  const TextStyle(color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.w600, height: 1.5),
                ),
              ),
              touchCallback: (event, response) => setState(() {
                _touchedIndex = (response?.spot == null) ? null
                    : response!.spot!.touchedBarGroupIndex;
              }),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: interval,
                  getTitlesWidget: (v, _) => v == 0 ? const SizedBox() : Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(_fmtAxis(v),
                      style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                      textAlign: TextAlign.right)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, reservedSize: 22,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    final active = i == widget.currentMonth - 1;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_mNames[i], style: TextStyle(
                        fontSize: 9,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w400,
                        color: active ? AppTheme.primary : const Color(0xFF94A3B8))));
                  },
                ),
              ),
            ),
            barGroups: List.generate(12, (i) {
              final active   = i == widget.currentMonth - 1;
              final touched  = i == _touchedIndex;
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: widget.monthly[i] / 1e6,
                  width: touched ? 18 : 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  color: active
                      ? AppTheme.primary
                      : touched ? AppTheme.secondary : const Color(0xFFE0E7FF),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true, toY: maxY, color: const Color(0xFFF8FAFC)),
                ),
              ]);
            }),
          )),
        ),
      ]),
    );
  }
}
