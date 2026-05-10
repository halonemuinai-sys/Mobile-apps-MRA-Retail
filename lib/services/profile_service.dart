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

  static Future<int> getNewProfileCount({
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

    var query = _sb.from('crm_profiling').select('id');

    if (isManager) {
      query = query.ilike('lokasi_store', '%${store.split(' ').last}%');
    } else {
      query = query.eq('customer_advisor', advisorName);
    }

    final res = await query.gte('tanggal_input', from).lte('tanggal_input', to);
    return (res as List).length;
  }
}
