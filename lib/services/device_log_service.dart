
class DeviceLogService {
  /// Kirim info device ke Supabase (Dinonaktifkan agar tidak ada error device log).
  static Future<String?> logIfFirstInstall() async {
    return null;
  }

  /// Ambil error terakhir (Dinonaktifkan).
  static Future<String?> getLastError() async {
    return null;
  }

  /// Reset flag (Dinonaktifkan).
  static Future<void> resetFlag() async {}
}

