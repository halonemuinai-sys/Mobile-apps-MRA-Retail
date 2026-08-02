# Flutter Integration Guide: Proxmox API Backend

Panduan ini berisi instruksi teknis untuk tim pengembang Flutter (`D:\Mobile-Apps-MRA-Retail`) dalam mengintegrasikan aplikasi mobile **MPI Advisor** dengan backend API yang telah di-deploy di Proxmox VM Server.

---

## 📍 Server Details & Endpoints

| Resource | URL | Description |
| :--- | :--- | :--- |
| **Server Base URL** | `http://202.6.239.245` | Proxmox VM Endpoint |
| **Mobile Web App** | `http://202.6.239.245/m` | Mobile Web Mirror |
| **API Base Path** | `http://202.6.239.245/api/mobile` | REST API Service for Flutter |

---

## 🛠️ Modul & Integrasi Service Flutter

### 1. Service Login & Authentikasi (`auth_service.dart`)
* **Endpoint:** `POST /api/mobile/auth/login`
* **Body Request:**
  ```json
  {
    "store": "Plaza Indonesia",
    "advisor": "Aris",
    "pin": "123456"
  }
  ```
* **Status:** Hash PIN diverifikasi di server; mengembalikan JWT token dan role akses (`isManager`).

### 2. Service Dashboard & Sales (`sales_service.dart`)
* **Endpoint:** `GET /api/mobile/dashboard`
* **Query Parameters:**
  - `store`: `Plaza Indonesia` | `Plaza Senayan` | `Bali` | `All Stores`
  - `advisor`: Nama Advisor
  - `scope`: `personal` (Data pribadi) | `store` (Data toko)
  - `month`: `1` - `12` (Default: `7` / Juli)
  - `year`: `2026`
* **Response Output:**
  - Net Sales (IDR) & Volume Qty
  - Growth Pct vs Bulan Lalu
  - Achievement Progress Bar vs Target
  - Category Breakdown (`Jewelry`, `Watches`, `Accessories`, etc.)
  - 12-Month Sales Trend Array

### 3. Service CRM & Clienteling 360 (`profile_service.dart`)
* **Endpoint List Pelanggan:** `GET /api/mobile/segmentation?segment=Top&search=Ratna&pageSize=50`
* **Endpoint Profiling 360°:** `GET /api/mobile/segmentation/{customerName}`
* **Fitur:**
  - Mengambil KPI pelanggan aktif, rata-rata LTV, dan top spender.
  - Menampilkan riwayat transaksi lengkap pelanggan 360 view.
  - Membantu Advisor melihat preferensi koleksi perhiasan & jam tangan favorit pelanggan.

### 4. Service Leaderboard & Reports (`reports_service.dart`)
* **Endpoint Leaderboard:** `GET /api/mobile/leaderboard?store=Plaza Indonesia`
* **Endpoint Laporan:** `GET /api/mobile/reports?store=Plaza Indonesia&month=7&year=2026`
* **Fitur:** Ranking omzet antar Advisor per toko & persentase pencapaian target.

---

## 🚀 Langkah Menjalankan Test Integrasi di Flutter

1. **Jalankan Flutter App di Emulator / Device:**
   ```bash
   flutter pub get
   flutter run -d chrome  # atau -d android
   ```

2. **Ganti URL Supabase Direct ke Proxmox REST API:**
   Buka `lib/services/sales_service.dart` atau buat service baru `lib/services/proxmox_api_service.dart` yang menggunakan HTTP client untuk memanggil `http://202.6.239.245/api/mobile/...`.

---
*Dokumentasi ini dibuat untuk referensi pengembang aplikasi Bvlgari Advisor MRA Retail.*
