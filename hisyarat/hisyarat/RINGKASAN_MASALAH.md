# Ringkasan Masalah: Login/Register Gagal di Aplikasi HiSyarat

## Gejala
- Register/login selalu gagal dengan pesan "Terjadi kesalahan saat register" atau "server belum menyala"
- Ngrok tunnel menunjukkan 0 koneksi — tidak ada request dari HP yang masuk

## Akar Masalah

### 1. Port Mismatch
- `apiBaseUrl` di `constants.dart` default ke `http://10.0.2.2:8000/api/v1`
- Backend Laravel jalan di port **6000**, bukan 8000
- `10.0.2.2` hanya bisa diakses dari emulator Android, **tidak dari HP real**

### 2. PHP Server Binding
- Awalnya PHP hanya bind ke `127.0.0.1:6000` → tidak bisa diakses dari perangkat lain
- Diubah ke `0.0.0.0:6000` agar bisa dijangkau via IP lokal

### 3. Deteksi Server di `run-hisyarat.cmd`
- Script memonitor PID proses PHP yang di-spawn
- Jika PHP di-restart manual (PID baru), script tetap mengacu ke PID lama yang sudah mati
- Solusi: matikan semua proses PHP dulu, lalu jalankan ulang `run-hisyarat.cmd`

## Perbaikan yang Dilakukan

| Area | Perubahan |
|------|-----------|
| `constants.dart` | `apiBaseUrl` menggunakan `String.fromEnvironment('HISYARAT_API_URL')` agar bisa di-set saat build APK |
| `auth_service.dart` | Ditambahkan catch khusus `HandshakeException` (SSL error) |
| `auth_service.dart` | `_api.saveToken()` dibungkus try-catch agar gagal simpan token tidak menggagalkan login |
| Build APK | APK dibuild dengan `--dart-define=HISYARAT_API_URL=https://polyester-pupil-armored.ngrok-free.dev/api/v1` |
| PHP server | Binding diubah dari `127.0.0.1:6000` ke `0.0.0.0:6000` |

## Status Terkini
- APK release siap di `build/app/outputs/flutter-apk/app-release.apk`
- Menunggu user: (1) jalankan `run-hisyarat.cmd`, (2) install APK, (3) test register/login

## File Penting
- `lib/core/constants.dart:68-71` — konfigurasi URL backend
- `lib/services/auth_service.dart` — logika login/register + error handling
- `lib/services/api_client.dart` — HTTP client + token storage
- `../run-hisyarat.ps1` — script manajemen server
- `../hisyarat-api/routes/api.php` — route register & login
- `../hisyarat-api/app/Http/Controllers/Api/AuthController.php` — controller auth
- `../hisyarat-api/.env` — konfigurasi backend (APP_DEBUG, NGROK_DOMAIN)
