import 'package:flutter/material.dart';
import '../models/errand_model.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/mock_data_service.dart';
import '../widgets/errand_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/state_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late List<ErrandModel> _errands;
  double _radiusKm = 3.0;
  String _selectedCategory = 'Semua';

  final List<String> _categories = const [
    'Semua',
    'Kantin',
    'ATK',
    'Kafe',
  ];

  @override
  void initState() {
    super.initState();
    _errands = List<ErrandModel>.from(MockDataService.getInitialErrands());
  }

  bool _matchesCategory(ErrandModel errand, String category) {
    if (category == 'Semua') return true;
    final catLower = errand.category.toLowerCase();
    final itemLower = errand.item.toLowerCase();
    final pickupLower = errand.pickup.toLowerCase();

    if (category == 'Kantin') {
      return catLower.contains('makan') ||
          pickupLower.contains('kantin') ||
          itemLower.contains('ayam') ||
          catLower.contains('kantin');
    }
    if (category == 'ATK') {
      return catLower.contains('dokumen') ||
          catLower.contains('atk') ||
          pickupLower.contains('atk') ||
          pickupLower.contains('koperasi') ||
          itemLower.contains('laporan');
    }
    if (category == 'Kafe') {
      return catLower.contains('minuman') ||
          catLower.contains('kafe') ||
          pickupLower.contains('kafe') ||
          itemLower.contains('macchiato');
    }
    return catLower.contains(category.toLowerCase());
  }

  List<ErrandModel> get _filteredErrands {
    return _errands.where((errand) {
      final inRadius = errand.distanceKm <= _radiusKm;
      final inCategory = _matchesCategory(errand, _selectedCategory);
      return inRadius && inCategory;
    }).toList();
  }

  void _handleAcceptErrand(ErrandModel errand) {
    setState(() {
      final index = _errands.indexWhere((e) => e.id == errand.id);
      if (index != -1) {
        _errands[index] = _errands[index].copyWith(status: OrderStatus.accepted);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCreateErrandDialog() {
    final itemCtrl = TextEditingController();
    final pickupCtrl = TextEditingController();
    final dropoffCtrl = TextEditingController();
    final tipCtrl = TextEditingController(text: '5000');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add_shopping_cart_rounded,
                          color: Color(0xFF059669),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Buat Titipan Baru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: itemCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Barang / Makanan',
                      hintText: 'Contoh: Es Kopi Susu Gedung A',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: pickupCtrl,
                    decoration: InputDecoration(
                      labelText: 'Lokasi Pengambilan (Pickup)',
                      hintText: 'Contoh: Kantin Barat',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: dropoffCtrl,
                    decoration: InputDecoration(
                      labelText: 'Lokasi Pengantaran (Dropoff)',
                      hintText: 'Contoh: Lab Komputer Lt. 2',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: tipCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Nominal Tip Imbalan (Rp)',
                      hintText: '5000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (v) => (v == null || int.tryParse(v) == null) ? 'Nominal tidak valid' : null,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Terbitkan Titipan',
                    icon: Icons.send_rounded,
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final newErrand = ErrandModel(
                          id: 'err_${DateTime.now().millisecondsSinceEpoch}',
                          item: itemCtrl.text.trim(),
                          pickup: pickupCtrl.text.trim(),
                          dropoff: dropoffCtrl.text.trim(),
                          tip: int.parse(tipCtrl.text.trim()),
                          requester: AuthService.instance.currentUser?.name ?? 'Mahasiswa',
                          status: OrderStatus.open,
                          distanceKm: 0.6,
                          category: 'Makanan',
                        );
                        setState(() {
                          _errands.insert(0, newErrand);
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Titipan baru berhasil diterbitkan!'),
                            backgroundColor: Color(0xFF059669),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService.instance.currentUser;
    final userName = user?.name ?? 'Mahasiswa';
    final filtered = _filteredErrands;

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
                Text(
                  'Halo, $userName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radius slider label & slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.radar_rounded,
                          size: 18,
                          color: Color(0xFF059669),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Radius Pengantaran: ${_radiusKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
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
                    overlayColor: const Color(0xFF059669).withValues(alpha: 0.14),
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

                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(cat),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                          backgroundColor: const Color(0xFFF1F5F9),
                          selectedColor: const Color(0xFF059669),
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF059669) : Colors.transparent,
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

          // Errand List Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Titipan Tersedia (${filtered.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
                Text(
                  'P2P Kampus',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          // Errand List View or Empty State
          Expanded(
            child: filtered.isEmpty
                ? EmptyStateView(
                    title: 'Tidak Ada Titipan Ditemukan',
                    message:
                        'Tidak ada permintaan titipan pada radius ${_radiusKm.toStringAsFixed(1)} km dengan kategori "$_selectedCategory". Cobalah memperluas radius atau ubah kategori.',
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
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 84),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final errand = filtered[index];
                      return ErrandCard(
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
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateErrandDialog,
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Buat Titipan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
