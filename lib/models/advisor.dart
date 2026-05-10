class Advisor {
  final String name;
  final String homeLocation;
  final String role;
  final String store;

  const Advisor({
    required this.name,
    required this.homeLocation,
    required this.role,
    required this.store,
  });

  bool get isManager {
    final r = role.toLowerCase();
    return r.contains('manager') || r.contains('supervisor') || r.contains('spv') || r == 'asm';
  }

  /// Operations Manager can view ALL stores
  bool get isOpsManager => role.toLowerCase().contains('operation');

  factory Advisor.fromPin(Map<String, dynamic> pin, {String homeLocation = ''}) {
    return Advisor(
      name: pin['advisor_name'] as String,
      homeLocation: homeLocation,
      role: (pin['role'] as String?) ?? 'advisor',
      store: (pin['store'] as String?) ?? homeLocation,
    );
  }
}
