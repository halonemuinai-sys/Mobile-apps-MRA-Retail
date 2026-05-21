import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_segment.dart';

class _CollData {
  double value;
  int qty;
  _CollData(this.value, this.qty);
}

class SegmentationService {
  static final _sb = Supabase.instance.client;

  /// Fetch segment counts for the segment badge filters
  static Future<Map<String, int>> getSegmentCounts() async {
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
    return l.contains('group') || l.contains('corp') || l.contains('company') || l.contains('pt ');
  }

  /// Calculate high-level KPI cards for the segmentation overview
  static Future<Map<String, dynamic>> getSegmentationKPIs({required int year}) async {
    // Fetch ltv and first_visit for all active customers
    final activeRes = await _sb
        .from('view_customer_segmentation')
        .select('name, ltv, first_visit')
        .neq('segment', 'Inactive');
        
    final activeList = activeRes as List;
    final totalActive = activeList.length;

    double sumLtv = 0.0;
    int newCustomersCount = 0;
    
    // Calculate top spender from active list (excluding groups)
    String topSpenderName = '—';
    double topSpenderSpend = 0.0;

    for (var r in activeList) {
      final name = r['name'] as String? ?? '';
      final ltv = ((r['ltv'] as num?) ?? 0).toDouble();
      sumLtv += ltv;

      final firstVisit = r['first_visit'] as String?;
      if (firstVisit != null && firstVisit.startsWith('$year-')) {
        newCustomersCount++;
      }

      if (!_isGroup(name) && ltv > topSpenderSpend) {
        topSpenderName = name;
        topSpenderSpend = ltv;
      }
    }

    final avgLtv = totalActive > 0 ? sumLtv / totalActive : 0.0;
    final newCustomerRatio = totalActive > 0 ? (newCustomersCount / totalActive) * 100 : 0.0;

    return {
      'totalActiveCustomers': totalActive,
      'avgLtv': avgLtv,
      'topSpender': {
        'name': topSpenderName,
        'spend': topSpenderSpend,
      },
      'newCustomerRatio': newCustomerRatio,
    };
  }

  /// Fetch detailed transaction history and insights for a specific customer
  static Future<CustomerSegmentDetail> getCustomerDetail(String name) async {
    final res = await _sb
        .from('clean_master')
        .select('transaction_date, net_sales, qty, trans_no, location, main_category, collection')
        .eq('customer', name)
        .order('transaction_date', ascending: false);

    final rows = res as List;
    final transactions = rows.map((r) => SegmentTransaction.fromMap(r)).toList();

    final Map<String, _CollData> collMap = {};
    double totalSpend = 0.0;
    int totalQty = 0;

    for (var r in rows) {
      final col = ((r['collection'] as String?) ?? 'Uncategorized').trim();
      final collectionName = col.isEmpty ? 'Uncategorized' : col;
      final net = ((r['net_sales'] as num?) ?? 0).toDouble();
      final qty = ((r['qty'] as num?) ?? 0).toInt();

      totalSpend += net;
      totalQty += qty;

      collMap.putIfAbsent(collectionName, () => _CollData(0.0, 0));
      collMap[collectionName]!.value += net;
      collMap[collectionName]!.qty += qty;
    }

    final topCollections = collMap.entries
        .map((e) => CollectionShare(name: e.key, value: e.value.value, qty: e.value.qty))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sortedTransactions = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    final firstVisit = sortedTransactions.isNotEmpty ? sortedTransactions.last.date : '—';
    final lastVisit = sortedTransactions.isNotEmpty ? sortedTransactions.first.date : '—';

    return CustomerSegmentDetail(
      transactions: transactions,
      topCollections: topCollections.take(5).toList(),
      totalSpend: totalSpend,
      totalQty: totalQty,
      firstVisit: firstVisit,
      lastVisit: lastVisit,
    );
  }
}
