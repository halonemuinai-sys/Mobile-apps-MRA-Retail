class MasterData {
  static const titles = ['Mr', 'Mrs', 'Ms'];

  static const umurOptions = [
    '<30', '30-35', '35-40', '40-45', '45-50', '>50'
  ];

  static const tinggiOptions = [
    '<160', '160 - 170', '170 - 180', '>180'
  ];

  static const bentukTubuh = [
    'Kurus', 'Sedang', 'Berisi', 'Gemuk', 'Tinggi'
  ];

  static const stores = [
    'Plaza Indonesia', 'Plaza Senayan', 'Pop Up Senayan City', 'Bali'
  ];

  static const hariRaya = [
    'Idul Fitri dan Idul Adha', 'Waisak', 'Natal', 'Nyepi', 'Imlek'
  ];

  static const barangAntusias = [
    'Jewelry', 'Watches', 'Perfume', 'LLGA', 'Semi HJ'
  ];

  static const statusPernikahan = [
    'Belum Kawin', 'Kawin', 'Cerai Hidup', 'Cerai Mati', 'Janda', 'Duda'
  ];

  static const statusPelanggan = [
    'New', 'Old', 'VIP'
  ];

  static const memilikiAnak = [
    'YA', 'TIDAK'
  ];

  static const fashionStyle = [
    'Casual', 'Stylish', 'Sporty', 'Konservatif', 'Hijab', 'Simple', 'Formal'
  ];

  static const pemicuBeli = [
    'Promo / Discount', 'New Collection', 'Gift for Someone', 'Personal Reward', 'Investment', 'Limited Edition'
  ];

  static const karakter = [
    'Pendiam', 'Ceriwis', 'To The Point', 'Supel', 'Humoris', 'Kritis', 'Antusias', 'Ramah', 'Sok Tahu', 'Suka Discount'
  ];

  static const provinsi = [
    'Aceh', 'Bali', 'Bangka Belitung', 'Banten', 'Bengkulu', 'Daerah Istimewa Yogyakarta',
    'Dki Jakarta', 'Gorontalo', 'Jambi', 'Jawa Barat', 'Jawa Tengah', 'Jawa Timur',
    'Kalimantan Barat', 'Kalimantan Selatan', 'Kalimantan Tengah', 'Kalimantan Timur', 'Kalimantan Utara',
    'Kepulauan Riau', 'Lampung', 'Maluku', 'Maluku Utara', 'Nusa Tenggara Barat', 'Nusa Tenggara Timur',
    'Papua', 'Papua Barat', 'Papua Barat Daya', 'Papua Pegunungan', 'Papua Selatan', 'Papua Tengah',
    'Riau', 'Sulawesi Barat', 'Sulawesi Selatan', 'Sulawesi Tengah', 'Sulawesi Tenggara', 'Sulawesi Utara',
    'Sumatera Barat', 'Sumatera Selatan', 'Sumatera Utara'
  ];

  static const phoneCodes = {
    'Indonesia': '62', 'Afghanistan': '93', 'Albania': '355', 'Algeria': '213', 'American Samoa': '1-683',
    'Andorra': '376', 'Angola': '244', 'Anguilla': '263', 'Antigua and Barbuda': '267', 'Argentina': '54',
    'Armenia': '374', 'Aruba': '297', 'Australia': '61', 'Austria': '43', 'Azerbaijan': '994', 'Bahamas': '1-241',
    'Bahrain': '973', 'Bangladesh': '880', 'Barbados': '1-245', 'Belarus': '375', 'Belgium': '32', 'Belize': '501',
    'Benin': '229', 'Bermuda': '1-440', 'Bhutan': '975', 'Bolivia': '591', 'Bosnia and Herzegovina': '387',
    'Botswana': '267', 'Brazil': '55', 'Brunei Darussalam': '673', 'Bulgaria': '359', 'Burkina Faso': '226',
    'Burundi': '257', 'Cambodia': '855', 'Cameroon': '237', 'Canada': '1', 'Chile': '56', 'China': '86',
    'Colombia': '57', 'Congo': '242', 'Costa Rica': '506', 'Croatia': '385', 'Cuba': '53', 'Cyprus': '357',
    'Czechia': '420', 'Denmark': '45', 'Dominica': '1-766', 'Dominican Republic': '1-809', 'Ecuador': '593',
    'Egypt': '20', 'El Salvador': '503', 'Estonia': '372', 'Ethiopia': '251', 'Fiji': '679', 'Finland': '358',
    'France': '33', 'Gabon': '241', 'Gambia': '220', 'Georgia': '995', 'Germany': '49', 'Ghana': '233',
    'Greece': '30', 'Grenada': '1-472', 'Guatemala': '502', 'Guinea': '224', 'Guyana': '592', 'Haiti': '509',
    'Honduras': '504', 'Hong Kong': '852', 'Hungary': '36', 'Iceland': '354', 'India': '91', 'Iran': '98',
    'Iraq': '964', 'Ireland': '353', 'Israel': '972', 'Italy': '39', 'Jamaica': '1-875', 'Japan': '81',
    'Jordan': '962', 'Kazakhstan': '7', 'Kenya': '254', 'Kuwait': '965', 'Kyrgyzstan': '996', 'Laos': '856',
    'Latvia': '371', 'Lebanon': '961', 'Liberia': '231', 'Libya': '218', 'Lithuania': '370', 'Luxembourg': '352',
    'Macao': '853', 'Madagascar': '261', 'Malaysia': '60', 'Maldives': '960', 'Mali': '223', 'Malta': '356',
    'Mexico': '52', 'Monaco': '377', 'Mongolia': '976', 'Morocco': '212', 'Myanmar': '95', 'Namibia': '264',
    'Nepal': '977', 'Netherlands': '31', 'New Zealand': '64', 'Nicaragua': '505', 'Nigeria': '234',
    'Norway': '47', 'Oman': '968', 'Pakistan': '92', 'Panama': '507', 'Paraguay': '595', 'Peru': '51',
    'Philippines': '63', 'Poland': '48', 'Portugal': '351', 'Qatar': '974', 'Romania': '40', 'Russian Federation': '7',
    'Saudi Arabia': '966', 'Senegal': '221', 'Serbia': '381', 'Singapore': '65', 'Slovakia': '421', 'Slovenia': '386',
    'South Africa': '27', 'South Korea': '82', 'Spain': '34', 'Sri Lanka': '94', 'Sudan': '249', 'Sweden': '46',
    'Switzerland': '41', 'Syria': '963', 'Taiwan': '886', 'Thailand': '66', 'Turkey': '90', 'Ukraine': '380',
    'United Arab Emirates': '971', 'United Kingdom': '44', 'United States': '1', 'Uruguay': '598',
    'Uzbekistan': '998', 'Venezuela': '58', 'Vietnam': '84', 'Yemen': '967', 'Zimbabwe': '263'
  };

  static List<String> get negara => phoneCodes.keys.toList();

  static const etnis = [
    'Jawa', 'Sunda', 'Batak', 'Minangkabau', 'Betawi', 'Bugis', 'Aceh', 'Dayak', 'Madura', 'Ambon', 'Sasak',
    'Toraja', 'Papua', 'Flores', 'Minahasa', 'Tionghoa', 'Korea', 'India', 'Western', 'Japanese', 'Middle East',
    'Arabic', 'Filipina', 'European', 'Australian', 'American', 'Asian', 'Thai', 'Vietnamese', 'Malay'
  ];

  static const pekerjaan = [
    'Wirausaha', 'ASN', 'TNI/Polri', 'IRT', 'Karyawan', 'Mahasiswa/i', 'Direktur', 'Dokter', 'Artis / Model', 'Pramugari', 'Lainnya'
  ];

  static const warnaFavorit = [
    'Merah', 'Biru', 'Hijau', 'Kuning', 'Jingga', 'Ungu', 'Violet', 'Merah Jambu', 'Coklat', 'Abu-abu', 
    'Putih', 'Hitam', 'Cyan', 'Magenta', 'Krem', 'Marun', 'Lavender', 'Peach', 'Mint', 'Turquoise', 'All Color'
  ];

  static const hobiKategori = {
    'Olahraga & Kesehatan': ['GYM & Fitness', 'Lari', 'Golf', 'Padel', 'Berenang', 'Bersepeda', 'Yoga / Pilates', 'Diving / Snorkeling'],
    'Gaya Hidup & Mewah': ['Fashion', 'Travelling', 'Handbag', 'Jam Tangan', 'Barang Antik', 'Gemstones'],
    'Otomotif': ['Otomotif Roda 2', 'Otomotif Roda 4', 'Motorsport'],
    'Kuliner': ['Wisata Kuliner', 'Memasak', 'Baking'],
    'Hiburan & Seni': ['Menonton', 'Gaming', 'Fotografi', 'Musik', 'Membaca', 'Die Cast / Action Figure', 'Aquascaping, Aquarium & Terarium'],
    'Alam & Lingkungan': ['Berkebun', 'Bunga & Tanaman Hias', 'Pet Care', 'Hiking & Trekking', 'Camping & Glamping'],
    'Others': ['Others']
  };
}
