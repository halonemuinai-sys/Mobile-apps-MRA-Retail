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
    return CustomerSegmentProfile(
      name: map['name'] ?? '',
      segment: map['segment'] ?? 'Prospect',
      freqInvoice: (map['freq_invoice'] as num?)?.toInt() ?? 0,
      freqQty: (map['freq_qty'] as num?)?.toInt() ?? 0,
      recencyDays: (map['recency_days'] as num?)?.toInt() ?? 9999,
      ltv: (map['ltv'] as num?)?.toDouble() ?? 0.0,
      firstVisit: map['first_visit'] ?? '',
      lastVisit: map['last_visit'] ?? '',
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
