# Proxmox VM API Deployment & Integration Log
**Project:** Bvlgari Intelligence Dashboard & MPI Advisor Mobile App  
**Target Proxmox VM IP:** `202.6.239.245`  
**Container Name:** `bvl-intelligence-dashboard`  
**Deployment Date:** August 1, 2026  

---

## 1. Executive Summary & Server Status
Aplikasi Web Mobile & Backend API Service Next.js 16 (Turbopack) telah sukses di-build dan di-deploy ke server Proxmox VM menggunakan Docker Container.

* **Base URL Production:** `http://202.6.239.245`
* **Mobile Web Portal:** `http://202.6.239.245/m`
* **Mobile CRM Clienteling 360:** `http://202.6.239.245/m/crm`
* **API Endpoints Base Path:** `http://202.6.239.245/api/mobile`
* **Docker Container Status:** `Up` (Running on Port 80 -> Container 3000)

---

## 2. Remote Proxmox VM Specifications & Environment
* **Host IP:** `202.6.239.245`
* **SSH User:** `ubuntu-mogems`
* **SSH Password:** `ubuntu2026`
* **Remote Path:** `/home/ubuntu-mogems/dashboard-bvl`
* **Runtime Stack:** Docker Compose, Node.js 20 Alpine, Next.js 16.2.4 (Standalone Mode), Supabase PostgreSQL.

---

## 3. Endpoints API Proxmox (`/api/mobile/*`)

Berikut adalah daftar lengkap endpoint API yang dapat dikonsumsi oleh aplikasi Flutter (`D:\Mobile-Apps-MRA-Retail`):

### A. Authentication & Master Data
1. **GET `/api/mobile/auth/advisors`**
   * **Fungsi:** Mengambil daftar store dan nama Advisor yang aktif.
   * **Query Params:** `?store=Plaza Indonesia` (Opsional)
   * **Response:** `{ success: true, data: { stores: [...], advisors: [...] } }`

2. **POST `/api/mobile/auth/login`**
   * **Fungsi:** Verifikasi login PIN SHA-256 Advisor.
   * **Body (JSON):** `{ "store": "Plaza Indonesia", "advisor": "Aris", "pin": "123456" }`
   * **Response:** `{ success: true, token: "JWT...", advisor: { name: "Aris", role: "advisor", store: "Plaza Indonesia" } }`

### B. Dashboard Performance
3. **GET `/api/mobile/dashboard`**
   * **Fungsi:** Data Performa Sales MTD, Visualisasi Tren 12 Bulan, Breakdown Kategori, Quick Stats.
   * **Query Params:**
     * `store`: Nama store (`All Stores`, `Plaza Indonesia`, `Plaza Senayan`, `Bali`)
     * `advisor`: Nama Advisor
     * `scope`: `personal` (Advisor sendiri) atau `store` (Overall Toko)
     * `month`: Angka bulan (1-12, default `7` / Juli)
     * `year`: Tahun (default `2026`)
   * **Response:** `{ success: true, data: { netSales, qty, target, growthPct, categoryBreakdown: [...], monthlyTrend: [...] } }`

### C. Clienteling 360 & CRM
4. **GET `/api/mobile/segmentation`**
   * **Fungsi:** Pencarian pelanggan & KPI Segmentasi VIP (`Top VIP`, `Elite`, `High Potential`, `Potential`, `Prospect`, `Inactive`).
   * **Query Params:** `?segment=Top&search=Ratna&pageSize=50`
   * **Response:** `{ success: true, data: { kpis: {...}, segmentCounts: {...}, customers: [...] } }`

5. **GET `/api/mobile/segmentation/[customer]`**
   * **Fungsi:** Profiling 360° lengkap untuk 1 pelanggan (Total LTV, Item dibeli, Kategori favorit, dan Riwayat Transaksi).
   * **Response:** `{ success: true, data: { profile: {...}, summary: {...}, topCollections: [...], transactions: [...] } }`

### D. Leaderboard & Laporan
6. **GET `/api/mobile/leaderboard`**
   * **Fungsi:** Ranking pencapaian target dan omzet antar Advisor per toko.
   * **Query Params:** `?store=Plaza Indonesia`
   * **Response:** `{ success: true, data: { leaderboard: [{ advisor, netSales, qty, achievementPct }, ...] } }`

7. **GET `/api/mobile/reports`**
   * **Fungsi:** Ringkasan laporan traffic conversion rate, profile CRM baru, dan performa tahunan YTD.
   * **Query Params:** `?store=Plaza Indonesia&month=7&year=2026`
   * **Response:** `{ success: true, data: { trafficBreakdown: {...}, newProfiles: 12, conversionRate: 18.5, annualSummary: {...} } }`

---

## 4. Cara Menghubungkan Flutter App (`bvlgari_advisor`) ke Proxmox API

Untuk mengubah endpoint dari local/direct Supabase ke Proxmox API di Flutter:

1. buka file `lib/supabase_config.dart` atau buat file `lib/services/api_config.dart`:
```dart
class ApiConfig {
  static const String baseUrl = 'http://202.6.239.245';
  static const String mobileApiBase = '$baseUrl/api/mobile';
}
```

2. Contoh HTTP Service Call di Flutter (`http` package):
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> fetchDashboardData({
  required String store,
  required String advisor,
  String scope = 'personal',
  int month = 7,
  int year = 2026,
}) async {
  final url = Uri.parse(
    'http://202.6.239.245/api/mobile/dashboard?store=${Uri.encodeComponent(store)}&advisor=${Uri.encodeComponent(advisor)}&scope=$scope&month=$month&year=$year'
  );
  
  final response = await http.get(url);
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load dashboard data from Proxmox API');
  }
}
```

---

## 5. Deployment Verification Checklist
- [x] Docker Container `bvl-intelligence-dashboard` running on Proxmox VM (`202.6.239.245`)
- [x] Web Mobile Layout di-redesign 1-to-1 mengikuti UI/UX Flutter `MPI Advisor`
- [x] Modul Clienteling 360 (`/m/crm`) terintegrasi penuh ke API `/api/mobile/segmentation`
- [x] Dialog Kirim Email Excel terhubung ke endpoint butik MRA Retail
- [x] Cross-Origin Resource Sharing (CORS) di-enable untuk akses dari Flutter App

---
*Log generated automatically after Proxmox VM deployment.*
