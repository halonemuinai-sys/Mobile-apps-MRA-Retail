import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/customer_segment.dart';
import '../../services/segmentation_service.dart';
import '../../theme.dart';
import '../../widgets/fade_in_slide.dart';
import '../../widgets/hover_card.dart';
import 'customer_segment_detail_sheet.dart';

class CustomerSegmentScreen extends StatefulWidget {
  const CustomerSegmentScreen({super.key});

  @override
  State<CustomerSegmentScreen> createState() => _CustomerSegmentScreenState();
}

class _CustomerSegmentScreenState extends State<CustomerSegmentScreen> {
  bool _loadingKpis = true;
  bool _loadingCounts = true;
  bool _loadingCustomers = true;
  bool _loadingMore = false;
  
  Map<String, dynamic>? _kpis;
  Map<String, int> _counts = {};
  List<CustomerSegmentProfile> _customers = [];
  
  // Pagination & Filters
  final int _pageSize = 20;
  int _page = 0;
  bool _hasMore = true;
  String _searchQuery = '';
  String? _selectedSegment;
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  static const List<String> _segments = [
    'Top', 'Elite', 'High Potential', 'Potential', 'Prospect', 'Inactive'
  ];

  static const Map<String, Color> _segmentColors = {
    'Top': Color(0xFF0F172A),
    'Elite': Color(0xFF7C3AED),
    'High Potential': Color(0xFF0D9488),
    'Potential': Color(0xFF2563EB),
    'Prospect': Color(0xFF64748B),
    'Inactive': Color(0xFFE11D48),
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadAll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (!_loadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadAll() async {
    setState(() {
      _loadingKpis = true;
      _loadingCounts = true;
      _loadingCustomers = true;
      _page = 0;
      _hasMore = true;
    });

    final currentYear = DateTime.now().year;

    // Load KPIs, counts, and initial customers in parallel
    try {
      await Future.wait([
        _loadKPIs(currentYear),
        _loadCounts(),
        _loadInitialCustomers(),
      ]);
    } catch (e) {
      debugPrint('Error in _loadAll: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingKpis = false;
          _loadingCounts = false;
          _loadingCustomers = false;
        });
      }
    }
  }

  Future<void> _loadKPIs(int year) async {
    try {
      final kpis = await SegmentationService.getSegmentationKPIs(year: year);
      if (mounted) {
        setState(() {
          _kpis = kpis;
          _loadingKpis = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading KPIs: $e');
      if (mounted) setState(() => _loadingKpis = false);
    }
  }

  Future<void> _loadCounts() async {
    try {
      final counts = await SegmentationService.getSegmentCounts();
      if (mounted) {
        setState(() {
          _counts = counts;
          _loadingCounts = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading counts: $e');
      if (mounted) setState(() => _loadingCounts = false);
    }
  }

  Future<void> _loadInitialCustomers() async {
    try {
      final customers = await SegmentationService.getCustomers(
        page: 0,
        pageSize: _pageSize,
        search: _searchQuery,
        segmentFilter: _selectedSegment,
      );
      if (mounted) {
        setState(() {
          _customers = customers;
          _loadingCustomers = false;
          _hasMore = customers.length == _pageSize;
        });
      }
    } catch (e) {
      debugPrint('Error loading initial customers: $e');
      if (mounted) setState(() => _loadingCustomers = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    try {
      final nextPage = _page + 1;
      final newCustomers = await SegmentationService.getCustomers(
        page: nextPage,
        pageSize: _pageSize,
        search: _searchQuery,
        segmentFilter: _selectedSegment,
      );

      if (mounted) {
        setState(() {
          _page = nextPage;
          _customers.addAll(newCustomers);
          _loadingMore = false;
          _hasMore = newCustomers.length == _pageSize;
        });
      }
    } catch (e) {
      debugPrint('Error loading more customers: $e');
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    // Debounce or instant reload
    _loadInitialCustomers();
  }

  void _onSegmentSelected(String? seg) {
    setState(() {
      _selectedSegment = seg;
    });
    _loadInitialCustomers();
  }

  String _fmtCurrency(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(0)}M';
    return v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _fmtShort(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          'Customer Intel & Segment',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // ── KPI CARDS ──
            if (_loadingKpis || _kpis == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              )
            else
              FadeInSlide(
                delay: const Duration(milliseconds: 0),
                duration: const Duration(milliseconds: 400),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.45,
                  children: [
                    _buildKpiCard(
                      title: 'ACTIVE CUSTOMERS',
                      value: _kpis!['totalActiveCustomers'].toString(),
                      subtitle: 'Last 24 months',
                      icon: Icons.people_outline,
                      color: const Color(0xFF2563EB),
                    ),
                    _buildKpiCard(
                      title: 'AVG. LTV',
                      value: 'IDR ${_fmtShort(_kpis!['avgLtv'] as double)}',
                      subtitle: 'Per active customer',
                      icon: Icons.trending_up,
                      color: const Color(0xFF7C3AED),
                    ),
                    _buildKpiCard(
                      title: 'TOP SPENDER',
                      value: _kpis!['topSpender']['name'].toString(),
                      subtitle: 'Spend: IDR ${_fmtShort(_kpis!['topSpender']['spend'] as double)}',
                      icon: Icons.star_border_rounded,
                      color: const Color(0xFFD97706),
                      valueFontSize: 13,
                    ),
                    _buildKpiCard(
                      title: 'NEW CUST. RATIO',
                      value: '${(_kpis!['newCustomerRatio'] as double).toStringAsFixed(1)}%',
                      subtitle: 'Registered in $year',
                      icon: Icons.person_add_alt_1_outlined,
                      color: const Color(0xFF0D9488),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ── DONUT CHART CARD ──
            if (!_loadingCounts && _counts.isNotEmpty)
              FadeInSlide(
                delay: const Duration(milliseconds: 100),
                duration: const Duration(milliseconds: 400),
                child: _buildDonutChartCard(),
              ),
            const SizedBox(height: 16),

            // ── SEGMENT FILTERS (Badges) ──
            if (!_loadingCounts)
              FadeInSlide(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 400),
                child: _buildFilterChips(),
              ),
            const SizedBox(height: 12),

            // ── SEARCH BAR ──
            FadeInSlide(
              delay: const Duration(milliseconds: 250),
              duration: const Duration(milliseconds: 400),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Cari nama customer...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── CUSTOMERS DETAILED LIST ──
            _buildSectionHeader(),
            const SizedBox(height: 8),
            
            if (_loadingCustomers)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else if (_customers.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Tidak ada customer yang cocok dengan filter.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _customers.length + (_hasMore ? 1 : 0),
                itemBuilder: (ctx, idx) {
                  if (idx == _customers.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                    );
                  }

                  final c = _customers[idx];
                  return _buildCustomerItem(c);
                },
              ),
            
            const SizedBox(height: 100), // Navigation spacing
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    double valueFontSize = 16,
  }) {
    return HoverCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChartCard() {
    final total = _counts.values.fold<int>(0, (sum, val) => sum + val);

    final sections = _segments.where((seg) => (_counts[seg] ?? 0) > 0).map((seg) {
      final val = _counts[seg]!.toDouble();
      return PieChartSectionData(
        color: _segmentColors[seg],
        value: val,
        title: '',
        radius: 18,
        showTitle: false,
      );
    }).toList();

    return HoverCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEGMENT DISTRIBUTION',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    sections: sections,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: _segments.map((seg) {
                    final cnt = _counts[seg] ?? 0;
                    final pct = total > 0 ? (cnt / total * 100).toStringAsFixed(1) : '0';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _segmentColors[seg],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              seg,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$cnt ($pct%)',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _segments.length + 1,
        itemBuilder: (ctx, idx) {
          if (idx == 0) {
            final isSelected = _selectedSegment == null;
            return Container(
              margin: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: const Text('Semua'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) _onSegmentSelected(null);
                },
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF1E293B),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            );
          }

          final seg = _segments[idx - 1];
          final isSelected = _selectedSegment == seg;
          final color = _segmentColors[seg]!;
          final count = _counts[seg] ?? 0;

          return Container(
            margin: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text('$seg ($count)'),
              selected: isSelected,
              onSelected: (selected) {
                _onSegmentSelected(selected ? seg : null);
              },
              backgroundColor: Colors.white,
              selectedColor: color.withValues(alpha: 0.15),
              checkmarkColor: color,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : const Color(0xFF64748B),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? color.withValues(alpha: 0.5) : const Color(0xFFE2E8F0)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'DETAILED SEGMENT ANALYSIS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerItem(CustomerSegmentProfile c) {
    final color = _segmentColors[c.segment] ?? const Color(0xFF64748B);
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CustomerSegmentDetailSheet(
            customerName: c.name,
            segment: c.segment,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: color, width: 3.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: const Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          c.segment.toUpperCase(),
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildMetricText('LTV: ', 'IDR ${_fmtCurrency(c.ltv)}'),
                      _buildDivider(),
                      _buildMetricText('Freq: ', '${c.freqInvoice} x'),
                      _buildDivider(),
                      _buildMetricText('Recency: ', '${c.recencyDays}d'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricText(String label, String val) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
        children: [
          TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.w400)),
          TextSpan(text: val, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      height: 8,
      width: 1,
      color: const Color(0xFFCBD5E1),
    );
  }
}
