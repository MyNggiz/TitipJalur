import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/errand_feed_notifier.dart';
import '../models/errand_model.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../widgets/errand_card.dart';
import '../widgets/fade_slide_entry.dart';
import '../widgets/primary_button.dart';
import '../widgets/state_view.dart';
import 'create_errand_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const DashboardScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  double _radiusKm = 3.0;
  String _selectedCategory = 'Semua';

  final List<String> _categories = const [
    'Semua',
    'Kantin',
    'ATK',
    'Kafe',
    'Belanja',
    'Obat',
  ];

  bool _matchesCategory(ErrandModel errand, String category) {
    if (category == 'Semua') return true;
    final catLower = errand.category.toLowerCase();
    final itemLower = errand.item.toLowerCase();
    final pickupLower = errand.pickup.toLowerCase();

    if (category == 'Kantin') {
      return catLower.contains('makan') ||
          catLower.contains('kantin') ||
          pickupLower.contains('kantin') ||
          itemLower.contains('ayam') ||
          itemLower.contains('nasi');
    }
    if (category == 'ATK') {
      return catLower.contains('dokumen') ||
          catLower.contains('atk') ||
          pickupLower.contains('atk') ||
          pickupLower.contains('koperasi') ||
          itemLower.contains('laporan') ||
          itemLower.contains('print');
    }
    if (category == 'Kafe') {
      return catLower.contains('minuman') ||
          catLower.contains('kafe') ||
          pickupLower.contains('kafe') ||
          itemLower.contains('kopi') ||
          itemLower.contains('macchiato');
    }
    if (category == 'Belanja') {
      return catLower.contains('belanja') ||
          pickupLower.contains('mart') ||
          pickupLower.contains('minimarket');
    }
    if (category == 'Obat') {
      return catLower.contains('obat') ||
          pickupLower.contains('apotek') ||
          pickupLower.contains('klinik');
    }
    return catLower.contains(category.toLowerCase());
  }

  List<ErrandModel> _filterErrands(List<ErrandModel> errands) {
    return errands.where((errand) {
      final inRadius = errand.distanceKm <= _radiusKm;
      final inCategory = _matchesCategory(errand, _selectedCategory);
      return inRadius && inCategory;
    }).toList();
  }

  Future<void> _handleAcceptErrand(ErrandModel errand) async {
    try {
      await ref
          .read(errandFeedNotifierProvider.notifier)
          .acceptErrand(errand.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Titipan "${errand.item}" berhasil diambil!',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengambil titipan: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openCreateErrandScreen() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateErrandScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService.instance.currentUser;
    final userName = user?.name ?? 'Mahasiswa';

    final feedState = ref.watch(errandFeedNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Halo, $userName',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Komuter Aktif',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
            const Text(
              'Rute Searah Kampus Bersama',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          // Demo P4 Menu for interactive verification of the 6 UI states
          PopupMenuButton<String>(
            tooltip: 'Simulasi Kondisi UI (Demo P4)',
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.science_outlined,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Demo P4',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
            onSelected: (value) {
              final notifier = ref.read(errandFeedNotifierProvider.notifier);
              if (value == 'normal') {
                notifier.loadErrands();
              } else if (value == 'empty') {
                notifier.loadErrands(forceEmpty: true);
              } else if (value == 'error') {
                notifier.loadErrands(forceError: true);
              } else if (value == 'create') {
                _openCreateErrandScreen();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'normal',
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: Color(0xFF059669),
                    ),
                    SizedBox(width: 8),
                    Text('1 & 2. Muat Normal (Data Berhasil)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'empty',
                child: Row(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 18,
                      color: Color(0xFFD97706),
                    ),
                    SizedBox(width: 8),
                    Text('3. Simulasi Empty State'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'error',
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: Color(0xFFDC2626),
                    ),
                    SizedBox(width: 8),
                    Text('4. Simulasi Error State + Retry'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'create',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 18,
                      color: Color(0xFF2563EB),
                    ),
                    SizedBox(width: 8),
                    Text('5 & 6. Buka Form & Validasi'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Profil Saya',
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF059669), width: 1.5),
              ),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF059669),
                child: Icon(Icons.person, size: 18, color: Colors.white),
              ),
            ),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Section (Radius Slider + Category Chips)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radius slider label & slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.radar_rounded,
                            size: 18,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Radius Pengantaran: ${_radiusKm.toStringAsFixed(1)} km',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Max: 5.0 km',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF059669),
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                    thumbColor: const Color(0xFF059669),
                    overlayColor:
                        const Color(0xFF059669).withValues(alpha: 0.14),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _radiusKm,
                    min: 0.5,
                    max: 5.0,
                    divisions: 9,
                    onChanged: (val) {
                      setState(() => _radiusKm = val);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(cat),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF475569),
                          ),
                          backgroundColor: const Color(0xFFF1F5F9),
                          selectedColor: const Color(0xFF059669),
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF059669)
                                  : Colors.transparent,
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Feed Content handled by feedState.when
          Expanded(
            child: feedState.when(
              // Kondisi UI 1: Initial Loading
              loading: () => const LoadingStateView(
                message: 'Memuat feed titipan komuter...',
              ),

              // Kondisi UI 4: Error State dengan tombol Retry
              error: (err, _) => ErrorStateView(
                title: 'Gagal Memuat Titipan',
                message: err.toString().replaceFirst('Exception: ', ''),
                onRetry: () =>
                    ref.read(errandFeedNotifierProvider.notifier).retry(),
              ),

              // Kondisi UI 2 & 3: Data Loaded / Empty State
              data: (errands) {
                // Kondisi UI 3: Empty State jika data dari repository kosong
                if (errands.isEmpty) {
                  return EmptyStateView(
                    title: 'Belum Ada Titipan Aktif',
                    message:
                        'Saat ini belum ada pesanan titipan di rute Anda. Jadilah yang pertama membuat titipan!',
                    icon: Icons.inbox_outlined,
                    action: PrimaryButton(
                      label: 'Buat Titipan Pertama',
                      icon: Icons.add_rounded,
                      onPressed: _openCreateErrandScreen,
                    ),
                  );
                }

                // Filter berdasarkan slider radius dan kategori
                final filtered = _filterErrands(errands);

                if (filtered.isEmpty) {
                  return EmptyStateView(
                    title: 'Tidak Ada Titipan Ditemukan',
                    message:
                        'Tidak ada titipan pada radius ${_radiusKm.toStringAsFixed(1)} km kategori "$_selectedCategory". Cobalah memperluas radius atau ubah kategori.',
                    icon: Icons.search_off_rounded,
                    action: PrimaryButton(
                      label: 'Reset Filter',
                      height: 40,
                      onPressed: () {
                        setState(() {
                          _radiusKm = 5.0;
                          _selectedCategory = 'Semua';
                        });
                      },
                    ),
                  );
                }

                // Kondisi UI 2: Data Berhasil Dimuat
                return RefreshIndicator(
                  color: const Color(0xFF059669),
                  onRefresh: () =>
                      ref.read(errandFeedNotifierProvider.notifier).loadErrands(),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 16,
                          bottom: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Titipan Tersedia (${filtered.length})',
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'P2P Kampus',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 130),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final errand = filtered[index];
                            return FadeSlideEntry.staggered(
                              index: index,
                              child: ErrandCard(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                errand: errand,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.detail,
                                    arguments: errand,
                                  );
                                },
                                onAccept: errand.status == OrderStatus.open
                                    ? () => _handleAcceptErrand(errand)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateErrandScreen,
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          '+ Titip Cepat',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
