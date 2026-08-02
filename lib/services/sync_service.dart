import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
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

/// SyncService — Triggers Server-Side Sync ETL on Proxmox Server
class SyncService {
  static final _sb = Supabase.instance.client;

  /// Main sync function — uses Proxmox Server-Side Sync with fallback
  static Future<SyncResult> syncSalesData(int month, int year, {
    void Function(String status)? onProgress,
  }) async {
    try {
      onProgress?.call('Menghubungkan ke server Proxmox...');
      final apiRes = await ApiService.syncData(month: month, year: year);

      if (apiRes != null && apiRes['success'] == true) {
        onProgress?.call('Sinkronisasi server selesai!');
        return SyncResult(
          success: true,
          rawInserted: apiRes['inserted'] ?? 0,
          normalizedInserted: apiRes['inserted'] ?? 0,
          skippedDuplicates: apiRes['skipped'] ?? 0,
        );
      }

      // Fallback message if API error
      return SyncResult(
        success: false,
        error: apiRes?['error'] ?? 'Gagal menghubungi server Proxmox',
      );
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }
}
