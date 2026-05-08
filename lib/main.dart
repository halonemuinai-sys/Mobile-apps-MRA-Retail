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
import 'supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E293B),
          elevation: 0, centerTitle: false,
          surfaceTintColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
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
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    }
    if (_advisor == null) {
      return LoginScreen(onLogin: (adv) => setState(() => _advisor = adv));
    }
    return MainShell(advisor: _advisor!, onLogout: () => setState(() => _advisor = null));
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

  static const _months = ['January','February','March','April','May','June',
    'July','August','September','October','November','December'];

  static const _labels  = ['Beranda', 'Prospek', 'Laporan'];
  static const _icons   = [Icons.home_outlined,   Icons.people_outline,    Icons.bar_chart_outlined];
  static const _actives = [Icons.home_rounded,    Icons.people_rounded,    Icons.bar_chart_rounded];

  void _navTo(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final adv = widget.advisor;

    final screens = [
      DashboardScreen(advisor: adv, month: _month, year: _year,
        onNavProspect: () => _navTo(1), onNavLaporan: () => _navTo(2)),
      ProspectsScreen(advisor: adv, month: _month, year: _year),
      ReportsScreen(advisor: adv, month: _month, year: _year),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // ── HEADER ──────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Advisor Portal', style: TextStyle(
            fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 1)),
          Text(adv.name, style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B),
            fontFamily: 'Georgia')),
        ]),
        actions: [
          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20, color: Color(0xFF94A3B8)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Pengaturan'), backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white),
                body: SettingsScreen(advisor: adv, onLogout: widget.onLogout),
              ))),
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout_outlined, size: 20, color: Color(0xFF94A3B8)),
            onPressed: () async {
              await AuthService.logout();
              widget.onLogout();
            },
          ),
        ],
      ),

      // ── MONTH/YEAR FILTER (sticky below header) ──────────────────────
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _month,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: Color(0xFF475569)),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF94A3B8)),
                    items: List.generate(12, (i) => DropdownMenuItem(
                      value: i + 1, child: Text(_months[i]))),
                    onChanged: (v) { if (v != null) setState(() => _month = v); },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _year,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                    color: Color(0xFF475569)),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF94A3B8)),
                  items: [2024, 2025, 2026].map((y) => DropdownMenuItem(
                    value: y, child: Text('$y'))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _year = v); },
                ),
              ),
            ),
          ]),
        ),
        Container(height: 1, color: const Color(0xFFE2E8F0)),

        // ── PAGES ──
        Expanded(child: IndexedStack(index: _tab, children: screens)),
      ]),

      // ── BOTTOM NAV ──────────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
          elevation: 0,
          items: List.generate(3, (i) => BottomNavigationBarItem(
            icon: Icon(_icons[i], size: 22),
            activeIcon: Icon(_actives[i], size: 22),
            label: _labels[i],
          )),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
