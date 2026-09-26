import '../models/errand_model.dart';

class MockDataService {
  MockDataService._();

  static List<ErrandModel> getInitialErrands() {
    return [
      const ErrandModel(
        id: 'err_001',
        item: 'Ayam Geprek Sambal Matah + Es Teh',
        pickup: 'Kantin Pusat / Gazebo Barat',
        dropoff: 'Gedung C - Lab Rekayasa Perangkat Lunak',
        tip: 5000,
        requester: 'Farhan Dwi',
        status: OrderStatus.open,
        distanceKm: 0.4,
        category: 'Makanan',
      ),
      const ErrandModel(
        id: 'err_002',
        item: 'Cetak Laporan Praktikum & Jilid Mika Biru',
        pickup: 'Koperasi Mahasiswa / Percetakan ATK',
        dropoff: 'Ruang Dosen Gedung B Lt. 3',
        tip: 7500,
        requester: 'Nadia Az-Zahra',
        status: OrderStatus.open,
        distanceKm: 0.8,
        category: 'Dokumen',
      ),
      const ErrandModel(
        id: 'err_003',
        item: 'Caramel Macchiato Dingin Less Sugar',
        pickup: 'Kafe Perpustakaan Utama',
        dropoff: 'Coworking Space Gedung Belajar Bersama',
        tip: 4000,
        requester: 'Kevin Pratama',
        status: OrderStatus.accepted,
        distanceKm: 0.3,
        category: 'Minuman',
      ),
      const ErrandModel(
        id: 'err_004',
        item: 'Ambil Paket Buku di Pos Pengamanan Kampus',
        pickup: 'Pos Satpam Gerbang Utama',
        dropoff: 'Asrama Mahasiswa Asri Blok B',
        tip: 10000,
        requester: 'Rizky Ramadhan',
        status: OrderStatus.open,
        distanceKm: 1.2,
        category: 'Logistik',
      ),
      const ErrandModel(
        id: 'err_005',
        item: 'Kabel Converter HDMI to Type-C & Pointer',
        pickup: 'Lab Jaringan & Sistem Terdistribusi',
        dropoff: 'Auditorium Utama Lantai 2',
        tip: 6000,
        requester: 'Siti Sarah',
        status: OrderStatus.completed,
        distanceKm: 0.5,
        category: 'Elektronik',
      ),
    ];
  }

  static List<ErrandModel> get initialErrands => getInitialErrands();
}
