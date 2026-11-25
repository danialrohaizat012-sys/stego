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
  data/      models.dart, seed.dart (harga, menu, maklumat perniagaan), store.dart (logik + simpanan),
             firebase_remote.dart (sync Firestore + log masuk staf)
  firebase_options.dart   placeholder — ditulis semula oleh `flutterfire configure`
  ui/        home, booking, cafe, tickets, profile, admin, widgets
assets/      logo Stegoland, maskot, ikon app, fon Fredoka & Nunito
test/        ujian logik harga/slot/Last Call, UI dan sync Firebase
firestore.rules, firebase.json, firebase_tests/   Security Rules + ujiannya
```

## Jalankan

```bash
flutter pub get
flutter run            # telefon / emulator
flutter run -d chrome  # web
flutter test
```

Mod tempatan: PIN staf lalai **1234** (tukar di Panel Staf → Tetapan). Mod Firebase: staf log masuk dengan emel.

## Firebase (data dikongsi semua telefon)

App ini menyokong dua mod secara automatik:

| Mod | Bila | Data |
| --- | --- | --- |
| **Tempatan** | `lib/firebase_options.dart` masih placeholder | Disimpan dalam peranti sahaja (sesuai untuk demo) |
| **Firebase** | Selepas `flutterfire configure` | Tempahan, pesanan, menu, Last Call, tetapan & member di **Cloud Firestore** — staf nampak tempahan cikgu serta-merta |

Reka bentuk (pelan **Spark/percuma**, tanpa Cloud Functions):

- **Pelanggan** log masuk tanpa nama (Anonymous Auth) secara automatik — tiada kata laluan untuk diingat.
- **Staf** log masuk dengan emel & kata laluan dalam sesi berasingan, jadi tablet kaunter juga boleh digunakan sebagai pelanggan.
- **Kapasiti slot** dikira dari koleksi awam `slotEntries` (tiada nama/telefon), jadi setiap pelanggan nampak tempat yang tinggal tanpa boleh baca tempahan orang lain.
- **Security Rules** (`firestore.rules`) memastikan: pelanggan hanya baca tempahan/pesanan sendiri, tak boleh tanda "sudah bayar", tak boleh tambah mata sendiri, baucar mesti ditolak mata, stok Last Call hanya boleh berkurang, dan hanya staf boleh ubah menu/harga.

### Langkah sambung (sekali sahaja, ~15 minit)

1. Buka [console.firebase.google.com](https://console.firebase.google.com) → **Add project** (cth. `stegoland`). Pelan Spark (percuma) sudah cukup.
2. **Build → Authentication → Sign-in method**: hidupkan **Anonymous** dan **Email/Password**.
3. **Build → Firestore Database → Create database** → mod *production*, lokasi `asia-southeast1 (Singapore)`.
4. Pada komputer anda (dalam folder repo ini):
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase use --add            # pilih projek stegoland
   firebase deploy --only firestore:rules,firestore:indexes
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<project-id> --platforms=android,ios,web
   ```
   `flutterfire configure` menulis semula `lib/firebase_options.dart` (dan `google-services.json` / `GoogleService-Info.plist`). **Commit fail-fail itu** — ia bukan rahsia; keselamatan dijaga oleh Security Rules.
5. **Daftar staf**: Authentication → **Add user** (emel + kata laluan). Salin **User UID**, kemudian Firestore → **Start collection** `staff` → Document ID = UID itu, medan `email` (string).
6. Buka app → Profil → **Mod Staf / Admin** → log masuk. Log masuk staf pertama akan memuat naik menu, harga dan maklumat perniagaan lalai ke Firestore secara automatik.
7. Untuk versi web di GitHub Pages: Authentication → Settings → **Authorized domains** → tambah `danialrohaizat012-sys.github.io`.

### Ujian

```bash
flutter test                                   # logik + UI + sync Firebase (Firestore palsu)
cd firebase_tests && npm install && npm test   # Security Rules pada Firebase Emulator (perlu Java)
```

Jalankan app pada emulator tempatan tanpa projek sebenar:

```bash
firebase emulators:start --only auth,firestore --project demo-stegoland
flutter run -d chrome --dart-define=FIREBASE_EMULATOR=localhost
```

### Had yang perlu diketahui

- Identiti pelanggan tanpa nama terikat pada peranti/pelayar. Jika app dipadam atau data pelayar dikosongkan, tiket lama tidak lagi kelihatan di "Tiket Saya" (staf masih nampak semuanya). Log masuk nombor telefon (OTP) boleh ditambah kemudian.
- Kapasiti disemak sebelum tempahan; jika dua orang menempah tempat terakhir pada saat yang sama, slot boleh terlebih sedikit. Untuk jaminan penuh, guna Cloud Functions (pelan Blaze).
- Bayaran masih di kaunter. Integrasi FPX/DuitNow boleh ditambah kemudian.
- Sila sahkan dengan pemilik: waktu operasi, panjang slot & kapasiti (semua boleh diubah dalam Panel Staf → Tetapan).

## Deploy web

Workflow `.github/workflows/deploy-web.yml` membina dan menerbitkan versi web ke GitHub Pages setiap kali
`main` dikemas kini (Settings → Pages → Source: **GitHub Actions**).
