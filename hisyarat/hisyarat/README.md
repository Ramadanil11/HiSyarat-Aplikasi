# HiSyarat

**HiSyarat** — Aplikasi pembelajaran Bahasa Isyarat BISINDO (*Belajar Isyarat dengan Ejaan Alfabet*) berbasis Flutter. Fokus utama adalah **Spelling Quiz**: mengeja kata per huruf menggunakan alfabet BISINDO yang dideteksi secara real-time melalui kamera.

## Tech Stack

| Komponen          | Teknologi                                                           |
| ----------------- | ------------------------------------------------------------------- |
| Framework         | Flutter (Dart SDK ^3.10.1)                                          |
| State Management  | Provider (ChangeNotifier)                                           |
| Database Lokal    | SQLite (sqflite)                                                    |
| Backend API       | Laravel REST API (Sanctum auth)                                     |
| AI/ML             | TensorFlow Lite + Google ML Kit Pose Detection                      |
| TTS               | flutter_tts (Bahasa Indonesia)                                      |
| Camera            | camera (real-time image stream)                                     |
| Storage           | flutter_secure_storage, path_provider                               |

## Arsitektur

**Pattern:** Flat-page (tidak menggunakan named routes/navigator 2.0).

**Alur data:**
```
UI (StatefulWidget + setState())
  └─ Services (Plain Dart class, instance baru tiap penggunaan)
       └─ DatabaseHelper (Singleton, SQLite)
            └─ SQLite Database
  └─ AuthProvider (ChangeNotifier via Provider)
       └─ AuthService
  └─ SyncService (Singleton)
       └─ ApiClient (Singleton, HTTP ke Laravel backend)
  └─ QuizService (Singleton)
       └─ QuizSessionModel, QuizAnswerModel
```

**Offline-first:** Semua data disimpan lokal via SQLite. SyncService mengirim data pending ke backend saat koneksi tersedia.

## Struktur Project

```
lib/
├── main.dart                          # Entry point, Provider setup, error boundary
├── splash_page.dart                   # Splash screen + inisialisasi DB
├── login_page.dart                    # Login/Register tab
├── home_page.dart                     # Dashboard utama
├── translate_page.dart                # Terjemahan (Teks + Kamera)
├── dictionary_page.dart               # Kamus alfabet & kategori
├── spelling_quiz_page.dart            # Quiz ejaan huruf per huruf via kamera
├── history_page.dart                  # Riwayat quiz & terjemahan
├── profile_page.dart                  # Profil user, statistik quiz, badge, leaderboard
├── dataset_collector_page.dart        # Koleksi dataset foto BISINDO
│
├── core/
│   ├── constants.dart                 # App constants (API URL, threshold, dll)
│   ├── themes.dart                    # Material 3 theme + AppColors
│   ├── database_helper.dart           # Singleton SQLite (11 tabel + sync tables)
│   └── app_logger.dart                # Centralized logging
│
├── providers/
│   └── auth_provider.dart             # ChangeNotifier untuk auth state
│
├── services/
│   ├── api_client.dart                # HTTP client (Singleton, Bearer token)
│   ├── auth_service.dart              # Login/register/logout + UserModel
│   ├── sync_service.dart              # Sinkronisasi data pending ke server
│   ├── translation_service.dart       # Terjemahan teks↔isyarat + models
│   ├── detection_service.dart         # Queue hasil deteksi untuk sync
│   ├── quiz_service.dart              # Logic quiz spelling + ranking
│   ├── audio_service.dart             # Text-to-Speech (Singleton)
│   ├── feedback_service.dart          # Feedback user + akurasi AI
│   ├── gamification_service.dart      # Streak, badge, leaderboard
│   ├── history_service.dart           # CRUD riwayat terjemahan & quiz
│   ├── dataset_capture_service.dart   # Upload foto dataset ke server
│   └── camera/
│       ├── camera_service.dart        # Inisialisasi & manajemen kamera
│       ├── gesture_recognizer.dart    # Proses frame kamera → deteksi gesture
│       ├── tflite_classifier.dart     # TFLite inference
│       ├── bisindo_alphabet_data.dart # Data alfabet BISINDO (26 huruf)
│       ├── hand_crop_region.dart      # Region cropping tangan
│       ├── model_profile.dart         # Profil model AI
│       └── prediction_filter.dart     # Filter prediksi (smoothing)
│
└── widgets/
    ├── animated_hand_gesture.dart     # Animasi tangan untuk gesture
    ├── letter_progress_bar.dart       # Progress bar huruf (ijo/merah)
    └── leaderboard_card.dart          # Kartu peringkat leaderboard
```

## Halaman & Fitur

| Halaman              | Fitur Utama                                                   |
| -------------------- | ------------------------------------------------------------- |
| **SplashPage**       | Animated splash, inisialisasi database + seed data            |
| **LoginPage**        | Login (email+password), Register (nama, email, password, role)|
| **HomePage**         | Statistik dashboard, riwayat quiz terakhir, akses cepat       |
| **TranslatePage**    | Tab Teks→Isyarat & Kamera BISINDO (deteksi real-time)         |
| **DictionaryPage**   | Grid alfabet A-Z, kategori tematik                            |
| **SpellingQuizPage** | **Quiz ejaan**: deteksi gesture per huruf via kamera          |
| **HistoryPage**      | Riwayat quiz & terjemahan, detail skor, statistik per sesi    |
| **ProfilePage**      | Profil user, statistik quiz, streak, badge, leaderboard       |
| **DatasetCollector** | Ambil foto dataset untuk training model                       |

## Quiz Spelling (Fitur Utama)

### Alur Permainan

```
Kata target: "MAKAN"

  M  A  K  A  N
 [ ][ ][ ][ ][ ]   ← progress per huruf

1. Sistem menampilkan kata target di bagian atas layar
2. Huruf pertama ("M") disorot sebagai huruf aktif
3. Kamera aktif — user memperagakan gesture BISINDO untuk huruf "M"
4. Detection Service membandingkan gesture dengan alfabet target:
   ✅ **Cocok**  → huruf berubah **hijau**, lanjut ke huruf berikutnya
   ❌ **Salah**  → huruf tetap **merah**, counter percobaan +1, user ulang
5. Setelah semua huruf dalam kata terjawab → otomatis spasi → kata berikutnya
6. Jika semua kata selesai → quiz berakhir, skor dihitung dan disimpan
```

### Aturan Spasi

- Spasi (` `) tidak perlu diperagakan
- Setelah huruf terakhir dalam satu kata benar → otomatis dianggap spasi
- Sistem langsung melanjutkan ke huruf pertama kata berikutnya

### Contoh Sesi

```
Sesi: "MAKAN AYAM GORENG"

Kata 1: M-A-K-A-N  → semua hijau → spasi otomatis
Kata 2: A-Y-A-M    → semua hijau → spasi otomatis
Kata 3: G-O-R-E-N-G → semua hijau → sesi selesai ✅
```

### Scoring

| Komponen   | Bobot | Detail                                        |
| ---------- | ----- | -------------------------------------------   |
| Akurasi    | 70%   | `(total_huruf_benar / total_percobaan) × 100` |
| Kecepatan  | 30%   | `max(0, 100 - (rata_rata_detik/huruf × 5))`   |

```
Skor Akhir = (Akurasi × 0.7) + (Kecepatan × 0.3)
Rentang: 0.0 - 100.0
```

## Database (SQLite)

**11 Tabel utama:**

| Tabel               | Fungsi                                               |
| ------------------- | ---------------------------------------------------- |
| `users`             | Data pengguna (username, password_hash, role)        |
| `categories`        | Kategori gesture (Salam, Keluarga, dll)              |
| `gestures`          | Gerakan isyarat (nama, direction, difficulty)        |
| `vocabularies`      | Kosakata BISINDO (word → gesture mapping)            |
| `translations`      | Hasil terjemahan (source → target)                   |
| `audio_data`        | Data audio/TTS per vocabulary/gesture                |
| `translation_history` | Riwayat terjemahan per user                        |
| `quiz_sessions`     | **Sesi quiz spelling** (skor, durasi, status)        |
| `quiz_answers`      | **Detail jawaban per huruf** (percobaan, waktu)      |
| `ai_model_data`     | Metadata model AI (akurasi, versi)                   |
| `feedbacks`         | Feedback user terhadap terjemahan                    |

**2 Tabel Sync:**

| Tabel                  | Fungsi                                    |
| ---------------------- | ----------------------------------------- |
| `detection_uploads`    | Antrian upload foto deteksi ke server     |
| `composition_uploads`  | Antrian upload komposisi teks ke server   |

### Tabel Quiz

```sql
CREATE TABLE quiz_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  words TEXT NOT NULL,                -- JSON array of words
  total_letters INTEGER NOT NULL,
  correct_letters INTEGER DEFAULT 0,
  wrong_attempts INTEGER DEFAULT 0,
  score REAL DEFAULT 0.0,             -- 0.0 - 100.0
  duration_seconds INTEGER DEFAULT 0,
  status TEXT DEFAULT 'in_progress',  -- in_progress | completed | abandoned
  started_at TEXT NOT NULL,
  completed_at TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE quiz_answers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  word TEXT NOT NULL,
  letter TEXT NOT NULL,               -- A-Z
  attempts INTEGER DEFAULT 1,
  time_ms INTEGER DEFAULT 0,
  is_correct INTEGER DEFAULT 0,
  FOREIGN KEY (session_id) REFERENCES quiz_sessions(id) ON DELETE CASCADE
);
```

## Ranking & Leaderboard

### Cara Kerja Ranking

1. Setiap sesi quiz selesai → skor dihitung dan disimpan di `quiz_sessions.score`
2. Leaderboard mengambil skor **tertinggi per user** dari seluruh sesi
3. Ranking diurutkan berdasarkan skor tertinggi (jika sama, durasi tercepat)

### Tampilan Leaderboard

```
Peringkat | Nama            | Role        | Skor | Kata | Akurasi
──────────┼─────────────────┼─────────────┼──────┼──────┼────────
🥇 1      | Andi Pratama    | Learner     | 95.2 │ 15   │ 98%
🥈 2      | Sari Dewi       | Learner     | 88.7 │ 12   │ 92%
🥉 3      | Budi Santoso    | Instructor  | 85.0 │ 10   │ 90%
```

### Filter Ranking

- **Minggu ini** — skor terbaik dalam 7 hari terakhir
- **Bulan ini** — skor terbaik dalam 30 hari terakhir
- **Semua waktu** — skor terbaik sepanjang masa

## Role Pengguna

| Role         | Deskripsi                      |
| ------------ | ------------------------------ |
| `learner`    | Orang Dengar (pembelajar)      |
| `instructor` | Teman Tuli (pengajar)          |
| `admin`      | Administrator                  |

## Badge & Gamification

### Badge Spelling Quiz

| Badge              | Syarat                                          |
| ------------------ | ----------------------------------------------- |
| 🏅 Ejaan Pertama  | Selesaikan 1 sesi quiz spelling                  |
| 🏅 Rajin Mengeja   | Selesaikan 10 sesi quiz spelling                |
| 🏅 Ahli Ejaan      | Selesaikan 50 sesi quiz spelling                |
| 🏅 Sempurna        | 100% akurasi dalam 1 sesi (min 5 huruf)         |
| 🏅 Speed Demon     | Selesaikan sesi dengan rata-rata <2 detik/huruf |
| 🏅 Pantang Menyerah| 100+ total percobaan dalam 1 sesi          |

### Badge Lainnya

| Badge              | Syarat                                      |
| ------------------ | ------------------------------------------- |
| 🌟 Konsisten       | Streak 3 hari berturut-turut                |
| 🌟 Semangat Membara| Streak 7 hari berturut-turut                |
| 🌟 Tak Terbendung  | Streak 30 hari berturut-turut               |
| 📖 Setengah Jalan  | Pelajari 13 huruf alfabet                   |
| 📖 Master Alfabet  | Pelajari seluruh 26 huruf alfabet           |

## Cara Menjalankan

```bash
# Install dependencies
flutter pub get

# Run di device/emulator
flutter run

# Build APK
flutter build apk --release
```

## Environment Variables

```dart
// API Base URL (dapat di-set via --dart-define)
// Default: http://10.0.2.2:8000/api/v1 (localhost dari emulator Android)
AppConstants.apiBaseUrl = String.fromEnvironment(
  'HISYARAT_API_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);
```

## Catatan Penting

- Semua `Service` (kecuali yang disebut Singleton) dibuat sebagai **instance baru** setiap penggunaan (plain Dart class).
- Singleton services: `AudioService`, `SyncService`, `ApiClient`, `DatabaseHelper`, `QuizService`.
- Auth state dikelola via `AuthProvider` (ChangeNotifier + Provider).
- Navigasi menggunakan imperative `Navigator.push` / `pushReplacement` (bukan named routes).
- Data seed di-load dari `assets/data/bisindo_seed_data.json` saat pertama kali database dibuat.
- Quiz menggunakan data alfabet dari `BisindoAlphabetData` (26 huruf A-Z) yang dideteksi via kamera real-time.
