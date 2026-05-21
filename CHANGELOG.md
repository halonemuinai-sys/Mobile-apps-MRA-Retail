# Changelog

## [Unreleased] — 2026-05-19

### Added
- `canViewTransactions` getter di `Advisor` model — hanya manager/ops-manager yang bisa akses Detail Transaksi
- `WidgetsBindingObserver` di Dashboard dan Reports screen — data auto-refresh saat app kembali dari background
- CLAUDE.md — dokumentasi project untuk konteks Claude Code

### Fixed
- Transaction list untuk manager/ops-manager sebelumnya selalu filter by `salesman`, sekarang filter by store (atau semua store jika "All Stores")
- CRM search untuk Ops Manager dengan "All Stores" — sebelumnya string `'All Stores'` di-split jadi `'Stores'` dan di-filter ke database, hasilnya kosong. Sekarang store filter dilewati jika "All Stores"
- Data mobile tidak update setelah hapus di web — sudah diatasi dengan auto-refresh saat app resume

### Changed
- Format angka di dashboard dari singkatan (1.5M / 2.7B) menjadi full format Indonesia (1.500.000 / 2.700.000.000)

---

## [1.0.0] — sebelum 2026-05-19

### Added
- Operations Manager multi-store view dengan store selector, store ranking, cross-store leaderboard, dan All Stores mode
- Modernisasi UI, assets logo Bvlgari, laporan CRM Traffic dengan data profiling real
- CRM: integrasi Master Data dropdowns, phone prefix locking, data visibility per role (Data Melekat)
- Transaction list dan commission input helper
- Dashboard: bar chart Y-axis labels dan touch tooltip
- Rebrand ke "MPI Advisor"
- Cleanup: deprecated `withOpacity` → `withValues(alpha: x)`
