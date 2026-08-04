import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'api_service.dart';

class SyncResult {
  final bool success;
  final int rawInserted;
  final int normalizedInserted;
  final int skippedDuplicates;
  final String? error;

  SyncResult({
    required this.success,
    this.rawInserted = 0,
    this.normalizedInserted = 0,
    this.skippedDuplicates = 0,
    this.error,
  });
}

/// SyncService — Trigger full ETL via /api/mobile/sync (Vercel).
/// Flow: POST → Vercel fetches Bvlgari API → inserts bvlgari_sales + clean_master
class SyncService {
  static Future<SyncResult> syncSalesData(
    int month,
    int year, {
    String? location,
    void Function(String status)? onProgress,
  }) async {
    try {
      onProgress?.call('Menghubungkan ke server...');

      final headers = await ApiService.getHeaders();
      final body = <String, dynamic>{'month': month, 'year': year};
      if (location != null && location.isNotEmpty) body['location'] = location;

      onProgress?.call('Mengirim permintaan sync $month/$year...');

      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/sync'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60));

      onProgress?.call('Memproses respons server...');

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final success = json['success'] as bool? ?? false;

        if (success) {
          final inserted    = (json['inserted']    as num?)?.toInt() ?? 0;
          final totalFetched = (json['totalFetched'] as num?)?.toInt() ?? 0;
          final skipped     = (json['skipped']     as num?)?.toInt() ?? 0;

          onProgress?.call(
            'Selesai — $inserted baris baru · $skipped duplikat dilewati · $totalFetched total data',
          );

          return SyncResult(
            success: true,
            rawInserted: totalFetched,
            normalizedInserted: inserted,
            skippedDuplicates: skipped,
          );
        } else {
          final msg = json['error']?.toString() ?? 'Sync gagal';
          onProgress?.call('Gagal: $msg');
          return SyncResult(success: false, error: msg);
        }
      } else {
        final msg = 'HTTP ${res.statusCode}: ${res.reasonPhrase}';
        debugPrint('SyncService error: $msg\nBody: ${res.body}');
        onProgress?.call('Gagal: $msg');
        return SyncResult(success: false, error: msg);
      }
    } catch (e) {
      debugPrint('SyncService exception: $e');
      onProgress?.call('Error: $e');
      return SyncResult(success: false, error: e.toString());
    }
  }
}
