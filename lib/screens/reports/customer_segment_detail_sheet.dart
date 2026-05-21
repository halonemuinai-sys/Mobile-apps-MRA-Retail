import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/customer_segment.dart';
import '../../services/segmentation_service.dart';
import '../../theme.dart';

class CustomerSegmentDetailSheet extends StatefulWidget {
  final String customerName;
  final String segment;
  const CustomerSegmentDetailSheet({
    super.key,
    required this.customerName,
    required this.segment,
  });

  @override
  State<CustomerSegmentDetailSheet> createState() => _CustomerSegmentDetailSheetState();
}

class _CustomerSegmentDetailSheetState extends State<CustomerSegmentDetailSheet> {
  bool _loading = true;
  CustomerSegmentDetail? _detail;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final detail = await SegmentationService.getCustomerDetail(widget.customerName);
      if (mounted) {
        setState(() {
          _detail = detail;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading segment details: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtCurrency(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) {
      final m = v / 1e6;
      return '${m.toStringAsFixed(m >= 100 ? 0 : 1)}M';
    }
    return v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Color _getSegmentColor() {
    switch (widget.segment) {
      case 'Top':
        return const Color(0xFFD97706); // Amber
      case 'Elite':
        return const Color(0xFF7C3AED); // Purple
      case 'High Potential':
        return const Color(0xFF0D9488); // Teal
      case 'Potential':
        return const Color(0xFF2563EB); // Blue
      case 'Inactive':
        return const Color(0xFFE11D48); // Rose
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  @override
  Widget build(BuildContext context) {
    final segmentColor = _getSegmentColor();
    final sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: segmentColor.withValues(alpha: 0.15),
                  child: Text(
                    widget.customerName.isNotEmpty ? widget.customerName.trim().substring(0, 1).toUpperCase() : 'C',
                    style: TextStyle(
                      color: segmentColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.customerName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: segmentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: segmentColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              widget.segment.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: segmentColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Body
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _detail == null
                    ? const Center(child: Text('Gagal mengambil detail customer.'))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                        children: [
                          // KPI Summary row
                          Row(
                            children: [
                              Expanded(
                                child: _buildKpiCard(
                                  label: 'LIFETIME VALUE',
                                  value: 'IDR ${_fmtCurrency(_detail!.totalSpend)}',
                                  icon: Icons.payments_outlined,
                                  color: const Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildKpiCard(
                                  label: 'TOTAL KUANTITAS',
                                  value: '${_detail!.totalQty} Pcs',
                                  icon: Icons.shopping_bag_outlined,
                                  color: const Color(0xFF0D9488),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Visit details
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow('Kunjungan Pertama', _detail!.firstVisit),
                                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                                _buildDetailRow('Kunjungan Terakhir', _detail!.lastVisit),
                                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                                _buildDetailRow('Total Invoice', '${_detail!.transactions.length} kali'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Top Collections
                          if (_detail!.topCollections.isNotEmpty) ...[
                            _buildSectionLabel('TOP COLLECTIONS'),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                children: _detail!.topCollections.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final col = entry.value;
                                  final maxVal = _detail!.topCollections.first.value;
                                  final pct = maxVal > 0 ? col.value / maxVal : 0.0;
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: i == _detail!.topCollections.length - 1 ? 0 : 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              col.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF1E293B),
                                              ),
                                            ),
                                            Text(
                                              'IDR ${_fmtCurrency(col.value)} (${col.qty} Qty)',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value: pct,
                                            minHeight: 5,
                                            backgroundColor: const Color(0xFFF1F5F9),
                                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Transactions List
                          _buildSectionLabel('RIWAYAT TRANSAKSI'),
                          const SizedBox(height: 8),
                          if (_detail!.transactions.isEmpty)
                            const Center(child: Text('Tidak ada riwayat transaksi.'))
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _detail!.transactions.length,
                              itemBuilder: (ctx, idx) {
                                final tx = _detail!.transactions[idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.receipt_long_outlined,
                                          size: 18,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tx.collection.isNotEmpty ? tx.collection : 'Uncategorized',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF1E293B),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${tx.category} • ${tx.location}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  tx.date,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF94A3B8),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '|  No: ${tx.transNo}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'IDR ${_fmtCurrency(tx.netSales)}',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${tx.qty} Qty',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF94A3B8),
        letterSpacing: 0.7,
      ),
    );
  }
}
