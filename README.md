# Stegoland — app all-in-one

App rasmi **Stegoland Indoor Playground** & **Jasmine Cafe**, Pasir Tumboh, Kota Bharu, Kelantan.
Dibina semula dari kosong dengan **Flutter** (Android, iOS & Web/PWA).

## Ciri utama

| Bahagian | Apa yang boleh dibuat |
| --- | --- |
| **Tiket Keluarga** | Pilih tarikh & slot masa, bilangan kanak-kanak/penjaga, tiket QR serta-merta. Harga ikut hari (hari biasa / hujung minggu Jumaat–Sabtu / cuti umum). |
| **Lawatan Sekolah & Kumpulan** | Untuk cikgu/tadika tempah ramai-ramai: nama institusi, bilangan murid & guru (5 guru percuma), Kids Meal, Iced Lemon Tea, sesi privasi, sebut harga automatik, hantar terus ke WhatsApp Stegoland. Status *Menunggu Pengesahan* sehingga staf sahkan. |
| **Jasmine Cafe** | Menu ikut kategori, troli, makan di sini (no. meja) / bungkus, status pesanan masa nyata. |
| **Last Call** | Jualan diskaun hujung hari (gaya pelekat kuning) — staf tanda makanan lebihan dengan harga murah + kuantiti; hanya boleh dibeli dalam tempoh Last Call (lalai 8:00–10:00 malam) dan tamat sendiri esoknya. |
| **Stego Member** | Daftar dengan nama & telefon, 1 mata / RM1, tebus ganjaran → baucar. |
| **Panel Staf** (PIN) | Ringkasan harian & kapasiti slot, sahkan/tolak kumpulan, daftar masuk & tanda bayar, barisan dapur, urus menu & Last Call, ubah harga/kapasiti/cuti umum/waktu operasi. |

Kapasiti slot dikawal (lalai 80 kanak-kanak/slot), slot tengah hari Jumaat ditutup untuk solat Jumaat, dan sesi privasi mengunci seluruh slot.

## Struktur kod

```
lib/
  core/      tema & warna jenama, format RM/tarikh BM, pautan WhatsApp/Waze/TikTok
  data/      models.dart, seed.dart (harga, menu, maklumat perniagaan), store.dart (logik + simpanan)
  ui/        home, booking, cafe, tickets, profile, admin, widgets
assets/      logo Stegoland, maskot, ikon app, fon Fredoka & Nunito
test/        ujian logik harga/slot/Last Call + ujian UI
```

## Jalankan

```bash
flutter pub get
flutter run            # telefon / emulator
flutter run -d chrome  # web
flutter test
```

PIN staf lalai: **1234** (tukar di Panel Staf → Tetapan).

## Nota penting sebelum lancar

- **Data disimpan pada peranti** (SharedPreferences). Ini sesuai untuk demo/prototaip; untuk operasi sebenar
  (pelanggan & staf guna telefon berbeza), sambungkan `AppStore` kepada backend seperti Firebase/Supabase —
  hanya `_load()`/`_save()` dan kaedah tempahan dalam `lib/data/store.dart` perlu ditukar.
- **Bayaran** dibuat di kaunter. Integrasi FPX/DuitNow boleh ditambah kemudian.
- Sila sahkan dengan pemilik: waktu operasi, panjang slot & kapasiti (semua boleh diubah dalam Tetapan / `seed.dart`).

## Deploy web

Workflow `.github/workflows/deploy-web.yml` membina dan menerbitkan versi web ke GitHub Pages setiap kali
`main` dikemas kini (Settings → Pages → Source: **GitHub Actions**).
