import 'package:flutter/material.dart';

void main() {
  runApp(const TitipJalurApp());
}

class TitipJalurApp extends StatelessWidget {
  const TitipJalurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TitipJalur',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          primary: const Color(0xFF0F766E),
        ),
        useMaterial3: true,
      ),
      home: const ErrandFeedScreen(),
    );
  }
}

enum OrderStatus { open, accepted, completed }

class ErrandOrder {
  final String id;
  final String item;
  final String pickup;
  final String dropoff;
  final int tip;
  final String requester;
  OrderStatus status;

  ErrandOrder({
    required this.id,
    required this.item,
    required this.pickup,
    required this.dropoff,
    required this.tip,
    required this.requester,
    this.status = OrderStatus.open,
  });
}

class AiErrandParser {
  static Map<String, dynamic> parse(String text) {
    final lower = text.toLowerCase();
    String item = 'Titipan Barang';
    String pickup = 'Lokasi Jemput';
    String dropoff = 'Lokasi Antar';
    int tip = 5000;

    final tipMatch = RegExp(r'(\d+)\s*(k|rb|ribu)?').firstMatch(lower);
    if (tipMatch != null) {
      final rawNum = int.tryParse(tipMatch.group(1) ?? '5') ?? 5;
      tip = rawNum < 100 ? rawNum * 1000 : rawNum;
    }

    if (lower.contains('kopi')) item = 'Kopi Susu Dingin';
    if (lower.contains('geprek')) item = 'Ayam Geprek Sambal Bawang';
    if (lower.contains('print') || lower.contains('fotokopi')) item = 'Dokumen Fotokopi / Print';

    if (lower.contains('kantin')) pickup = 'Kantin Kampus';
    if (lower.contains('minimarket') || lower.contains('indomaret')) pickup = 'Minimarket Depan';

    if (lower.contains('gedung')) dropoff = 'Gedung Kuliah';
    if (lower.contains('kos') || lower.contains('kost')) dropoff = 'Kosan Mahasiswa';

    return {
      'item': item,
      'pickup': pickup,
      'dropoff': dropoff,
      'tip': tip,
    };
  }
}

class ErrandFeedScreen extends StatefulWidget {
  const ErrandFeedScreen({super.key});

  @override
  State<ErrandFeedScreen> createState() => _ErrandFeedScreenState();
}

class _ErrandFeedScreenState extends State<ErrandFeedScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  final List<ErrandOrder> _orders = [
    ErrandOrder(
      id: '1',
      item: 'Ayam Geprek Bu Siti (Level 3)',
      pickup: 'Kantin Pusat',
      dropoff: 'Lab Komputer 2 Lt. 3',
      tip: 6000,
      requester: 'Fahrel',
      status: OrderStatus.open,
    ),
    ErrandOrder(
      id: '2',
      item: 'Print Makalah 10 Lembar + Map',
      pickup: 'Fotokopi Gerbang Depan',
      dropoff: 'Gedung Dekanat Lt. 1',
      tip: 5000,
      requester: 'Dimas',
      status: OrderStatus.accepted,
    ),
  ];

  void _createOrder(String item, String pickup, String dropoff, int tip) {
    setState(() {
      _orders.insert(
        0,
        ErrandOrder(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          item: item,
          pickup: pickup,
          dropoff: dropoff,
          tip: tip,
          requester: 'Saya (Pemohon)',
          status: OrderStatus.open,
        ),
      );
    });
  }

  void _updateStatus(ErrandOrder order, OrderStatus newStatus) {
    setState(() {
      order.status = newStatus;
    });
  }

  void _showCreateOrderSheet() {
    final aiController = TextEditingController();
    final itemController = TextEditingController();
    final pickupController = TextEditingController();
    final dropoffController = TextEditingController();
    final tipController = TextEditingController(text: '5000');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Buat Titipan Baru',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: aiController,
                        decoration: const InputDecoration(
                          hintText: 'Prompt AI: "Titip geprek kantin antar ke Lab, tip 5rb"',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            if (aiController.text.trim().isNotEmpty) {
                              final result = AiErrandParser.parse(aiController.text);
                              itemController.text = result['item'];
                              pickupController.text = result['pickup'];
                              dropoffController.text = result['dropoff'];
                              tipController.text = result['tip'].toString();
                            }
                          },
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Ekstrak via AI'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: itemController,
                  decoration: const InputDecoration(labelText: 'Barang / Makanan', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pickupController,
                  decoration: const InputDecoration(labelText: 'Titik Beli / Jemput', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: dropoffController,
                  decoration: const InputDecoration(labelText: 'Tujuan Antar', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tipController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tawaran Tip (Rp)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      if (itemController.text.isNotEmpty && pickupController.text.isNotEmpty) {
                        _createOrder(
                          itemController.text,
                          pickupController.text,
                          dropoffController.text,
                          int.tryParse(tipController.text) ?? 5000,
                        );
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Publikasikan Titipan'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TitipJalur 🛵', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              Future.delayed(const Duration(milliseconds: 500), () {
                setState(() {
                  _isLoading = false;
                });
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('Belum ada titipan aktif di rute ini.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    order.item,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: order.status == OrderStatus.open
                                        ? Colors.green.shade100
                                        : (order.status == OrderStatus.accepted ? Colors.orange.shade100 : Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    order.status == OrderStatus.open
                                        ? 'TERBUKA'
                                        : (order.status == OrderStatus.accepted ? 'DIAMBIL' : 'SELESAI'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: order.status == OrderStatus.open
                                          ? Colors.green.shade800
                                          : (order.status == OrderStatus.accepted ? Colors.orange.shade800 : Colors.grey.shade700),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('📍 Dari: ${order.pickup}', style: const TextStyle(fontSize: 13)),
                            Text('🎯 Ke: ${order.dropoff}', style: const TextStyle(fontSize: 13)),
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tip: Rp ${order.tip}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F766E))),
                                if (order.status == OrderStatus.open)
                                  OutlinedButton(
                                    onPressed: () => _updateStatus(order, OrderStatus.accepted),
                                    child: const Text('Ambil Titipan'),
                                  )
                                else if (order.status == OrderStatus.accepted)
                                  FilledButton(
                                    onPressed: () => _updateStatus(order, OrderStatus.completed),
                                    child: const Text('Konfirmasi Selesai'),
                                  )
                                else
                                  const Text('✓ Berhasil diantar', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateOrderSheet,
        icon: const Icon(Icons.add),
        label: const Text('Titip Barang'),
      ),
    );
  }
}
// ponytail: single-file vertical slice MVP; split into features/data/domain/presentation when wiring Supabase.
