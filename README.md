# Umay Umcha - Sistem Manajemen Inventaris

![Logo Aplikasi](assets/images/logo.png)

## Ikhtisar

Umay Umcha adalah aplikasi manajemen inventaris komprehensif yang dibuat dengan Flutter dan didukung oleh Supabase. Aplikasi ini dirancang untuk membantu bisnis mengelola stok, melacak transaksi, dan menghasilkan laporan dengan mudah.

## Fitur Utama

*   **Autentikasi Pengguna:** Sistem masuk, mendaftar, dan manajemen pengguna yang aman.
*   **Manajemen Produk:** Menambah, mengubah, dan menghapus produk.
*   **Manajemen Cabang:** Mengelola beberapa cabang atau lokasi.
*   **Manajemen Stok:** Melacak kuantitas produk di setiap cabang.
*   **Catatan Pengiriman (Delivery Notes):** Membuat dan mengelola catatan pengiriman untuk transfer antar cabang.
*   **Catatan Pengiriman Masuk (Incoming Delivery Notes):** Melacak pengiriman masuk dari vendor.
*   **Manajemen Barang Habis Pakai (Consumables):** Mengelola item yang tidak dijual tetapi digunakan dalam operasi sehari-hari.
*   **Pencatatan Transaksi:** Mencatat semua transaksi inventaris dan barang habis pakai.
*   **Pembuatan Laporan:** Menghasilkan laporan dalam format PDF dan Excel untuk catatan pengiriman, catatan pengiriman masuk, dan laporan gabungan.
*   **Peringatan Stok Rendah:** Dapatkan pemberitahuan untuk produk dan barang habis pakai yang hampir habis.

## Alur Aplikasi

1.  **Autentikasi:** Pengguna masuk ke aplikasi menggunakan email dan kata sandi mereka. Pengguna baru dapat mendaftar untuk sebuah akun.
2.  **Dasbor:** Setelah masuk, pengguna akan disambut oleh dasbor yang menampilkan ringkasan informasi penting.
3.  **Manajemen Inventaris:**
    *   Pengguna dapat melihat daftar produk dan kuantitasnya di setiap cabang.
    *   Pengguna dapat menambahkan produk baru, termasuk nama, deskripsi, dan vendornya.
    *   Pengguna dapat memperbarui detail produk yang ada.
4.  **Transaksi:**
    *   **Catatan Pengiriman:** Untuk mentransfer produk antar cabang, pengguna membuat catatan pengiriman, menentukan produk dan kuantitas yang akan ditransfer.
    *   **Catatan Pengiriman Masuk:** Saat menerima stok dari vendor, pengguna membuat catatan pengiriman masuk.
    *   **Barang Habis Pakai:** Pengguna dapat mencatat penggunaan barang habis pakai.
5.  **Pelaporan:**
    *   Aplikasi ini dapat menghasilkan laporan terperinci untuk catatan pengiriman, catatan pengiriman masuk, dan laporan gabungan.
    *   Laporan dapat diekspor ke format PDF dan Excel untuk memudahkan berbagi dan analisis.
6.  **Manajemen Pengguna:** Admin dapat mengelola pengguna, termasuk menambahkan pengguna baru dan menetapkan peran.

## Memulai

### Prasyarat

*   Flutter SDK
*   Akun Supabase

### Instalasi

1.  **Kloning repositori:**
    ```bash
    git clone https://github.com/username/umayumcha.git
    ```
2.  **Buka direktori proyek:**
    ```bash
    cd umayumcha
    ```
3.  **Instal dependensi:**
    ```bash
    flutter pub get
    ```
4.  **Konfigurasi Supabase:**
    *   Buat file `lib/utils/app_constants.dart` dari `lib/utils/app_constants.dart.example` (jika ada).
    *   Isi kredensial Supabase Anda (URL dan Kunci Anon) di `lib/utils/app_constants.dart`.
5.  **Jalankan aplikasi:**
    ```bash
    flutter run
    ```

## Teknologi yang Digunakan

*   **Framework:** Flutter
*   **Backend:** Supabase (Auth, Database, Functions)
*   **Manajemen State:** GetX
*   **Database:** PostgreSQL
*   **Pembuatan PDF:** `pdf`
*   **Pembuatan Excel:** `excel`

## Skema Database

Aplikasi ini menggunakan beberapa tabel di Supabase untuk menyimpan data, termasuk:

*   `products`
*   `branches`
*   `branch_products`
*   `delivery_notes`
*   `delivery_note_items`
*   `incoming_delivery_notes`
*   `incoming_delivery_note_items`
*   `consumables`
*   `consumable_transactions`
*   `profiles`

Lihat file `.sql` di direktori root untuk detail lebih lanjut tentang skema dan fungsi database.

## Berkontribusi

Kontribusi untuk proyek ini sangat diharapkan. Silakan fork repositori, buat branch baru untuk pekerjaan Anda, dan ajukan pull request.