import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class ProfileService {
  static final _sb = Supabase.instance.client;

  static Future<List<CrmProfile>> search(String query, {String store = '', String advisor = ''}) async {
    // Build filter string for .or()
    String? orFilter;
    if (query.isNotEmpty) {
      orFilter = 'nama_lengkap.ilike.%$query%,no_hp.ilike.%$query%,nama_panggilan.ilike.%$query%';
    }

    var q = _sb.from('crm_profiling').select();

    // 1. Filter by Advisor (Data Melekat ke Advisor)
    if (advisor.isNotEmpty) {
      q = q.ilike('customer_advisor', '%$advisor%') as dynamic;
    }

    // 2. Filter by Store (Optional)
    if (store.isNotEmpty) {
      final storeKey = store.split(' ').last;
      q = (q as dynamic).ilike('lokasi_store', '%$storeKey%');
    }

    // 3. Search query
    if (orFilter != null) {
      q = q.or(orFilter) as dynamic;
    }

    final res = await (q as dynamic).order('nama_lengkap').limit(30);
    return (res as List).map((r) => CrmProfile.fromMap(r as Map<String, dynamic>)).toList();
  }

  static Future<void> createProfile(Map<String, dynamic> data) async {
    await _sb.from('crm_profiling').insert(data);
  }
}
