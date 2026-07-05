/// HiSyarat App Constants
/// Konstanta aplikasi BISINDO sign language
/// Pattern: Flat-page (seperti spedi project)

class AppConstants {
  AppConstants._();

  // ─── App Identity ───────────────────────────────────────────────────────────
  static const String appName = 'HiSyarat';
  static const String appTagline = 'Berkomunikasi dengan BISINDO';
  static const String appTheme = 'Komunikasi Inklusif';
  static const String appDescription =
      'Belajar dan berkomunikasi dengan BISINDO';
  static const String appVersion = '1.0.0';

  // ─── Database ───────────────────────────────────────────────────────────────
  static const String dbName = 'hisyarat.db';
  static const int dbVersion = 8;

  // ─── Timing ─────────────────────────────────────────────────────────────────
  static const int splashDuration = 3; // detik

  // ─── AI / Detection ─────────────────────────────────────────────────────────
  static const double defaultAccuracy = 87.9;
  static const double confidenceThreshold = 0.7;
  static const double aiPredictionConfidence = 0.60;
  static const double aiPredictionMargin = 0.10;
  static const int aiPredictionWindowSize = 5;
  static const int aiPredictionRequiredMatches = 3;

  // ─── Quiz AI Prediction V2 (more strict than translate) ──────────────────────
  static const double quizPredictionConfidence = 0.75;
  static const double quizPredictionMargin = 0.15;
  static const int quizPredictionWindowSize = 5;
  static const int quizPredictionRequiredMatches = 4;
  static const int poseDetectionInterval = 100; // ms
  static const String tfliteModelName = 'bisindo_curriculum_v2.tflite';
  static const String labelsFileName = 'labels.json';
  static const int modelInputSize = 224; // Input image size for model

  // ─── User Roles ─────────────────────────────────────────────────────────────
  static const List<String> roles = ['learner', 'instructor', 'admin'];

  // ─── Gesture Directions ─────────────────────────────────────────────────────
  static const List<String> directions = [
    'up',
    'down',
    'left',
    'right',
    'forward',
    'backward',
    'circular_cw',
    'circular_ccw',
    'static',
  ];

  // ─── Difficulty Levels ──────────────────────────────────────────────────────
  static const List<String> difficulties = [
    'beginner',
    'intermediate',
    'advanced',
    'expert',
  ];

  // ─── Asset Paths ────────────────────────────────────────────────────────────
  static const String seedDataPath = 'assets/data/bisindo_seed_data.json';
  static const String gestureImagesPath = 'assets/images/gestures/';
  static const String aiModelPath = 'assets/models/';

  // ─── API / Endpoints (jika diperlukan) ──────────────────────────────────────
  static const int connectionTimeout = 15000; // ms
  static const int receiveTimeout = 15000; // ms
  static const String apiBaseUrl = String.fromEnvironment(
    'HISYARAT_API_URL',
    defaultValue: 'https://polyester-pupil-armored.ngrok-free.dev/api/v1',
  );

  // ─── Pagination ─────────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ─── Validation ─────────────────────────────────────────────────────────────
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  static const int minPasswordLength = 8;
}
