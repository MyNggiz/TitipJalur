# Pertemuan 10 — Release Candidate

## Logging runtime

`lib/services/runtime_log.dart` mencatat event startup dan error Flutter/platform dengan nama logger `titip_jalur.runtime` melalui `dart:developer`. Payload hanya berisi nama event; pesan exception, stack trace, dan input pengguna tidak disertakan. `lib/main.dart` mempertahankan handler error sebelumnya dan meneruskan exception startup.

Log ini belum membuktikan pelacakan masalah pada APK Android: ketersediaannya di perangkat release dan mekanisme pengumpulan log masih perlu diuji. Event yang tersedia mengidentifikasi jenis kejadian, bukan penyebab spesifik kegagalan.

## APK release

APK mode release tersedia di [`P10/app-release.apk`](app-release.apk) (salinan dari `build/app/outputs/flutter-apk/app-release.apk`; 53.057.816 byte), package `io.github.mynggiz.titip_jalur`, versi `1.0.0+1`, minSdk 24, targetSdk 36. SHA-256: `4e06a94cc26527685abd89517814521a5a2c2fedeb21c4f5148d8d4a86d35f00`.

**Batasan:** APK ini ditandatangani dengan sertifikat `Android Debug` dari template Flutter, hanya untuk pengujian lokal. Bukan kunci distribusi Play Store. `adb devices -l` tidak menemukan perangkat, sehingga instalasi dan fungsi sensor fisik belum diuji. Publikasi Play Store tidak dilakukan.

## Verifikasi

- `flutter analyze lib/main.dart lib/services/runtime_log.dart`: No issues found.
- `flutter test test/unit/p9_profile_test_and_refactor_test.dart`: 13 tes lulus.
- `flutter build apk --release --no-pub`: berhasil menghasilkan APK; `apksigner verify` berhasil dan menunjukkan sertifikat debug.
- Tidak ada perangkat Android terdeteksi untuk pengujian instalasi.

## Issues

Issue dicatat di [GitHub Issues TitipJalur](https://github.com/MyNggiz/TitipJalur/issues), meliputi dugaan bug berdasarkan inspeksi kode dan usulan fitur. Status reproduksi masing-masing dijelaskan pada issue; inspeksi statis tidak disamakan dengan pengujian pada perangkat.
