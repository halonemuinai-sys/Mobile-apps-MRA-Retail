# MPI Advisor — Bvlgari Mobile App (`bvlgari_advisor`)

Aplikasi Flutter Mobile untuk Customer Advisor dan Manager Bvlgari di MRA Retail. Digunakan untuk tracking performa penjualan, prospek pelanggan, laporan transaksi, dan Clienteling 360.

---

## 🚀 Proxmox Backend API Integration

Backend API dan Mobile Web Portal telah aktif di-deploy di Server **Proxmox VM**:

* **Base URL Production:** `http://202.6.239.245`
* **Mobile Web App:** `http://202.6.239.245/m`
* **Clienteling 360 Hub:** `http://202.6.239.245/m/crm`
* **API Mobile Base Path:** `http://202.6.239.245/api/mobile`

---

## 📑 Dokumentasi & Log Integrasi Backend

1. **[DEPLOYMENT_PROXMOX_LOG.md](file:///D:/Mobile-Apps-MRA-Retail/DEPLOYMENT_PROXMOX_LOG.md)**
   * Catatan log deployment container Docker di Proxmox VM.
   * Daftar lengkap endpoint API `/api/mobile/*` (Auth, Dashboard, Segmentation 360, Leaderboard, Reports).

2. **[PROXMOX_API_INTEGRATION_GUIDE.md](file:///D:/Mobile-Apps-MRA-Retail/PROXMOX_API_INTEGRATION_GUIDE.md)**
   * Panduan teknis integrasi service Flutter (`sales_service.dart`, `profile_service.dart`, `auth_service.dart`) dengan backend REST API Proxmox.

---

## 📂 Struktur Proyek

```
lib/
├── main.dart               # Entry point aplikasi & session check
├── theme.dart              # Desain & tema visual (Indigo & Violet)
├── models/                 # Data model (Advisor, Profile, Traffic, Transaction)
├── services/               # HTTP & API Services (Auth, Sales, Profile, Traffic)
└── screens/
    ├── login/              # Screen Login PIN
    ├── dashboard/          # Screen Performa MTD & Bar Chart 12 Bulan
    ├── prospects/          # Screen Traffic & Input Prospek
    ├── crm/                # Screen Clienteling 360 & Profiling
    └── reports/            # Screen Leaderboard & Laporan Transaksi
```

---

## 💻 Cara Menjalankan Aplikasi Flutter

```bash
# Get dependencies
flutter pub get

# Run application
flutter run
```
