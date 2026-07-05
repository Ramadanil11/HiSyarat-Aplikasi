# Dokumentasi Project HiSyarat

> **Aplikasi**: Belajar & Berkomunikasi dengan BISINDO (Bahasa Isyarat Indonesia)
> **Platform**: Flutter / Dart 3.x
> **State Management**: Provider (ChangeNotifier)
> **Database**: SQLite (sqflite, version 8)
> **ML Stack**: TensorFlow Lite + Google ML Kit Pose Detection
> **Auth**: Argon2id hashing + Laravel REST API

---

## 1. Struktur Direktori

```
hisyarat/
├── android/                     # Konfigurasi Android
├── assets/
│   ├── data/                    # File data (JSON)
│   ├── images/                  # Gambar (logo + 26 alfabet)
│   └── models/                  # Model TFLite + ONNX + PyTorch
├── ios/                         # Konfigurasi iOS
├── lib/                         # Source code utama (52 file)
│   ├── core/                    # Infrastructure
│   ├── providers/               # State management
│   ├── services/                # Business logic
│   │   └── camera/              # ML pipeline
│   ├── widgets/                 # Shared UI
│   └── features/quiz/           # Quiz sub-feature
├── test/                        # Unit & widget tests (8 file, 56+ test)
├── pubspec.yaml
└── README.md
```

---

## 2. lib/ — Entry Point & Pages (11 file)

### 2.1 `lib/main.dart`
| Item | Detail |
|------|--------|
| **Role** | Entry point aplikasi |
| `main()` | Init logger, preload camera, setup Provider tree |
| `HiSyaratApp` | Root widget: MaterialApp + Providers + tema |
| `_ErrorBoundary` | Catch unhandled errors, log, show error UI |

### 2.2 `lib/splash_page.dart`
| Item | Detail |
|------|--------|
| **Role** | Splash screen animasi |
| **Key methods** | `initState` → timer 2 detik → navigate ke login/home |
| **UI** | Fade-in logo, scale-up tagline, loading spinner |

### 2.3 `lib/login_page.dart`
| Item | Detail |
|------|--------|
| **Role** | Login & Register dengan tab switching |
| **UI** | Username, password, role dropdown, reset password link |
| **Logic** | Panggil `AuthProvider.login()` / `.register()` |

### 2.4 `lib/forgot_password_page.dart`
| Item | Detail |
|------|--------|
| **Role** | Form request reset password |
| **Logic** | Panggil `AuthProvider.forgotPassword()` |

### 2.5 `lib/reset_password_page.dart`
| Item | Detail |
|------|--------|
| **Role** | Form reset password dengan token |
| **Logic** | Baca token dari route args, panggil `AuthProvider.resetPassword()` |

### 2.6 `lib/home_page.dart`
| Item | Detail |
|------|--------|
| **Role** | Main hub navigasi — 4 tabs: Home, Translate, History, Profile |
| **Home tab** | Stats (total vocab, learned words, accuracy), avatar, greeting, category chips, tip cards, gamification (streak, XP, level, badges) |
| **Services** | `TranslationService.getDashboard()`, `GamificationService` |

### 2.7 `lib/translate_page.dart`
| Item | Detail |
|------|--------|
| **Role** | Text-to-sign translation + camera detection |
| **Tab 1** | Input teks → tampil gesture images + video URL per huruf/kata |
| **Tab 2** | Kamera real-time detection: pose → crop → TFLite → filter |
| **Services** | `TranslationService`, `GestureRecognizer`, `CameraService` |

### 2.8 `lib/dictionary_page.dart`
| Item | Detail |
|------|--------|
| **Role** | Browse & search vocabulary by category |
| **UI** | Category chips, search bar, word cards (gesture image, meaning, difficulty) |
| **Services** | `TranslationService` |

### 2.9 `lib/history_page.dart`
| Item | Detail |
|------|--------|
| **Role** | History translasi dengan pagination, search, filter, export CSV |
| **Services** | `HistoryService` |

### 2.10 `lib/profile_page.dart`
| Item | Detail |
|------|--------|
| **Role** | User profile + settings |
| **UI** | Avatar (initials), stats cards, settings (role, name, email), logout |

### 2.11 `lib/dataset_collector_page.dart`
| Item | Detail |
|------|--------|
| **Role** | Admin tool — capture training data dari kamera |
| **Methods** | `_startCapture()`, `_captureFrame()`, `_exportDataset()` |
| **Visibility** | Hanya untuk role `admin` |

---

## 3. lib/core/ — Infrastructure (4 file)

### 3.1 `lib/core/constants.dart`
| Constants | Nilai |
|-----------|-------|
| `AppConstants` | appName, appVersion, dbName, dbVersion, AI thresholds, quiz params, validation, roles, pagination, ML path |
| `ApiConstants` | baseUrl, timeout, endpoints auth/translate/vocab/sync/quiz |
| `AppStrings` | UI labels untuk login, home, quiz |
| `AppKeys` | Key objects untuk widget testing |

### 3.2 `lib/core/themes.dart`
| Class | Detail |
|-------|--------|
| `AppColors` | 20+ warna (primary teal `#009688`, secondary green, error, surface, text) |
| `AppTheme` | Material 3, font Poppins, rounded shapes, light theme |

### 3.3 `lib/core/database_helper.dart`
| Item | Detail |
|------|--------|
| **Role** | Singleton SQLite manager |
| **Tables** | users, sessions, categories, vocabulary, gestures, translations, history, feedback, model_metadata, quiz_scores, achievements |
| **Methods** | `get database`, `_onCreate`, `_onUpgrade` (v1→v8), `insert`, `query`, `update`, `delete`, `rawQuery`, `search` |
| **Seed** | Load dari `assets/data/bisindo_seed_data.json` |

### 3.4 `lib/core/app_logger.dart`
| Item | Detail |
|------|--------|
| **Levels** | debug, info, warning, error, fatal |
| **LogEntry** | Immutable: timestamp, level, message, source, error, stackTrace |
| **AppLogger** | Static: `debug()`, `info()`, `warning()`, `error()`, `fatal()`, `getLogsByLevel()`, `errorLogs`, `clear()`, `export()` |
| **Buffer** | Circular 500 entries, `onLog` callback |

---

## 4. lib/providers/ — State Management (4 file)

### 4.1 `lib/providers/auth_provider.dart`
| Item | Detail |
|------|--------|
| **Role** | ChangeNotifier — auth state |
| **Properties** | currentUser, isLoading, errorMessage, isLoggedIn |
| **Methods** | `login()`, `register()`, `logout()`, `forgotPassword()`, `resetPassword()`, `updateProfile()`, `checkSession()` |

### 4.2 `lib/features/quiz/providers/quiz_provider.dart`
| Item | Detail |
|------|--------|
| **Role** | ChangeNotifier — quiz gameplay state |
| **Properties** | currentWord, currentLetterIndex, score, comboCount, wordsCompleted, totalAttempts, correctAttempts, remainingSeconds |
| **Methods** | `startQuiz()`, `attemptLetter()`, `pauseQuiz()`, `resumeQuiz()`, `endQuiz()`, `getResult()` |
| **Key logic** | Cooldown 1s antar huruf, combo bonus tiap 5 berturut-turut, hint setelah 3 gagal |

### 4.3 `lib/features/quiz/providers/leaderboard_provider.dart`
| Item | Detail |
|------|--------|
| **Role** | ChangeNotifier — leaderboard |
| **Methods** | `loadLeaderboard(category)`, `refresh()` |

### 4.4 `lib/features/quiz/providers/achievement_provider.dart`
| Item | Detail |
|------|--------|
| **Role** | ChangeNotifier — achievements |
| **Methods** | `loadAchievements(userId)`, `checkAndUnlock()` (evaluasi 5 kondisi) |

---

## 5. lib/services/ — Business Logic (10 file)

### 5.1 `lib/services/auth_service.dart`
| Class | Detail |
|-------|--------|
| `AuthException` | Structured error: statusCode, code, message; `fromResponse()` parse JSON |
| `UserModel` | id, name, email, passwordHash, salt, role, fullName; `fromMap()`, `toMap()`, `copyWith()` |
| `SessionModel` | token, userId, createdAt, expiresAt; `isExpired` getter |
| `AuthService` | `hashPassword()` (Argon2id), `verifyPassword()`, `login()`, `register()`, `logout()`, `createSession()`, `validateSession()` |

### 5.2 `lib/services/translation_service.dart`
| Class | Detail |
|-------|--------|
| `VocabularyModel` | id, word, meaning, categoryId, gestureId, difficulty, usageExample |
| `CategoryModel` | id, name, description, iconName, colorHex, sortOrder |
| `GestureModel` | id, name, description, categoryId, difficulty, direction, handType |
| `TranslationResult` | sourceText, translatedText, confidence, direction, matched vocabs/gestures |
| `TranslationService` | `translateText()`, `getCategories()`, `getVocabularyByCategory()`, `getDashboard()`, `searchVocabulary()` |

### 5.3 `lib/services/history_service.dart`
| Class | Detail |
|-------|--------|
| `HistoryModel` | id, userId, inputType, inputData, translatedText, confidenceScore, processingTimeMs, isCorrect |
| `HistoryService` | `saveHistory()`, `getHistory()`, `getUserHistoryPaginated()`, `searchHistory()`, `exportToCsv()`, `deleteHistory()` |

### 5.4 `lib/services/sync_service.dart`
| Item | Detail |
|------|--------|
| **Role** | Background sync offline→API |
| **Methods** | `syncAll()`, `syncVocabulary()`, `syncHistory()`, `syncFeedback()`, `syncProfile()` |

### 5.5 `lib/services/gamification_service.dart`
| Item | Detail |
|------|--------|
| **Role** | XP, levels, streaks, daily rewards, badges |
| **Methods** | `awardXp()`, `getUserLevel()`, `updateStreak()`, `getStreakDays()`, `getBadges()`, `claimDailyReward()` |

### 5.6 `lib/services/feedback_service.dart`
| Class | Detail |
|-------|--------|
| `FeedbackModel` | id, userId, type (positive/negative/suggestion), subject, message, rating |
| `FeedbackService` | `submitFeedback()`, `getFeedback()`, `getFeedbackStats()`, `updateFeedbackStatus()` |

### 5.7 `lib/services/detection_service.dart`
| Item | Detail |
|------|--------|
| **Role** | High-level sign detection pipeline |
| **Methods** | `detectSign()` — capture frame + run detection |

### 5.8 `lib/services/dataset_capture_service.dart`
| Item | Detail |
|------|--------|
| **Role** | Capture & store labeled training images |
| **Methods** | `startCapture()`, `captureFrame()`, `exportDataset()`, `getCapturedCount(label)` |

### 5.9 `lib/services/audio_service.dart`
| Item | Detail |
|------|--------|
| **Role** | Text-to-speech |
| **Methods** | `speak(text, language)`, `stop()`, `isSpeaking()` |
| **Languages** | id_ID, en_US |

### 5.10 `lib/services/api_client.dart`
| Item | Detail |
|------|--------|
| **Role** | HTTP client with retry, auth token, JSON decoding |
| **Methods** | `get()`, `post()`, `put()`, `delete()` — auto auth header, retry 3×, timeout 30s |

---

## 6. lib/services/camera/ — Camera & ML Pipeline (7 file)

### 6.1 `lib/services/camera/camera_service.dart`
| Item | Detail |
|------|--------|
| **Role** | Singleton — CameraController lifecycle |
| **Methods** | `initCamera()`, `dispose()`, `startImageStream()`, `stopImageStream()`, `captureImage()`, `setCameraLens()` |
| **Format** | NV21, medium resolution |

### 6.2 `lib/services/camera/gesture_recognizer.dart`
| Item | Detail |
|------|--------|
| **Role** | Orkestrator pipeline: pose detection → crop → TFLite → filter |
| **Classes** | `GestureResult`, `GestureRecognizer` |
| **Methods** | `processFrame()` — throttle 100ms, 3 mode (AI/rule-based/hybrid) |
| **Flow** | `_detectHandRegion()` → `_classifyWithAI()` → `PredictionFilter.add()` → emit-once |
| **Tuning** | wrist likelihood ≥ 0.25, throttle 100ms |

### 6.3 `lib/services/camera/prediction_filter.dart`
| Item | Detail |
|------|--------|
| **Role** | Temporal stabilizer + emit-once logic |
| **Classes** | `PredictionCandidate`, `PredictionFilter` |
| **Methods** | `accepts()` — check confidence & margin threshold; `add()` — buffer sliding window, return label jika ≥ N match; `reset()` — clear buffer + `_hasEmitted` flag |
| **Parameters** | confidence 0.60 (translate) / 0.75 (quiz), margin 0.10 / 0.15, window 5, required 3 / 4 |

### 6.4 `lib/services/camera/tflite_classifier.dart`
| Item | Detail |
|------|--------|
| **Role** | Singleton — TFLite model runner |
| **Classes** | `ClassificationResult` (label, confidence, margin, allProbabilities) |
| **Methods** | `initialize()` — load model + fallback chain; `classifyFrame()` — ROI → NV21→RGB → resize 224×224 → inference → softmax/clamp |
| **Normalization** | Raw 0-255 (v2) atau /255 - mean/std (legacy) |

### 6.5 `lib/services/camera/hand_crop_region.dart`
| Item | Detail |
|------|--------|
| **Role** | Compute padded square crop dari hand landmarks |
| **Classes** | `HandCropRegion` |
| **Methods** | `fromNormalizedPoints()` — min 2 point with likelihood ≥ 0.25, padding 1.8×, clamp [0,1]; `isUsable` — score ≥ 0.35, size 0.15-0.78 |
| **Tuning** | paddingScale: 1.8, minimumSize: 0.22, score threshold: 0.35 |

### 6.6 `lib/services/camera/model_profile.dart`
| Item | Detail |
|------|--------|
| **Role** | Definisi 3 varian model TFLite |
| **Profiles** | `publicV2` (default, probability output, no ImageNet norm), `generalization` (sama), `legacy` (logits, ImageNet norm) |
| **Methods** | `selected` — dari env var `HISYARAT_MODEL_PROFILE`; `fallbackFor()` — chain v2→generalization→legacy |

### 6.7 `lib/services/camera/bisindo_alphabet_data.dart`
| Item | Detail |
|------|--------|
| **Role** | Static registry 26 alfabet BISINDO |
| **Classes** | `BisindoLetter` (letter, description, imagePath, handShape), `BisindoAlphabetData` |
| **Methods** | `getByLetter()`, `getAll()` |

---

## 7. lib/features/quiz/ — Quiz Sub-Feature

### 7.1 Models (3 file)

| File | Classes |
|------|---------|
| `quiz_word.dart` | `QuizWord` — word, category, letters, length |
| `quiz_score.dart` | `QuizScore` — id, userId, score, category, wordsCompleted, accuracy, comboCount |
| `achievement.dart` | `Achievement` — id, userId, code, unlockedAt |

### 7.2 Services (3 file)

| File | Key Classes/Methods |
|------|---------------------|
| `quiz_service.dart` | `loadWords()`, `getWordsForCategory()`, `getHint()`, `calculateScore()` — formula: base 10/word + accuracy + perfect bonus + speed bonus + combo bonus |
| `quiz_score_service.dart` | `saveScore()`, `getTopScores()`, `getUserScores()`, `getUserTotalScore()` |
| `achievement_service.dart` | 5 achievements: beginner_signer, fast_signer, perfect_signer, quiz_master, bisindo_legend |

### 7.3 Pages (5 file)

| File | Role |
|------|------|
| `quiz_menu_page.dart` | Category selection (Easy/Medium/Hard) |
| `quiz_page.dart` | Gameplay: kamera + timer + score + progress word + detected letter |
| `quiz_result_page.dart` | Post-quiz: score, accuracy, achievements unlock |
| `leaderboard_page.dart` | Top scores by category |
| `achievement_page.dart` | User achievements list |

### 7.4 Widgets (5 file)

| File | Role |
|------|------|
| `timer_widget.dart` | Circular timer bar (MM:SS, color-coded) |
| `score_widget.dart` | Score + combo count + words completed |
| `progress_word_widget.dart` | Letter boxes (completed/current/pending) + animated cooldown |
| `leaderboard_card.dart` | Leaderboard entry row (rank, avatar, stats) |
| `achievement_card.dart` | Achievement display (icon, name, date) |

---

## 8. lib/widgets/ — Shared UI (1 file)

| File | Role |
|------|------|
| `animated_hand_gesture.dart` | AnimatedSwitcher untuk transisi gambar gesture |

---

## 9. Assets

### 9.1 Data Files (2 file)
| Path | Isi |
|------|-----|
| `assets/data/quiz_words.json` | Kata per kategori (easy/medium/hard) |
| `assets/data/bisindo_seed_data.json` | Seed database (categories, vocabulary, gestures A-Z, numbers, words) |

### 9.2 Models (7 file)
| Path | Role |
|------|------|
| `bisindo_curriculum_v2.tflite` | Primary model (public-v2) — 224×224, 26 classes, 83.28% accuracy |
| `bisindo_generalization_v1.tflite` | Fallback model #1 |
| `bisindo_model.tflite` | Fallback model #2 (legacy) |
| `bisindo_model.pt` | PyTorch source |
| `bisindo_model.onnx` | ONNX intermediate |
| `labels.json` | Labels + metadata (accuracy, min recall 27.27%) |
| `labels.txt` | Labels plain text |

### 9.3 Images (27 file)
| Path | Isi |
|------|-----|
| `logo.png` | App logo |
| `gestures/alphabet_a.png` ... `alphabet_z.png` | 26 gesture illustrations A-Z |

---

## 10. Tests (8 file, 60+ test cases)

| File | Tests | Scope |
|------|-------|-------|
| `widget_test.dart` | 4 | Splash screen smoke tests |
| `prediction_filter_test.dart` | 3 | Confidence/margin, 3 consecutive, reset behavior |
| `model_profile_test.dart` | 3 | Default profile, fallback chain, legacy contract |
| `models_test.dart` | 13 | 6 models — fromMap, toMap, null handling, copyWith |
| `hand_crop_region_test.dart` | 3 | Build crop, reject weak landmarks, clamp edge |
| `constants_test.dart` | 9 | Identity, DB, AI thresholds, roles, pagination, paths |
| `auth_service_test.dart` | 11 | AuthException, UserModel, SessionModel, session CRUD |
| `app_logger_test.dart` | 12 | All levels, filtering, export, max limit, callback |

**Total**: 8 test files, ~60 test cases

---

## 11. Arsitektur Pipeline AI

```
Camera (NV21) ──► ML Kit Pose Detection
                        │
                        ▼
                 HandCropRegion (padding 1.8×)
                        │
                        ▼
                 NV21 → RGB (inlined, 224×224)
                        │
                        ▼
                 TFLite Inference (83.28% accuracy)
                        │
                        ▼
                 PredictionFilter (emit-once)
                        │
                        ▼
                 GestureResult → UI
```

### Threshold Saat Ini

| Parameter | Translate | Quiz |
|-----------|-----------|------|
| Confidence | ≥ 0.60 | ≥ 0.75 |
| Margin | ≥ 0.10 | ≥ 0.15 |
| Window | 5 frame | 5 frame |
| Required matches | 3 | 4 |
| Throttle | 100ms | 100ms |
| Emit mode | **1× per gesture** (emit-once) | **1× per gesture** |

---

## 12. Count Summary

| Kategori | Jumlah |
|----------|--------|
| **File Dart** (lib/) | **52** |
| Pages | 10 |
| Core | 4 |
| Providers | 4 |
| Services (app) | 10 |
| Services (camera) | 7 |
| Services (quiz) | 3 |
| Quiz models | 3 |
| Quiz pages | 5 |
| Quiz widgets | 5 |
| Shared widgets | 1 |
| **Test files** | **8** |
| **Test cases** | **60+** |
| **Assets** | **36** |
| Data JSON | 2 |
| Model files | 7 |
| Images | 27 |
