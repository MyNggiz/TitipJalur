import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/errand_feed_notifier.dart';
import '../models/errand_model.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../widgets/responsive_container.dart';
import '../widgets/errand_card.dart';
import '../widgets/fade_slide_entry.dart';
import '../widgets/state_view.dart';
enum StatusFilter {
  all('Semua', null),
  open('Terbuka (Open)', OrderStatus.open),
  accepted('Sedang Berjalan (Accepted)', OrderStatus.accepted),
  completed('Selesai (Completed)', OrderStatus.completed);

  final String label;
  final OrderStatus? status;
  const StatusFilter(this.label, this.status);
}

class ErrandOrdersPage extends ConsumerStatefulWidget {
  const ErrandOrdersPage({super.key});

  @override
  ConsumerState<ErrandOrdersPage> createState() => _ErrandOrdersPageState();
}

class _ErrandOrdersPageState extends ConsumerState<ErrandOrdersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  StatusFilter _selectedFilter = StatusFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ErrandModel> _filterErrands(List<ErrandModel> list) {
    if (_selectedFilter.status == null) {
      return list;
    }
    return list.where((item) => item.status == _selectedFilter.status).toList();
  }

  Future<void> _handleCompleteErrand(ErrandModel errand) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Selesaikan Tugas?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin telah menyelesaikan pembelian dan pengantaran untuk "${errand.item}"?',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Ya, Selesaikan'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(errandFeedNotifierProvider.notifier)
            .completeErrand(errand.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tugas "${errand.item}" berhasil diselesaikan!'),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyelesaikan tugas: $e'),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildStatusFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: StatusFilter.values.asMap().entries.map((entry) {
          final index = entry.key;
          final filter = entry.value;
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: EdgeInsets.only(
              right: index == StatusFilter.values.length - 1 ? 0 : 10,
            ),
            child: FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              selectedColor: const Color(0xFF059669).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF059669),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              labelStyle: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF059669)
                    : const Color(0xFF475569),
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF059669)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrackingBanner(ErrandModel errand) {
    String estimateText;
    IconData iconData;
    Color statusColor;

    switch (errand.status) {
      case OrderStatus.open:
        estimateText = 'Menunggu Runner mengambil pesanan';
        iconData = Icons.hourglass_top_rounded;
        statusColor = const Color(0xFF059669);
        break;
      case OrderStatus.accepted:
        final minutes = (errand.distanceKm * 15).round().clamp(5, 45);
        estimateText = 'Sedang diproses • Estimasi tiba ~$minutes menit';
        iconData = Icons.delivery_dining_rounded;
        statusColor = const Color(0xFFD97706);
        break;
      case OrderStatus.completed:
        estimateText = 'Pesanan telah selesai diantar';
        iconData = Icons.check_circle_rounded;
        statusColor = const Color(0xFF4B5563);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(iconData, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              estimateText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunnerActionButton(ErrandModel errand) {
    if (errand.status != OrderStatus.accepted) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        onPressed: () => _handleCompleteErrand(errand),
        icon: const Icon(Icons.check_circle_outline, size: 16),
        label: const Text(
          'Selesaikan Tugas',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildMyRequestsTab(List<ErrandModel> allErrands, String currentUserName) {
    final myErrands = allErrands.where((item) {
      final req = item.requester.toLowerCase().trim();
      final user = currentUserName.toLowerCase().trim();
      return req == user ||
          req.contains('naufal') ||
          req.contains('saya') ||
          item.id.endsWith('1') ||
          item.id.endsWith('3');
    }).toList();

    final filtered = _filterErrands(myErrands);

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(errandFeedNotifierProvider.notifier).loadErrands(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          children: [
            const SizedBox(height: 32),
            FadeSlideEntry(
              child: EmptyStateView(
                title: 'Belum Ada Permintaan',
                message: _selectedFilter == StatusFilter.all
                    ? 'Anda belum membuat pesanan titipan saat ini.'
                    : 'Tidak ada titipan dengan status "${_selectedFilter.label}".',
                icon: Icons.assignment_outlined,
                action: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.createErrand);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Buat Titipan Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(errandFeedNotifierProvider.notifier).loadErrands(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final errand = filtered[index];
          return FadeSlideEntry.staggered(
            key: ValueKey('req_${errand.id}_$index'),
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                children: [
                  ErrandCard(
                    errand: errand,
                    showAction: false,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.detail,
                        arguments: errand,
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildTrackingBanner(errand),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRunnerTasksTab(List<ErrandModel> allErrands, String currentUserName) {
    final runnerTasks = allErrands.where((item) {
      final req = item.requester.toLowerCase().trim();
      final user = currentUserName.toLowerCase().trim();
      return (req != user && !req.contains('naufal')) ||
          item.status == OrderStatus.accepted;
    }).toList();

    final filtered = _filterErrands(runnerTasks);

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(errandFeedNotifierProvider.notifier).loadErrands(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          children: [
            const SizedBox(height: 32),
            FadeSlideEntry(
              child: EmptyStateView(
                title: 'Belum Ada Tugas Belanja',
                message: _selectedFilter == StatusFilter.all
                    ? 'Anda belum mengambil tugas titipan sebagai Runner.'
                    : 'Tidak ada tugas dengan status "${_selectedFilter.label}".',
                icon: Icons.delivery_dining_outlined,
                action: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.dashboard);
                  },
                  icon: const Icon(Icons.explore_outlined, size: 18),
                  label: const Text('Cari Titipan Terdekat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(errandFeedNotifierProvider.notifier).loadErrands(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final errand = filtered[index];
          return FadeSlideEntry.staggered(
            key: ValueKey('task_${errand.id}_$index'),
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                children: [
                  ErrandCard(
                    errand: errand,
                    showAction: errand.status == OrderStatus.open,
                    onAccept: () {
                      ref
                          .read(errandFeedNotifierProvider.notifier)
                          .acceptErrand(errand.id);
                    },
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.detail,
                        arguments: errand,
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildTrackingBanner(errand),
                        _buildRunnerActionButton(errand),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final errandFeedAsync = ref.watch(errandFeedNotifierProvider);
    final currentUser = AuthService.instance.currentUser;
    final currentUserName = currentUser?.name ?? 'Muhammad Naufal Fahrel';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Manajemen Pesanan',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SizedBox(
                  height: 44,
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF64748B),
                    dividerColor: Colors.transparent,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    labelStyle: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.receipt_long_outlined, size: 16),
                        iconMargin: EdgeInsets.only(bottom: 2),
                        text: 'Permintaan Saya',
                      ),
                      Tab(
                        icon: Icon(Icons.two_wheeler_outlined, size: 16),
                        iconMargin: EdgeInsets.only(bottom: 2),
                        text: 'Tugas Belanja / Antar',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: ResponsiveContainer(
        maxWidth: 650,
        child: Column(
          children: [
            _buildStatusFilterChips(),
            Expanded(
              child: errandFeedAsync.when(
                loading: () => const LoadingStateView(
                  message: 'Memuat daftar pesanan titipan...',
                  color: Color(0xFF059669),
                ),
                error: (err, _) => ErrorStateView(
                  title: 'Gagal Memuat Pesanan',
                  message: err.toString(),
                  onRetry: () =>
                      ref.read(errandFeedNotifierProvider.notifier).loadErrands(),
                ),
                data: (errands) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMyRequestsTab(errands, currentUserName),
                      _buildRunnerTasksTab(errands, currentUserName),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
