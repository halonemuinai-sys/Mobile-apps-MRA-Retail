class Transaction {
  final String transNo;
  final String transactionDate;
  final String customer;
  final String salesman;
  final String location;
  final String mainCategory;
  final String collection;
  final double netSales;
  final double grossSales;
  final double valDisc;
  final int qty;
  final String sapCode;
  final String catalogueCode;

  const Transaction({
    required this.transNo,
    required this.transactionDate,
    required this.customer,
    required this.salesman,
    required this.location,
    required this.mainCategory,
    required this.collection,
    required this.netSales,
    required this.grossSales,
    required this.valDisc,
    required this.qty,
    required this.sapCode,
    required this.catalogueCode,
  });

  factory Transaction.fromMap(Map<String, dynamic> m) {
    return Transaction(
      transNo:         (m['trans_no'] as String?) ?? '',
      transactionDate: (m['transaction_date'] as String?) ?? '',
      customer:        (m['customer'] as String?) ?? '',
      salesman:        (m['salesman'] as String?) ?? '',
      location:        (m['location'] as String?) ?? '',
      mainCategory:    (m['main_category'] as String?) ?? '',
      collection:      (m['collection'] as String?) ?? '',
      netSales:        ((m['net_sales'] as num?) ?? 0).toDouble(),
      grossSales:      ((m['gross_sales'] as num?) ?? 0).toDouble(),
      valDisc:         ((m['val_disc'] as num?) ?? 0).toDouble(),
      qty:             ((m['qty'] as num?) ?? 0).toInt(),
      sapCode:         (m['sap_code'] as String?) ?? '',
      catalogueCode:   (m['catalogue_code'] as String?) ?? '',
    );
  }
}
