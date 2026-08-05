import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/traffic.dart';

class ProspectCounts {
  final int total;
  final int walkIn;
  final int followUp;
  final int delivery;
  final int service;
  final int online;
  final int newProfile;
  const ProspectCounts({
    this.total = 0, this.walkIn = 0, this.followUp = 0,
    this.delivery = 0, this.service = 0, this.online = 0, this.newProfile = 0,
  });
}

class TrafficService {
  static final _sb = Supabase.instance.client;

  static Future<List<TrafficRow>> getProspects({
    required String advisorName,
    required bool isManager,
    required String store,
    required int month,
    required int year,
  }) async {
    String pad(int n) => n.toString().padLeft(2, '0');
    final lastDay = DateTime(year, month + 1, 0).day;
    final from = '$year-${pad(month)}-01';
    final to   = '$year-${pad(month)}-${pad(lastDay)}';

    var q = _sb
        .from('mirror_traffic')
        .select()
        .gte('tanggal_berkunjung', from)
        .lte('tanggal_berkunjung', to);

    if (isManager) {
      if (store != 'All Stores') {
        q = q.ilike('location', '%${store.split(' ').last}%');
      }
    } else {
      // GAS uses served_by (col F) to match advisor, not customer_advisor (col E)
      q = q.eq('served_by', advisorName);
    }

    final res = await q.order('tanggal_berkunjung', ascending: false);
    return (res as List).map((r) => TrafficRow.fromMap(r)).toList();
  }

  static Future<ProspectCounts> getProspectCounts({
    required String advisorName,
    required bool isManager,
    required String store,
    required int month,
    required int year,
  }) async {
    final rows = await getProspects(
      advisorName: advisorName, isManager: isManager,
      store: store, month: month, year: year);

    int walkIn = 0, followUp = 0, delivery = 0, service = 0, online = 0, newProfile = 0;
    for (final r in rows) {
      final s = r.status.toLowerCase();
      if (s.contains('walk')) {
        walkIn++;
      } else if (s.contains('follow')) {
        followUp++;
      } else if (s.contains('delivery') || s.contains('showing')) {
        delivery++;
      } else if (s.contains('repair') || s.contains('service')) {
        service++;
      } else if (s.contains('online')) {
        online++;
      }
      final p = r.prospectItem.toLowerCase();
      if (p.contains('potensial pelanggan baru') || p == 'pelanggan baru') {
        newProfile++;
      }
    }
    return ProspectCounts(
      total: rows.length, walkIn: walkIn, followUp: followUp,
      delivery: delivery, service: service, online: online, newProfile: newProfile,
    );
  }

  // Traffic breakdown by status type for Laporan screen
  static Future<Map<String, int>> getTrafficBreakdown({
    required String advisorName,
    required bool isManager,
    required String store,
    required int month,
    required int year,
  }) async {
    final rows = await getProspects(
      advisorName: advisorName, isManager: isManager,
      store: store, month: month, year: year);
    final map = <String, int>{};
    for (final r in rows) {
      final s = r.status.isEmpty ? 'Lainnya' : r.status;
      map[s] = (map[s] ?? 0) + 1;
    }
    return map;
  }

  static Future<int> saveTraffic(Map<String, dynamic> data) async {
    final res = await _sb
        .from('mirror_traffic')
        .insert(data)
        .select('id')
        .single();
    return (res['id'] as num).toInt();
  }

  static Future<void> saveTrafficItems(int trafficId, List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    await _sb.from('traffic_items').insert(
      items.map((i) => {...i, 'traffic_id': trafficId}).toList(),
    );
  }

  static Future<List<TrafficRow>> getTrafficByCustomer(String name, {String noHp = ''}) async {
    var q = _sb.from('mirror_traffic').select();
    if (noHp.isNotEmpty) {
      q = q.or('customer_name.ilike.%$name%,no_hp.eq.$noHp');
    } else {
      q = q.ilike('customer_name', '%$name%');
    }
    final res = await q.order('tanggal_berkunjung', ascending: false).limit(20);
    return (res as List).map((r) => TrafficRow.fromMap(r)).toList();
  }
}
