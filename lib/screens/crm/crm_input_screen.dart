import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/advisor.dart';
import '../../services/profile_service.dart';
import '../../services/cdn_service.dart';
import '../../constants/master_data.dart';
import '../../theme.dart';

class CrmInputScreen extends StatefulWidget {
  final Advisor advisor;
  const CrmInputScreen({super.key, required this.advisor});

  @override
  State<CrmInputScreen> createState() => _CrmInputScreenState();
}

class _CrmInputScreenState extends State<CrmInputScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // Foto customer
  Uint8List? _fotoBytes;
  String? _fotoFilename;

  // Controllers - Utama
  String? _selectedStatusPelanggan;
  String? _selectedTitle;
  final _namaDepan        = TextEditingController();
  final _namaBelakang     = TextEditingController();
  final _namaPanggilan    = TextEditingController();
  final _noHp             = TextEditingController();
  final _email            = TextEditingController();

  // Controllers - Identitas & Domisili
  String? _selectedKewarganegaraan;
  String? _domisiliType = 'Dalam Negeri';
  String? _selectedDomisili;
  String? _selectedUmur;
  String? _selectedEtnis;
  String? _selectedPernikahan;
  String? _selectedAnak;
  String? _selectedJumlahAnak;
  String? _selectedTinggi;
  String? _selectedBentuk;
  String? _selectedPekerjaan;
  String? _selectedAgama;
  final _tglLahir         = TextEditingController();
  final _tglPernikahan    = TextEditingController();
  final _ktpPassport      = TextEditingController();

  // Controllers - Lifestyle & Minat
  String? _selectedFashion;
  String? _selectedHobbyKat;
  String? _selectedHobbySub;
  String? _selectedWarna;
  final _liburanFavorit   = TextEditingController();
  final _topikPembicaraan = TextEditingController();
  final _hobbyOthers      = TextEditingController();

  // Controllers - Kuliner
  final _makananFavorit   = TextEditingController();
  final _minumanFavorit   = TextEditingController();
  final _alergiMakanan    = TextEditingController();
  final _cakeFavorit      = TextEditingController();

  // Controllers - Social Media
  final _instagram        = TextEditingController();
  final _tiktok           = TextEditingController();

  // Controllers - Insight
  String? _selectedPemicu;
  String? _selectedAntusias;
  String? _selectedKarakter;
  final _notes            = TextEditingController();

  String get _phonePrefix {
    if (_selectedKewarganegaraan != null && MasterData.phoneCodes.containsKey(_selectedKewarganegaraan)) {
      return '+${MasterData.phoneCodes[_selectedKewarganegaraan]} ';
    }
    return '';
  }

  Future<void> _pickFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _fotoBytes    = bytes;
      _fotoFilename = picked.name;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // Upload foto customer ke CDN jika ada
      String fotoUrl = '';
      if (_fotoBytes != null && _fotoFilename != null) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final url = await CdnService.uploadImage(
          bytes: _fotoBytes!,
          filename: 'foto_${ts}_$_fotoFilename',
          folder: 'foto_customer',
        );
        fotoUrl = url ?? '';
      }

      // Title case helper
      String titleCase(String s) => s.trim().split(' ')
          .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
          .join(' ');

      final namaDepan    = titleCase(_namaDepan.text);
      final namaBelakang = titleCase(_namaBelakang.text);
      final namaLengkap  = '$namaDepan $namaBelakang'.trim();

      final fullNoHp = '$_phonePrefix${_noHp.text}'.replaceAll(' ', '');

      final data = {
        // Primary
        'title'              : _selectedTitle ?? '',
        'nama_lengkap'       : namaLengkap,
        'nama_panggilan'     : _namaPanggilan.text,
        'nama_depan'         : namaDepan,
        'nama_belakang'      : namaBelakang,
        'full_name_tittle'   : '${_selectedTitle ?? ''} $namaLengkap'.trim(),
        'status_pelanggan'   : _selectedStatusPelanggan ?? 'New',
        'foto_customer'      : fotoUrl,
        // Contact
        'no_hp'              : fullNoHp,
        'email'              : _email.text,
        // Identitas
        'kewarganegaraan'    : _selectedKewarganegaraan ?? '',
        'tanggal_lahir'      : _tglLahir.text,
        'umur'               : _selectedUmur ?? '',
        'tinggi_badan'       : _selectedTinggi ?? '',
        'bentuk_tubuh'       : _selectedBentuk ?? '',
        'etnis'              : _selectedEtnis ?? '',
        'agama'              : _selectedAgama ?? '',
        'status_pernikahan'  : _selectedPernikahan ?? '',
        'tanggal_pernikahan' : _tglPernikahan.text,
        'memiliki_anak'      : _selectedAnak ?? '',
        'jumlah_anak'        : _selectedJumlahAnak ?? '',
        'pekerjaan'          : _selectedPekerjaan ?? '',
        'ktp_passport'       : _ktpPassport.text,
        // Domisili — simpan ke field yang tepat
        'domisili'           : _domisiliType == 'Dalam Negeri' ? (_selectedDomisili ?? '') : '',
        'domisili_luar_negeri': _domisiliType == 'Luar Negeri' ? (_selectedDomisili ?? '') : '',
        // Lifestyle
        'fashion_style'      : _selectedFashion ?? '',
        'hobby_kategori'     : _selectedHobbyKat ?? '',
        'hobby_sub'          : _selectedHobbySub ?? '',
        'hobby_others'       : _hobbyOthers.text,
        'warna_favorit'      : _selectedWarna ?? '',
        'tempat_liburan_favorit'    : _liburanFavorit.text,
        'topik_pembicaraan_favorit' : _topikPembicaraan.text,
        // Kuliner
        'makanan_favorit'    : _makananFavorit.text,
        'minuman_favorit'    : _minumanFavorit.text,
        'alergi_makanan'     : _alergiMakanan.text,
        'cake_favorit'       : _cakeFavorit.text,
        // Sosmed
        'instagram'          : _instagram.text,
        'tiktok'             : _tiktok.text,
        // Insight
        'faktor_pemicu_pembelian': _selectedPemicu ?? '',
        'barang_antusias'    : _selectedAntusias ?? '',
        'karakter'           : _selectedKarakter ?? '',
        'notes'              : _notes.text,
        // Meta
        'customer_advisor'   : widget.advisor.name,
        'lokasi_store'       : widget.advisor.store,
        'tanggal_input'      : DateTime.now().toIso8601String().split('T')[0],
        'created_at'         : DateTime.now().toIso8601String(),
      };

      await ProfileService.createProfile(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pelanggan berhasil didaftarkan'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('New Client Profiling',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.dark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  // ── PRIMARY INFORMATION ──────────────────────────
                  _SectionHeader(Icons.person_pin_rounded, 'PRIMARY INFORMATION'),
                  _Card([
                    // Foto Customer
                    _buildFotoSection(),
                    const SizedBox(height: 4),
                    _Dropdown('Client Status', _selectedStatusPelanggan, MasterData.statusPelanggan,
                        (v) => setState(() => _selectedStatusPelanggan = v)),
                    Row(children: [
                      Expanded(flex: 2, child: _Dropdown('Title', _selectedTitle, MasterData.titles,
                          (v) => setState(() => _selectedTitle = v))),
                      const SizedBox(width: 10),
                      Expanded(flex: 3, child: _Field(_namaDepan, 'First Name',
                          required: true, icon: Icons.badge_outlined, titleCase: true)),
                      const SizedBox(width: 10),
                      Expanded(flex: 3, child: _Field(_namaBelakang, 'Last Name',
                          icon: Icons.badge_outlined, titleCase: true)),
                    ]),
                    _Field(_namaPanggilan, 'Preferred Name', icon: Icons.face_retouching_natural),
                  ]),

                  const SizedBox(height: 24),

                  // ── CONTACT DETAILS ──────────────────────────────
                  _SectionHeader(Icons.contact_phone_rounded, 'CONTACT DETAILS'),
                  _Card([
                    _Dropdown('Nationality', _selectedKewarganegaraan, MasterData.negara,
                        (v) => setState(() => _selectedKewarganegaraan = v), icon: Icons.public),
                    _Field(_noHp, 'Mobile Number',
                        required: true,
                        keyboard: TextInputType.phone,
                        prefixText: _phonePrefix.isEmpty ? null : _phonePrefix,
                        hint: '8123456xxx',
                        icon: Icons.phone_android_rounded),
                    _Field(_email, 'Email Address',
                        keyboard: TextInputType.emailAddress, icon: Icons.email_outlined),
                  ]),

                  const SizedBox(height: 24),

                  // ── DOMICILE & IDENTITY ──────────────────────────
                  _SectionHeader(Icons.home_work_rounded, 'DOMICILE & IDENTITY'),
                  _Card([
                    _SectionSubHeader('Current Domicile Type'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        _segmentButton('Domestic', _domisiliType == 'Dalam Negeri',
                            () => setState(() { _domisiliType = 'Dalam Negeri'; _selectedDomisili = null; })),
                        _segmentButton('International', _domisiliType == 'Luar Negeri',
                            () => setState(() { _domisiliType = 'Luar Negeri'; _selectedDomisili = null; })),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    _Dropdown(
                      _domisiliType == 'Dalam Negeri' ? 'Province' : 'Country',
                      _selectedDomisili,
                      _domisiliType == 'Dalam Negeri' ? MasterData.provinsi : MasterData.negara,
                      (v) => setState(() => _selectedDomisili = v),
                      icon: Icons.location_on_outlined,
                    ),
                    const Divider(height: 32, thickness: 1, color: Color(0xFFF1F5F9)),
                    _Field(_tglLahir, 'Date of Birth', hint: 'YYYY-MM-DD',
                        icon: Icons.calendar_month_outlined),
                    _Dropdown('Age Range', _selectedUmur, MasterData.umurOptions,
                        (v) => setState(() => _selectedUmur = v), icon: Icons.trending_up),
                    _Dropdown('Height Range', _selectedTinggi, MasterData.tinggiOptions,
                        (v) => setState(() => _selectedTinggi = v), icon: Icons.height),
                    _Dropdown('Body Shape', _selectedBentuk, MasterData.bentukTubuh,
                        (v) => setState(() => _selectedBentuk = v), icon: Icons.accessibility_new_rounded),
                    _Dropdown('Ethnicity', _selectedEtnis, MasterData.etnis,
                        (v) => setState(() => _selectedEtnis = v), icon: Icons.people_outline),
                    _Dropdown('Religion / Agama', _selectedAgama, MasterData.hariRaya,
                        (v) => setState(() => _selectedAgama = v), icon: Icons.mosque_outlined),
                    _Dropdown('Marital Status', _selectedPernikahan, MasterData.statusPernikahan,
                        (v) => setState(() => _selectedPernikahan = v), icon: Icons.favorite_border),
                    if (_selectedPernikahan != null &&
                        (_selectedPernikahan == 'Kawin'))
                      _Field(_tglPernikahan, 'Wedding Anniversary', hint: 'YYYY-MM-DD',
                          icon: Icons.cake_outlined),
                    _Dropdown('Have Children?', _selectedAnak, MasterData.memilikiAnak,
                        (v) => setState(() => _selectedAnak = v), icon: Icons.child_care_rounded),
                    if (_selectedAnak == 'YA')
                      _Dropdown('Number of Children', _selectedJumlahAnak, MasterData.jumlahAnak,
                          (v) => setState(() => _selectedJumlahAnak = v), icon: Icons.family_restroom_outlined),
                    _Dropdown('Occupation', _selectedPekerjaan, MasterData.pekerjaan,
                        (v) => setState(() => _selectedPekerjaan = v), icon: Icons.work_outline),
                    _Field(_ktpPassport, 'KTP / Passport Number', icon: Icons.credit_card_outlined,
                        keyboard: TextInputType.number),
                  ]),

                  const SizedBox(height: 24),

                  // ── LIFESTYLE & INTERESTS ────────────────────────
                  _SectionHeader(Icons.auto_awesome_rounded, 'LIFESTYLE & INTERESTS'),
                  _Card([
                    _Dropdown('Fashion Style', _selectedFashion, MasterData.fashionStyle,
                        (v) => setState(() => _selectedFashion = v), icon: Icons.checkroom),
                    _Dropdown('Hobby Category', _selectedHobbyKat,
                        MasterData.hobiKategori.keys.toList(), (v) {
                      setState(() { _selectedHobbyKat = v; _selectedHobbySub = null; });
                    }, icon: Icons.category_outlined),
                    if (_selectedHobbyKat != null)
                      _Dropdown('Hobby Detail', _selectedHobbySub,
                          MasterData.hobiKategori[_selectedHobbyKat]!,
                          (v) => setState(() => _selectedHobbySub = v),
                          icon: Icons.interests_outlined),
                    if (_selectedHobbyKat == 'Others')
                      _Field(_hobbyOthers, 'Other Hobby (specify)', icon: Icons.edit_note_rounded),
                    _Dropdown('Favorite Color', _selectedWarna, MasterData.warnaFavorit,
                        (v) => setState(() => _selectedWarna = v), icon: Icons.color_lens_outlined),
                    _Field(_liburanFavorit, 'Preferred Holiday Destination',
                        icon: Icons.beach_access_outlined),
                    _Field(_topikPembicaraan, 'Favorite Conversation Topics',
                        icon: Icons.chat_bubble_outline_rounded),
                  ]),

                  const SizedBox(height: 24),

                  // ── CULINARY PREFERENCES ─────────────────────────
                  _SectionHeader(Icons.restaurant_rounded, 'CULINARY PREFERENCES'),
                  _Card([
                    _Field(_makananFavorit, 'Favorite Food', icon: Icons.restaurant_menu),
                    _Field(_minumanFavorit, 'Favorite Drink', icon: Icons.local_bar),
                    _Field(_cakeFavorit, 'Favorite Cake', icon: Icons.cake_outlined),
                    _Field(_alergiMakanan, 'Food Allergies', icon: Icons.warning_amber_rounded),
                  ]),

                  const SizedBox(height: 24),

                  // ── SOCIAL MEDIA ─────────────────────────────────
                  _SectionHeader(Icons.alternate_email_rounded, 'SOCIAL MEDIA'),
                  _Card([
                    _Field(_instagram, 'Instagram', hint: '@username', icon: Icons.camera_alt_outlined),
                    _Field(_tiktok, 'TikTok', hint: '@username', icon: Icons.video_collection_outlined),
                  ]),

                  const SizedBox(height: 24),

                  // ── SALES INSIGHTS ───────────────────────────────
                  _SectionHeader(Icons.insights_rounded, 'SALES INSIGHTS'),
                  _Card([
                    _Dropdown('Purchase Triggers', _selectedPemicu, MasterData.pemicuBeli,
                        (v) => setState(() => _selectedPemicu = v), icon: Icons.shopping_bag_outlined),
                    _Dropdown('Interest Item', _selectedAntusias, MasterData.barangAntusias,
                        (v) => setState(() => _selectedAntusias = v), icon: Icons.star_border_rounded),
                    _Dropdown('Client Character', _selectedKarakter, MasterData.karakter,
                        (v) => setState(() => _selectedKarakter = v), icon: Icons.psychology_outlined),
                    _Field(_notes, 'Private Notes / Specific Character',
                        maxLines: 3, icon: Icons.note_alt_outlined),
                  ]),

                  const SizedBox(height: 40),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('CREATE CLIENT PROFILE',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }

  Widget _buildFotoSection() {
    return GestureDetector(
      onTap: _pickFoto,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        height: _fotoBytes != null ? 200 : 90,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _fotoBytes != null
                ? AppTheme.primary.withValues(alpha: 0.3)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: _fotoBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_fotoBytes!, fit: BoxFit.cover),
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() { _fotoBytes = null; _fotoFilename = null; }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Ganti Foto',
                            style: TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: AppTheme.primary.withValues(alpha: 0.5), size: 24),
                  const SizedBox(height: 6),
                  Text('Tambah Foto Customer',
                      style: TextStyle(fontSize: 12, color: AppTheme.primary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500)),
                  Text('Opsional · Galeri', style: TextStyle(fontSize: 10,
                      color: const Color(0xFF94A3B8).withValues(alpha: 0.8))),
                ],
              ),
      ),
    );
  }

  Widget _segmentButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  color: active ? AppTheme.primary : const Color(0xFF64748B))),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader(this.icon, this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 12),
    child: Row(children: [
      Icon(icon, size: 16, color: AppTheme.primary),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
              color: Color(0xFF475569), letterSpacing: 1.2)),
    ]));
}

class _SectionSubHeader extends StatelessWidget {
  final String title;
  const _SectionSubHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: Color(0xFF64748B))));
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card(this.children);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 20, offset: const Offset(0, 4))],
      border: Border.all(color: const Color(0xFFF1F5F9)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children));
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData? icon;
  const _Dropdown(this.label, this.value, this.items, this.onChanged, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        style: const TextStyle(fontSize: 14, color: AppTheme.dark, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFF94A3B8)) : null,
          labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        ),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: onChanged,
        isExpanded: true,
      ),
    );
  }
}

class _WordCapitalizeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    final text = nv.text;
    final buffer = StringBuffer();
    bool capitalizeNext = true;
    for (final ch in text.characters) {
      if (ch == ' ') {
        capitalizeNext = true;
        buffer.write(ch);
      } else if (capitalizeNext) {
        buffer.write(ch.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(ch);
      }
    }
    final result = buffer.toString();
    return nv.copyWith(
      text: result,
      selection: nv.selection.copyWith(
        baseOffset: nv.selection.baseOffset.clamp(0, result.length),
        extentOffset: nv.selection.extentOffset.clamp(0, result.length),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? prefixText;
  final bool required;
  final int maxLines;
  final TextInputType? keyboard;
  final IconData? icon;
  final bool titleCase;

  const _Field(this.controller, this.label,
      {this.hint, this.prefixText, this.required = false,
       this.keyboard, this.maxLines = 1, this.icon, this.titleCase = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        textCapitalization: titleCase ? TextCapitalization.words : TextCapitalization.none,
        inputFormatters: titleCase ? [_WordCapitalizeFormatter()] : null,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.dark),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFF94A3B8)) : null,
          prefixText: prefixText,
          prefixStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
          labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          hintStyle: TextStyle(fontSize: 13, color: const Color(0xFF94A3B8).withValues(alpha: 0.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        ),
        validator: required ? (v) => v == null || v.isEmpty ? 'Field required' : null : null,
      ),
    );
  }
}
