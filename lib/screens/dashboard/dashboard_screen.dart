import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/advisor.dart';
import '../../services/sales_service.dart';

class DashboardScreen extends StatefulWidget {
  final Advisor advisor;
  const DashboardScreen({super.key, required this.advisor});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final now = DateTime.now();
  bool _loading = true;
  double _mtd = 0, _target = 0;
  int _txCount = 0;
  List<double> _monthly = List.filled(12, 0);

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  String _fmtM(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(0)}M';
    return NumberFormat('#,###').format(v);
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
      SalesService.getMtdNetSales(
        advisorName: adv.name, isManager: adv.isManager,
        store: adv.store, month: now.month, year: now.year),
      SalesService.getTarget(
        advisorName: adv.name, isManager: adv.isManager,
        store: adv.store, month: now.month, year: now.year),
      SalesService.getMtdTransactionCount(
        advisorName: adv.name, isManager: adv.isManager,
        store: adv.store, month: now.month, year: now.year).then((v) => v.toDouble()),
      SalesService.getMonthlyChart(
        advisorName: adv.name, isManager: adv.isManager,
        store: adv.store, year: now.year).then((v) => v.fold(0.0, (a, b) => a + b)),
    ]);

    final chart = await SalesService.getMonthlyChart(
      advisorName: adv.name, isManager: adv.isManager,
      store: adv.store, year: now.year);

    setState(() {
      _mtd    = results[0];
      _target = results[1];
      _txCount = results[2].toInt();
      _monthly = chart;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adv = widget.advisor;
    final ach = _target > 0 ? (_mtd / _target) : 0.0;
    final achPct = (ach * 100).clamp(0.0, 999.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E40AF)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A1628), Color(0xFF1E3A5F)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFD4AF37),
                          child: Text(adv.name.isNotEmpty ? adv.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(adv.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(adv.store, style: const TextStyle(color: Color(0xFF8899AA), fontSize: 12)),
                          ],
                        )),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD4AF37), width: 0.5),
                          ),
                          child: Text(adv.isManager ? 'MANAGER' : 'ADVISOR',
                            style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Net Sales KPI
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: const Border(left: BorderSide(color: Color(0xFF1E40AF), width: 4)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(adv.isManager ? 'STORE PERFORMANCE MTD' : 'MY PERFORMANCE MTD',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B), letterSpacing: 1)),
                          Text(_months[now.month - 1] + ' ${now.year}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        ]),
                        const SizedBox(height: 8),
                        Text('IDR ${_fmtM(_mtd)}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        Text('Target: IDR ${_fmtM(_target)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: ach.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation(
                              ach >= 1.0 ? const Color(0xFF059669) : const Color(0xFF1E40AF)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('${achPct.toStringAsFixed(1)}% Achievement',
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold,
                              color: ach >= 1.0 ? const Color(0xFF059669) : const Color(0xFF1E40AF))),
                          Text('$_txCount transaksi',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Monthly Chart
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NET SALES ${0}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B), letterSpacing: 1)),
                        Text('Monthly ${now.year}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B), letterSpacing: 1)),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 160,
                          child: BarChart(BarChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) => Text(_months[v.toInt()],
                                  style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                              )),
                            ),
                            barGroups: List.generate(12, (i) => BarChartGroupData(
                              x: i,
                              barRods: [BarChartRodData(
                                toY: _monthly[i] / 1e6,
                                width: 14,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                color: i == now.month - 1
                                    ? const Color(0xFF1E40AF)
                                    : const Color(0xFFBFDBFE),
                              )],
                            )),
                          )),
                        ),
                        const SizedBox(height: 4),
                        const Center(child: Text('dalam Juta IDR',
                          style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
