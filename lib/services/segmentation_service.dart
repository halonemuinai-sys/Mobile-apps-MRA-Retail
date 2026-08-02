import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_segment.dart';
import 'api_service.dart';

class _CollData {
  double value;
  int qty;
  _CollData(this.value, this.qty);
}

class SegmentationService {
  static final _sb = Supabase.instance.client;

  /// Fetch segment counts for the segment badge filters via Proxmox API with fallback
  static Future<Map<String, int>> getSegmentCounts() async {
    final apiData = await ApiService.getSegmentation();
    if (apiData != null && apiData['segmentCounts'] != null) {
      final raw = apiData['segmentCounts'] as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(k, (v as num).toInt()));
    }

    // Fallback
    final res = await _sb.from('view_customer_segmentation').select('segment');
    final Map<String, int> counts = {
      'Top': 0,
      'Elite': 0,
      'High Potential': 0,
      'Potential': 0,
      'Prospect': 0,
      'Inactive': 0,
    };
    for (var r in res as List) {
      final seg = r['segment'] as String?;
      if (seg != null && counts.containsKey(seg)) {
        counts[seg] = counts[seg]! + 1;
      }
    }
    return counts;
  }

  /// Fetch paginated customer profiles with filtering and search
  static Future<List<CustomerSegmentProfile>> getCustomers({
    required int page,
    int pageSize = 20,
    String search = '',
    String? segmentFilter,
  }) async {
    final apiData = await ApiService.getSegmentation(
      search: search,
      segment: segmentFilter ?? '',
      page: page + 1,
    );

    if (apiData != null && apiData['customers'] != null) {
      final list = apiData['customers'] as List;
      return list
          .map((r) => CustomerSegmentProfile.fromMap(r as Map<String, dynamic>))
          .toList();
    }

    // Fallback
    final from = page * pageSize;
    final to = from + pageSize - 1;

    var query = _sb.from('view_customer_segmentation').select();

    if (search.isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }
    if (segmentFilter != null && segmentFilter.isNotEmpty) {
      query = query.eq('segment', segmentFilter);
    }

    final res = await query.order('ltv', ascending: false).range(from, to);
    return (res as List)
        .map((r) => CustomerSegmentProfile.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Helper to check if a customer name represents a group/PT
  static bool _isGroup(String name) {
    final l = name.toLowerCase();
    return l.startsWith('pt ') ||
        l.startsWith('pt.') ||
        l.contains(' group') ||
        l.contains('indonesia') ||
        l.contains('holding') ||
        l.contains('corporation') ||
        l.contains('corp');
  }

  /// Fetch overall KPIs for the dashboard banner (Active Customers, Avg LTV, Top Spender, New Ratio)
  static Future<Map<String, dynamic>> getSegmentationKPIs({int? year}) async {
    final apiData = await ApiService.getSegmentation();
    if (apiData != null && apiData['kpis'] != null) {
      final kpis = apiData['kpis'] as Map<String, dynamic>;
      final topSpender = kpis['topSpender'] as Map<String, dynamic>? ?? {};
      return {
        'activeCustomers': (kpis['activeCustomers'] as num?)?.toInt() ?? 0,
        'avgLtv': (kpis['avgLtv'] as num?)?.toDouble() ?? 0.0,
        'topSpenderName': topSpender['name'] ?? '-',
        'topSpenderLtv': (topSpender['ltv'] as num?)?.toDouble() ?? 0.0,
        'newCustomerRatio': (kpis['newCustomerRatio'] as num?)?.toDouble() ?? 0.0,
      };
    }

    // Fallback
    final res = await _sb
        .from('view_customer_segmentation')
        .select('name, ltv, first_visit')
        .neq('segment', 'Inactive');

    final rows = res as List;
    if (rows.isEmpty) {
      return {
        'activeCustomers': 0,
        'avgLtv': 0.0,
        'topSpenderName': '-',
        'topSpenderLtv': 0.0,
        'newCustomerRatio': 0.0,
      };
    }

    final totalActive = rows.length;
    double totalLtv = 0;
    double topSpenderLtv = 0;
    String topSpenderName = '-';
    int newCustomersCount = 0;
    final now = DateTime.now();

    for (var r in rows) {
      final name = (r['name'] as String? ?? '').trim();
      final ltv = (r['ltv'] as num? ?? 0).toDouble();
      totalLtv += ltv;

      if (!_isGroup(name) && ltv > topSpenderLtv) {
        topSpenderLtv = ltv;
        topSpenderName = name;
      }

      final fvStr = r['first_visit'] as String?;
      if (fvStr != null) {
        final fv = DateTime.tryParse(fvStr);
        if (fv != null && now.difference(fv).inDays <= 90) {
          newCustomersCount++;
        }
      }
    }

    final avgLtv = totalActive > 0 ? totalLtv / totalActive : 0.0;
    final newRatio = totalActive > 0 ? newCustomersCount / totalActive : 0.0;

    return {
      'activeCustomers': totalActive,
      'avgLtv': avgLtv,
      'topSpenderName': topSpenderName,
      'topSpenderLtv': topSpenderLtv,
      'newCustomerRatio': newRatio,
    };
  }

  /// Fetch detail for a single customer profile
  static Future<CustomerSegmentDetail?> getCustomerDetail(String name) async {
    final res = await _sb
        .from('clean_master')
        .select()
        .eq('customer', name)
        .order('transaction_date', ascending: false);

    final rows = res as List;
    if (rows.isEmpty) return null;

    final txs = rows
        .map((r) => SegmentTransaction.fromMap(r as Map<String, dynamic>))
        .toList();

    double totalSpend = 0;
    int totalQty = 0;
    final Map<String, _CollData> collMap = {};

    for (var tx in txs) {
      totalSpend += tx.netSales;
      totalQty += tx.qty;

      final key = tx.collection.isNotEmpty
          ? tx.collection
          : (tx.category.isNotEmpty ? tx.category : 'Other');

      if (collMap.containsKey(key)) {
        collMap[key]!.value += tx.netSales;
        collMap[key]!.qty += tx.qty;
      } else {
        collMap[key] = _CollData(tx.netSales, tx.qty);
      }
    }

    final sortedColls = collMap.entries.toList()
      ..sort((a, b) => b.value.value.compareTo(a.value.value));

    final topCollections = sortedColls
        .take(5)
        .map((e) => CollectionShare(
              name: e.key,
              value: e.value.value,
              qty: e.value.qty,
            ))
        .toList();

    DateTime? firstVisitDt;
    DateTime? lastVisitDt;

    for (var tx in txs) {
      if (tx.date.isNotEmpty) {
        final dt = DateTime.tryParse(tx.date);
        if (dt != null) {
          if (lastVisitDt == null || dt.isAfter(lastVisitDt)) {
            lastVisitDt = dt;
          }
          if (firstVisitDt == null || dt.isBefore(firstVisitDt)) {
            firstVisitDt = dt;
          }
        }
      }
    }

    return CustomerSegmentDetail(
      transactions: txs,
      topCollections: topCollections,
      totalSpend: totalSpend,
      totalQty: totalQty,
      firstVisit: firstVisitDt?.toIso8601String() ?? '',
      lastVisit: lastVisitDt?.toIso8601String() ?? '',
    );
  }
}
