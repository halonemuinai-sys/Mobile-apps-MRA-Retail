import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class ProfileService {
  static final _sb = Supabase.instance.client;

  static Future<List<CrmProfile>> search(String query, {String store = ''}) async {
    // Build filter string for .or() — must include all conditions
    String? orFilter;
    if (query.isNotEmpty) {
      orFilter = 'nama_lengkap.ilike.%$query%,no_hp.ilike.%$query%,nama_panggilan.ilike.%$query%';
    }

    var q = _sb.from('crm_profiling').select();

    if (orFilter != null) q = q.or(orFilter) as dynamic;
    if (store.isNotEmpty) {
      final storeKey = store.split(' ').last;
      q = (q as dynamic).ilike('lokasi_store', '%$storeKey%');
    }

    final res = await (q as dynamic).order('nama_lengkap').limit(30);
    return (res as List).map((r) => CrmProfile.fromMap(r as Map<String, dynamic>)).toList();
  }
}
