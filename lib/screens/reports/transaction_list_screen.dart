import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/advisor.dart';
import '../../models/transaction.dart';
import '../../services/sales_service.dart';
import '../../theme.dart';

class TransactionListScreen extends StatefulWidget {
  final Advisor advisor;
  final int month;
  final int year;

  const TransactionListScreen({
    super.key,
    required this.advisor,
    required this.month,
    required this.year,
  });

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  bool _loading = true;
  List<Transaction> _transactions = [];
  List<Transaction> _filtered = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await SalesService.getRecentTransactions(
        advisorName: widget.advisor.name,
        month: widget.month,
        year: widget.year,
      );
      setState(() {
        _transactions = res;
        _filtered = res;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _transactions.where((t) {
        return t.transNo.toLowerCase().contains(q) ||
               t.customer.toLowerCase().contains(q) ||
               t.mainCategory.toLowerCase().contains(q);
      }).toList();
    });
  }

  String _fmt(double v) {
    final nfmt = NumberFormat.currency(locale: 'id_ID', symbol: 'IDR ', decimalDigits: 0);
    return nfmt.format(v);
  }

  Future<void> _showCommDialog(Transaction t) async {
    final ctrl = TextEditingController(text: t.comm > 0 ? t.comm.toInt().toString() : '');
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Input Card Comm / MDR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(t.transNo, style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.normal)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Net Sales: ${_fmt(t.netSales)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nilai Komisi (IDR)',
                hintText: 'Contoh: 15000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixText: 'IDR ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null) {
      final val = double.tryParse(result) ?? 0;
      setState(() => _loading = true);
      try {
        await SalesService.updateCommission(t.id, val);
        await _load(); // Refresh
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Berhasil update komisi'), backgroundColor: Color(0xFF16A34A)),
          );
        }
      } catch (e) {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal update: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.dark,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari Invoice atau Customer...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 64, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),
                      const Text('Tidak ada transaksi', style: TextStyle(color: Color(0xFF94A3B8))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final t = _filtered[index];
                    final hasComm = t.comm > 0;
                    
                    return GestureDetector(
                      onTap: () => _showCommDialog(t),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.transNo, 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
                                      const SizedBox(height: 2),
                                      Text(t.transactionDate, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: hasComm ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          hasComm ? Icons.check_circle_outline : Icons.edit_note_outlined,
                                          size: 14,
                                          color: hasComm ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          hasComm ? 'Comm: ${_fmt(t.comm)}' : 'Isi Comm',
                                          style: TextStyle(
                                            fontSize: 10, 
                                            fontWeight: FontWeight.bold,
                                            color: hasComm ? const Color(0xFF16A34A) : const Color(0xFFEA580C)
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, color: Color(0xFFF1F5F9)),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('CUSTOMER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                                        const SizedBox(height: 4),
                                        Text(t.customer, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('NET SALES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                                        const SizedBox(height: 4),
                                        Text(_fmt(t.netSales), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.category_outlined, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text(t.mainCategory, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text(t.location, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
