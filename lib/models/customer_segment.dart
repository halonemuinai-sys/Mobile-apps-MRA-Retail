class CustomerSegmentProfile {
  final String name;
  final String segment;
  final int freqInvoice;
  final int freqQty;
  final int recencyDays;
  final double ltv;
  final String firstVisit;
  final String lastVisit;

  CustomerSegmentProfile({
    required this.name,
    required this.segment,
    required this.freqInvoice,
    required this.freqQty,
    required this.recencyDays,
    required this.ltv,
    required this.firstVisit,
    required this.lastVisit,
  });

  factory CustomerSegmentProfile.fromMap(Map<String, dynamic> map) {
    int parseInt(dynamic val, [int fallback = 0]) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    double parseDouble(dynamic val, [double fallback = 0.0]) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? fallback;
      return fallback;
    }

    String parseString(dynamic val, [String fallback = '']) {
      if (val == null) return fallback;
      return val.toString();
    }

    return CustomerSegmentProfile(
      name: parseString(map['name'] ?? map['customerName'] ?? map['customer_name'] ?? map['nama_lengkap']),
      segment: parseString(map['segment'] ?? map['status'] ?? map['status_pelanggan'], 'Prospect'),
      freqInvoice: parseInt(map['freq_invoice'] ?? map['freqInvoice'] ?? map['invoices']),
      freqQty: parseInt(map['freq_qty'] ?? map['freqQty'] ?? map['itemsCount']),
      recencyDays: parseInt(map['recency_days'] ?? map['recencyDays'] ?? map['recency'], 9999),
      ltv: parseDouble(map['ltv'] ?? map['totalLtv'] ?? map['netSales']),
      firstVisit: parseString(map['first_visit'] ?? map['firstVisit']),
      lastVisit: parseString(map['last_visit'] ?? map['lastVisit']),
    );
  }
}

class SegmentTransaction {
  final String date;
  final int qty;
  final String collection;
  final String category;
  final String location;
  final double netSales;
  final String transNo;

  SegmentTransaction({
    required this.date,
    required this.qty,
    required this.collection,
    required this.category,
    required this.location,
    required this.netSales,
    required this.transNo,
  });

  factory SegmentTransaction.fromMap(Map<String, dynamic> map) {
    return SegmentTransaction(
      date: map['transaction_date'] ?? '',
      qty: (map['qty'] as num?)?.toInt() ?? 0,
      collection: (map['collection'] ?? '').toString().trim(),
      category: (map['main_category'] ?? '').toString().trim(),
      location: (map['location'] ?? '').toString().trim(),
      netSales: (map['net_sales'] as num?)?.toDouble() ?? 0.0,
      transNo: map['trans_no'] ?? '',
    );
  }
}

class CollectionShare {
  final String name;
  final double value;
  final int qty;

  CollectionShare({
    required this.name,
    required this.value,
    required this.qty,
  });
}

class CustomerSegmentDetail {
  final List<SegmentTransaction> transactions;
  final List<CollectionShare> topCollections;
  final double totalSpend;
  final int totalQty;
  final String firstVisit;
  final String lastVisit;

  CustomerSegmentDetail({
    required this.transactions,
    required this.topCollections,
    required this.totalSpend,
    required this.totalQty,
    required this.firstVisit,
    required this.lastVisit,
  });
}
