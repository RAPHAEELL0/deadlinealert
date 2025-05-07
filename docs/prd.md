
## 📝 Product Requirement Document (PRD)

### 📌 Product Name

📍 Deadline Alert – Smart Web & Mobile Deadline Tracker

---

### 🧠 Overview

Deadline Alert adalah aplikasi lintas platform (web & mobile) berbasis Flutter, yang berfungsi sebagai pengelola dan pengingat deadline harian. Dengan penyimpanan berbasis cloud melalui Supabase, pengguna dapat mengakses dan menyinkronkan data dari berbagai perangkat tanpa login rumit.

---

### 🎯 Goals

* Memberikan solusi pengingat deadline yang ringan, cepat, dan intuitif.
* Menyediakan notifikasi berbasis waktu via Notification API.
* Mendukung akses lintas platform dengan integrasi cloud (Supabase).
* Menyederhanakan manajemen tugas dan deadline harian.

---

### 👥 Target User

* Pelajar dan mahasiswa untuk manajemen tugas, ujian, dan project.
* Freelancer dan pekerja mandiri dengan banyak deadline klien.
* Pengguna personal yang ingin mengelola waktu dan prioritas.

---

### 🎨 UI & Theme

* Warna dominan: Merah modern (dengan aksen abu dan putih)
* Mode default: Light mode (dark mode opsional)
* Desain: Minimalis, fokus pada kegunaan dan kecepatan akses
* Font utama: Inter / sans-serif
* Terinspirasi dari: Todoist + Linear UI

---

### 🧩 Key Features

#### 1. ➕ Tambah Deadline

* Field: Judul, deskripsi, tanggal & waktu deadline, kategori (opsional), prioritas
* Validasi input waktu
* Opsi pengingat (reminder) aktif/nonaktif

#### 2. 🗂 Tampilan Daftar Deadline

* Pengelompokan otomatis:

  * Hari Ini
  * 7 Hari ke Depan
  * Telat (Overdue)
* Filter berdasarkan kategori & pencarian
* Penanda status: ✅ Selesai / ❌ Belum

#### 3. 🔔 Reminder & Notifikasi

* Notifikasi berbasis waktu via Notification API
* Reminder muncul 5, 15, atau 30 menit sebelum deadline (pilihan pengguna)
* Meminta izin notifikasi saat pertama kali aplikasi dibuka

#### 4. ✅ Manajemen Deadline

* Aksi: Edit / Hapus / Tandai selesai
* Snooze: Tunda +1 jam atau +1 hari
* Status otomatis: overdue / done / upcoming

#### 5. 📅 Kalender (Opsional)

* Tampilan kalender bulanan dengan highlight deadline
* Klik tanggal untuk melihat daftar deadline pada hari tersebut

#### 6. ☁ Export/Import Data

* Ekspor data ke JSON
* Impor file JSON untuk restore atau migrasi

---

### 🔐 Autentikasi

* Opsional login menggunakan Supabase Auth (Email/password atau magic link)
* Atau mode tamu dengan local session (dengan sync manual ke akun saat login)

---

### 🛠 Tech Stack

* Frontend: Flutter (support Android, iOS, dan Web)
* Backend & Database: Supabase (PostgreSQL, Realtime, Auth)
* Notifikasi: Notification API (web), Flutter Local Notifications (mobile)

---
