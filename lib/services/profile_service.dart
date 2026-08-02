import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class ProfileService {
  static final _sb = Supabase.instance.client;

  static Future<List<CrmProfile>> search(String query, {String store = '', String advisor = ''}) async {
    // 1. Try Proxmox API Endpoint first
    try {
      final proxmoxUrl = Uri.parse(
        'http://202.6.239.245/api/mobile/segmentation?search=${Uri.encodeComponent(query)}&store=${Uri.encodeComponent(store)}&advisor=${Uri.encodeComponent(advisor)}'
      );
      final res = await http.get(proxmoxUrl).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final list = (json['data']?['customers'] ?? json['customers'] ?? json['data']) as List?;
        if (list != null) {
          return list.map((r) => CrmProfile.fromMap(r as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      print('Proxmox API fetch failed, falling back to Supabase: $e');
    }

    // 2. Fallback to Supabase direct query
    try {
      dynamic q = _sb.from('crm_profiling').select();

      if (advisor.isNotEmpty && advisor != 'All Stores') {
        q = q.ilike('customer_advisor', '%$advisor%');
      }

      if (store.isNotEmpty && store != 'All Stores') {
        final storeKey = store.split(' ').last;
        q = q.ilike('lokasi_store', '%$storeKey%');
      }

      if (query.isNotEmpty) {
        final orFilter = 'nama_lengkap.ilike.%$query%,no_hp.ilike.%$query%,nama_panggilan.ilike.%$query%';
        q = q.or(orFilter);
      }

      final res = await q.order('nama_lengkap').limit(50);
      return (res as List).map((r) => CrmProfile.fromMap(r as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error in ProfileService.search Supabase fallback: $e');
      return [];
    }
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
      if (store != 'All Stores') {
        query = query.ilike('lokasi_store', '%${store.split(' ').last}%');
      }
    } else {
      query = query.eq('customer_advisor', advisorName);
    }

    final res = await query.gte('tanggal_input', from).lte('tanggal_input', to);
    return (res as List).length;
  }
}
