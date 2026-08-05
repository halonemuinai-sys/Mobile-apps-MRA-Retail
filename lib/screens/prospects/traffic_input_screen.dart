import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../models/advisor.dart';
import '../../models/profile.dart';
import '../../services/profile_service.dart';
import '../../services/traffic_service.dart';
import '../../services/cdn_service.dart';
import '../../theme.dart';
import '../../constants/master_data.dart';
import '../../services/auth_service.dart';
import '../../services/catalog_service.dart';

class TrafficInputScreen extends StatefulWidget {
  final Advisor advisor;
  const TrafficInputScreen({super.key, required this.advisor});

  @override
  State<TrafficInputScreen> createState() => _TrafficInputScreenState();
}

class _TrafficInputScreenState extends State<TrafficInputScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // Form Fields
  final _nameCtrl = TextEditingController();
  final _panggilanCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _status = 'Follow Up';
  String _statusPelanggan = 'New Prospect';
  String? _locationStore;
  String? _servedBy;
  List<String> _advisorNames = [];
  String? _prospekLevel;
  String? _minatBarang;
  String? _aksesMasuk;
  String? _siapa;
  String? _faktorPemicu;
  String? _groupSize;
  Uint8List? _buktiBytes;
  String? _buktiFilename;
  DateTime _selectedDate = DateTime.now();
  final List<CatalogItem> _selectedItems = [];
  final _discountCtrl = TextEditingController();

  // CRM profile yang dipilih
  CrmProfile? _selectedProfile;

  double get _subtotal => _selectedItems.fold(0.0, (s, i) => s + i.harga);
  double get _discountAmount => _subtotal * (double.tryParse(_discountCtrl.text) ?? 0) / 100;
  double get _totalAfterDiscount => _subtotal - _discountAmount;

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _servedBy = widget.advisor.name;
    AuthService.getAdvisorNames().then((names) {
      if (mounted) setState(() => _advisorNames = names);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _buktiBytes = bytes;
      _buktiFilename = picked.name;
    });
  }

  // Pencarian Pelanggan via Modal
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchCustomerModal(
        advisor: widget.advisor,
        onSelected: _fillFromProfile,
      ),
    );
  }

  void _fillFromProfile(CrmProfile p) {
    setState(() {
      _selectedProfile = p;
      _nameCtrl.text = p.namaLengkap;
      _panggilanCtrl.text = p.namaPanggilan;
      _phoneCtrl.text = p.noHp;
      _emailCtrl.text = p.email;
      _statusPelanggan = p.statusPelanggan.isNotEmpty
          ? p.statusPelanggan
          : 'Existing Customer';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = {
        'customer_name': _nameCtrl.text,
        'nama_panggilan': _panggilanCtrl.text,
        'customer_advisor': widget.advisor.name,
        'served_by': _servedBy ?? widget.advisor.name,
        'location': _locationStore ?? widget.advisor.store,
        'status': _status,
        'tanggal_berkunjung': _selectedDate.toIso8601String().split('T')[0],
        'prospect_item': _prospekLevel ?? '',
        'minat_barang': _minatBarang ?? '',
        'akses_masuk': _aksesMasuk ?? '',
        'siapa': _siapa ?? '',
        'faktor_pemicu': _faktorPemicu ?? '',
        'group_size': _groupSize ?? '',
        'no_hp': _phoneCtrl.text,
        'email': _emailCtrl.text,
        'status_pelanggan': _statusPelanggan,
        'notes': _notesCtrl.text,
        'barang_diminati': _selectedItems.map((i) => '${i.displayCode} - ${i.deskripsi} (${i.hargaFormatted})').join('; '),
        'net_sales': _totalAfterDiscount.toInt(),
        'diskon_pct': double.tryParse(_discountCtrl.text) ?? 0,
        'bukti_chat': '',
      };

      // Upload bukti image jika ada
      if (_buktiBytes != null && _buktiFilename != null) {
        final url = await CdnService.uploadImage(
          bytes: _buktiBytes!,
          filename: _buktiFilename!,
          folder: 'bukti_chat',
        );
        if (url != null) data['bukti_chat'] = url;
      }

      final trafficId = await TrafficService.saveTraffic(data);

      // Simpan barang diminati ke tabel terstruktur
      if (_selectedItems.isNotEmpty) {
        await TrafficService.saveTrafficItems(
          trafficId,
          _selectedItems.map((i) => {
            'item_code': i.itemCode,
            'sap_code':  i.sapCode,
            'deskripsi': i.deskripsi,
            'harga':     i.harga,
            'kategori':  i.kategori,
            'koleksi':   i.koleksi,
          }).toList(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan harian berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Input Traffic Harian',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.dark,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionHeader('DATA PELANGGAN'),
                  _Card([
                    GestureDetector(
                      onTap: _showSearchModal,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Cari Nama / No. HP Pelanggan',
                            hintText: 'Klik untuk mencari...',
                            prefixIcon: const Icon(
                              Icons.person_search,
                              size: 20,
                              color: AppTheme.primary,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Pilih pelanggan' : null,
                        ),
                      ),
                    ),
                    if (_selectedProfile != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified_user_rounded,
                                  size: 14,
                                  color: Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Data dari CRM',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _showSearchModal,
                                  child: const Text(
                                    'Ganti',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF2563EB),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _CrmInfoRow(
                              Icons.phone_rounded,
                              'No. HP',
                              _selectedProfile!.noHp.isNotEmpty
                                  ? _selectedProfile!.noHp
                                  : '—',
                            ),
                            _CrmInfoRow(
                              Icons.badge_rounded,
                              'Panggilan',
                              _selectedProfile!.namaPanggilan.isNotEmpty
                                  ? _selectedProfile!.namaPanggilan
                                  : '—',
                            ),
                            _CrmInfoRow(
                              Icons.person_pin_rounded,
                              'Data diisi oleh',
                              _selectedProfile!.customerAdvisor.isNotEmpty
                                  ? _selectedProfile!.customerAdvisor
                                  : '—',
                            ),
                            _CrmInfoRow(
                              Icons.star_rounded,
                              'Status Pelanggan',
                              _selectedProfile!.statusPelanggan.isNotEmpty
                                  ? _selectedProfile!.statusPelanggan
                                  : '—',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 20),
                  _SectionHeader('DETAIL KUNJUNGAN'),
                  _Card([
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primary),
                          const SizedBox(width: 10),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Tanggal Kedatangan', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            Text(
                              '${_selectedDate.day.toString().padLeft(2, '0')} / ${_selectedDate.month.toString().padLeft(2, '0')} / ${_selectedDate.year}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            ),
                          ]),
                          const Spacer(),
                          const Icon(Icons.edit_calendar_rounded, size: 16, color: Color(0xFF94A3B8)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_advisorNames.isEmpty)
                      AbsorbPointer(
                        child: TextFormField(
                          initialValue: _servedBy,
                          decoration: _inputDecor('Served By').copyWith(
                            suffixIcon: const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          enabled: false,
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        key: ValueKey(_advisorNames.length),
                        initialValue: _servedBy,
                        decoration: _inputDecor('Served By'),
                        hint: const Text(
                          'Pilih advisor...',
                          style: TextStyle(fontSize: 13),
                        ),
                        items: _advisorNames
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _servedBy = v),
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue:
                          _locationStore ??
                          (MasterData.stores.contains(widget.advisor.store)
                              ? widget.advisor.store
                              : null),
                      decoration: _inputDecor('Location Store'),
                      hint: const Text(
                        'Pilih store...',
                        style: TextStyle(fontSize: 13),
                      ),
                      items: MasterData.stores
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _locationStore = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: _inputDecor('Tipe Traffic'),
                      items:
                          [
                                'Follow Up',
                                'Walk In',
                                'Delivery & Showing',
                                'Online Only',
                                'Upsell Repair Drop off',
                                'Repair Cancel',
                                'Upsell Repair Pick Up',
                                'Outsider',
                                'In House',
                              ]
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _prospekLevel,
                      decoration: _inputDecor('Prospek Level'),
                      hint: const Text(
                        'Pilih level prospek...',
                        style: TextStyle(fontSize: 13),
                      ),
                      items: MasterData.prospekLevel
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _prospekLevel = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _minatBarang,
                      decoration: _inputDecor('Minat Barang'),
                      hint: const Text(
                        'Pilih minat barang...',
                        style: TextStyle(fontSize: 13),
                      ),
                      items: MasterData.minatBarang
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _minatBarang = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _siapa,
                      decoration: _inputDecor('Siapa'),
                      hint: const Text(
                        'Pilih tipe pengunjung...',
                        style: TextStyle(fontSize: 13),
                      ),
                      items: MasterData.siapa
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _siapa = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _aksesMasuk,
                      decoration: _inputDecor('Akses Masuk'),
                      hint: const Text(
                        'Pilih akses masuk...',
                        style: TextStyle(fontSize: 13),
                      ),
                      items: MasterData.aksesMasuk
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _aksesMasuk = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _groupSize,
                      decoration: _inputDecor('Jumlah Orang dalam Group'),
                      hint: const Text('Pilih jumlah...', style: TextStyle(fontSize: 13)),
                      items: MasterData.groupSize
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) => setState(() => _groupSize = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _faktorPemicu,
                      decoration: _inputDecor('Faktor Pemicu Pembelian'),
                      hint: const Text('Pilih faktor pemicu...', style: TextStyle(fontSize: 13)),
                      items: MasterData.faktorPemicu
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) => setState(() => _faktorPemicu = v),
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      _notesCtrl,
                      'Catatan / Notes',
                      hint: 'Catatan tambahan...',
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _SectionHeader('BARANG DIMINATI'),
                  _Card([
                    if (_selectedItems.isNotEmpty) ...[
                      ..._selectedItems.asMap().entries.map((entry) {
                        final item = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item.displayCode, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              Text(item.deskripsi, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                              Text(item.hargaFormatted, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                            ])),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFDC2626)),
                              onPressed: () => setState(() => _selectedItems.removeAt(entry.key)),
                            ),
                          ]),
                        );
                      }),
                      const SizedBox(height: 4),
                    ],
                    if (_selectedItems.isNotEmpty) ...[
                      const Divider(height: 20),
                      Row(children: [
                        const Expanded(
                          child: Text('Estimasi Diskon (%)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ),
                        SizedBox(
                          width: 90,
                          child: TextFormField(
                            controller: _discountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              suffixText: '%',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      _TotalRow('Subtotal', _subtotal),
                      if (_discountAmount > 0) _TotalRow('Diskon', -_discountAmount, isDiscount: true),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(children: [
                          const Text('Total Estimasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const Spacer(),
                          Text(
                            _formatRp(_totalAfterDiscount),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 12),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _CatalogSearchModal(
                          onSelected: (item) => setState(() {
                            if (!_selectedItems.any((i) => i.sapCode == item.sapCode)) {
                              _selectedItems.add(item);
                            }
                          }),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tambah Barang', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _SectionHeader('BUKTI CHAT / APPOINTMENT'),
                  _Card([
                    if (_buktiBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _buktiBytes!,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: Text(
                            _buktiFilename ?? '',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() { _buktiBytes = null; _buktiFilename = null; }),
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                          label: const Text('Hapus', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                        ),
                      ]),
                    ] else
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                          ),
                          child: const Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 36, color: Color(0xFF94A3B8)),
                            SizedBox(height: 8),
                            Text('Pilih dari Galeri', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                            SizedBox(height: 2),
                            Text('Screenshot chat / appointment', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ]),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Simpan Laporan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  InputDecoration _inputDecor(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
  );
}

class _SearchCustomerModal extends StatefulWidget {
  final Advisor advisor;
  final Function(CrmProfile) onSelected;
  const _SearchCustomerModal({required this.advisor, required this.onSelected});

  @override
  State<_SearchCustomerModal> createState() => _SearchCustomerModalState();
}

class _SearchCustomerModalState extends State<_SearchCustomerModal> {
  final _ctrl = TextEditingController();
  List<CrmProfile> _results = [];
  bool _loading = false;

  void _search(String q) async {
    if (q.length < 3) return;
    setState(() => _loading = true);
    try {
      final results = await ProfileService.search(
        q,
        store: widget.advisor.store,
        advisor: widget.advisor.isManager ? '' : widget.advisor.name,
      );
      if (mounted)
        setState(() {
          _results = results;
        });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Cari nama atau nomor HP...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
              ),
              onChanged: _search,
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      'Cari minimal 3 huruf',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final p = _results[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Text(
                          p.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (p.noHp.isNotEmpty)
                              Text(
                                p.noHp,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            if (p.namaPanggilan.isNotEmpty)
                              Text(
                                'Panggilan: ${p.namaPanggilan}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            if (p.customerAdvisor.isNotEmpty)
                              Text(
                                'Data oleh: ${p.customerAdvisor}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Color(0xFFCBD5E1),
                        ),
                        onTap: () {
                          widget.onSelected(p);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: Color(0xFF94A3B8),
        letterSpacing: 1,
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card(this.children);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(children: children),
  );
}

class _CrmInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _CrmInfoRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _CatalogSearchModal extends StatefulWidget {
  final Function(CatalogItem) onSelected;
  const _CatalogSearchModal({required this.onSelected});
  @override
  State<_CatalogSearchModal> createState() => _CatalogSearchModalState();
}

class _CatalogSearchModalState extends State<_CatalogSearchModal> {
  final _ctrl = TextEditingController();
  List<CatalogItem> _results = [];
  bool _loading = false;

  void _search(String q) async {
    if (q.length < 3) { setState(() => _results = []); return; }
    setState(() => _loading = true);
    final res = await CatalogService.search(q);
    if (mounted) setState(() { _results = res; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Cari Barang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ketik SAP code atau nama item...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: const Color(0xFFF1F5F9),
              ),
              onChanged: _search,
            ),
          ]),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: _results.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 8),
                  Text(_ctrl.text.length < 3 ? 'Ketik minimal 3 karakter' : 'Produk tidak ditemukan',
                    style: const TextStyle(color: Color(0xFF94A3B8))),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _results.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final item = _results[i];
                    return GestureDetector(
                      onTap: () { widget.onSelected(item); Navigator.pop(context); },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)],
                        ),
                        child: Row(children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.diamond_outlined, size: 20, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                child: Text(item.displayCode, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                              ),
                              if (item.kategori.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text(item.kategori, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                                ),
                              ],
                              if (item.koleksi.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Text(item.koleksi, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                              ],
                            ]),
                            const SizedBox(height: 3),
                            Text(item.deskripsi, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Row(children: [
                              Text(item.hargaFormatted, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                              if (item.qoh > 0) ...[
                                const SizedBox(width: 8),
                                Text('QOH: ${item.qoh}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              ],
                            ]),
                          ])),
                          const Icon(Icons.add_circle_outline_rounded, size: 22, color: Color(0xFF2563EB)),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

String _formatRp(double amount) {
  if (amount == 0) return 'Rp 0';
  final n = amount.abs().toInt();
  final str = n.toString();
  final buf = StringBuffer('Rp ');
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
    buf.write(str[i]);
  }
  return buf.toString();
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isDiscount;
  const _TotalRow(this.label, this.amount, {this.isDiscount = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      const Spacer(),
      Text(
        '${isDiscount ? "- " : ""}${_formatRp(amount.abs())}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDiscount ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
        ),
      ),
    ]),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboard;
  const _Field(this.controller, this.label, {this.hint, this.keyboard});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    ),
  );
}
