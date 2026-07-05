/// HiSyarat - Home/Dashboard Page
/// Pattern: StatefulWidget + setState(), imperative navigation, SnackBar feedback
/// Bottom navigation with 4 tabs: Beranda, Terjemah, Riwayat, Profil

import 'package:flutter/material.dart';

import 'core/themes.dart';
import 'core/constants.dart';
import 'services/auth_service.dart';
import 'services/translation_service.dart';
import 'translate_page.dart';
import 'dictionary_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'dataset_collector_page.dart';
import 'features/quiz/pages/quiz_menu_page.dart';
import 'features/quiz/pages/leaderboard_page.dart';
import 'features/quiz/pages/achievement_page.dart';

class HomePage extends StatefulWidget {
  final UserModel user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ─── State Variables ──────────────────────────────────────────────────────
  int _currentNavIndex = 0;
  bool _isLoadingStats = true;
  Map<String, dynamic> _stats = {};
  List<CategoryModel> _categories = [];

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // ─── Data Loading ─────────────────────────────────────────────────────────

  Future<void> _loadDashboardData() async {
    setState(() => _isLoadingStats = true);

    try {
      final translationService = TranslationService();
      final userId = widget.user.id ?? 0;

      final stats = await translationService.getDashboardStats(userId);
      final categories = await translationService.getAllCategories();

      if (!mounted) return;

      setState(() {
        _stats = stats;
        _categories = categories;
        _isLoadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingStats = false);
      _showSnackBar('Gagal memuat data dashboard', isError: true);
    }
  }

  // ─── Navigation Handler ───────────────────────────────────────────────────

  void _onNavTap(int index) {
    if (index == 0) {
      setState(() => _currentNavIndex = 0);
      return;
    }

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TranslatePage(user: widget.user)),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HistoryPage(user: widget.user)),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage(user: widget.user)),
      );
    }
  }

  // ─── SnackBar Helper ──────────────────────────────────────────────────────

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  _buildCategoriesSection(),
                  const SizedBox(height: 24),
                  _buildDatasetCollector(),
                  const SizedBox(height: 24),
                  _buildQuizCard(),
                  const SizedBox(height: 24),
                  _buildLeaderboardCard(),
                  const SizedBox(height: 24),
                  _buildAchievementCard(),
                  const SizedBox(height: 24),
                  _buildInfoCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Header with Gradient ─────────────────────────────────────────────────

  Widget _buildHeader() {
    final roleSubtitle = _getRoleSubtitle();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${widget.user.name}!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          roleSubtitle,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TranslatePage(user: widget.user),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: AppColors.primaryDark,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Terjemahkan dengan kamera',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Deteksi alfabet BISINDO secara langsung',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.text_fields,
                      label: 'Teks ke Isyarat',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TranslatePage(user: widget.user),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.menu_book_rounded,
                      label: 'Belajar BISINDO',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DictionaryPage(user: widget.user),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20, semanticLabel: label),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Statistics Grid ──────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    if (_isLoadingStats) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final statItems = [
      _StatItem(
        label: 'Kosakata tersedia',
        value: '${_stats['totalVocabularies'] ?? 0}',
        unit: 'kata',
        icon: Icons.menu_book_outlined,
        color: AppColors.primary,
      ),
      _StatItem(
        label: 'Terjemahanmu',
        value: '${_stats['totalTranslations'] ?? 0}',
        unit: 'kali',
        icon: Icons.translate,
        color: AppColors.secondary,
      ),
      _StatItem(
        label: 'Sesi latihan',
        value: '${_stats['totalSessions'] ?? 0}',
        unit: 'sesi',
        icon: Icons.timer_outlined,
        color: AppColors.accent,
      ),
      _StatItem(
        label: 'Akurasi deteksi',
        value: (_stats['aiAccuracy'] as num?)?.toStringAsFixed(1) ?? '0.0',
        unit: '%',
        icon: Icons.auto_awesome_outlined,
        color: AppColors.info,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan aktivitas',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 380;
              return GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: isCompact ? 1.45 : 1.7,
                ),
                itemCount: statItems.length,
                itemBuilder: (context, index) {
                  return _buildStatCard(statItems[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Semantics(
      label: '${item.label}: ${item.value} ${item.unit}',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: item.value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: item.color,
                      ),
                      children: [
                        TextSpan(
                          text: ' ${item.unit}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Categories Section ───────────────────────────────────────────────────

  Widget _buildCategoriesSection() {
    if (_categories.isEmpty && !_isLoadingStats) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Mulai belajar',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 116,
            child: _categories.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada kategori',
                      style: TextStyle(color: AppColors.textHint),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 4),
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _buildCategoryChip(_categories[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(CategoryModel category, int index) {
    final color =
        AppColors.categoryColors[index % AppColors.categoryColors.length];
    final iconData = _getCategoryIcon(category);

    return SizedBox(
      width: 104,
      child: Material(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DictionaryPage(
                  user: widget.user,
                  initialCategoryName: category.name,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(iconData, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Info Card ────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Komunikasi yang lebih inklusif',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'BISINDO adalah bahasa yang tumbuh alami di komunitas Tuli '
              'Indonesia. Gunakan kamus untuk belajar, lalu latih gerakanmu '
              'melalui kamera.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatasetCollector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DatasetCollectorPage(user: widget.user),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.add_a_photo_outlined, color: AppColors.primaryDark),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Koleksi Dataset BISINDO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Ambil foto huruf dari pemeraga baru',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.primaryDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuizMenuPage()),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.quiz_outlined, color: Colors.amber),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quiz BISINDO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Uji kemampuan isyarat huruf dalam waktu terbatas',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.amber),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LeaderboardPage(),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.leaderboard, color: Colors.purple),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leaderboard',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Lihat peringkat pengguna terbaik',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.purple),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AchievementPage(userId: widget.user.id ?? 0),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.teal),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Achievement',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Kumpulkan lencana prestasi',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.teal),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Bottom Navigation ────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return NavigationBar(
      height: 70,
      selectedIndex: _currentNavIndex,
      onDestinationSelected: _onNavTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.translate_outlined),
          selectedIcon: Icon(Icons.translate),
          label: 'Terjemah',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'Riwayat',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _getRoleSubtitle() {
    switch (widget.user.role) {
      case 'learner':
        return 'Mari belajar dan berkomunikasi dengan BISINDO';
      case 'instructor':
        return 'Bagikan pengetahuan BISINDO hari ini';
      case 'admin':
        return 'Panel Administrator';
      default:
        return AppConstants.appTagline;
    }
  }

  IconData _getCategoryIcon(CategoryModel category) {
    final iconName = category.iconName?.toLowerCase().trim();
    final categoryName = category.name.toLowerCase().trim();

    if (categoryName.contains('aktivitas')) {
      return Icons.checklist_rounded;
    }
    if (categoryName.contains('alfabet')) {
      return Icons.abc_rounded;
    }
    if (categoryName.contains('angka')) {
      return Icons.onetwothree_rounded;
    }
    if (categoryName.contains('darurat')) {
      return Icons.warning_amber_rounded;
    }
    if (categoryName.contains('salam') || categoryName.contains('sapaan')) {
      return Icons.waving_hand_rounded;
    }
    if (categoryName.contains('keluarga')) {
      return Icons.diversity_3_rounded;
    }
    if (categoryName.contains('perasaan')) {
      return Icons.sentiment_satisfied_alt_rounded;
    }
    if (categoryName.contains('pertanyaan')) {
      return Icons.contact_support_rounded;
    }
    if (categoryName.contains('tempat')) {
      return Icons.map_rounded;
    }
    if (categoryName.contains('waktu')) {
      return Icons.schedule_rounded;
    }

    switch (iconName) {
      case 'greeting':
      case 'waving_hand':
        return Icons.waving_hand_rounded;
      case 'family':
      case 'family_restroom':
        return Icons.diversity_3_rounded;
      case 'food':
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'emotion':
      case 'emoji_emotions':
        return Icons.sentiment_satisfied_alt_rounded;
      case 'number':
      case 'numbers':
        return Icons.onetwothree_rounded;
      case 'color':
      case 'palette':
        return Icons.palette_rounded;
      case 'animal':
      case 'pets':
        return Icons.pets_rounded;
      case 'place':
        return Icons.map_rounded;
      case 'time':
      case 'schedule':
        return Icons.schedule_rounded;
      case 'activity':
        return Icons.checklist_rounded;
      case 'alphabet':
      case 'abc':
        return Icons.abc_rounded;
      case 'emergency':
        return Icons.warning_amber_rounded;
      case 'question':
      case 'help_outline':
        return Icons.contact_support_rounded;
      default:
        return Icons.label_outline;
    }
  }
}

// ─── Helper Model ─────────────────────────────────────────────────────────────

class _StatItem {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });
}
