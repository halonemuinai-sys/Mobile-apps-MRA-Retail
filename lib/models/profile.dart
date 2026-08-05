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
  // Extended fields from Supabase
  final String namaDepan;
  final String namaBelakang;
  final String etnis;
  final String agama;
  final String jumlahAnak;
  final String domisiliLuarNegeri;
  final String topikPembicaraanFavorit;
  final String cakeFavorit;
  final String hobbySub;
  final String hobbyOthers;
  final String ktpPassport;
  final String fotoCustomer;
  final String? tanggalPernikahan;

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
    this.namaDepan = '',
    this.namaBelakang = '',
    this.etnis = '',
    this.agama = '',
    this.jumlahAnak = '',
    this.domisiliLuarNegeri = '',
    this.topikPembicaraanFavorit = '',
    this.cakeFavorit = '',
    this.hobbySub = '',
    this.hobbyOthers = '',
    this.ktpPassport = '',
    this.fotoCustomer = '',
    this.tanggalPernikahan,
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
    int parsedId = 0;
    if (m['id'] is num) {
      parsedId = (m['id'] as num).toInt();
    } else if (m['id'] is String) {
      parsedId = int.tryParse(m['id'] as String) ?? 0;
    }

    String s(dynamic v) => v?.toString() ?? '';

    return CrmProfile(
      id:                    parsedId,
      namaLengkap:           s(m['nama_lengkap'] ?? m['customerName'] ?? m['customer_name'] ?? m['name']),
      namaPanggilan:         s(m['nama_panggilan'] ?? m['nickname']),
      title:                 s(m['title']),
      fullNameTittle:        s(m['full_name_tittle'] ?? m['fullNameTitle'] ?? m['nama_lengkap'] ?? m['customerName']),
      customerAdvisor:       s(m['customer_advisor'] ?? m['customerAdvisor'] ?? m['salesman']),
      lokasiStore:           s(m['lokasi_store'] ?? m['lokasiStore'] ?? m['store'] ?? m['location']),
      noHp:                  s(m['no_hp'] ?? m['phone_no'] ?? m['phone']),
      email:                 s(m['email']),
      umur:                  s(m['umur'] ?? m['age']),
      tinggiBadan:           s(m['tinggi_badan']),
      bentukTubuh:           s(m['bentuk_tubuh']),
      domisili:              s(m['domisili'] ?? m['city']),
      kewarganegaraan:       s(m['kewarganegaraan']),
      statusPelanggan:       s(m['status_pelanggan'] ?? m['status'] ?? m['segment']),
      statusPernikahan:      s(m['status_pernikahan']),
      memilikiAnak:          s(m['memiliki_anak']),
      pekerjaan:             s(m['pekerjaan'] ?? m['occupation']),
      fashionStyle:          s(m['fashion_style']),
      hobby:                 s(m['hobby']),
      hobbyKategori:         s(m['hobby_kategori']),
      warnaFavorit:          s(m['warna_favorit']),
      makananFavorit:        s(m['makanan_favorit']),
      minumanFavorit:        s(m['minuman_favorit']),
      alergiMakanan:         s(m['alergi_makanan']),
      tempatLiburanFavorit:  s(m['tempat_liburan_favorit']),
      instagram:             s(m['instagram']),
      tiktok:                s(m['tiktok']),
      karakter:              s(m['karakter']),
      faktorPemicuPembelian: s(m['faktor_pemicu_pembelian']),
      barangAntusias:        s(m['barang_antusias']),
      tanggalLahir:          m['tanggal_lahir']?.toString(),
      createdAt:             s(m['created_at']),
      namaDepan:             s(m['nama_depan']),
      namaBelakang:          s(m['nama_belakang']),
      etnis:                 s(m['etnis']),
      agama:                 s(m['agama']),
      jumlahAnak:            s(m['jumlah_anak']),
      domisiliLuarNegeri:    s(m['domisili_luar_negeri']),
      topikPembicaraanFavorit: s(m['topik_pembicaraan_favorit']),
      cakeFavorit:           s(m['cake_favorit']),
      hobbySub:              s(m['hobby_sub']),
      hobbyOthers:           s(m['hobby_others']),
      ktpPassport:           s(m['ktp_passport']),
      fotoCustomer:          s(m['foto_customer']),
      tanggalPernikahan:     m['tanggal_pernikahan']?.toString(),
    );
  }
}
