# Analisa AI Gesture Detection HiSyarat

## Gejala Masalah

- Kamera menyala, tangan terdeteksi (ada bounding box/overlay)
- Model AI sudah di-load
- Tapi aplikasi **tidak menampilkan huruf** yang sesuai dengan gerakan tangan
- Tidak ada movement/pergerakan yang terdeteksi oleh AI

---

## Pipeline Deteksi (Alur Lengkap)

```
Camera Frame (NV21)
      │
      ▼
GestureRecognizer.processFrame()         ← gesture_recognizer.dart
      │  (throttle 300ms — max ~3 fps)
      │
      ├──► ML Kit PoseDetection
      │       │  (deteksi tangan via wrist/index/thumb landmarks)
      │       │
      │       └──► HandCropRegion.fromNormalizedPoints()
      │               │  (crop area 2.35x dari bounding box tangan)
      │               │
      │               └──► butuh: wrist >= 0.45, min 2 landmarks >= 0.35
      │
      ├──► TFLite Classifier
      │       │  (model: bisindo_curriculum_v2.tflite, 224×224 RGB)
      │       │
      │       └──► _softmax() → ClassificationResult {label, confidence, margin}
      │
      └──► PredictionFilter
              │  (stabilisasi temporal)
              │
              └──► butuh: confidence >= 0.75, margin >= 0.15,
                         4 dari 5 frame sama dalam 2 detik
                          → baru tampilkan huruf
```

---

## Akar Masalah (Prioritas Tertinggi ke Terendah)

### 1. Filter Stabilisasi Terlalu Agresif ⚠️

File: `lib/core/constants.dart:27-30`

| Parameter | Nilai | Dampak |
|-----------|-------|--------|
| `aiPredictionConfidence` | **0.75** | Keyakinan model minimal 75% — model hanya akurat 83% |
| `aiPredictionMargin` | **0.15** | Harus unggul 15% dari prediksi kedua |
| `aiPredictionRequiredMatches` | **4 dari 5 frame** | 80% frame harus setuju |
| `aiPredictionWindowSize` | **5** | Window 5 frame |

Akibat:

- Dengan throttle **300ms**, perlu **1.5 detik** tangan diam sempurna
- Gerakan sedikit / transisi antar huruf akan **mereset buffer** (`_predictionFilter.reset()`)
- Banyak prediksi benar dengan confidence 60-74% langsung dibuang
- Margin 15% sulit dicapai untuk huruf yang mirip (contoh: M/N, U/V)

### 2. Mode AI Tetap Aktif Walaupun Model Gagal Load

File: `gesture_recognizer.dart:121-123`

```dart
// GAGAL load → tetap aiPrimary, bukan fallback ke rule-based
if (success) {
  _mode = RecognitionMode.aiPrimary;
} else {
  _mode = RecognitionMode.aiPrimary;  // SAMA!
}
```

- Jika model TFLite gagal di-load (file corrupted / platform error), mode tetap `aiPrimary`
- Rule-based tidak pernah dipakai (tapi aturannya beda alfabet, jadi kurang berguna)
- Akibatnya: AI tidak menghasilkan prediksi → tidak ada huruf

### 3. Threshold Deteksi Tangan (Hand Landmarks)

File: `gesture_recognizer.dart:293` dan `hand_crop_region.dart:42-50`

| Threshold | Nilai | Masalah |
|-----------|-------|---------|
| Wrist likelihood minimum | **0.45** | Tangan agak jauh/blur → ditolak |
| Landmarks usable minimum | **≥ 2 landmark** | OK, reasonable |
| Landmark likelihood minimum | **0.35** | Threshold cukup tinggi |
| Padding scale | **2.35×** | Crop box besar, gampang ke luar frame |
| Ukuran crop clamp | **[0.28, 0.78]** | Posisi tangan harus pas |

### 4. Chicken-and-Egg: Crop Default vs Hand Detection

File: `tflite_classifier.dart:175-219`

Jika hand region tidak terdeteksi (`handRegion == null`), classifier menggunakan **default ROI** di tengah frame (pinggang/dada), bukan area tangan. Model mendapat input yang salah → confidence rendah → filter reject → loop terus.

### 5. Potensi Model Tidak Terload

File: `tflite_classifier.dart:66-100`

```dart
// Fallback chain: public-v2 → generalization → legacy → silent fail
```

Jika ketiga model gagal, `_isInitialized = false`. Tidak ada error yang ditampilkan ke user.

---

## File-File Penting

| File | Peran |
|------|-------|
| `lib/core/constants.dart` | Threshold AI (confidence, margin, window, requiredMatches) |
| `lib/services/camera/gesture_recognizer.dart` | Orkestrator utama: pose detection → crop → classifier → filter |
| `lib/services/camera/tflite_classifier.dart` | Load model TFLite, preprocessing NV21→RGB 224×224, inference |
| `lib/services/camera/hand_crop_region.dart` | Crop bounding box dari pose landmarks |
| `lib/services/camera/prediction_filter.dart` | Stabilisasi temporal (4/5 frame dalam 2 detik) |
| `lib/services/camera/model_profile.dart` | 3 profil model: public-v2, generalization, legacy |
| `lib/translate_page.dart` | UI kamera, start/stop detection, overlay hasil |
| `assets/models/bisindo_curriculum_v2.tflite` | Model default (public-v2) |
| `assets/models/bisindo_generalization_v1.tflite` | Fallback model #1 |
| `assets/models/bisindo_model.tflite` | Fallback model #2 (legacy) |
| `assets/models/labels.json` | Label A-Z, accuracy 83.28%, min recall 27.27% |
| `pubspec.yaml` | Dependencies: camera, google_mlkit_pose_detection, tflite_flutter |

---

## Rencana Perbaikan

### Prioritas 1 — Longgarkan Filter Stabilisasi

Ubah di `lib/core/constants.dart`:

| Parameter | Nilai Lama | Nilai Baru | Alasan |
|-----------|-----------|-----------|--------|
| `aiPredictionRequiredMatches` | 4 | **3** | 60% frame (dari 80%), lebih toleran |
| `aiPredictionConfidence` | 0.75 | **0.60** | Model akurasi 83%, threshold 60% lebih realistis |
| `aiPredictionMargin` | 0.15 | **0.10** | Margin 10% cukup untuk huruf yang mirip |

### Prioritas 2 — Tambahkan Debug Model Loading

Di `tflite_classifier.dart`, tambahkan print agar bisa lihat apakah model berhasil di-load:

```dart
debugPrint('[TFLite] Model loaded: $modelName');
debugPrint('[TFLite] Model FAILED: $error');
```

### Prioritas 3 — Fallback ke Hybrid Mode Jika Gagal

Di `gesture_recognizer.dart:122`, ganti menjadi:

```dart
_mode = RecognitionMode.hybrid;  // biar rule-based jalan
```

### Prioritas 4 — Debug Visual

Tambahkan bounding box overlay di `translate_page.dart` untuk melihat apakah crop region sesuai dengan posisi tangan.

---

## Cara Testing

1. Jalankan `flutter run` dengan HP terhubung
2. Buka tab kamera (TranslatePage), tekan "Mulai"
3. Perhatikan log untuk:
   - `[TFLite] Model loaded: ...` — pastikan model jalan
   - `[PredictionFilter]` — lihat confidence & margin tiap frame
4. Coba gerakan huruf A, B, C (yang mudah dan beda jauh)
5. Lihat apakah muncul di overlay setelah perbaikan
