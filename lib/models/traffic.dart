class TrafficRow {
  final int id;
  final String customerName;
  final String namaPanggilan;
  final String customerAdvisor;
  final String location;
  final String status;
  final String tanggalBerkunjung;
  final String prospectItem;
  final String noHp;
  final String email;
  final double netSales;
  final String statusPelanggan;
  final String prospekLevel;
  final String minatBarang;
  final String aksesMasuk;
  final String siapa;
  final String notes;
  final String servedBy;
  final String barangDiminati;
  final String faktorPemicu;
  final String groupSize;
  final double diskonPct;
  final String buktiChat;

  const TrafficRow({
    required this.id,
    required this.customerName,
    required this.namaPanggilan,
    required this.customerAdvisor,
    required this.location,
    required this.status,
    required this.tanggalBerkunjung,
    required this.prospectItem,
    required this.noHp,
    required this.email,
    required this.netSales,
    required this.statusPelanggan,
    this.prospekLevel = '',
    this.minatBarang = '',
    this.aksesMasuk = '',
    this.siapa = '',
    required this.notes,
    this.barangDiminati = '',
    this.servedBy = '',
    this.faktorPemicu = '',
    this.groupSize = '',
    this.diskonPct = 0,
    this.buktiChat = '',
  });

  factory TrafficRow.fromMap(Map<String, dynamic> m) {
    return TrafficRow(
      id:                ((m['id'] as num?) ?? 0).toInt(),
      customerName:      (m['customer_name'] as String?) ?? '',
      namaPanggilan:     (m['nama_panggilan'] as String?) ?? '',
      customerAdvisor:   (m['customer_advisor'] as String?) ?? '',
      location:          (m['location'] as String?) ?? '',
      status:            (m['status'] as String?) ?? '',
      tanggalBerkunjung: (m['tanggal_berkunjung'] as String?) ?? '',
      prospectItem:      (m['prospect_item'] as String?) ?? '',
      noHp:              (m['no_hp'] as String?) ?? '',
      email:             (m['email'] as String?) ?? '',
      netSales:          ((m['net_sales'] as num?) ?? 0).toDouble(),
      statusPelanggan:   (m['status_pelanggan'] as String?) ?? '',
      prospekLevel:      (m['prospek_level'] as String?) ?? '',
      minatBarang:       (m['minat_barang'] as String?) ?? '',
      aksesMasuk:        (m['akses_masuk'] as String?) ?? '',
      siapa:             (m['siapa'] as String?) ?? '',
      notes:             (m['notes'] as String?) ?? '',
      barangDiminati:    (m['barang_diminati'] as String?) ?? '',
      servedBy:          (m['served_by'] as String?) ?? '',
      faktorPemicu:      (m['faktor_pemicu'] as String?) ?? '',
      groupSize:         m['group_size']?.toString() ?? '',
      diskonPct:         ((m['diskon_pct'] as num?) ?? 0).toDouble(),
      buktiChat:         (m['bukti_chat'] as String?) ?? '',
    );
  }
}
