# MPI Advisor — Mobile App
### Customer Intelligence & Sales Performance Platform
**MRA Retail · Bvlgari Division**

---

## 1. Latar Belakang

Advisor Bvlgari di lapangan tidak memiliki tools digital untuk:
- Memantau performa penjualan secara real-time
- Mengelola data prospek dan follow-up customer
- Mengakses profil CRM customer dengan cepat
- Melihat laporan dan komisi secara transparan

**MPI Advisor** hadir sebagai solusi mobile-first yang dapat diakses kapan saja, di mana saja — langsung dari smartphone advisor.

---

## 2. Tentang Aplikasi

| | |
|---|---|
| **Nama App** | MPI Advisor |
| **Platform** | Android & iOS |
| **Pengguna** | Customer Advisor, SPV, Store Manager, Operations Manager |
| **Backend** | Supabase (PostgreSQL Cloud) |
| **Akses** | Login PIN per advisor — tanpa email, tanpa password |
| **Koneksi** | Real-time data langsung dari server |

---

## 3. Fitur Utama

### Beranda — Dashboard Performa
- Pencapaian MTD (Month-to-Date) vs Target dalam persentase
- Perbandingan dengan bulan sebelumnya
- Grafik tren penjualan 12 bulan
- Jumlah transaksi & total prospek aktif
- Ringkasan follow-up yang perlu ditindak

### Prospek — Traffic & Follow-Up Management
- Input traffic pengunjung harian
- Daftar prospek dengan status (baru, follow-up, closing)
- Quick action: WhatsApp & Email langsung dari app
- Filter per bulan dan per advisor (untuk manager)

### CRM — Customer Profile
- Pencarian customer by nama, nomor HP, atau email
- Input profil customer baru dengan data lengkap
- Detail riwayat interaksi per customer
- Segmentasi customer (RFM: Recency, Frequency, Monetary)
- Data melekat per advisor — privacy terjaga

### Laporan — Reports & Analytics
- Breakdown penjualan per kategori produk
- Leaderboard advisor dalam satu toko
- Segmentasi customer (Premium, Loyal, At-Risk, dll)
- Kalkulasi komisi otomatis
- Filter per bulan & tahun

---

## 4. Sistem Role & Akses

```
Operations Manager  →  Lihat SEMUA store (multi-store view + store ranking)
        │
Store Manager / ASM →  Lihat semua advisor di store-nya
        │
SPV                 →  Lihat semua advisor di bawahnya
        │
Advisor             →  Lihat data milik sendiri saja
```

| Role | Dashboard | Prospek | CRM | Laporan | Multi-Store |
|---|:---:|:---:|:---:|:---:|:---:|
| Advisor | ✅ | ✅ | ✅ | ✅ | ❌ |
| SPV / Manager | ✅ | ✅ | ✅ | ✅ | ❌ |
| Operations Manager | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 5. Keamanan & Login

- Login menggunakan **PIN 6 digit** — tidak ada email/password
- PIN disimpan sebagai **SHA-256 hash** di server
- Sesi tersimpan di device — tidak perlu login ulang setiap buka app
- Data advisor **tidak bisa diakses lintas toko** tanpa izin role

---

## 6. Tech Stack

| Layer | Teknologi |
|---|---|
| **Mobile Framework** | Flutter (Android & iOS dari satu codebase) |
| **Database & API** | Supabase (PostgreSQL + REST API) |
| **Auth** | PIN-based, SHA-256, shared_preferences |
| **Charts** | fl_chart |
| **State** | flutter_riverpod |
| **Fonts** | Google Fonts — Inter |

---

## 7. Distribusi Aplikasi

### APK Production
- Untuk advisor yang sudah berlangganan penuh
- Tidak ada batas waktu
- Package: `com.mraretail.bvlgari_advisor`

### APK Trial *(Baru)*
- Untuk demo & onboarding store baru
- **Masa trial 14 hari** — semua fitur aktif penuh
- Timer berjalan dari login pertama
- Perpanjangan dilakukan dari dashboard admin (tanpa update APK)
- Package berbeda — bisa install berdampingan di HP yang sama

```
Hari 1–14   →  Semua fitur aktif + banner sisa hari
Hari 15+    →  App terkunci, tampil halaman hubungi admin
```

---

## 8. Device Intelligence (Trial APK)

Setiap install APK Trial, app otomatis mencatat:

| Data | Contoh |
|---|---|
| Brand & Model | Samsung Galaxy S23 Ultra |
| Versi Android | Android 14 |
| Device ID | Unik per device |
| Waktu Install | 2026-05-25 09:41 |

Data masuk ke Supabase `device_logs` — admin bisa pantau siapa dan device apa yang menggunakan trial.

---

## 9. Roadmap & Pengembangan Lanjutan

| Prioritas | Fitur |
|---|---|
| 🔵 High | Push notification follow-up reminder |
| 🔵 High | Export laporan ke PDF / Excel |
| 🟡 Medium | Offline mode dengan sync otomatis |
| 🟡 Medium | Dashboard web untuk HQ / Area Manager |
| 🟢 Low | Integrasi kalender untuk jadwal follow-up |
| 🟢 Low | Foto produk & katalog in-app |

---

## 10. Kontak & Info Lebih Lanjut

> Untuk demo langsung, aktivasi trial, atau pertanyaan teknis:

**MRA Retail — Digital Team**
- WhatsApp: +62 xxx-xxxx-xxxx
- Email: admin@mraretail.com

---

*MPI Advisor · MRA Retail · 2026*
