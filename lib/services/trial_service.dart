import 'package:supabase_flutter/supabase_flutter.dart';

class TrialStatus {
  final bool isActive;
  final int daysRemaining;
  final DateTime trialStartedAt;

  const TrialStatus({
    required this.isActive,
    required this.daysRemaining,
    required this.trialStartedAt,
  });
}

class TrialService {
  static const int trialDays = 14;

  /// Cek status trial advisor. Jika belum pernah login trial, otomatis set tanggal mulai.
  static Future<TrialStatus> checkAndInitTrial(String advisorName) async {
    final client = Supabase.instance.client;

    final data = await client
        .from('advisors')
        .select('trial_started_at')
        .eq('name', advisorName)
        .maybeSingle();

    DateTime trialStart;
    final rawDate = data?['trial_started_at'];
    if (rawDate == null) {
      trialStart = DateTime.now().toUtc();
      await client
          .from('advisors')
          .update({'trial_started_at': trialStart.toIso8601String()})
          .eq('name', advisorName);
    } else {
      trialStart = DateTime.parse(rawDate as String);
    }

    final daysPassed = DateTime.now().toUtc().difference(trialStart).inDays;
    final daysRemaining = (trialDays - daysPassed).clamp(0, trialDays);

    return TrialStatus(
      isActive: daysPassed < trialDays,
      daysRemaining: daysRemaining,
      trialStartedAt: trialStart,
    );
  }
}
