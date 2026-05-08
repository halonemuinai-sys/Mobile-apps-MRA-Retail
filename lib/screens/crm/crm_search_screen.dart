import 'package:flutter/material.dart';
import '../../models/advisor.dart';
import '../../models/profile.dart';
import '../../services/profile_service.dart';
import 'crm_detail_screen.dart';

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

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    setState(() { _loading = true; _searched = true; });
    try {
      final data = await ProfileService.search(
        q, store: widget.advisor.isManager ? widget.advisor.store : '');
      setState(() { _results = data; });
    } catch (e) {
      debugPrint('CRM search error: $e');
    } finally {
      setState(() => _loading = false);
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
            child: !_searched
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.person_search, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text('Cari pelanggan by nama atau nomor HP',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  ]))
                : _results.isEmpty
                    ? const Center(child: Text('Tidak ada hasil', style: TextStyle(color: Color(0xFF94A3B8))))
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
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                              ),
                              child: Row(children: [
                                CircleAvatar(
                                  radius: 20, backgroundColor: sc.withOpacity(0.15),
                                  child: Text(p.initials, style: TextStyle(color: sc,
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.displayName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      overflow: TextOverflow.ellipsis),
                                    if (p.namaPanggilan.isNotEmpty)
                                      Text('Panggilan: ${p.namaPanggilan}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
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
    );
  }
}
