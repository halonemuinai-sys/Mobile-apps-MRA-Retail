import 'package:supabase_flutter/supabase_flutter.dart';

class CatalogItem {
  final String itemCode;
  final String sapCode;
  final String deskripsi;
  final double harga;
  final int qoh;
  final String kategori;
  final String koleksi;

  const CatalogItem({
    required this.itemCode,
    required this.sapCode,
    required this.deskripsi,
    required this.harga,
    required this.qoh,
    required this.kategori,
    required this.koleksi,
  });

  factory CatalogItem.fromMap(Map<String, dynamic> m) {
    String s(dynamic v) => v?.toString() ?? '';
    double d(dynamic v) {
      if (v == null) return 0;
      return double.tryParse(v.toString()) ?? 0;
    }
    int i(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;

    return CatalogItem(
      itemCode:  s(m['item_code']),
      sapCode:   s(m['item_sku']),
      deskripsi: s(m['description']),
      harga:     d(m['item_price']),
      qoh:       i(m['qoh']),
      kategori:  s(m['main_category']),
      koleksi:   s(m['collection_name']),
    );
  }

  String get hargaFormatted {
    if (harga == 0) return '-';
    final n = harga.toInt();
    final str = n.toString();
    final buf = StringBuffer('Rp ');
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  String get displayCode => itemCode.isNotEmpty ? itemCode : sapCode;
}

class CatalogService {
  static final _sb = Supabase.instance.client;

  static Future<List<CatalogItem>> search(String keyword) async {
    if (keyword.length < 3) return [];
    try {
      final orFilter = 'item_code.ilike.%$keyword%,item_sku.ilike.%$keyword%,description.ilike.%$keyword%';
      final res = await _sb
          .from('inventory_valuation')
          .select('item_code, item_sku, description, item_price, main_category, collection_name, qoh')
          .or(orFilter)
          .gt('qoh', 0)
          .order('item_code')
          .limit(20);
      return (res as List).map((r) => CatalogItem.fromMap(r as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
