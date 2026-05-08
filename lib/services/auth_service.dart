import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/advisor.dart';

class AuthService {
  static final _sb = Supabase.instance.client;

  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  static Future<List<String>> getAdvisorNames() async {
    final res = await _sb.from('advisors').select('name').order('name');
    return (res as List).map((r) => r['name'] as String).toList();
  }

  // Returns unique stores from advisors table
  static Future<List<String>> getStores() async {
    final res = await _sb.from('advisors').select('home_location').order('home_location');
    final stores = (res as List)
        .map((r) => (r['home_location'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return stores;
  }

  // Returns advisor names filtered by store
  static Future<List<String>> getAdvisorNamesByStore(String store) async {
    final res = await _sb
        .from('advisors')
        .select('name')
        .eq('home_location', store)
        .order('name');
    return (res as List).map((r) => r['name'] as String).toList();
  }

  static Future<Advisor?> login(String name, String pin) async {
    final hash = _hashPin(pin);
    final res = await _sb
        .from('advisor_pins')
        .select()
        .eq('advisor_name', name)
        .eq('pin_hash', hash)
        .maybeSingle();
    if (res == null) return null;

    final advRes = await _sb
        .from('advisors')
        .select('home_location')
        .eq('name', name)
        .maybeSingle();
    final homeLocation = (advRes?['home_location'] as String?) ?? '';

    final advisor = Advisor.fromPin(res, homeLocation: homeLocation);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('advisor_name', advisor.name);
    await prefs.setString('advisor_role', advisor.role);
    await prefs.setString('advisor_store', advisor.store);
    await prefs.setString('advisor_home', advisor.homeLocation);

    return advisor;
  }

  static Future<Advisor?> getStoredAdvisor() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('advisor_name');
    if (name == null) return null;
    return Advisor(
      name: name,
      homeLocation: prefs.getString('advisor_home') ?? '',
      role:  prefs.getString('advisor_role') ?? 'advisor',
      store: prefs.getString('advisor_store') ?? '',
    );
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> changePin(String advisorName, String oldPin, String newPin) async {
    final oldHash = _hashPin(oldPin);
    final newHash = _hashPin(newPin);
    final check = await _sb
        .from('advisor_pins')
        .select('advisor_name')
        .eq('advisor_name', advisorName)
        .eq('pin_hash', oldHash)
        .maybeSingle();
    if (check == null) return false;
    await _sb
        .from('advisor_pins')
        .update({'pin_hash': newHash, 'updated_at': DateTime.now().toIso8601String()})
        .eq('advisor_name', advisorName);
    return true;
  }
}
