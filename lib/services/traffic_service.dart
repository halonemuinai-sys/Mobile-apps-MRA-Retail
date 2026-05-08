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
    final pad = (int n) => n.toString().padLeft(2, '0');
    final lastDay = DateTime(year, month + 1, 0).day;
    final from = '$year-${pad(month)}-01';
    final to   = '$year-${pad(month)}-${pad(lastDay)}';

    var q = _sb
        .from('mirror_traffic')
        .select()
        .gte('tanggal_berkunjung', from)
        .lte('tanggal_berkunjung', to);

    if (isManager) {
      q = q.ilike('location', '%${store.split(' ').last}%');
    } else {
      q = q.eq('customer_advisor', advisorName);
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
      if (s.contains('walk')) walkIn++;
      else if (s.contains('follow')) followUp++;
      else if (s.contains('delivery') || s.contains('showing')) delivery++;
      else if (s.contains('repair') || s.contains('service')) service++;
      else if (s.contains('online')) online++;
      final p = r.prospectItem.toLowerCase();
      if (p.contains('baru') || p.contains('potensial')) newProfile++;
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
}
