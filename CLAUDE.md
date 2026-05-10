# MRA Retail — Bvlgari Advisor App

## Project Overview
Flutter mobile app untuk Customer Advisor Bvlgari di MRA Retail. Digunakan oleh advisor dan manager toko untuk tracking prospects, CRM, dashboard performa, dan laporan transaksi.

- **App name (internal):** `bvlgari_advisor`
- **Package name:** `bvlgari_advisor`
- **Platform target:** Android/iOS, portrait-only

## Tech Stack
- **Flutter** SDK ^3.10.8
- **Backend:** Supabase (PostgreSQL + Auth)
- **State management:** flutter_riverpod ^2.6.1
- **Routing:** go_router ^14.6.3
- **Charts:** fl_chart ^0.70.2
- **Fonts:** google_fonts ^6.2.1
- **Auth:** PIN-based login (SHA-256 hash), disimpan via shared_preferences
- **HTTP:** supabase_flutter ^2.8.4 + http ^1.6.0

## Project Structure
```
lib/
├── main.dart               # App entry point, AppRoot (session check)
├── supabase_config.dart    # Supabase URL & anon key
├── theme.dart              # AppTheme (warna utama: #2563EB biru)
├── constants/
│   └── master_data.dart    # Data master (tipe produk, kategori, dsb.)
├── models/
│   ├── advisor.dart        # Advisor model, isManager getter
│   ├── profile.dart
│   ├── traffic.dart
│   └── transaction.dart
├── services/
│   ├── auth_service.dart   # Login PIN, getStores, getAdvisorNames
│   ├── profile_service.dart
│   ├── sales_service.dart
│   ├── sync_service.dart
│   └── traffic_service.dart
└── screens/
    ├── login/              # login_screen.dart
    ├── dashboard/          # dashboard_screen.dart (charts, performa)
    ├── prospects/          # prospects_screen.dart, traffic_input_screen.dart
    ├── crm/                # crm_search, crm_input, crm_detail
    ├── reports/            # reports_screen, transaction_list_screen
    └── settings/           # settings_screen.dart
```

## Auth & Role System
- Login: pilih store → pilih nama advisor → masukkan PIN
- PIN di-hash SHA-256, disimpan di tabel `advisor_pins`
- Role: `advisor`, `spv`, `asm`, `store_manager`
- `Advisor.isManager` = true jika role store_manager / asm / spv
- **Data Melekat:** advisor biasa hanya lihat data milik sendiri; manager bisa lihat semua advisor di store-nya

## Supabase Tables (diketahui)
- `advisors` — nama advisor, home_location (store), role
- `advisor_pins` — advisor_name, pin_hash
- CRM data, traffic/prospects, transactions

## UI/UX Convention
- Warna primer: `#2563EB` (biru)
- Background: `#F8FAFC`
- Modern casual style, rebrand ke "MPI Advisor"
- Portrait-only (SystemChrome.setPreferredOrientations)
- Tidak pakai deprecated `withOpacity` → gunakan `.withValues(alpha: x)`

## Recent Changes (per Mei 2026)
- CRM screen: integrasi Master Data dropdowns, phone prefix locking, data visibility per role
- Reports: transaction list + commission input helper
- Dashboard: bar chart Y-axis labels + touch tooltip
- UI: redesign modern casual, rebrand MPI Advisor
- Cleanup: deprecated withOpacity → withValues, naming conventions

## Development Notes
- Supabase config ada di `lib/supabase_config.dart` (jangan commit ke public repo)
- Tidak pakai go_router secara penuh — navigasi masih manual via Navigator di beberapa screen
- State management belum sepenuhnya Riverpod — ada StatefulWidget manual
