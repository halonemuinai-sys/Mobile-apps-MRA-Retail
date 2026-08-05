import 'package:flutter/material.dart';
import '../../models/advisor.dart';
import '../../models/profile.dart';
import '../../services/profile_service.dart';
import 'crm_detail_screen.dart';
import 'crm_input_screen.dart';
import '../../theme.dart';

class CrmSearchScreen extends StatefulWidget {
  final Advisor advisor;
  const CrmSearchScreen({super.key, required this.advisor});

  @override
  State<CrmSearchScreen> createState() => _CrmSearchScreenState();
}

class _CrmSearchScreenState extends State<CrmSearchScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  bool _searched = false;
  List<CrmProfile> _results = [];

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void didUpdateWidget(covariant CrmSearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.advisor.store != widget.advisor.store || oldWidget.advisor.name != widget.advisor.name) {
      _search();
    }
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (!mounted) return;
    setState(() { _loading = true; _searched = true; });
    try {
      final data = await ProfileService.search(
        q,
        store: widget.advisor.store == 'All Stores' ? '' : widget.advisor.store,
        advisor: (widget.advisor.isManager || widget.advisor.isOpsManager) ? '' : widget.advisor.name,
      );
      if (mounted) setState(() { _results = data; });
    } catch (e) {
      debugPrint('CRM search error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _storeColors = {
    'PI': Color(0xFF1E40AF),
    'PS': Color(0xFF7C3AED),
    'Bali': Color(0xFF059669),
  };

  Color _storeColor(String store) {
    if (store.contains('Intermark') || store.toUpperCase() == 'PI') return _storeColors['PI']!;
    if (store.contains('Senayan') || store.contains('Superstore') || store.toUpperCase() == 'PS') return _storeColors['PS']!;
    if (store.toLowerCase().contains('bali')) return _storeColors['Bali']!;
    return const Color(0xFF64748B);
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('vip') || s.contains('loyal')) return const Color(0xFFD97706);
    if (s.contains('new') || s.contains('prospect')) return const Color(0xFF2563EB);
    if (s.contains('active')) return const Color(0xFF059669);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      hintText: 'Cari nama, nomor HP...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading ? null : _search,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Cari', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Results
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada data pelanggan ditemukan',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _results.length,
                        itemBuilder: (ctx, i) {
                          final p = _results[i];
                          final sc = _storeColor(p.lokasiStore);
                          return GestureDetector(
                            onTap: () => Navigator.push(ctx,
                              MaterialPageRoute(builder: (_) => CrmDetailScreen(profile: p))),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border(left: BorderSide(color: sc, width: 3)),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                              ),
                              child: Row(children: [
                                CircleAvatar(
                                  radius: 20, backgroundColor: sc.withValues(alpha: 0.15),
                                  child: Text(p.initials, style: TextStyle(color: sc,
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(p.displayName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              overflow: TextOverflow.ellipsis),
                                          ),
                                          if (p.statusPelanggan.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _statusColor(p.statusPelanggan).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(p.statusPelanggan,
                                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _statusColor(p.statusPelanggan))),
                                            ),
                                        ],
                                      ),
                                      if (p.namaPanggilan.isNotEmpty)
                                        Text('Panggilan: ${p.namaPanggilan}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        if (p.domisili.isNotEmpty) ...[
                                          const Icon(Icons.location_on_outlined, size: 11, color: Color(0xFF94A3B8)),
                                          const SizedBox(width: 3),
                                          Text(p.domisili, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                          const SizedBox(width: 8),
                                        ],
                                        if (p.pekerjaan.isNotEmpty) ...[
                                          const Icon(Icons.work_outline, size: 11, color: Color(0xFF94A3B8)),
                                          const SizedBox(width: 3),
                                          Text(p.pekerjaan, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                        ],
                                      ]),
                                      const SizedBox(height: 2),
                                      Row(children: [
                                        if (p.noHp.isNotEmpty) ...[
                                          const Icon(Icons.phone, size: 11, color: Color(0xFF94A3B8)),
                                          const SizedBox(width: 3),
                                          Text(p.noHp, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                          const SizedBox(width: 8),
                                        ],
                                        if (p.customerAdvisor.isNotEmpty) ...[
                                          const Icon(Icons.person, size: 11, color: Color(0xFF94A3B8)),
                                          const SizedBox(width: 3),
                                          Expanded(child: Text(p.customerAdvisor,
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                            overflow: TextOverflow.ellipsis)),
                                        ],
                                      ]),
                                    ],
                                  )),
                                Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20),
                              ]),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_crm',
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CrmInputScreen(advisor: widget.advisor)),
          );
          if (res == true) _search(); // Refresh if new profile added
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
    );
  }
}
