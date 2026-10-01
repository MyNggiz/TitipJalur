import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/errand_feed_notifier.dart';
import '../models/errand_model.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../widgets/fade_slide_entry.dart';

class HomepageScreen extends ConsumerStatefulWidget {
  const HomepageScreen({
    super.key,
    this.onExploreFeed,
  });

  /// Optional callback to switch to feed tab in bottom navigation
  final VoidCallback? onExploreFeed;

  @override
  ConsumerState<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends ConsumerState<HomepageScreen> {
  int _activeStepIndex = 0;

  static const Color _primaryEmerald = Color(0xFF059669);
  static const Color _lightEmeraldBg = Color(0xFFECFDF5);
  static const Color _darkEmerald = Color(0xFF065F46);

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final userName = (user?.name != null && user!.name.isNotEmpty) ? user.name : 'Mahasiswa';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'M';
    final feedState = ref.watch(errandFeedNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: FadeSlideEntry.staggered(
          index: 0,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _lightEmeraldBg,
                child: Text(
                  userInitial,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: _primaryEmerald,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Halo, $userName 👋',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Color(0xFF111827),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Komuter Siap Bantu',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FadeSlideEntry.staggered(
            index: 0,
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF374151)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Belum ada notifikasi baru.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Banner
            FadeSlideEntry.staggered(
              index: 1,
              child: _buildHeroBanner(),
            ),
            const SizedBox(height: 30),

            // 2. Quick Actions
            FadeSlideEntry.staggered(
              index: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActionsHeader(),
                  const SizedBox(height: 14),
                  _buildQuickActionsGrid(context),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 3. Step-by-Step Tutorial
            FadeSlideEntry.staggered(
              index: 3,
              child: _buildTutorialSection(context),
            ),
            const SizedBox(height: 30),

            // 4. Live Stats Kampus
            FadeSlideEntry.staggered(
              index: 4,
              child: _buildLiveStatsSection(feedState),
            ),
            const SizedBox(height: 30),

            // 5. CTA Buttons
            FadeSlideEntry.staggered(
              index: 5,
              child: _buildPrimaryCTAs(context),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. HERO BANNER ---
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_darkEmerald, _primaryEmerald],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryEmerald.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'Gerakan Kampus Ramah Lingkungan',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Titip Jalur: Nol Emisi, Hemat Waktu',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Crowdsourcing cerdas yang menghubungkan mahasiswa yang butuh barang dengan komuter yang searah jalan pulang atau menuju kelas.',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. QUICK ACTIONS ---
  Widget _buildQuickActionsHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mau Titip Apa Hari Ini?',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Pilih kategori cepat untuk membuat permintaan titip',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      _QuickActionItem(
        title: 'Titip Makanan',
        subtitle: 'Kantin & Warung',
        icon: Icons.fastfood_rounded,
        color: const Color(0xFFF97316),
        bgTint: const Color(0xFFFFF7ED),
      ),
      _QuickActionItem(
        title: 'Titip ATK/Print',
        subtitle: 'Fotokopi Kampus',
        icon: Icons.print_rounded,
        color: const Color(0xFF2563EB),
        bgTint: const Color(0xFFEFF6FF),
      ),
      _QuickActionItem(
        title: 'Kopi/Minuman',
        subtitle: 'Kedai & Kafe',
        icon: Icons.local_cafe_rounded,
        color: const Color(0xFF7C3AED),
        bgTint: const Color(0xFFF5F3FF),
      ),
      _QuickActionItem(
        title: 'Bantuan Obat',
        subtitle: 'Apotek & Darurat',
        icon: Icons.medical_services_rounded,
        color: const Color(0xFFDC2626),
        bgTint: const Color(0xFFFEF2F2),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        return _InteractiveScaleCard(
          onTap: () {
            Navigator.of(context).pushNamed(AppRoutes.createErrand);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.bgTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Quick actions implementation integrated above

  // --- 3. TUTORIAL SECTION ---
  Widget _buildTutorialSection(BuildContext context) {
    final tutorialSteps = [
      _TutorialStepData(
        stepNumber: 1,
        title: 'Ketik Pesanan Anda',
        summary: 'Tulis barang & lokasi jemput',
        description:
            'Tentukan barang yang kamu butuhkan, mulai dari kantin, tempat print, atau apotek. Masukkan tip sukarela untuk teman komutermu.',
        icon: Icons.edit_note_rounded,
        tag: 'Mudah & Cepat',
      ),
      _TutorialStepData(
        stepNumber: 2,
        title: 'Temukan Komuter Searah',
        summary: 'Cocokkan radius rute jalan',
        description:
            'Algoritma TitipJalur menampilkan permintaanmu kepada teman-teman kampus yang kebetulan sedang melintasi lokasi jemput menuju lokasimu.',
        icon: Icons.alt_route_rounded,
        tag: 'P2P Matching',
      ),
      _TutorialStepData(
        stepNumber: 3,
        title: 'Terima Barang & Serahkan Tip',
        summary: 'Verifikasi & serah terima aman',
        description:
            'Komuter menyerahkan pesanan di titik temu yang disepakati. Cek kelengkapan barang dan selesaikan pesanan dengan senyum.',
        icon: Icons.verified_user_rounded,
        tag: 'Aman & Terpercaya',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_stories_rounded, color: _primaryEmerald, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Cara Kerja TitipJalur',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _lightEmeraldBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '3 Langkah Cepat',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _primaryEmerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stepper Tabs Indicator
          Row(
            children: List.generate(tutorialSteps.length, (index) {
              final isSelected = index == _activeStepIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeStepIndex = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: index < tutorialSteps.length - 1 ? 8 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isSelected ? _primaryEmerald : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),

          // Expandable / Interactive Step Cards
          Column(
            children: List.generate(tutorialSteps.length, (index) {
              final step = tutorialSteps[index];
              final isExpanded = index == _activeStepIndex;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: EdgeInsets.only(bottom: index < tutorialSteps.length - 1 ? 16 : 0),
                decoration: BoxDecoration(
                  color: isExpanded ? _lightEmeraldBg.withValues(alpha: 0.5) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isExpanded ? _primaryEmerald.withValues(alpha: 0.4) : const Color(0xFFF3F4F6),
                    width: isExpanded ? 1.5 : 1.0,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      _activeStepIndex = index;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isExpanded ? _primaryEmerald : const Color(0xFFE5E7EB),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${step.stepNumber}',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isExpanded ? Colors.white : const Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.title,
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isExpanded ? _darkEmerald : const Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    step.summary,
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: isExpanded ? _primaryEmerald : const Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.only(left: 48),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.description,
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12.5,
                                    color: Color(0xFF374151),
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _primaryEmerald.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '# ${step.tag}',
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _darkEmerald,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showP2PExplanationDialog(context);
              },
              icon: const Icon(Icons.info_outline_rounded, size: 16, color: _primaryEmerald),
              label: const Text(
                'Pelajari Sistem P2P TitipJalur',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _primaryEmerald,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFA7F3D0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. LIVE STATS KAMPUS ---
  Widget _buildLiveStatsSection(AsyncValue<List<ErrandModel>> feedState) {
    final errands = feedState.valueOrNull ?? [];
    final activeCount = errands.where((e) => e.status == OrderStatus.open).length;
    final displayActive = activeCount > 0 ? '$activeCount Titipan' : '5 Titipan';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.insights_rounded, color: _primaryEmerald, size: 20),
            SizedBox(width: 8),
            Text(
              'Ringkasan Ekosistem Kampus',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Titipan Aktif',
                value: displayActive,
                subtext: 'Bisa kamu bantu',
                icon: Icons.local_mall_outlined,
                accentColor: const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Waktu Antar',
                value: '~12 Menit',
                subtext: 'Rute searah kampus',
                icon: Icons.timer_outlined,
                accentColor: const Color(0xFFEA580C),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Emisi Karbon',
                value: '0 kg CO₂',
                subtext: 'Hemat perjalanan',
                icon: Icons.eco_outlined,
                accentColor: _primaryEmerald,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10,
              color: Color(0xFF9CA3AF),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  // --- 5. PRIMARY CTA BUTTONS ---
  Widget _buildPrimaryCTAs(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.createErrand);
            },
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
            label: const Text(
              'Buat Permintaan Titip Baru',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryEmerald,
              elevation: 2,
              shadowColor: _primaryEmerald.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              if (widget.onExploreFeed != null) {
                widget.onExploreFeed!();
              } else {
                Navigator.of(context).pushNamed(AppRoutes.dashboard);
              }
            },
            icon: const Icon(Icons.explore_rounded, color: _primaryEmerald),
            label: const Text(
              'Jelajahi Feed Komuter Sekarang',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _primaryEmerald,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _primaryEmerald, width: 1.5),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showP2PExplanationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.hub_rounded, color: _primaryEmerald),
            SizedBox(width: 8),
            Text('Konsep Peer-to-Peer', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          'TitipJalur bukan jasa kurir komersil, melainkan komunitas gotong royong antar sesama mahasiswa.\n\n'
          'Sambil kamu berjalan kaki atau naik motor ke kelas atau kosan, kamu bisa membantu membelikan barang pesanan teman yang searah tanpa membuang waktu tambahan.',
          style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF374151)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mengerti', style: TextStyle(color: _primaryEmerald)),
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem {
  _QuickActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgTint,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgTint;
}

class _TutorialStepData {
  _TutorialStepData({
    required this.stepNumber,
    required this.title,
    required this.summary,
    required this.description,
    required this.icon,
    required this.tag,
  });

  final int stepNumber;
  final String title;
  final String summary;
  final String description;
  final IconData icon;
  final String tag;
}

class _InteractiveScaleCard extends StatefulWidget {
  const _InteractiveScaleCard({
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_InteractiveScaleCard> createState() => _InteractiveScaleCardState();
}

class _InteractiveScaleCardState extends State<_InteractiveScaleCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? 0.95 : (_isHovered ? 1.02 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: widget.child,
        ),
      ),
    );
  }
}
