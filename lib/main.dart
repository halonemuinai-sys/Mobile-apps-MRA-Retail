import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/advisor.dart';
import 'screens/login/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/prospects/prospects_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/crm/crm_search_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'services/auth_service.dart';
import 'services/sales_service.dart';
import 'supabase_config.dart';
import 'theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const BvlgariAdvisorApp());
}

class BvlgariAdvisorApp extends StatelessWidget {
  const BvlgariAdvisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bvlgari Advisor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  Advisor? _advisor;
  bool _checking = true;

  @override
  void initState() { super.initState(); _checkSession(); }

  Future<void> _checkSession() async {
    final advisor = await AuthService.getStoredAdvisor();
    setState(() { _advisor = advisor; _checking = false; });
  }

  @override
  Widget build(BuildContext context) {
    Widget activeScreen;
    if (_checking) {
      activeScreen = const Scaffold(
        key: ValueKey('checking'),
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    } else if (_advisor == null) {
      activeScreen = LoginScreen(
        key: const ValueKey('login'),
        onLogin: (adv) => setState(() => _advisor = adv),
      );
    } else {
      activeScreen = MainShell(
        key: const ValueKey('shell'),
        advisor: _advisor!,
        onLogout: () => setState(() => _advisor = null),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.03),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: activeScreen,
    );
  }
}


class MainShell extends StatefulWidget {
  final Advisor advisor;
  final VoidCallback onLogout;
  const MainShell({super.key, required this.advisor, required this.onLogout});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  final now = DateTime.now();
  late int _month = DateTime.now().month;
  late int _year  = DateTime.now().year;

  // Store selector (for Ops Manager)
  String _selectedStore = 'All Stores';
  List<String> _availableStores = [];

  static const _months = ['January','February','March','April','May','June',
    'July','August','September','October','November','December'];

  static const _labels  = ['Beranda', 'Prospek', 'CRM', 'Laporan'];
  static const _icons   = [Icons.home_outlined,   Icons.people_outline,    Icons.person_search_outlined, Icons.bar_chart_outlined];
  static const _actives = [Icons.home_rounded,    Icons.people_rounded,    Icons.person_search_rounded, Icons.bar_chart_rounded];

  @override
  void initState() {
    super.initState();
    if (widget.advisor.isOpsManager) _loadStores();
  }

  Future<void> _loadStores() async {
    final stores = await SalesService.getAvailableStores();
    if (mounted) setState(() => _availableStores = stores);
  }

  /// The effective store: for OpsManager use dropdown; for others use their store.
  String get _effectiveStore {
    if (widget.advisor.isOpsManager) return _selectedStore;
    return widget.advisor.store;
  }

  void _navTo(int tab) => setState(() => _tab = tab);

  // ── Breakpoint: ≥600px is treated as tablet ──
  bool _isTablet(BuildContext ctx) => MediaQuery.of(ctx).size.width >= 600;

  // Shared AppBar used by both layouts
  PreferredSizeWidget _buildAppBar(Advisor adv) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFF1F5F9))),
      title: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('assets/logobvl.png', fit: BoxFit.contain))),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('MPI Advisor', style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          Text(adv.name, style: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ]),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded, size: 22, color: Color(0xFF64748B)),
          tooltip: 'Pengaturan',
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(title: Text('Pengaturan', style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                backgroundColor: Colors.white, surfaceTintColor: Colors.white),
              body: SettingsScreen(advisor: adv, onLogout: widget.onLogout)))),
        ),
        IconButton(
          icon: const Icon(Icons.power_settings_new_rounded, size: 22, color: Color(0xFF64748B)),
          tooltip: 'Keluar',
          onPressed: () async { await AuthService.logout(); widget.onLogout(); }),
        const SizedBox(width: 4),
      ],
    );
  }

  // Shared filter bar
  Widget _buildFilterBar() {
    final adv = widget.advisor;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(children: [
        // Store selector (only for Ops Manager)
        if (adv.isOpsManager) ...[
          Row(children: [
            const Icon(Icons.store_outlined, size: 20, color: Color(0xFF7C3AED)),
            const SizedBox(width: 12),
            Expanded(child: _FilterDropdown<String>(
              value: _selectedStore,
              items: [
                DropdownMenuItem(value: 'All Stores',
                  child: Text('All Stores', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED)))),
                ..._availableStores.map((s) => DropdownMenuItem(value: s,
                  child: Text(s, style: GoogleFonts.inter()))),
              ],
              onChanged: (v) { if (v != null) setState(() => _selectedStore = v); },
            )),
          ]),
          const SizedBox(height: 8),
        ],
        Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(child: _FilterDropdown<int>(
            value: _month,
            items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(_months[i], style: GoogleFonts.inter()))),
            onChanged: (v) { if (v != null) setState(() => _month = v); })),
          const SizedBox(width: 12),
          SizedBox(width: 100, child: _FilterDropdown<int>(
            value: _year,
            items: [2024,2025,2026].map((y) => DropdownMenuItem(value: y, child: Text('$y', style: GoogleFonts.inter()))).toList(),
            onChanged: (v) { if (v != null) setState(() => _year = v); })),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adv = widget.advisor;
    final tablet = _isTablet(context);
    final store = _effectiveStore;

    // Build an advisor copy with the effective store for downstream usage
    final effectiveAdv = Advisor(
      name: adv.name,
      homeLocation: adv.homeLocation,
      role: adv.role,
      store: store,
    );

    final screens = [
      DashboardScreen(advisor: effectiveAdv, month: _month, year: _year,
        onNavProspect: () => _navTo(1), onNavLaporan: () => _navTo(3)),
      ProspectsScreen(advisor: effectiveAdv, month: _month, year: _year),
      CrmSearchScreen(advisor: effectiveAdv),
      ReportsScreen(advisor: effectiveAdv, month: _month, year: _year),
    ];

    // ── Shared content area ──
    final content = Column(children: [
      _buildFilterBar(),
      Container(height: 1, color: const Color(0xFFF1F5F9)),
      Expanded(child: IndexedStack(index: _tab, children: screens)),
    ]);

    // ── TABLET LAYOUT ──
    if (tablet) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(adv),
        body: Row(children: [
          // Sidebar NavigationRail
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: NavigationRail(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              backgroundColor: Colors.white,
              indicatorColor: AppTheme.primary.withValues(alpha: 0.1),
              selectedIconTheme: const IconThemeData(color: AppTheme.primary, size: 24),
              unselectedIconTheme: const IconThemeData(color: Color(0xFF94A3B8), size: 22),
              selectedLabelTextStyle: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary),
              unselectedLabelTextStyle: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w400, color: const Color(0xFF94A3B8)),
              labelType: NavigationRailLabelType.all,
              minWidth: 80,
              groupAlignment: -0.5,
              destinations: List.generate(4, (i) => NavigationRailDestination(
                icon: Icon(_icons[i]),
                selectedIcon: Icon(_actives[i]),
                label: Text(_labels[i]),
                padding: const EdgeInsets.symmetric(vertical: 6),
              )),
            ),
          ),
          // Main content
          Expanded(child: content),
        ]),
      );
    }

    // ── PHONE LAYOUT (default) ──
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(adv),
      body: content,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border))),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textSub,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 10),
          elevation: 0,
          items: List.generate(4, (i) => BottomNavigationBarItem(
            icon: Icon(_icons[i], size: 22),
            activeIcon: Icon(_actives[i], size: 22),
            label: _labels[i],
          )),
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _FilterDropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F6F8),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value, isExpanded: true,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
        items: items,
        onChanged: onChanged,
      )));
}

