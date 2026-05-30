import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';

class SalesService {
  static final _sb = Supabase.instance.client;

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static (String, String) _monthRange(int month, int year) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return ('$year-${_pad(month)}-01', '$year-${_pad(month)}-${_pad(lastDay)}');
  }

  /// Helper: apply store filter. If store == 'All Stores', skip location filter.
  static bool _isAllStores(String store) => store == 'All Stores';

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
      if (!_isAllStores(store)) {
        q = q.ilike('location', '%${store.split(' ').last}%');
      }
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
      var q = _sb
          .from('targets')
          .select('target_value')
          .eq('month_number', month)
          .eq('year', year);
      if (!_isAllStores(store)) {
        q = q.ilike('store_name', '%${store.split(' ').last}%');
      }
      final res = await q;
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
      if (!_isAllStores(store)) {
        q = q.ilike('location', '%${store.split(' ').last}%');
      }
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
      if (!_isAllStores(store)) {
        q = q.ilike('location', '%${store.split(' ').last}%');
      }
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
      if (!_isAllStores(store)) {
        q = q.ilike('location', '%${store.split(' ').last}%');
      }
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

  // Advisor leaderboard (manager only) — with ACH% and VS PREV
  static Future<List<Map<String, dynamic>>> getLeaderboard({
    required String store,
    required int month,
    required int year,
  }) async {
    final (from, to) = _monthRange(month, year);

    // Previous month range
    int pm = month - 1, py = year;
    if (pm < 1) { pm = 12; py = year - 1; }
    final (prevFrom, prevTo) = _monthRange(pm, py);

    // Current month sales by salesman
    var q = _sb
        .from('clean_master')
        .select('salesman,net_sales')
        .gte('transaction_date', from)
        .lte('transaction_date', to)
        .not('location', 'ilike', '%head office%');
    if (!_isAllStores(store)) {
      q = q.ilike('location', '%${store.split(' ').last}%');
    }
    final res = await q;

    final salesMap = <String, double>{};
    for (final r in res as List) {
      final name = (r['salesman'] as String?) ?? '';
      if (name.isEmpty) continue;
      salesMap[name] = (salesMap[name] ?? 0) + ((r['net_sales'] as num?) ?? 0).toDouble();
    }

    if (salesMap.isEmpty) return [];

    // Previous month sales by salesman
    var pq = _sb
        .from('clean_master')
        .select('salesman,net_sales')
        .gte('transaction_date', prevFrom)
        .lte('transaction_date', prevTo)
        .not('location', 'ilike', '%head office%');
    if (!_isAllStores(store)) {
      pq = pq.ilike('location', '%${store.split(' ').last}%');
    }
    final prevRes = await pq;

    final prevMap = <String, double>{};
    for (final r in prevRes as List) {
      final name = (r['salesman'] as String?) ?? '';
      if (name.isEmpty) continue;
      prevMap[name] = (prevMap[name] ?? 0) + ((r['net_sales'] as num?) ?? 0).toDouble();
    }

    // Individual advisor targets
    final targetRes = await _sb
        .from('advisor_targets')
        .select('advisor_name,target_value')
        .eq('month_number', month)
        .eq('year', year);

    final targetMap = <String, double>{};
    for (final r in targetRes as List) {
      final name = (r['advisor_name'] as String?) ?? '';
      targetMap[name] = ((r['target_value'] as num?) ?? 0).toDouble();
    }

    // Build leaderboard entries
    final list = salesMap.entries.map((e) {
      final target = targetMap[e.key] ?? 0;
      final ach = target > 0 ? (e.value / target * 100) : 0.0;
      final prev = prevMap[e.key] ?? 0;
      final growth = prev > 0 ? ((e.value - prev) / prev * 100) : (e.value > 0 ? 100.0 : 0.0);

      return {
        'name': e.key,
        'net': e.value,
        'target': target,
        'ach': ach,
        'prev': prev,
        'growth': growth,
      };
    }).toList();

    list.sort((a, b) => (b['net'] as double).compareTo(a['net'] as double));
    return list;
  }

  // ── STORE COMPARISON (Ops Manager) ──
  // Returns per-store sales, target and achievement for comparison
  static Future<List<Map<String, dynamic>>> getStoreComparison({
    required int month,
    required int year,
  }) async {
    final (from, to) = _monthRange(month, year);

    // Previous month
    int pm = month - 1, py = year;
    if (pm < 1) { pm = 12; py = year - 1; }
    final (prevFrom, prevTo) = _monthRange(pm, py);

    // Fetch all sales for the month (excluding head office)
    final salesRes = await _sb
        .from('clean_master')
        .select('location,net_sales')
        .gte('transaction_date', from)
        .lte('transaction_date', to)
        .not('location', 'ilike', '%head office%');

    // Group by store keyword
    final storeKeys = ['Indonesia', 'Senayan', 'Bali'];
    final storeLabels = {
      'Indonesia': 'Plaza Indonesia',
      'Senayan': 'Plaza Senayan',
      'Bali': 'Bali',
    };

    final salesMap = <String, double>{};
    for (final key in storeKeys) {
      salesMap[key] = 0;
    }
    for (final r in salesRes as List) {
      final loc = (r['location'] as String?) ?? '';
      final net = ((r['net_sales'] as num?) ?? 0).toDouble();
      for (final key in storeKeys) {
        if (loc.toLowerCase().contains(key.toLowerCase())) {
          salesMap[key] = (salesMap[key] ?? 0) + net;
          break;
        }
      }
    }

    // Previous month sales
    final prevRes = await _sb
        .from('clean_master')
        .select('location,net_sales')
        .gte('transaction_date', prevFrom)
        .lte('transaction_date', prevTo)
        .not('location', 'ilike', '%head office%');

    final prevSalesMap = <String, double>{};
    for (final key in storeKeys) {
      prevSalesMap[key] = 0;
    }
    for (final r in prevRes as List) {
      final loc = (r['location'] as String?) ?? '';
      final net = ((r['net_sales'] as num?) ?? 0).toDouble();
      for (final key in storeKeys) {
        if (loc.toLowerCase().contains(key.toLowerCase())) {
          prevSalesMap[key] = (prevSalesMap[key] ?? 0) + net;
          break;
        }
      }
    }

    // Targets per store
    final targetRes = await _sb
        .from('targets')
        .select('store_name,target_value')
        .eq('month_number', month)
        .eq('year', year);

    final targetMap = <String, double>{};
    for (final r in targetRes as List) {
      final storeName = (r['store_name'] as String?) ?? '';
      final val = ((r['target_value'] as num?) ?? 0).toDouble();
      for (final key in storeKeys) {
        if (storeName.toLowerCase().contains(key.toLowerCase())) {
          targetMap[key] = (targetMap[key] ?? 0) + val;
          break;
        }
      }
    }

    // Build result
    final result = <Map<String, dynamic>>[];
    for (final key in storeKeys) {
      final sales = salesMap[key] ?? 0;
      final target = targetMap[key] ?? 0;
      final prev = prevSalesMap[key] ?? 0;
      final ach = target > 0 ? (sales / target * 100) : 0.0;
      final growth = prev > 0 ? ((sales - prev) / prev * 100) : (sales > 0 ? 100.0 : 0.0);

      result.add({
        'key': key,
        'label': storeLabels[key] ?? key,
        'sales': sales,
        'target': target,
        'ach': ach,
        'prev': prev,
        'growth': growth,
      });
    }

    result.sort((a, b) => (b['sales'] as double).compareTo(a['sales'] as double));
    return result;
  }

  // All transactions for an advisor or store (manager)
  static Future<List<Transaction>> getRecentTransactions({
    required String advisorName,
    required int month,
    required int year,
    bool isManager = false,
    String store = '',
  }) async {
    final (from, to) = _monthRange(month, year);
    var q = _sb
        .from('clean_master')
        .select()
        .gte('transaction_date', from)
        .lte('transaction_date', to)
        .not('location', 'ilike', '%head office%');
    if (isManager) {
      if (!_isAllStores(store)) {
        q = q.ilike('location', '%${store.split(' ').last}%');
      }
    } else {
      q = q.eq('salesman', advisorName);
    }
    final res = await q.order('transaction_date', ascending: false);
    return (res as List).map((r) => Transaction.fromMap(r)).toList();
  }

  // Update commission for a transaction
  static Future<void> updateCommission(int id, double value) async {
    await _sb
        .from('clean_master')
        .update({'comm': value})
        .eq('id', id);
  }

  /// Get available stores from advisors table
  static Future<List<String>> getAvailableStores() async {
    final res = await _sb.from('advisors').select('home_location').order('home_location');
    final stores = (res as List)
        .map((r) => (r['home_location'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return stores;
  }

  // MTD QTY sales for an advisor (or whole store if isManager)
  static Future<int> getMtdQtySales({
    required String advisorName,
    required bool isManager,
    required String store,
    required int month,
    required int year,
  }) async {
    final (from, to) = _monthRange(month, year);
    var q = _sb
        .from('clean_master')
        .select('qty')
        .gte('transaction_date', from)
        .lte('transaction_date', to)
        .not('location', 'ilike', '%head office%');
    if (isManager) {
      if (!_isAllStores(store)) {
        q = q.ilike('location', '%${store.split(' ').last}%');
      }
    } else {
      q = q.eq('salesman', advisorName);
    }
    final res = await q;
    return (res as List).fold<int>(0, (sum, r) => sum + ((r['qty'] as num?) ?? 0).toInt());
  }

  // QTY Target for advisor/store in month
  static Future<int> getQtyTarget({
    required String advisorName,
    required bool isManager,
    required String store,
    required int month,
    required int year,
  }) async {
    if (isManager) {
      var q = _sb
          .from('targets')
          .select('target_qty')
          .eq('month_number', month)
          .eq('year', year);
      if (!_isAllStores(store)) {
        q = q.ilike('store_name', '%${store.split(' ').last}%');
      }
      final res = await q;
      return (res as List).fold<int>(0, (s, r) => s + ((r['target_qty'] as num?) ?? 0).toInt());
    } else {
      // Individual advisors don't have QTY targets. Return 0.
      return 0;
    }
  }

  // Monthly QTY chart data — 12 months
  static Future<List<int>> getMonthlyQtyChart({
    required String advisorName,
    required bool isManager,
    required String store,
    required int year,
  }) async {
    var q = _sb
        .from('clean_master')
        .select('transaction_date,qty')
        .gte('transaction_date', '$year-01-01')
        .lte('transaction_date', '$year-12-31')
        .not('location', 'ilike', '%head office%');
    if (isManager) {
      if (!_isAllStores(store)) {
        q = q.ilike('location', '%${store.split(' ').last}%');
      }
    } else {
      q = q.eq('salesman', advisorName);
    }
    final res = await q;
    final monthly = List<int>.filled(12, 0);
    for (final r in res as List) {
      final date = r['transaction_date'] as String?;
      if (date == null) continue;
      final m = int.tryParse(date.split('-')[1]) ?? 0;
      if (m >= 1 && m <= 12) {
        monthly[m - 1] += ((r['qty'] as num?) ?? 0).toInt();
      }
    }
    return monthly;
  }

  // Store QTY comparison for comparison (Ops Manager)
  static Future<List<Map<String, dynamic>>> getStoreComparisonQty({
    required int month,
    required int year,
  }) async {
    final (from, to) = _monthRange(month, year);

    // Previous month
    int pm = month - 1, py = year;
    if (pm < 1) { pm = 12; py = year - 1; }
    final (prevFrom, prevTo) = _monthRange(pm, py);

    // Fetch all QTY for the month (excluding head office)
    final salesRes = await _sb
        .from('clean_master')
        .select('location,qty')
        .gte('transaction_date', from)
        .lte('transaction_date', to)
        .not('location', 'ilike', '%head office%');

    // Group by store keyword
    final storeKeys = ['Indonesia', 'Senayan', 'Bali'];
    final storeLabels = {
      'Indonesia': 'Plaza Indonesia',
      'Senayan': 'Plaza Senayan',
      'Bali': 'Bali',
    };

    final salesMap = <String, int>{};
    for (final key in storeKeys) {
      salesMap[key] = 0;
    }
    for (final r in salesRes as List) {
      final loc = (r['location'] as String?) ?? '';
      final qty = ((r['qty'] as num?) ?? 0).toInt();
      for (final key in storeKeys) {
        if (loc.toLowerCase().contains(key.toLowerCase())) {
          salesMap[key] = (salesMap[key] ?? 0) + qty;
          break;
        }
      }
    }

    // Previous month QTY
    final prevRes = await _sb
        .from('clean_master')
        .select('location,qty')
        .gte('transaction_date', prevFrom)
        .lte('transaction_date', prevTo)
        .not('location', 'ilike', '%head office%');

    final prevSalesMap = <String, int>{};
    for (final key in storeKeys) {
      prevSalesMap[key] = 0;
    }
    for (final r in prevRes as List) {
      final loc = (r['location'] as String?) ?? '';
      final qty = ((r['qty'] as num?) ?? 0).toInt();
      for (final key in storeKeys) {
        if (loc.toLowerCase().contains(key.toLowerCase())) {
          prevSalesMap[key] = (prevSalesMap[key] ?? 0) + qty;
          break;
        }
      }
    }

    // Targets per store (QTY)
    final targetRes = await _sb
        .from('targets')
        .select('store_name,target_qty')
        .eq('month_number', month)
        .eq('year', year);

    final targetMap = <String, int>{};
    for (final r in targetRes as List) {
      final storeName = (r['store_name'] as String?) ?? '';
      final val = ((r['target_qty'] as num?) ?? 0).toInt();
      for (final key in storeKeys) {
        if (storeName.toLowerCase().contains(key.toLowerCase())) {
          targetMap[key] = (targetMap[key] ?? 0) + val;
          break;
        }
      }
    }

    // Build result
    final result = <Map<String, dynamic>>[];
    for (final key in storeKeys) {
      final sales = (salesMap[key] ?? 0).toDouble();
      final target = (targetMap[key] ?? 0).toDouble();
      final prev = (prevSalesMap[key] ?? 0).toDouble();
      final ach = target > 0 ? (sales / target * 100) : 0.0;
      final growth = prev > 0 ? ((sales - prev) / prev * 100) : (sales > 0 ? 100.0 : 0.0);

      result.add({
        'key': key,
        'label': storeLabels[key] ?? key,
        'sales': sales,
        'target': target,
        'ach': ach,
        'prev': prev,
        'growth': growth,
      });
    }

    result.sort((a, b) => (b['sales'] as double).compareTo(a['sales'] as double));
    return result;
  }
}
