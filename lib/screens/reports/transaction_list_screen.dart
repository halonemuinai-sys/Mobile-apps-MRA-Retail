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
  bool _isDpsSvc = false;
  String _subTab = 'ALL'; // 'ALL', 'DPS', 'SVC'
  String _locTab = 'ALL';
  String _sortBy = 'date_desc'; // 'date_desc', 'date_asc', 'no_asc', 'no_desc', 'sales_desc', 'sales_asc'
  List<Transaction> _transactions = [];
  List<Transaction> _filtered = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = _isDpsSvc
          ? await SalesService.getDpsSvcTransactions(
              advisorName: widget.advisor.name,
              month: widget.month,
              year: widget.year,
              isManager: widget.advisor.isManager || widget.advisor.isOpsManager,
              store: widget.advisor.store,
            )
          : await SalesService.getRecentTransactions(
              advisorName: widget.advisor.name,
              month: widget.month,
              year: widget.year,
              isManager: widget.advisor.isManager || widget.advisor.isOpsManager,
              store: widget.advisor.store,
            );
      setState(() {
        _transactions = res;
        _applyFilters();
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

  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      var temp = _transactions.where((t) {
        if (_isDpsSvc && _subTab != 'ALL') {
          final coll = t.collection.toUpperCase();
          if (_subTab == 'DPS' && !coll.contains('DPS')) return false;
          if (_subTab == 'SVC' && !coll.contains('SVC')) return false;
        }
        if (_locTab != 'ALL') {
          final loc = t.location.toUpperCase();
          if (_locTab == 'PI' && !(loc.contains('INDONESIA') || loc.contains('PI'))) return false;
          if (_locTab == 'PS' && !(loc.contains('SENAYAN') || loc.contains('PS'))) return false;
          if (_locTab == 'BALI' && !loc.contains('BALI')) return false;
        }
        return t.transNo.toLowerCase().contains(q) ||
               t.customer.toLowerCase().contains(q) ||
               t.mainCategory.toLowerCase().contains(q) ||
               t.collection.toLowerCase().contains(q) ||
               t.location.toLowerCase().contains(q);
      }).toList();

      if (_sortBy == 'date_desc') {
        temp.sort((a, b) {
          final cmp = b.transactionDate.compareTo(a.transactionDate);
          if (cmp != 0) return cmp;
          return b.transNo.compareTo(a.transNo);
        });
      } else if (_sortBy == 'date_asc') {
        temp.sort((a, b) {
          final cmp = a.transactionDate.compareTo(b.transactionDate);
          if (cmp != 0) return cmp;
          return a.transNo.compareTo(b.transNo);
        });
      } else if (_sortBy == 'no_asc') {
        temp.sort((a, b) => a.transNo.compareTo(b.transNo));
      } else if (_sortBy == 'no_desc') {
        temp.sort((a, b) => b.transNo.compareTo(a.transNo));
      } else if (_sortBy == 'sales_desc') {
        temp.sort((a, b) => b.netSales.compareTo(a.netSales));
      } else if (_sortBy == 'sales_asc') {
        temp.sort((a, b) => a.netSales.compareTo(b.netSales));
      }

      _filtered = temp;
    });
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Urutkan Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sortOption('Tanggal: Terbaru', 'date_desc'),
            _sortOption('Tanggal: Terlama', 'date_asc'),
            _sortOption('Nomor Invoice: A - Z', 'no_asc'),
            _sortOption('Nomor Invoice: Z - A', 'no_desc'),
            _sortOption('Net Sales: Tertinggi', 'sales_desc'),
            _sortOption('Net Sales: Terendah', 'sales_asc'),
          ],
        ),
      ),
    );
  }

  Widget _sortOption(String label, String value) {
    final active = _sortBy == value;
    return ListTile(
      title: Text(label, style: TextStyle(
        fontSize: 13, 
        fontWeight: active ? FontWeight.bold : FontWeight.normal,
        color: active ? AppTheme.primary : AppTheme.dark,
      )),
      trailing: active ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 20) : null,
      onTap: () {
        setState(() {
          _sortBy = value;
          _applyFilters();
        });
        Navigator.pop(context);
      },
    );
  }

  void _onSearch() {
    _applyFilters();
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
        if (_isDpsSvc) {
          await SalesService.updateDpsSvcCommission(transNo: t.transNo, value: val);
        } else {
          await SalesService.updateCommission(t.id, val);
        }
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

  Future<void> _sendExcelReportEmail() async {
    final monthNames = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    final mName = monthNames[widget.month - 1];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read_outlined, color: Color(0xFF10B981)),
              SizedBox(width: 10),
              Text('Kirim Laporan Excel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pilih butik — laporan $mName ${widget.year}:',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              _storeEmailOption('Plaza Indonesia', 'pi@mogems.co.id', Icons.location_city, const Color(0xFFB45309)),
              const SizedBox(height: 8),
              _storeEmailOption('Plaza Senayan', 'ps@mogems.co.id', Icons.location_city_outlined, const Color(0xFF047857)),
              const SizedBox(height: 8),
              _storeEmailOption('Bali', 'bali@mogems.co.id', Icons.beach_access_outlined, const Color(0xFF0369A1)),
              const SizedBox(height: 8),
              _storeEmailOption('Semua Lokasi (All Stores)', 'aris@mraretail.co.id', Icons.language, const Color(0xFF475569)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
          ],
        );
      },
    );
  }

  Widget _storeEmailOption(String locationName, String emailTarget, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _executeSendEmail(locationName, emailTarget);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(locationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(emailTarget, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Future<void> _executeSendEmail(String locationName, String emailTarget) async {
    final monthNames = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    final mName = monthNames[widget.month - 1];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(child: Text('Mengirim laporan ke $emailTarget...')),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      final (success, errMsg) = await SalesService.sendMonthlyExcelEmail(
        month: widget.month,
        year: widget.year,
        location: locationName,
        emailTo: emailTarget,
        ccEmail: 'aris@mraretail.co.id, jessica@mogems.co.id',
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Laporan $locationName $mName ${widget.year} terkirim ke $emailTarget'),
              backgroundColor: const Color(0xFF16A34A),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengirim email: $errMsg'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 8),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  int _countFor(String type) {
    if (type == 'ALL') return _transactions.length;
    return _transactions.where((t) => t.collection.toUpperCase().contains(type)).length;
  }

  Widget _subTabChip(String value, String label) {
    final isSelected = _subTab == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _subTab = value;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  int _locCountFor(String locCode) {
    if (locCode == 'ALL') return _transactions.length;
    return _transactions.where((t) {
      final loc = t.location.toUpperCase();
      if (locCode == 'PI') return loc.contains('INDONESIA') || loc.contains('PI');
      if (locCode == 'PS') return loc.contains('SENAYAN') || loc.contains('PS');
      if (locCode == 'BALI') return loc.contains('BALI');
      return false;
    }).length;
  }

  Widget _locTabChip(String value, String label) {
    final isSelected = _locTab == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _locTab = value;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.dark : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.dark : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  LinearGradient _getStoreGradient(String location) {
    final loc = location.toUpperCase();
    if (loc.contains('INDONESIA') || loc.contains('PI')) {
      // Plaza Indonesia - Warm Gold / Amber Tint
      return const LinearGradient(
        colors: [Color(0xFFFFFDF5), Color(0xFFFFF7ED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (loc.contains('SENAYAN') || loc.contains('PS')) {
      // Plaza Senayan - Emerald Green Tint
      return const LinearGradient(
        colors: [Color(0xFFF4FBF7), Color(0xFFE6F7ED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (loc.contains('BALI')) {
      // Bali - Ocean Sapphire Blue Tint
      return const LinearGradient(
        colors: [Color(0xFFF0F7FF), Color(0xFFE0F2FE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // Default / Other - Slate Purple Tint
      return const LinearGradient(
        colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  Color _getStoreBorderColor(String location) {
    final loc = location.toUpperCase();
    if (loc.contains('INDONESIA') || loc.contains('PI')) {
      return const Color(0xFFFCD34D); // Gold border
    } else if (loc.contains('SENAYAN') || loc.contains('PS')) {
      return const Color(0xFF6EE7B7); // Emerald border
    } else if (loc.contains('BALI')) {
      return const Color(0xFF7DD3FC); // Sapphire border
    } else {
      return const Color(0xFFE2E8F0);
    }
  }

  Color _getStoreBadgeTextColor(String location) {
    final loc = location.toUpperCase();
    if (loc.contains('INDONESIA') || loc.contains('PI')) {
      return const Color(0xFFB45309); // Amber gold text
    } else if (loc.contains('SENAYAN') || loc.contains('PS')) {
      return const Color(0xFF047857); // Emerald text
    } else if (loc.contains('BALI')) {
      return const Color(0xFF0369A1); // Sapphire text
    } else {
      return const Color(0xFF475569);
    }
  }

  Color _getStoreBadgeBgColor(String location) {
    final loc = location.toUpperCase();
    if (loc.contains('INDONESIA') || loc.contains('PI')) {
      return const Color(0xFFFEF3C7);
    } else if (loc.contains('SENAYAN') || loc.contains('PS')) {
      return const Color(0xFFD1FAE5);
    } else if (loc.contains('BALI')) {
      return const Color(0xFFE0F2FE);
    } else {
      return const Color(0xFFE2E8F0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.advisor.canViewTransactions) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Detail Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.dark,
          elevation: 0,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 64, color: Color(0xFFCBD5E1)),
                SizedBox(height: 16),
                Text('Akses Dibatasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                SizedBox(height: 8),
                Text('Detail transaksi hanya dapat diakses oleh Advisor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ),
      );
    }

    final totalFilteredNet = _filtered.fold<double>(0, (s, t) => s + t.netSales);
    final totalFilteredComm = _filtered.fold<double>(0, (s, t) => s + t.comm);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.dark,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: AppTheme.primary),
            tooltip: 'Urutkan',
            onPressed: _showSortDialog,
          ),
          IconButton(
            icon: const Icon(Icons.mark_email_read_outlined, color: Color(0xFF10B981)),
            tooltip: 'Kirim Email Excel ke aris@mraretail.co.id',
            onPressed: () => _sendExcelReportEmail(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_isDpsSvc ? 185 : 150),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_isDpsSvc) {
                            setState(() {
                              _isDpsSvc = false;
                              _subTab = 'ALL';
                              _transactions.clear();
                              _filtered.clear();
                            });
                            _load();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isDpsSvc ? AppTheme.dark : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'SALES TRANSACTIONS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: !_isDpsSvc ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!_isDpsSvc) {
                            setState(() {
                              _isDpsSvc = true;
                              _subTab = 'ALL';
                              _transactions.clear();
                              _filtered.clear();
                            });
                            _load();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isDpsSvc ? AppTheme.dark : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'DP & SERVICE (DPS/SVC)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _isDpsSvc ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isDpsSvc) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _subTabChip('ALL', 'ALL (${_countFor('ALL')})'),
                    const SizedBox(width: 6),
                    _subTabChip('DPS', 'DOWN PAYMENT (${_countFor('DPS')})'),
                    const SizedBox(width: 6),
                    _subTabChip('SVC', 'SERVICE (${_countFor('SVC')})'),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _locTabChip('ALL', 'ALL STORES (${_locCountFor('ALL')})'),
                    const SizedBox(width: 6),
                    _locTabChip('PI', 'PLAZA INDONESIA (${_locCountFor('PI')})'),
                    const SizedBox(width: 6),
                    _locTabChip('PS', 'PLAZA SENAYAN (${_locCountFor('PS')})'),
                    const SizedBox(width: 6),
                    _locTabChip('BALI', 'BALI (${_locCountFor('BALI')})'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: _isDpsSvc ? 'Cari DP/SVC Invoice...' : 'Cari Invoice atau Customer...',
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
            ],
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
                  itemCount: _filtered.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Top KPI Summary Card
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('TOTAL NET SALES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  Text(_fmt(totalFilteredNet), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 32, color: Colors.white24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('CARD COMM (MDR)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  Text(_fmt(totalFilteredComm), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${_filtered.length} Trans', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    }

                    final t = _filtered[index - 1];
                    final hasComm = t.comm > 0;
                    
                    return GestureDetector(
                      onTap: () => _showCommDialog(t),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: _getStoreGradient(t.location),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _getStoreBorderColor(t.location), width: 1.2),
                          boxShadow: [
                            BoxShadow(color: _getStoreBorderColor(t.location).withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))
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
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '#$index',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(t.transNo, 
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(t.transactionDate, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: hasComm ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: hasComm ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          hasComm ? Icons.check_circle_outline : Icons.edit_note_outlined,
                                          size: 14,
                                          color: hasComm ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          hasComm ? 'Comm: ${_fmt(t.comm)}' : 'Isi Comm',
                                          style: TextStyle(
                                            fontSize: 10, 
                                            fontWeight: FontWeight.bold,
                                            color: hasComm ? const Color(0xFF15803D) : const Color(0xFFB45309)
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, color: Color(0xFFCBD5E1)),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('CUSTOMER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                        const SizedBox(height: 4),
                                        Text(t.customer, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('NET SALES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.category_outlined, size: 11, color: Color(0xFF64748B)),
                                        const SizedBox(width: 4),
                                        Text(t.mainCategory, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _getStoreBadgeBgColor(t.location),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: _getStoreBorderColor(t.location)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 11, color: _getStoreBadgeTextColor(t.location)),
                                        const SizedBox(width: 4),
                                        Text(t.location, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStoreBadgeTextColor(t.location))),
                                      ],
                                    ),
                                  ),
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
