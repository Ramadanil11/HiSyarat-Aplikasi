# Quiz BISINDO

## Overview
Fitur Quiz BISINDO adalah permainan mengeja kata menggunakan isyarat tangan
yang terdeteksi oleh kamera. Pemain harus mengisyaratkan huruf per huruf
dari kata yang diberikan dalam batas waktu.

## Cara Kerja
1. Pemilih tingkat kesulitan (Easy / Medium / Hard)
2. Kata acak ditampilkan huruf per huruf
3. Pemain mengisyaratkan huruf yang sesuai di depan kamera
4. Jika isyarat benar → huruf hijau, lanjut ke huruf berikutnya
5. Jika salah 3× → muncul hint + tombol "Lewati"
6. Semua huruf dalam kata selesai → kata berikutnya
7. Timer 60 detik → otomatis selesai

## Skor
- Akurasi: (correctAttempts / totalAttempts) × 100
- Bonus kata sempurna: +5 per kata jika akurasi ≥ 80%
- Bonus kecepatan: +5 jika sisa waktu > 30 detik

## Struktur File
```
lib/features/quiz/
├── models/
│   ├── quiz_word.dart
│   └── quiz_score.dart
├── services/
│   ├── quiz_service.dart
│   └── quiz_score_service.dart
├── pages/
│   ├── quiz_menu_page.dart
│   ├── quiz_page.dart
│   └── quiz_result_page.dart
assets/data/quiz_words.json
```

## Threshold AI (lebih ketat dari Translate)
| Parameter | Translate | Quiz |
|-----------|-----------|------|
| Confidence | 0.60 | 0.75 |
| Margin | 0.10 | 0.15 |
| RequiredMatches | 3 | 4 |

## Tabel Database
`quiz_scores`:
- id, user_id, score, category, words_completed,
  total_attempts, correct_attempts, created_at

## Navigasi
HomePage → QuizMenuPage → QuizPage → QuizResultPage
