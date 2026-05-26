import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceLogService {
  static const _flagKey  = 'trial_device_logged';
  static const _errorKey = 'trial_device_log_error';

  /// Kirim info device ke Supabase hanya sekali saat pertama install.
  /// Return null jika sukses, return pesan error jika gagal.
  static Future<String?> logIfFirstInstall() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_flagKey) == true) return null;

    try {
      final payload = await _buildPayload();
      if (payload == null) return null;

      await Supabase.instance.client.from('device_logs').insert(payload);

      await prefs.setBool(_flagKey, true);
      await prefs.remove(_errorKey);
      return null;
    } catch (e) {
      final msg = e.toString();
      await prefs.setString(_errorKey, msg);
      return msg;
    }
  }

  /// Ambil error terakhir (untuk debug / ditampilkan di UI).
  static Future<String?> getLastError() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_errorKey);
  }

  /// Reset flag agar device log bisa dikirim ulang.
  static Future<void> resetFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_flagKey);
    await prefs.remove(_errorKey);
  }

  static Future<Map<String, dynamic>?> _buildPayload() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await info.androidInfo;
      return {
        'flavor'      : 'trial',
        'brand'       : android.brand,
        'model'       : android.model,
        'device_name' : '${android.brand} ${android.model}',
        'android_ver' : android.version.release,
        'sdk_int'     : android.version.sdkInt,
        'device_id'   : android.id,
      };
    } else if (Platform.isIOS) {
      final ios = await info.iosInfo;
      return {
        'flavor'      : 'trial',
        'brand'       : 'Apple',
        'model'       : ios.model,
        'device_name' : ios.name,
        'android_ver' : ios.systemVersion,
        'sdk_int'     : null,
        'device_id'   : ios.identifierForVendor,
      };
    }
    return null;
  }
}
