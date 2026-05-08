import 'package:flutter/material.dart';
import '../../models/advisor.dart';
import '../../models/profile.dart';
import '../../services/profile_service.dart';
import '../../services/traffic_service.dart';
import '../../theme.dart';

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
  final _itemCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  
  String _status = 'Walk-in';
  String _statusPelanggan = 'New Prospect';
  final DateTime _selectedDate = DateTime.now();

  // Pencarian Pelanggan via Modal
  void _showSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchCustomerModal(advisor: widget.advisor, onSelected: _fillFromProfile),
    );
  }

  void _fillFromProfile(CrmProfile p) {
    setState(() {
      _nameCtrl.text = p.namaLengkap;
      _panggilanCtrl.text = p.namaPanggilan;
      _phoneCtrl.text = p.noHp;
      _emailCtrl.text = p.email;
      _statusPelanggan = p.statusPelanggan.isNotEmpty ? p.statusPelanggan : 'Existing Customer';
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
        'location': widget.advisor.store,
        'status': _status,
        'tanggal_berkunjung': _selectedDate.toIso8601String().split('T')[0],
        'prospect_item': _itemCtrl.text,
        'no_hp': _phoneCtrl.text,
        'email': _emailCtrl.text,
        'status_pelanggan': _statusPelanggan,
        'notes': _notesCtrl.text,
        'net_sales': 0,
      };

      await TrafficService.saveTraffic(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan harian berhasil disimpan'), backgroundColor: Colors.green),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Input Traffic Harian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                            labelText: 'Cari Nama Pelanggan',
                            hintText: 'Klik untuk mencari...',
                            prefixIcon: const Icon(Icons.person_search, size: 20, color: AppTheme.primary),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Pilih pelanggan' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _Field(_phoneCtrl, 'No. HP', keyboard: TextInputType.phone)),
                      const SizedBox(width: 10),
                      Expanded(child: _Field(_panggilanCtrl, 'Nama Panggilan')),
                    ]),
                  ]),
                  const SizedBox(height: 20),
                  _SectionHeader('DETAIL KUNJUNGAN'),
                  _Card([
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: _inputDecor('Tipe Traffic'),
                      items: ['Walk-in', 'Follow Up', 'Delivery', 'Service/Repair', 'Online Inquiry']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    const SizedBox(height: 12),
                    _Field(_itemCtrl, 'Item / Kebutuhan', hint: 'Misal: B.Zero1 Ring'),
                    _Field(_notesCtrl, 'Catatan / Notes', hint: 'Catatan tambahan...'),
                  ]),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Simpan Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
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
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
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
      if (mounted) setState(() { _results = results; });
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
      child: Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Cari nama atau nomor HP...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
            ),
            onChanged: _search,
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: _results.isEmpty
              ? Center(child: Text('Cari minimal 3 huruf', style: TextStyle(color: Colors.grey.shade400)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _results.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final p = _results[i];
                    return ListTile(
                      title: Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(p.noHp),
                      onTap: () {
                        widget.onSelected(p);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1)));
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card(this.children);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(children: children));
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
        labelText: label, hintText: hint,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      )));
}
