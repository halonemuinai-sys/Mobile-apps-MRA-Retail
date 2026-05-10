import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Porting dari syncService.ts (Next.js Dashboard)
/// Flow: API Bvlgari → Vercel Proxy → bvlgari_sales (raw) → clean_master (normalized)
class SyncService {
  static final _sb = Supabase.instance.client;
  static const _proxyBase = 'https://dashboard-bvl-next.vercel.app/api/sync-sales';

  /// Main sync function — mirrors syncSalesData() from syncService.ts
  static Future<SyncResult> syncSalesData(int month, int year, {
    void Function(String status)? onProgress,
  }) async {
    try {
      String pad(int n) => n.toString().padLeft(2, '0');
      final lastDay = DateTime(year, month + 1, 0).day;
      final startDate = '$year-${pad(month)}-01';
      final endDate = '$year-${pad(month)}-${pad(lastDay)}';

      // 1. Load master data (categories & collections)
      onProgress?.call('Memuat master data...');
      final masterResults = await Future.wait([
        _sb.from('master_main_category').select(),
        _sb.from('master_collection').select(),
      ]);

      final catMap = <String, String>{};
      for (final r in (masterResults[0] as List)) {
        catMap[(r['code'] as String? ?? '').trim().toUpperCase()] = r['description'] as String? ?? '';
      }

      final collMap = <String, String>{};
      for (final r in (masterResults[1] as List)) {
        collMap[(r['code'] as String? ?? '').trim().toUpperCase()] = r['description'] as String? ?? '';
      }

      // 2. Fetch data from Vercel proxy
      onProgress?.call('Mengambil data dari API Bvlgari...');
      final url = '$_proxyBase?startdate=${Uri.encodeComponent(startDate)}&enddate=${Uri.encodeComponent(endDate)}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return SyncResult(success: false, error: 'API Error: HTTP ${response.statusCode}');
      }

      final apiData = jsonDecode(response.body);
      if (apiData is! List || apiData.isEmpty) {
        return SyncResult(success: true, rawInserted: 0, normalizedInserted: 0, skippedDuplicates: 0);
      }

      // 3. Check existing transactions (deduplication)
      onProgress?.call('Memeriksa duplikat...');
      final existingRaw = await _sb
          .from('bvlgari_sales')
          .select('transaction_no')
          .gte('transaction_date', startDate)
          .lte('transaction_date', endDate);

      final existingTxSet = <String>{};
      for (final r in (existingRaw as List)) {
        existingTxSet.add(r['transaction_no'] as String? ?? '');
      }

      // 4. Process & Calculate Net Sales (porting from GAS)
      final rawRows = <Map<String, dynamic>>[];
      int skipped = 0;

      for (final itm in apiData) {
        final txNo = itm['transactionNo'] as String? ?? '';
        if (existingTxSet.contains(txNo)) {
          skipped++;
          continue;
        }

        final qtyRaw = int.tryParse('${itm['qty']}') ?? 0;
        final qtyForCalc = (qtyRaw == 0) ? 1 : qtyRaw;
        final unitPrice = double.tryParse('${itm['price']}') ?? 0;
        final gross = qtyForCalc * unitPrice;
        final discount = double.tryParse('${itm['subTotalDiscount']}') ?? 0;
        var taxAmount = double.tryParse('${itm['subTotaltax'] ?? itm['subTotalTax']}') ?? 0;
        final taxRate = double.tryParse('${itm['tax']}') ?? 0;
        final collCode = (itm['collectionCode'] as String? ?? '').toUpperCase();
        final grossAfterDiscount = gross - discount;

        // Logic PFM Tax (GAS line 67-73)
        if (taxAmount == 0 && (collCode == 'PFM' || taxRate > 1)) {
          final divisor = taxRate > 1 ? taxRate : 1.11;
          final calculatedNet = grossAfterDiscount / divisor;
          taxAmount = grossAfterDiscount - calculatedNet;
        }

        final netSales = grossAfterDiscount - taxAmount;

        rawRows.add({
          'transaction_date': itm['transactionDate'],
          'transaction_time': itm['transactionTime'],
          'salesman': itm['salesman'],
          'customer_name': itm['customerName'],
          'phone_no': itm['phoneNo'],
          'transaction_no': txNo,
          'location': itm['location'],
          'sap_code': itm['sapCode'],
          'catalogue_code': itm['catalogueCode'],
          'description': itm['description'],
          'collection': itm['collectionCode'],
          'qty': qtyForCalc,
          'price': unitPrice,
          'sub_total_discount': discount,
          'sub_total_tax': taxAmount,
          'net_sales': netSales,
        });
      }

      if (rawRows.isEmpty) {
        return SyncResult(success: true, rawInserted: 0, normalizedInserted: 0, skippedDuplicates: skipped);
      }

      // 5. Insert to bvlgari_sales (raw data) — in batches of 500
      onProgress?.call('Menyimpan ${rawRows.length} baris ke bvlgari_sales...');
      int rawInserted = 0;
      for (int i = 0; i < rawRows.length; i += 500) {
        final batch = rawRows.sublist(i, (i + 500).clamp(0, rawRows.length));
        await _sb.from('bvlgari_sales').insert(batch);
        rawInserted += batch.length;
      }

      // 6. Normalize to clean_master
      onProgress?.call('Normalisasi ke clean_master...');
      const excludedCollections = ['DPS', 'SVC', 'PACK'];

      final normalizedRows = <Map<String, dynamic>>[];
      for (final row in rawRows) {
        final loc = ((row['location'] as String?) ?? '').toUpperCase();
        if (loc.contains('RB')) continue;

        final collCode = ((row['collection'] as String?) ?? '').toUpperCase();
        if (excludedCollections.any((ex) => collCode.contains(ex))) continue;

        // Comma-split mapping
        final codes = collCode.split(',').map((s) => s.trim().toUpperCase()).toList();
        final mainCat = catMap[codes[0]] ?? 'Other';
        final collName = collMap[codes.last] ?? 'Unknown';

        final grossSales = (row['qty'] as int) * (row['price'] as double);
        final valDisc = row['sub_total_discount'] as double;
        final discPct = grossSales > 0 ? valDisc / grossSales : 0.0;
        final netPrice = grossSales - valDisc;
        const comm = 0.0;
        final cost = valDisc + comm;

        normalizedRows.add({
          'transaction_date': row['transaction_date'],
          'location': row['location'],
          'salesman': row['salesman'],
          'customer': row['customer_name'],
          'trans_no': row['transaction_no'],
          'sap_code': row['sap_code'],
          'main_category': mainCat,
          'collection': collName,
          'qty': row['qty'],
          'gross_sales': grossSales,
          'disc_pct': discPct,
          'val_disc': valDisc,
          'net_price': netPrice,
          'comm': comm,
          'cost': cost,
          'net_sales': row['net_sales'],
          'type': 'Regular',
          'catalogue_code': row['catalogue_code'],
        });
      }

      int normalizedInserted = 0;
      for (int i = 0; i < normalizedRows.length; i += 500) {
        final batch = normalizedRows.sublist(i, (i + 500).clamp(0, normalizedRows.length));
        await _sb.from('clean_master').insert(batch);
        normalizedInserted += batch.length;
      }

      onProgress?.call('Sync selesai!');
      return SyncResult(
        success: true,
        rawInserted: rawInserted,
        normalizedInserted: normalizedInserted,
        skippedDuplicates: skipped,
      );

    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }
}

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
