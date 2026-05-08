import 'package:flutter/material.dart';
import '../../models/advisor.dart';
import '../../services/profile_service.dart';
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

  // Controllers - Utama
  String? _selectedStatusPelanggan;
  String? _selectedTitle;
  final _namaLengkap = TextEditingController();
  final _namaPanggilan = TextEditingController();
  final _noHp = TextEditingController();
  final _email = TextEditingController();

  // Controllers - Identitas & Domisili
  String? _selectedKewarganegaraan;
  String? _domisiliType = 'Dalam Negeri';
  String? _selectedDomisili;
  String? _selectedUmur;
  String? _selectedEtnis;
  String? _selectedPernikahan;
  String? _selectedAnak;
  String? _selectedTinggi;
  String? _selectedBentuk;
  String? _selectedPekerjaan;
  final _tglLahir = TextEditingController();

  // Controllers - Lifestyle & Minat
  String? _selectedFashion;
  String? _selectedHobbyKat;
  String? _selectedHobbySub;
  String? _selectedWarna;
  final _liburanFavorit = TextEditingController();
  String? _selectedHariRaya;

  // Controllers - Kuliner
  final _makananFavorit = TextEditingController();
  final _minumanFavorit = TextEditingController();
  final _alergiMakanan = TextEditingController();

  // Controllers - Social Media
  final _instagram = TextEditingController();
  final _tiktok = TextEditingController();

  // Controllers - Insight
  String? _selectedPemicu;
  String? _selectedAntusias;
  String? _selectedKarakter;
  final _karakter = TextEditingController();

  String get _phonePrefix {
    if (_selectedKewarganegaraan != null && MasterData.phoneCodes.containsKey(_selectedKewarganegaraan)) {
      return '+${MasterData.phoneCodes[_selectedKewarganegaraan]} ';
    }
    return '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final fullNoHp = '$_phonePrefix${_noHp.text}'.replaceAll(' ', '');
      
      final data = {
        'title': _selectedTitle ?? '',
        'nama_lengkap': _namaLengkap.text,
        'nama_panggilan': _namaPanggilan.text,
        'full_name_tittle': '${_selectedTitle ?? ''} ${_namaLengkap.text}'.trim(),
        'no_hp': fullNoHp,
        'email': _email.text,
        'tanggal_lahir': _tglLahir.text,
        'umur': _selectedUmur ?? '',
        'tinggi_badan': _selectedTinggi ?? '',
        'bentuk_tubuh': _selectedBentuk ?? '',
        'domisili': _selectedDomisili ?? '',
        'kewarganegaraan': _selectedKewarganegaraan ?? '',
        'status_pernikahan': _selectedPernikahan ?? '',
        'memiliki_anak': _selectedAnak ?? '',
        'pekerjaan': _selectedPekerjaan ?? '',
        'fashion_style': _selectedFashion ?? '',
        'hobby': _selectedHobbySub ?? '',
        'hobby_kategori': _selectedHobbyKat ?? '',
        'warna_favorit': _selectedWarna ?? '',
        'tempat_liburan_favorit': _liburanFavorit.text,
        'makanan_favorit': _makananFavorit.text,
        'minuman_favorit': _minumanFavorit.text,
        'alergi_makanan': _alergiMakanan.text,
        'instagram': _instagram.text,
        'tiktok': _tiktok.text,
        'faktor_pemicu_pembelian': _selectedPemicu ?? '',
        'barang_antusias': _selectedAntusias ?? '',
        'karakter': _selectedKarakter ?? '',
        'notes': _karakter.text,
        'customer_advisor': widget.advisor.name,
        'lokasi_store': widget.advisor.store,
        'created_at': DateTime.now().toIso8601String(),
        'status_pelanggan': _selectedStatusPelanggan ?? 'New',
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
        title: const Text('New Client Profiling', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.dark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  _SectionHeader(Icons.person_pin_rounded, 'PRIMARY INFORMATION'),
                  _Card([
                    _Dropdown('Client Status', _selectedStatusPelanggan, MasterData.statusPelanggan, (v) => setState(() => _selectedStatusPelanggan = v)),
                    Row(
                      children: [
                        Expanded(flex: 2, child: _Dropdown('Title', _selectedTitle, MasterData.titles, (v) => setState(() => _selectedTitle = v))),
                        const SizedBox(width: 12),
                        Expanded(flex: 5, child: _Field(_namaLengkap, 'Full Name', required: true, icon: Icons.badge_outlined)),
                      ],
                    ),
                    _Field(_namaPanggilan, 'Preferred Name', icon: Icons.face_retouching_natural),
                  ]),
                  const SizedBox(height: 24),
                  _SectionHeader(Icons.contact_phone_rounded, 'CONTACT DETAILS'),
                  _Card([
                    _Dropdown('Nationality', _selectedKewarganegaraan, MasterData.negara, (v) => setState(() => _selectedKewarganegaraan = v), icon: Icons.public),
                    _Field(
                      _noHp, 
                      'Mobile Number', 
                      required: true, 
                      keyboard: TextInputType.phone, 
                      prefixText: _phonePrefix.isEmpty ? null : _phonePrefix,
                      hint: '8123456xxx',
                      icon: Icons.phone_android_rounded,
                    ),
                    _Field(_email, 'Email Address', keyboard: TextInputType.emailAddress, icon: Icons.email_outlined),
                  ]),
                  const SizedBox(height: 24),
                  _SectionHeader(Icons.home_work_rounded, 'DOMICILE & IDENTITY'),
                  _Card([
                    _SectionSubHeader('Current Domicile Type'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          _segmentButton('Domestic', _domisiliType == 'Dalam Negeri', () => setState(() { _domisiliType = 'Dalam Negeri'; _selectedDomisili = null; })),
                          _segmentButton('International', _domisiliType == 'Luar Negeri', () => setState(() { _domisiliType = 'Luar Negeri'; _selectedDomisili = null; })),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Dropdown('City/Province/Country', _selectedDomisili, 
                      _domisiliType == 'Dalam Negeri' ? MasterData.provinsi : MasterData.negara, 
                      (v) => setState(() => _selectedDomisili = v), icon: Icons.location_on_outlined),
                    const Divider(height: 32, thickness: 1, color: Color(0xFFF1F5F9)),
                    _Field(_tglLahir, 'Date of Birth', hint: 'YYYY-MM-DD', icon: Icons.calendar_month_outlined),
                    _Dropdown('Age Range', _selectedUmur, MasterData.umurOptions, (v) => setState(() => _selectedUmur = v), icon: Icons.trending_up),
                    _Dropdown('Height Range', _selectedTinggi, MasterData.tinggiOptions, (v) => setState(() => _selectedTinggi = v), icon: Icons.height),
                    _Dropdown('Body Shape', _selectedBentuk, MasterData.bentukTubuh, (v) => setState(() => _selectedBentuk = v), icon: Icons.accessibility_new_rounded),
                    _Dropdown('Ethnicity', _selectedEtnis, MasterData.etnis, (v) => setState(() => _selectedEtnis = v), icon: Icons.people_outline),
                    _Dropdown('Marital Status', _selectedPernikahan, MasterData.statusPernikahan, (v) => setState(() => _selectedPernikahan = v), icon: Icons.favorite_border),
                    _Dropdown('Have Children?', _selectedAnak, MasterData.memilikiAnak, (v) => setState(() => _selectedAnak = v), icon: Icons.child_care_rounded),
                    _Dropdown('Occupation', _selectedPekerjaan, MasterData.pekerjaan, (v) => setState(() => _selectedPekerjaan = v), icon: Icons.work_outline),
                  ]),
                  const SizedBox(height: 24),
                  _SectionHeader(Icons.auto_awesome_rounded, 'LIFESTYLE & INTERESTS'),
                  _Card([
                    _Dropdown('Fashion Style', _selectedFashion, MasterData.fashionStyle, (v) => setState(() => _selectedFashion = v), icon: Icons.checkroom),
                    _Dropdown('Hobby Category', _selectedHobbyKat, MasterData.hobiKategori.keys.toList(), (v) {
                      setState(() { _selectedHobbyKat = v; _selectedHobbySub = null; });
                    }, icon: Icons.category_outlined),
                    if (_selectedHobbyKat != null)
                      _Dropdown('Hobby Detail', _selectedHobbySub, MasterData.hobiKategori[_selectedHobbyKat]!, (v) => setState(() => _selectedHobbySub = v), icon: Icons.interests_outlined),
                    _Dropdown('Favorite Color', _selectedWarna, MasterData.warnaFavorit, (v) => setState(() => _selectedWarna = v), icon: Icons.color_lens_outlined),
                    _Field(_liburanFavorit, 'Preferred Holiday Destination', icon: Icons.beach_access_outlined),
                    _Dropdown('Major Religious Holiday', _selectedHariRaya, MasterData.hariRaya, (v) => setState(() => _selectedHariRaya = v), icon: Icons.celebration_outlined),
                  ]),
                  const SizedBox(height: 24),
                  _SectionHeader(Icons.restaurant_rounded, 'CULINARY PREFERENCES'),
                  _Card([
                    _Field(_makananFavorit, 'Favorite Food', icon: Icons.restaurant_menu),
                    _Field(_minumanFavorit, 'Favorite Drink', icon: Icons.local_bar),
                    _Field(_alergiMakanan, 'Food Allergies', icon: Icons.warning_amber_rounded),
                  ]),
                  const SizedBox(height: 24),
                  _SectionHeader(Icons.alternate_email_rounded, 'SOCIAL MEDIA'),
                  _Card([
                    _Field(_instagram, 'Instagram', hint: '@username', icon: Icons.camera_alt_outlined),
                    _Field(_tiktok, 'TikTok', hint: '@username', icon: Icons.video_collection_outlined),
                  ]),
                  const SizedBox(height: 24),
                  _SectionHeader(Icons.insights_rounded, 'SALES INSIGHTS'),
                  _Card([
                    _Dropdown('Purchase Triggers', _selectedPemicu, MasterData.pemicuBeli, (v) => setState(() => _selectedPemicu = v), icon: Icons.shopping_bag_outlined),
                    _Dropdown('Interest Item', _selectedAntusias, MasterData.barangAntusias, (v) => setState(() => _selectedAntusias = v), icon: Icons.star_border_rounded),
                    _Dropdown('Client Character', _selectedKarakter, MasterData.karakter, (v) => setState(() => _selectedKarakter = v), icon: Icons.psychology_outlined),
                    _Field(_karakter, 'Private Notes / Specific Character', maxLines: 3, icon: Icons.note_alt_outlined),
                  ]),
                  const SizedBox(height: 40),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
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
                      child: const Text('CREATE CLIENT PROFILE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 48),
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
            boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.w500, color: active ? AppTheme.primary : const Color(0xFF64748B))),
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
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 1.2)),
      ],
    ));
}

class _SectionSubHeader extends StatelessWidget {
  final String title;
  const _SectionSubHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))));
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
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4))],
      border: Border.all(color: const Color(0xFFF1F5F9))
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
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        ),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: onChanged,
        isExpanded: true,
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

  const _Field(this.controller, this.label, {this.hint, this.prefixText, this.required = false, this.keyboard, this.maxLines = 1, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.dark),
        decoration: InputDecoration(
          labelText: label, hintText: hint,
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
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        ),
        validator: required ? (v) => v == null || v.isEmpty ? 'Field required' : null : null,
      ),
    );
  }
}
