import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';

class SalesService {
  static final _sb = Supabase.instance.client;

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static (String, String) _monthRange(int month, int year) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return ('$year-${_pad(month)}-01', '$year-${_pad(month)}-${_pad(lastDay)}');
  }

  // MTD net sales for an advisor (or whole store if isManager)
  static Future<double> getMtdNetSales({
    required String advisorName,
    required bool isManager,
    required String store,
    required int month,
    required int year,
  }) async {
    final (from, to) = _monthRange(month, year);
    var q = _sb
        .from('clean_master')
        .select('net_sales')
        .gte('transaction_date', from)
        .lte('transaction_date', to)
        .not('location', 'ilike', '%head office%');
    if (isManager) {
      q = q.ilike('location', '%${store.split(' ').last}%');
    } else {
      q = q.eq('salesman', advisorName);
    }
    final res = await q;
    return (res as List).fold<double>(0.0, (sum, r) => sum + ((r['net_sales'] as num?) ?? 0).toDouble());
  }

  // Target for advisor/store in month
  static Future<double> getTarget({
    required String advisorName,
    required bool isManager,
    required String store,
    required int month,
    required int year,
  }) async {
    if (isManager) {
      final res = await _sb
          .from('targets')
          .select('target_value')
          .eq('month_number', month)
          .eq('year', year)
          .ilike('store_name', '%${store.split(' ').last}%');
      return (res as List).fold<double>(0.0, (s, r) => s + ((r['target_value'] as num?) ?? 0).toDouble());
    } else {
      final res = await _sb
          .from('advisor_targets')
          .select('target_value')
          .eq('advisor_name', advisorName)
          .eq('month_number', month)
          .eq('year', year)
          .maybeSingle();
      return ((res?['target_value'] as num?) ?? 0).toDouble();
    }
  }

  // Transaction count MTD
  static Future<int> getMtdTransactionCount({
    required String advisorName,
    required bool isManager,
    required String store,
    required int month,
    required int year,
  }) async {
    final (from, to) = _monthRange(month, year);
    var q = _sb
        .from('clean_master')
        .select('trans_no')
        .gte('transaction_date', from)
        .lte('transaction_date', to)
        .not('location', 'ilike', '%head office%');
    if (isManager) {
      q = q.ilike('location', '%${store.split(' ').last}%');
    } else {
      q = q.eq('salesman', advisorName);
    }
    final res = await q;
    final transList = res as List;
    final unique = <String>{};
    for (final r in transList) {
      final t = r['trans_no'] as String?;
      if (t != null && t.isNotEmpty) unique.add(t);
    }
    return unique.length;
  }

  // Monthly chart data — 12 months
  static Future<List<double>> getMonthlyChart({
    required String advisorName,
    required bool isManager,
    required String store,
    required int year,
  }) async {
    var q = _sb
        .from('clean_master')
        .select('transaction_date,net_sales')
        .gte('transaction_date', '$year-01-01')
        .lte('transaction_date', '$year-12-31')
        .not('location', 'ilike', '%head office%');
    if (isManager) {
      q = q.ilike('location', '%${store.split(' ').last}%');
    } else {
      q = q.eq('salesman', advisorName);
    }
    final res = await q;
    final monthly = List<double>.filled(12, 0);
    for (final r in res as List) {
      final date = r['transaction_date'] as String?;
      if (date == null) continue;
      final m = int.tryParse(date.split('-')[1]) ?? 0;
      if (m >= 1 && m <= 12) {
        monthly[m - 1] += ((r['net_sales'] as num?) ?? 0).toDouble();
      }
    }
    return monthly;
  }

  // Category breakdown
  static Future<Map<String, Map<String, dynamic>>> getCategoryBreakdown({
    required String advisorName,
    required bool isManager,
    required String store,
    required int month,
    required int year,
  }) async {
    final (from, to) = _monthRange(month, year);
    var q = _sb
        .from('clean_master')
        .select('main_category,net_sales,qty')
        .gte('transaction_date', from)
        .lte('transaction_date', to)
        .not('location', 'ilike', '%head office%');
    if (isManager) {
      q = q.ilike('location', '%${store.split(' ').last}%');
    } else {
      q = q.eq('salesman', advisorName);
    }
    final res = await q;
    final map = <String, Map<String, dynamic>>{};
    for (final r in res as List) {
      final cat = (r['main_category'] as String?) ?? 'Unknown';
      map.putIfAbsent(cat, () => {'net': 0.0, 'qty': 0});
      map[cat]!['net'] = (map[cat]!['net'] as double) + ((r['net_sales'] as num?) ?? 0).toDouble();
      map[cat]!['qty'] = (map[cat]!['qty'] as int) + ((r['qty'] as num?) ?? 0).toInt();
    }
    return map;
  }

  // Advisor leaderboard (manager only)
  static Future<List<Map<String, dynamic>>> getLeaderboard({
    required String store,
    required int month,
    required int year,
  }) async {
    final (from, to) = _monthRange(month, year);
    final res = await _sb
        .from('clean_master')
        .select('salesman,net_sales')
        .gte('transaction_date', from)
        .lte('transaction_date', to)
        .ilike('location', '%${store.split(' ').last}%')
        .not('location', 'ilike', '%head office%');

    final map = <String, double>{};
    for (final r in res as List) {
      final name = (r['salesman'] as String?) ?? '';
      if (name.isEmpty) continue;
      map[name] = (map[name] ?? 0) + ((r['net_sales'] as num?) ?? 0).toDouble();
    }
    final list = map.entries.map((e) => {'name': e.key, 'net': e.value}).toList();
    list.sort((a, b) => (b['net'] as double).compareTo(a['net'] as double));
    return list;
  }

  // All transactions for an advisor (recent 50)
  static Future<List<Transaction>> getRecentTransactions({
    required String advisorName,
    required int month,
    required int year,
  }) async {
    final (from, to) = _monthRange(month, year);
    final res = await _sb
        .from('clean_master')
        .select()
        .eq('salesman', advisorName)
        .gte('transaction_date', from)
        .lte('transaction_date', to)
        .order('transaction_date', ascending: false)
        .limit(50);
    return (res as List).map((r) => Transaction.fromMap(r)).toList();
  }
}
