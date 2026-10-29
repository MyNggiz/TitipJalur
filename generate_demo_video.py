import os
import subprocess
from PIL import Image, ImageDraw, ImageFont, ImageFilter

FONT_DIR = "/home/mynggiz/development/flutter/bin/cache/artifacts/material_fonts"
ROBOTO_BOLD = f"{FONT_DIR}/Roboto-Bold.ttf"
ROBOTO_REGULAR = f"{FONT_DIR}/Roboto-Regular.ttf"
ROBOTO_MEDIUM = f"{FONT_DIR}/Roboto-Medium.ttf"

def get_font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except:
        return ImageFont.load_default()

font_title_brand = get_font(ROBOTO_BOLD, 22)
font_step_badge = get_font(ROBOTO_BOLD, 15)
font_scene_title = get_font(ROBOTO_BOLD, 36)
font_section_header = get_font(ROBOTO_BOLD, 20)
font_body = get_font(ROBOTO_REGULAR, 18)
font_body_bold = get_font(ROBOTO_BOLD, 18)
font_tag = get_font(ROBOTO_BOLD, 14)
font_status = get_font(ROBOTO_BOLD, 16)

SCENES = [
    {
        "step": "TAHAP 01 / 11 • AUTENTIKASI MAHASISWA",
        "title": "Layar Masuk & Mode Tamu Kampus",
        "screenshot": "P7/screenshots/00_p7_login_screen.png",
        "bullets": [
            "Autentikasi terintegrasi sesi lokal permanen SharedPreferences.",
            "Tersedia tombol cepat 'Masuk sebagai Tamu Kampus (Demo)'.",
            "Validasi format email kampus dan keamanan kata sandi.",
            "Sesi pengguna tetap tersimpan saat aplikasi ditutup/reboot."
        ],
        "tags": ["AuthService", "SharedPreferences", "Single Sign-On", "Session Restore"],
        "status": "STATUS: TERVERIFIKASI (UNIT TEST PASSED)"
    },
    {
        "step": "TAHAP 02 / 11 • BERANDA & PANDUAN PENGGUNA",
        "title": "Homepage & Statistik Komuter",
        "screenshot": "P7/screenshots/00_p7_homepage_screen.png",
        "bullets": [
            "Ringkasan ekosistem kampus: 128 Komuter Aktif, 420+ Titipan.",
            "Panduan interaktif 3 langkah kerja platform TitipJalur.",
            "Pintasan aksi cepat: Buat Titipan Baru & Eksplorasi Rute.",
            "Floating Interactive Bottom Navigation 4 tab dengan animasi halus."
        ],
        "tags": ["StateNotifier", "Tutorial Step Guide", "Live Ecosystem", "Responsive UI"],
        "status": "STATUS: TERVERIFIKASI (UNIT TEST PASSED)"
    },
    {
        "step": "TAHAP 03 / 11 • DISCOVERY & RADIUS HIPERLOKAL",
        "title": "Feed Titipan & Slider Radius Komuter",
        "screenshot": "P7/screenshots/05_p7_commuter_feed_active.png",
        "bullets": [
            "Runner dapat mengatur radius jangkauan jalan (0.5 km s/d 5.0 km).",
            "Filter chip kategori interaktif: Kantin, ATK, Kafe, Belanja, Obat.",
            "Kartu titipan menyajikan rute penjemputan, tujuan, dan tip Rupiah.",
            "Daftar diperbarui secara reaktif menggunakan Riverpod stream."
        ],
        "tags": ["Radius Filtering", "Haversine Distance", "Category Chips", "Riverpod 2.6"],
        "status": "STATUS: TERVERIFIKASI (UNIT TEST PASSED)"
    },
    {
        "step": "TAHAP 04 / 11 • PEMBUATAN TITIPAN & SENSOR GPS",
        "title": "Form Buat Titipan dengan Deteksi GPS",
        "screenshot": "P7/screenshots/02_p7_gps_location_create.png",
        "bullets": [
            "Penyematan koordinat lokasi riil GPS perangkat via Geolocator.",
            "Penanganan izin GPS otomatis: denied, disabled, & permanently denied.",
            "Shortcut nominal tip imbalan ramah mahasiswa: +2rb, +5rb, +10rb.",
            "Perlindungan Anti-Double Tap: tombol submit disabled saat memproses."
        ],
        "tags": ["Geolocator", "GPS Coordinates", "Hardware Permission", "Anti-Double Tap"],
        "status": "STATUS: TERVERIFIKASI (UNIT TEST PASSED)"
    },
    {
        "step": "TAHAP 05 / 11 • VALIDASI ATURAN BISNIS",
        "title": "Validasi Formulir & Penanganan Error",
        "screenshot": "P4/screenshots/05_form_input_validation.png",
        "bullets": [
            "Validasi minimal karakter: Nama item >= 3, Pickup >= 3, Dropoff >= 3.",
            "Validasi minimal nominal tip imbalan Runner >= Rp 2.000.",
            "Banner error informatif muncul seketika jika input tidak valid.",
            "Mencegah 'input merusak alur' sesuai standar rubrik Dr. Haryono."
        ],
        "tags": ["Form Validation", "Business Rules", "Zero Crash", "Error Feedback"],
        "status": "STATUS: TERVERIFIKASI (UNIT TEST PASSED)"
    },
    {
        "step": "TAHAP 06 / 11 • RINCIAN PESANAN & KLAIM RUNNER",
        "title": "Detail Titipan & Aksi Klaim Runner",
        "screenshot": "P5/screenshots/04_fitur2_detail_runner_claim.png",
        "bullets": [
            "Timeline status pesanan 3 tahap: Terbuka -> Diambil -> Selesai.",
            "Rincian lengkap komoditas, titik ambil, kontak, dan nominal tip.",
            "Runner menekan 'Bantu Teman (Ambil Titipan Ini)' untuk mengunci order.",
            "Status otomatis berpindah ke 'Accepted' di seluruh perangkat."
        ],
        "tags": ["DetailScreen", "State Machine", "Runner Claim", "Status Transition"],
        "status": "STATUS: TERVERIFIKASI (UNIT TEST PASSED)"
    },
    {
        "step": "TAHAP 07 / 11 • MANAJEMEN TUGAS BELANJA RUNNER",
        "title": "Tab Runner & Tombol Selesaikan Tugas",
        "screenshot": "P5/screenshots/05_fitur2_runner_tasks_complete.png",
        "bullets": [
            "Tab khusus memisahkan pesanan yang sedang diantar oleh Runner.",
            "Indikator tracking estimasi waktu tiba berdasarkan jarak tempuh.",
            "Tombol hijau 'Selesaikan Tugas' memicu alur verifikasi fisik.",
            "Menjamin alur dua-sisi (two-sided marketplace) berjalan tuntas."
        ],
        "tags": ["ErrandOrdersPage", "Runner Tasks", "Delivery Tracking", "Two-Sided Flow"],
        "status": "STATUS: TERVERIFIKASI (UNIT TEST PASSED)"
    },
    {
        "step": "TAHAP 08 / 11 • BUKTI SERAH TERIMA & KAMERA PERANGKAT",
        "title": "Kamera Proof of Delivery (POD) Dialog",
        "screenshot": "P7/screenshots/03_p7_pod_camera_dialog.png",
        "bullets": [
            "Integrasi kamera native perangkat via ImagePicker & PodCameraService.",
            "Runner memotret fisik barang yang telah sampai di titik serah terima.",
            "Opsi unggah foto dari galeri sebagai alternatif cadangan.",
            "Kompresi gambar otomatis lokal menjaga ukuran file tetap hemat kuota."
        ],
        "tags": ["ImagePicker", "Camera Native", "POD Verification", "Image Compression"],
        "status": "STATUS: TERVERIFIKASI (UNIT TEST PASSED)"
    },
    {
        "step": "TAHAP 09 / 11 • ORDER SELESAI & LENCANA VERIFIKASI",
        "title": "Pesanan Selesai Terverifikasi POD",
        "screenshot": "P7/screenshots/04_p7_pod_verified_detail.png",
        "bullets": [
            "Lencana hijau 'Bukti Serah Terima - Terverifikasi oleh Kamera'.",
            "Mencegah kecurangan serah-terima barang antara mahasiswa.",
            "Pemicu otomatis notifikasi sistem lokal: 'Titipan Berhasil Selesai!'.",
            "Status order berpindah ke tahap terminal 'Completed' secara persisten."
        ],
        "tags": ["Verified Badge", "Fraud Protection", "Local Notification", "Completed State"],
        "status": "STATUS: TERVERIFIKASI (UNIT TEST PASSED)"
    },
    {
        "step": "TAHAP 10 / 11 • KENDALI PEMOHON & PEMBATALAN",
        "title": "Tab Permintaan Saya & Batalkan Titipan",
        "screenshot": "P7/screenshots/06_p7_requester_orders_tab.png",
        "bullets": [
            "Pemohon dapat memantau seluruh status riwayat pesanan yang dibuat.",
            "Tombol 'Batalkan Titipan Ini' tersedia untuk pesanan berstatus Terbuka.",
            "Dialog konfirmasi mencegah salah tekan atau pembatalan tak sengaja.",
            "Data pesanan terhapus secara atomik dari penyimpanan lokal disk."
        ],
        "tags": ["User Control", "Delete (CRUD)", "Confirmation Dialog", "Storage Sync"],
        "status": "STATUS: TERVERIFIKASI (UNIT TEST PASSED)"
    },
    {
        "step": "TAHAP 11 / 11 • MULTI-SIDED ROLE SWITCHER & AKUN",
        "title": "Halaman Akun & Peralihan Peran Instan",
        "screenshot": "P7/screenshots/01_p7_auth_role_switcher.png",
        "bullets": [
            "Mahasiswa dapat beralih peran instan: Mode Pemohon <-> Mode Komuter.",
            "Hak akses aksi disesuaikan dinamis sesuai peran aktif (Role Gating).",
            "Dompet komuter kampus mencatat total kompensasi tip yang terkumpul.",
            "Tombol Logout aman dengan dialog konfirmasi dan pembersihan sesi."
        ],
        "tags": ["Role Switcher", "Multi-Sided Persona", "Commuter Wallet", "Profile Management"],
        "status": "STATUS: TERVERIFIKASI (112/112 TESTS PASSED)"
    }
]

def create_rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask

def generate_scene_frame(scene, output_path):
    width, height = 1920, 1080
    bg = Image.new("RGB", (width, height), (11, 18, 30))
    draw = ImageDraw.Draw(bg)

    # Gradient background
    for y in range(height):
        ratio = y / height
        r = int(11 * (1 - ratio) + 6 * ratio)
        g = int(22 * (1 - ratio) + 45 * ratio)
        b = int(34 * (1 - ratio) + 30 * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))

    # Decorative header bar
    draw.rectangle([(0, 0), (width, 68)], fill=(15, 23, 42))
    draw.line([(0, 68), (width, 68)], fill=(30, 41, 59), width=2)
    draw.ellipse([(60, 26), (74, 40)], fill=(16, 185, 129))
    draw.text((86, 21), "TITIPJALUR", font=font_title_brand, fill=(255, 255, 255))
    draw.text((220, 23), "•  P2P Micro-Errand & Commuter Delivery Platform", font=font_body, fill=(148, 163, 184))
    
    # Right header info
    right_text = "MVP VERSION 1 • SHOWCASE RESMI PERTEMUAN 07"
    draw.text((1420, 23), right_text, font=font_step_badge, fill=(52, 211, 153))

    # Left Column: Information Panel (Width: 980)
    left_x = 64
    y = 110

    # Step Pill Badge
    step_text = scene["step"]
    draw.rounded_rectangle([(left_x, y), (left_x + 360, y + 34)], radius=8, fill=(6, 78, 59), outline=(16, 185, 129))
    draw.text((left_x + 16, y + 7), step_text, font=font_step_badge, fill=(110, 231, 183))
    y += 52

    # Scene Title
    draw.text((left_x, y), scene["title"], font=font_scene_title, fill=(255, 255, 255))
    y += 62

    # Divider
    draw.line([(left_x, y), (left_x + 920, y)], fill=(30, 41, 59), width=2)
    y += 24

    # Section: Penjelasan Fungsional & Rekayasa
    draw.text((left_x, y), "ALUR KERJA & INTEGRASI TEKNIS", font=font_section_header, fill=(52, 211, 153))
    y += 36

    for b in scene["bullets"]:
        # Bullet dot
        draw.ellipse([(left_x + 4, y + 8), (left_x + 14, y + 18)], fill=(16, 185, 129))
        draw.text((left_x + 28, y + 4), b, font=font_body, fill=(226, 232, 240))
        y += 42

    y += 20
    # Tags / Technical Architecture Pills
    draw.text((left_x, y), "KOMPONEN ARSITEKTUR & SENSOR", font=font_section_header, fill=(148, 163, 184))
    y += 36

    tag_x = left_x
    for tag in scene["tags"]:
        tag_w = len(tag) * 9 + 28
        draw.rounded_rectangle([(tag_x, y), (tag_x + tag_w, y + 32)], radius=6, fill=(30, 41, 59), outline=(51, 65, 85))
        draw.text((tag_x + 14, y + 7), tag, font=font_tag, fill=(167, 243, 208))
        tag_x += tag_w + 14

    y += 64
    # Status Banner Box
    draw.rounded_rectangle([(left_x, y), (left_x + 920, y + 64)], radius=12, fill=(6, 95, 70), outline=(52, 211, 153), width=2)
    draw.ellipse([(left_x + 24, y + 24), (left_x + 40, y + 40)], fill=(16, 185, 129))
    draw.text((left_x + 54, y + 22), scene["status"], font=font_status, fill=(255, 255, 255))
    draw.text((left_x + 640, y + 23), "112 / 112 TESTS PASSED", font=font_tag, fill=(167, 243, 208))

    # Footer Notes
    draw.text((left_x, 1020), "Pemrograman Mobile (Era AI Agent) • Dr. Haryono • Repositori: MyNggiz/TitipJalur", font=font_tag, fill=(100, 116, 139))

    # Right Column: Phone Mockup Frame (X: 1220 to 1800, Y: 90 to 1030)
    phone_x = 1260
    phone_y = 90
    phone_h = 940
    # Screenshot aspect ratio is 1080x2400 (ratio: 0.45)
    phone_w = int(phone_h * (1080 / 2400))  # approx 423 px

    # Phone outer shadow and chassis
    chassis_pad = 12
    outer_box = [
        phone_x - chassis_pad,
        phone_y - chassis_pad,
        phone_x + phone_w + chassis_pad,
        phone_y + phone_h + chassis_pad
    ]
    draw.rounded_rectangle(outer_box, radius=36, fill=(15, 23, 42), outline=(52, 211, 153), width=3)

    # Load and place screenshot
    shot_path = scene["screenshot"]
    if os.path.exists(shot_path):
        shot_img = Image.open(shot_path).convert("RGBA")
        shot_resized = shot_img.resize((phone_w, phone_h), Image.Resampling.LANCZOS)
        
        # Round the screenshot corners
        corner_radius = 26
        mask = create_rounded_mask((phone_w, phone_h), corner_radius)
        bg.paste(shot_resized, (phone_x, phone_y), mask)

    bg.save(output_path, "PNG")

print("Rendering scene frames for video...")
os.makedirs("temp_video_frames", exist_ok=True)
for i, scene in enumerate(SCENES):
    frame_path = f"temp_video_frames/frame_{i:02d}.png"
    generate_scene_frame(scene, frame_path)
    print(f"Rendered frame {i+1}/{len(SCENES)}: {frame_path}")

print("Frames rendered successfully!")
