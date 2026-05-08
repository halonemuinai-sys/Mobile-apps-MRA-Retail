import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/traffic.dart';

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
}
