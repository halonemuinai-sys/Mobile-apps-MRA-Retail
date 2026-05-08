class CrmProfile {
  final int id;
  final String namaLengkap;
  final String namaPanggilan;
  final String title;
  final String fullNameTittle;
  final String customerAdvisor;
  final String lokasiStore;
  final String noHp;
  final String email;
  final String umur;
  final String tinggiBadan;
  final String bentukTubuh;
  final String domisili;
  final String kewarganegaraan;
  final String statusPelanggan;
  final String statusPernikahan;
  final String memilikiAnak;
  final String pekerjaan;
  final String fashionStyle;
  final String hobby;
  final String hobbyKategori;
  final String warnaFavorit;
  final String makananFavorit;
  final String minumanFavorit;
  final String alergiMakanan;
  final String tempatLiburanFavorit;
  final String instagram;
  final String tiktok;
  final String karakter;
  final String faktorPemicuPembelian;
  final String barangAntusias;
  final String? tanggalLahir;
  final String createdAt;

  const CrmProfile({
    required this.id,
    required this.namaLengkap,
    required this.namaPanggilan,
    required this.title,
    required this.fullNameTittle,
    required this.customerAdvisor,
    required this.lokasiStore,
    required this.noHp,
    required this.email,
    required this.umur,
    required this.tinggiBadan,
    required this.bentukTubuh,
    required this.domisili,
    required this.kewarganegaraan,
    required this.statusPelanggan,
    required this.statusPernikahan,
    required this.memilikiAnak,
    required this.pekerjaan,
    required this.fashionStyle,
    required this.hobby,
    required this.hobbyKategori,
    required this.warnaFavorit,
    required this.makananFavorit,
    required this.minumanFavorit,
    required this.alergiMakanan,
    required this.tempatLiburanFavorit,
    required this.instagram,
    required this.tiktok,
    required this.karakter,
    required this.faktorPemicuPembelian,
    required this.barangAntusias,
    this.tanggalLahir,
    required this.createdAt,
  });

  String get displayName =>
      fullNameTittle.isNotEmpty ? fullNameTittle :
      namaLengkap.isNotEmpty ? namaLengkap : '—';

  String get initials {
    final parts = displayName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory CrmProfile.fromMap(Map<String, dynamic> m) {
    return CrmProfile(
      id:                    ((m['id'] as num?) ?? 0).toInt(),
      namaLengkap:           (m['nama_lengkap'] as String?) ?? '',
      namaPanggilan:         (m['nama_panggilan'] as String?) ?? '',
      title:                 (m['title'] as String?) ?? '',
      fullNameTittle:        (m['full_name_tittle'] as String?) ?? '',
      customerAdvisor:       (m['customer_advisor'] as String?) ?? '',
      lokasiStore:           (m['lokasi_store'] as String?) ?? '',
      noHp:                  (m['no_hp'] as String?) ?? '',
      email:                 (m['email'] as String?) ?? '',
      umur:                  (m['umur'] as String?) ?? '',
      tinggiBadan:           (m['tinggi_badan'] as String?) ?? '',
      bentukTubuh:           (m['bentuk_tubuh'] as String?) ?? '',
      domisili:              (m['domisili'] as String?) ?? '',
      kewarganegaraan:       (m['kewarganegaraan'] as String?) ?? '',
      statusPelanggan:       (m['status_pelanggan'] as String?) ?? '',
      statusPernikahan:      (m['status_pernikahan'] as String?) ?? '',
      memilikiAnak:          (m['memiliki_anak'] as String?) ?? '',
      pekerjaan:             (m['pekerjaan'] as String?) ?? '',
      fashionStyle:          (m['fashion_style'] as String?) ?? '',
      hobby:                 (m['hobby'] as String?) ?? '',
      hobbyKategori:         (m['hobby_kategori'] as String?) ?? '',
      warnaFavorit:          (m['warna_favorit'] as String?) ?? '',
      makananFavorit:        (m['makanan_favorit'] as String?) ?? '',
      minumanFavorit:        (m['minuman_favorit'] as String?) ?? '',
      alergiMakanan:         (m['alergi_makanan'] as String?) ?? '',
      tempatLiburanFavorit:  (m['tempat_liburan_favorit'] as String?) ?? '',
      instagram:             (m['instagram'] as String?) ?? '',
      tiktok:                (m['tiktok'] as String?) ?? '',
      karakter:              (m['karakter'] as String?) ?? '',
      faktorPemicuPembelian: (m['faktor_pemicu_pembelian'] as String?) ?? '',
      barangAntusias:        (m['barang_antusias'] as String?) ?? '',
      tanggalLahir:          m['tanggal_lahir'] as String?,
      createdAt:             (m['created_at'] as String?) ?? '',
    );
  }
}
