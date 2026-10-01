import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../widgets/primary_button.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  double _commuterRadius = 2.0;
  bool _offlineFirstMode = true;
  bool _nearbyNotifications = true;
  bool _autoRunnerMode = false;
  int _walletBalance = 82000;

  void _showWithdrawDialog() {
    String selectedEwallet = 'GoPay';
    final amountController = TextEditingController(text: '50000');
    final accountController = TextEditingController(text: '081234567890');

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF059669),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Tarik Saldo Tip',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Tersedia: Rp ${_walletBalance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih Metode Pencairan:',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['GoPay', 'OVO', 'ShopeePay', 'DANA', 'BCA']
                          .map((method) {
                        final isSelected = selectedEwallet == method;
                        return ChoiceChip(
                          label: Text(method),
                          selected: isSelected,
                          selectedColor: const Color(0xFF059669),
                          labelStyle: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                          ),
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() => selectedEwallet = method);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: accountController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Akun / Rekening',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nominal Penarikan (Rp)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final amount = int.tryParse(amountController.text) ?? 0;
                    if (amount > 0 && amount <= _walletBalance) {
                      setState(() => _walletBalance -= amount);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Pencairan Rp $amount ke $selectedEwallet berhasil diproses!',
                          ),
                          backgroundColor: const Color(0xFF059669),
                        ),
                      );
                    }
                  },
                  child: const Text('Tarik Sekarang'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi Keluar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari akun TitipJalur?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService.instance.currentUser;
    final userName = user?.name ?? 'Muhammad Naufal Fahrel';
    final userEmail = user?.email ?? 'mhs@kampus.ac.id';
    final userRole = user?.role ?? 'Mahasiswa Komuter';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'M';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          'Pengaturan Akun & Komuter',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Profil Mahasiswa
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF059669),
                    child: Text(
                      userInitial,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$userRole • Akun Terverifikasi',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Dompet Mahasiswa / Saldo Tip
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Dompet Komuter Kampus',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFA7F3D0),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'P2P Terjamin',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rp ${_walletBalance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF065F46),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _showWithdrawDialog,
                        icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                        label: const Text(
                          'Tarik Saldo',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Riwayat tip: 14 titipan berhasil diselesaikan.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history_rounded, size: 16),
                        label: const Text(
                          'Riwayat',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Preferensi Perjalanan & Aplikasi
            Text(
              'Preferensi Perjalanan & Layanan',
              style: theme.textTheme.titleSmall?.copyWith(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.radar_rounded, color: Color(0xFF059669)),
                    title: const Text(
                      'Radius Komuter Default',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${_commuterRadius.toStringAsFixed(1)} km dari posisi rute',
                      style: const TextStyle(fontFamily: 'Roboto', fontSize: 12),
                    ),
                    trailing: SizedBox(
                      width: 120,
                      child: Slider(
                        value: _commuterRadius,
                        min: 0.5,
                        max: 5.0,
                        divisions: 9,
                        activeColor: const Color(0xFF059669),
                        onChanged: (val) => setState(() => _commuterRadius = val),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    activeColor: const Color(0xFF059669),
                    secondary: const Icon(Icons.wifi_off_rounded, color: Color(0xFF059669)),
                    title: const Text(
                      'Mode Offline-First (Hemat Sinyal)',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Otomatis simpan antrean ke basis data lokal saat koneksi kampus terputus',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
                    ),
                    value: _offlineFirstMode,
                    onChanged: (val) => setState(() => _offlineFirstMode = val),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    activeColor: const Color(0xFF059669),
                    secondary: const Icon(Icons.notifications_active_outlined, color: Color(0xFF059669)),
                    title: const Text(
                      'Notifikasi Titipan Searah',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Kirim alarm lokal saat ada pesanan baru di kantin/titik yang Anda lewati',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
                    ),
                    value: _nearbyNotifications,
                    onChanged: (val) => setState(() => _nearbyNotifications = val),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    activeColor: const Color(0xFF059669),
                    secondary: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF059669)),
                    title: const Text(
                      'Status Runner Otomatis',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Tampilkan status aktif di rute perjalanan menuju kelas/gedung',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
                    ),
                    value: _autoRunnerMode,
                    onChanged: (val) => setState(() => _autoRunnerMode = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Informasi & Bantuan
            Text(
              'Informasi & Bantuan',
              style: theme.textTheme.titleSmall?.copyWith(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.menu_book_rounded, color: Color(0xFF64748B)),
                    title: const Text(
                      'Panduan Komuter & Etika Titip',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Etika Penitipan Kampus'),
                          content: const Text(
                            '1. Kompensasi tip minimal Rp 2.000 untuk menghargai rute teman.\n'
                            '2. Pastikan titik penjemputan dan pengantaran jelas.\n'
                            '3. Segera konfirmasi dan selesaikan pesanan setelah barang tiba.',
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B)),
                    title: const Text(
                      'Versi Aplikasi',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    trailing: const Text(
                      'v1.0.0-p4',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. Tombol Keluar Akun
            PrimaryButton(
              label: 'Keluar dari Akun',
              icon: Icons.logout_rounded,
              color: const Color(0xFFEF4444),
              isOutlined: true,
              onPressed: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }
}
