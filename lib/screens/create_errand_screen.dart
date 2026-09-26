import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/errand_feed_notifier.dart';
import '../controllers/errand_form_notifier.dart';
import '../repositories/errand_repository.dart';
import '../services/auth_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class CreateErrandScreen extends ConsumerStatefulWidget {
  const CreateErrandScreen({super.key});

  @override
  ConsumerState<CreateErrandScreen> createState() => _CreateErrandScreenState();
}

class _CreateErrandScreenState extends ConsumerState<CreateErrandScreen> {
  late final TextEditingController _itemController;
  late final TextEditingController _pickupController;
  late final TextEditingController _dropoffController;
  late final TextEditingController _tipController;

  bool _simulateSubmitError = false;

  final List<String> _categoryOptions = const [
    'Kantin',
    'ATK',
    'Kafe',
    'Belanja',
    'Obat',
  ];

  @override
  void initState() {
    super.initState();
    _itemController = TextEditingController();
    _pickupController = TextEditingController();
    _dropoffController = TextEditingController();
    _tipController = TextEditingController(text: '5000');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(errandFormNotifierProvider.notifier);
      notifier.reset();
      notifier.setTip(_tipController.text);
      notifier.setCategory('Kantin');
    });
  }

  @override
  void dispose() {
    _itemController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  void _addTipAmount(int amount) {
    final clean = _tipController.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final current = int.tryParse(clean) ?? 0;
    final updated = current + amount;
    _tipController.text = updated.toString();
    ref.read(errandFormNotifierProvider.notifier).setTip(updated.toString());
  }

  void _setExactTip(int amount) {
    _tipController.text = amount.toString();
    ref.read(errandFormNotifierProvider.notifier).setTip(amount.toString());
  }

  Future<void> _handleSubmit() async {
    final authUser = AuthService.instance.currentUser;
    final requesterName = authUser?.name.isNotEmpty == true
        ? authUser!.name
        : 'Mahasiswa Komuter';

    final repository = ref.read(errandRepositoryProvider);
    final formNotifier = ref.read(errandFormNotifierProvider.notifier);

    final success = await formNotifier.submit(
      repository,
      requesterName: requesterName,
      simulateError: _simulateSubmitError,
    );

    if (!mounted) return;

    if (success) {
      final createdErrand =
          ref.read(errandFormNotifierProvider).lastCreatedErrand;
      if (createdErrand != null) {
        ref.read(errandFeedNotifierProvider.notifier).addErrand(createdErrand);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Titipan "${_itemController.text.trim()}" berhasil dibuat!',
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
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(errandFormNotifierProvider);
    final formNotifier = ref.read(errandFormNotifierProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buat Titipan Baru',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Reset Form',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: formState.isSubmitting
                ? null
                : () {
                    _itemController.clear();
                    _pickupController.clear();
                    _dropoffController.clear();
                    _tipController.text = '5000';
                    formNotifier.reset();
                    formNotifier.setTip('5000');
                    formNotifier.setCategory('Kantin');
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Isi detail titipan Anda. Komuter di sekitar rute kampus akan menerima notifikasi dan membantu membawakannya.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category Selector
              const Text(
                'Kategori Titipan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categoryOptions.map((cat) {
                  final isSelected = formState.category == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: const Color(0xFF059669),
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF059669)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    onSelected: formState.isSubmitting
                        ? null
                        : (selected) {
                            if (selected) {
                              formNotifier.setCategory(cat);
                            }
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Item Field
              AppTextField(
                label: 'Nama Barang / Pesanan',
                hint: 'Minimal 3 karakter (misal: Nasi Padang Rendang)',
                controller: _itemController,
                prefixIcon: Icons.shopping_bag_outlined,
                errorText: formState.itemError,
                enabled: !formState.isSubmitting,
                onChanged: formNotifier.setItem,
              ),
              const SizedBox(height: 16),

              // Pickup Location
              AppTextField(
                label: 'Lokasi Pengambilan (Pickup)',
                hint: 'Minimal 3 karakter (misal: Kantin Utama FMIPA Lt. 1)',
                controller: _pickupController,
                prefixIcon: Icons.storefront_outlined,
                errorText: formState.pickupError,
                enabled: !formState.isSubmitting,
                onChanged: formNotifier.setPickup,
              ),
              const SizedBox(height: 16),

              // Dropoff Location
              AppTextField(
                label: 'Lokasi Tujuan Pengantaran (Dropoff)',
                hint: 'Minimal 3 karakter (misal: Lab Komputer Gedung B R.204)',
                controller: _dropoffController,
                prefixIcon: Icons.location_on_outlined,
                errorText: formState.dropoffError,
                enabled: !formState.isSubmitting,
                onChanged: formNotifier.setDropoff,
              ),
              const SizedBox(height: 16),

              // Tip Amount
              AppTextField(
                label: 'Nominal Tip Imbalan (Rupiah)',
                hint: 'Minimal 2000',
                controller: _tipController,
                prefixIcon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                errorText: formState.tipError,
                enabled: !formState.isSubmitting,
                onChanged: formNotifier.setTip,
              ),
              const SizedBox(height: 10),

              // Quick Tip Buttons
              Row(
                children: [
                  const Text(
                    'Tambah Cepat:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _QuickTipChip(
                            label: '+Rp 2.000',
                            onTap: formState.isSubmitting
                                ? null
                                : () => _addTipAmount(2000),
                          ),
                          const SizedBox(width: 6),
                          _QuickTipChip(
                            label: '+Rp 5.000',
                            onTap: formState.isSubmitting
                                ? null
                                : () => _addTipAmount(5000),
                          ),
                          const SizedBox(width: 6),
                          _QuickTipChip(
                            label: '+Rp 10.000',
                            onTap: formState.isSubmitting
                                ? null
                                : () => _addTipAmount(10000),
                          ),
                          const SizedBox(width: 6),
                          _QuickTipChip(
                            label: 'Rp 5.000',
                            isExact: true,
                            onTap: formState.isSubmitting
                                ? null
                                : () => _setExactTip(5000),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Demo Testing Controls (For P4 Lecturer Demo)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.science_outlined,
                      color: Color(0xFFD97706),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Simulasi Error Submit (Demo P4)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                    Switch(
                      value: _simulateSubmitError,
                      activeColor: const Color(0xFFD97706),
                      onChanged: formState.isSubmitting
                          ? null
                          : (val) {
                              setState(() {
                                _simulateSubmitError = val;
                              });
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Submit Error Banner
              if (formState.submitError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          formState.submitError!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Submit Button (Anti-Double Tap via isLoading / null onPressed)
              PrimaryButton(
                label: 'Kirim Permintaan Titipan',
                icon: Icons.send_rounded,
                isLoading: formState.isSubmitting,
                width: double.infinity,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 12),

              Center(
                child: Text(
                  formState.isSubmitting
                      ? 'Sedang memproses permintaan titipan...'
                      : 'Validasi otomatis aktif (Minimal 3 huruf & tip Rp 2.000)',
                  style: TextStyle(
                    fontSize: 12,
                    color: formState.isSubmitting
                        ? theme.colorScheme.primary
                        : const Color(0xFF94A3B8),
                    fontWeight: formState.isSubmitting
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTipChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isExact;

  const _QuickTipChip({
    required this.label,
    required this.onTap,
    this.isExact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isExact ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isExact ? const Color(0xFFBAE6FD) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isExact ? const Color(0xFF0284C7) : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
