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

  bool get isManager =>
      role == 'store_manager' || role == 'asm' || role == 'spv';

  factory Advisor.fromPin(Map<String, dynamic> pin, {String homeLocation = ''}) {
    return Advisor(
      name: pin['advisor_name'] as String,
      homeLocation: homeLocation,
      role: (pin['role'] as String?) ?? 'advisor',
      store: (pin['store'] as String?) ?? homeLocation,
    );
  }
}
