# Analisis Transaksi E-Commerce Indonesia

Project UAS Statistika dan Probabilitas yang mengolah data transaksi e-commerce Indonesia dari awal sampai evaluasi model regresi. Seluruh proses analisis memakai R/RStudio dan tercatat dalam satu script, `R/analysis.R`.

Topik ini masuk bidang Ekonomi dan Bisnis. Fokusnya bukan memilih produk terlaris, melainkan mengukur seberapa besar kuantitas barang, diskon, dan ongkos kirim menjelaskan nilai total pembayaran.

## Hasil Utama

| Item | Nilai |
|---|---|
| Sumber data | Kaggle `zkyfauzi/indonesia-ecommerce-sales`, lisensi CC0 |
| Baris awal | 18.868 |
| Baris setelah cleaning | 18.585 |
| Variabel dependen (Y) | `total_pembayaran` |
| Variabel independen (X) | `total_qty`, `total_diskon`, `ongkos_kirim_dibayar_oleh_pembeli` |
| R² regresi sederhana | 0,0988 |
| R² regresi berganda | 0,2521 |
| Signifikan | `total_qty` dan ongkos kirim (p < 2e-16) |
| Tidak signifikan | `total_diskon` (p = 0,345) |

Dua uji asumsi tidak lolos: normalitas residual (Shapiro-Wilk p < 2,2e-16) dan homoskedastisitas (Breusch-Pagan p < 2,2e-16). Laporan menyatakan keduanya terbuka, bukan disembunyikan.

## Daftar Isi

- [Struktur Project](#struktur-project)
- [Kebutuhan Sistem](#kebutuhan-sistem)
- [Alur Pengerjaan](#alur-pengerjaan)
- [Cara Menjalankan Ulang](#cara-menjalankan-ulang)
- [Penjelasan Script](#penjelasan-script)
- [Daftar Output](#daftar-output)
- [Catatan Metodologi](#catatan-metodologi)
- [Pemecahan Masalah](#pemecahan-masalah)

## Struktur Project

```text
projek_uas/
├── README.md                         # Dokumentasi ini
├── R/
│   └── analysis.R                    # Seluruh pipeline analisis
├── data/
│   ├── raw/
│   │   ├── ec_indonesia.csv          # Dataset asli hasil unduhan Kaggle
│   │   └── kaggle_ec.zip             # Arsip unduhan asli
│   ├── processed/
│   │   └── ec_indonesia_clean.csv    # Dataset setelah cleaning
│   ├── plots/                        # Cadangan plot (kosong pada rilis ini)
│   └── tables/                       # Cadangan tabel (kosong pada rilis ini)
├── output/
│   ├── analisis_log.txt              # Log lengkap eksekusi R
│   ├── tables/
│   │   ├── provenance.txt            # Bukti sumber dan lisensi data
│   │   ├── statistik_deskriptif.csv  # Mean, median, modus, varians, sd, kuartil
│   │   ├── korelasi.csv              # Matriks korelasi Pearson
│   │   ├── regresi_sederhana.txt     # Ringkasan model Y ~ X1
│   │   ├── regresi_berganda.txt      # Ringkasan model Y ~ X1 + X2 + X3
│   │   ├── uji_asumsi.txt            # VIF, Shapiro-Wilk, Breusch-Pagan
│   │   └── prediksi.csv              # Tiga skenario prediksi + interval 95%
│   └── plots/
│       ├── scatter_qty_y.png
│       ├── scatter_diskon_y.png
│       ├── scatter_ongkir_y.png
│       ├── hist_y.png
│       ├── box_y.png
│       ├── residual_vs_fitted.png
│       └── qq_plot.png
├── laporan/                          # Laporan PDF dan log render
└── presentasi/                       # Draft slide dan catatan demo
```

Folder `_scratch/` berisi percobaan internal: probe API,/installer paket, dan skrip draf. Folder itu bukan bagian dari hasil yang dikumpulkan.

## Kebutuhan Sistem

| Kebutuhan | Versi terpasang | Keterangan |
|---|---|---|
| R | 4.6.2 | Path: `C:\Program Files\R\R-4.6.2\bin\x64\Rscript.exe` |
| RStudio | 2026.11.0+203 | Dipakai untuk menjalankan dan mendemonstrasikan script |
| Paket R | `ggplot2`, `car`, `lmtest` | Wajib untuk analisis |
| Paket R tambahan | `knitr`, `rmarkdown`, `tinytex` | Diperlukan untuk render laporan PDF |

Semua paket R dipasang di library pengguna:

```text
C:\Users\mfarr\AppData\Local\R\win-library\4.6
```

Jalankan ini di RStudio apabila paket belum ada:

```r
options(repos = c(CRAN = "https://cloud.r-project.org"))
install.packages(c("ggplot2", "car", "lmtest", "knitr", "rmarkdown", "tinytex"))
```

## Alur Pengerjaan

### 1. Menentukan topik dan tujuan

Topik terpilih: Ekonomi dan Bisnis. Rumusan masalahnya: seberapa besar kuantitas barang, diskon, dan ongkos kirim berhubungan dengan total pembayaran pada transaksi e-commerce di Indonesia?

Tujuannya ada tiga: menggambarkan distribusi tiap variabel, mengukur kekuatan korelasi, lalu membangun model regresi untuk menjelaskan dan memprediksi total pembayaran.

### 2. Mencari dan memilih data

Beberapa sumber dicek. BPS memerlukan API key dan sebagian data kabupaten/kota tidak tersedia lewat jalur publik. World Bank menyediakan data makro lintas negara, tetapi itu di luar batas "ekonomi nasional". Kaggle dipilih karena dataset transaksi tersedia, jumlah baris jauh di atas syarat minimal 100, dan lisensinya CC0.

Dataset: <https://www.kaggle.com/datasets/zkyfauzi/indonesia-ecommerce-sales>
Berkas: `indonesia_ecommerce_sales_challenging.csv`
Unduhan: `https://www.kaggle.com/api/v1/datasets/download/zkyfauzi/indonesia-ecommerce-sales`

API publik Kaggle dapat diakses tanpa akun untuk endpoint di atas, sehingga unduhan langsung berhasil. Bukti metadata ada di `output/tables/provenance.txt`.

### 3. Mengimpor dan membersihkan data

Dataset asli disalin ke `data/raw/ec_indonesia.csv`. File ini memakai pemisah titik koma, jadi script memakai `read.csv2()` dengan `check.names = FALSE`. Opsi itu penting: tanpa itu, R mengubah nama kolom ber-spasi seperti `Total Diskon` menjadi `Total.Diskon`.

Tahap cleaning:

1. Rename lima kolom ke snake_case supaya mudah dipanggil di kode.
2. Konversi empat variabel model ke numerik. Koma diganti titik, lalu `as.numeric()`.
3. Cek jumlah `NA` per kolom dan simpan di log.
4. Hapus baris duplikat. Hasilnya: tidak ada duplikat.
5. Buang 283 baris yang memiliki `NA` pada variabel model.
6. Urutkan berdasarkan `order_id` dan simpan ke `data/processed/ec_indonesia_clean.csv`.

Jumlah baris akhir: 18.585.

### 4. Statistika deskriptif

Script menghitung mean, median, modus, varians, simpangan baku, minimum, kuartil, dan maksimum untuk keempat variabel. Hasil ditulis ke `output/tables/statistik_deskriptif.csv`.

Rata-rata `total_pembayaran` Rp50.997,58, tetapi mediannya Rp21.800. Selisih ini besar dan menunjukkan distribusi yang condong ke kanan. Histogram dan boxplot di `output/plots/` memperlihatkan bentuk yang sama.

Modus dihitung manual dengan `table()` karena R tidak menyediakan fungsi bawaan untuk modus.

### 5. Analisis korelasi

Matriks korelasi Pearson dihitung untuk keempat variabel dan disimpan ke `output/tables/korelasi.csv`. Korelasi total pembayaran dengan ongkos kirim paling kuat (0,454), disusul kuantitas (0,314) dan diskon (0,229).

Ada satu temuan yang perlu dijaga saat interpretasi: kuantitas dan diskon berkorelasi 0,728. Nilai itu tinggi, tetapi masih di bawah ambang yang biasa dipakai untuk menandai multikolinearitas parah.

Scatter plot dibuat untuk masing-masing pasangan X dan Y. Garis regresi ditambahkan supaya arah hubungan terlihat langsung.

### 6. Analisis regresi

Dua model dijalankan:

```r
model_sederhana <- lm(total_pembayaran ~ total_qty, data = df)

model_berganda <- lm(
  total_pembayaran ~ total_qty + total_diskon + ongkos_kirim_dibayar_oleh_pembeli,
  data = df
)
```

Model sederhana menghasilkan slope 5.767,4 dengan R² 0,0988. Model berganda menaikkan R² menjadi 0,2521. Kenaikan ini nyata, tetapi tetap berarti sekitar 74,8 persen variasi total pembayaran belum dijelaskan ketiga variabel itu.

Koefisien model berganda:

| Variabel | Estimasi | Interpretasi singkat |
|---|---:|---|
| Intercept | 22.990 | Nilai prediksi saat semua X = 0 |
| `total_qty` | 3.938 | Tiap tambah 1 unit kuantitas, pembayaran naik sekitar Rp3.938 |
| `total_diskon` | 0,125 | Tidak signifikan secara statistik (p = 0,345) |
| Ongkos kirim | 4,134 | Tiap tambah Rp1 ongkos kirim, pembayaran naik sekitar Rp4,13 |

### 7. Evaluasi model

Tiga pemeriksaan dijalankan:

- **Multikolinearitas:** VIF berkisar 1,06 sampai 2,19. Tidak ada variabel yang mendekati ambang 5 atau 10.
- **Normalitas residual:** Shapiro-Wilk pada sampel acak 5.000 residual memberi W = 0,272 dan p < 2,2e-16. Asumsi ini ditolak.
- **Heteroskedastisitas:** Breusch-Pagan memberi BP = 218,91 dan p < 2,2e-16. Asumsi ini juga ditolak.

Konsekuensinya: standar error dan interval kepercayaan dapat meleset. Interpretasi arah koefisien masih dipakai, tetapi klaim presisi dibatasi. Laporan tidak mengklaim model ini layak untuk keputusan bisnis tanpa perbaikan lanjutan.

### 8. Prediksi

Script membuat tiga skenario memakai median dan kuartil data, lalu menghitung interval kepercayaan 95% dengan `predict(..., interval = "confidence")`. Hasil ada di `output/tables/prediksi.csv`.

## Cara Menjalankan Ulang

### Opsi A: RStudio

1. Buka RStudio.
2. Buka file `R/analysis.R`.
3. Pastikan *working directory* adalah root project. Cek dengan `getwd()`.
4. Klik **Source** atau tekan `Ctrl+Enter` untuk menjalankan seluruh baris.
5. Pantau panel Console. Log lengkap juga ditulis ke `output/analisis_log.txt`.
6. Buka file di `output/plots/` dan `output/tables/` untuk memeriksa hasil.

### Opsi B: command line

Dari root project:

```bash
powershell -NoProfile -Command "& 'C:\Program Files\R\R-4.6.2\bin\x64\Rscript.exe' 'R/analysis.R'"
```

Script dapat dijalankan berulang. Setiap kali berjalan, file output ditimpa dengan hasil terbaru.

### Opsi C: render laporan

```r
rmarkdown::render("laporan/laporan.Rmd")
```

Jika TinyTeX belum terpasang:

```r
tinytex::install_tinytex()
```

## Penjelasan Script

`R/analysis.R` berjalan linear dari atas ke bawah. Urutannya:

| Baris | Bagian | Fungsi |
|---|---|---|
| 1-12 | Inisialisasi | `set.seed`, load paket, buat folder, buka `sink()` untuk log |
| 17-26 | Import | Baca CSV asli dengan `read.csv2()` |
| 28-40 | Rename | Petakan nama kolom asli ke snake_case |
| 42-61 | Validasi | Cek kolom wajib, konversi numerik |
| 63-87 | Cleaning | Cek NA, hapus duplikat, buang NA, simpan CSV bersih |
| 89-126 | Deskriptif | Hitung statistik dan simpan CSV |
| 128-152 | Korelasi & scatter | Matriks Pearson dan tiga scatter plot |
| 154-179 | Regresi | Model sederhana dan berganda |
| 181-210 | Uji asumsi | VIF, Shapiro-Wilk, Breusch-Pagan |
| 212-236 | Prediksi | Tiga skenario + interval 95% |
| 238-267 | Plot tambahan | Histogram, boxplot, residual plot, QQ-plot |
| 269-275 | Penutup | Ringkasan log dan tutup `sink()` |

## Daftar Output

| File | Isi |
|---|---|
| `data/processed/ec_indonesia_clean.csv` | Dataset siap analisis, 18.585 baris |
| `output/analisis_log.txt` | Jejak seluruh proses, termasuk peringatan R |
| `output/tables/statistik_deskriptif.csv` | Delapan ukuran deskriptif per variabel |
| `output/tables/korelasi.csv` | Matriks korelasi Pearson 4×4 |
| `output/tables/regresi_sederhana.txt` | Ringkasan `lm()` model tunggal |
| `output/tables/regresi_berganda.txt` | Ringkasan `lm()` model tiga prediktor |
| `output/tables/uji_asumsi.txt` | Hasil tiga pemeriksaan model |
| `output/tables/prediksi.csv` | Nilai prediksi dan batas interval |
| `output/tables/provenance.txt` | Metadata sumber data dan lisensi |
| `output/plots/*.png` | Tujuh grafik untuk laporan dan presentasi |

## Catatan Metodologi

Beberapa keputusan sengaja dibuat sederhana supaya mudah dipertanggungjawabkan saat praktik:

- **Tanpa train-test split.** Ini analisis statistika inferensial, bukan model prediksi produksi. Data tidak dibuang supaya koefisien memakai seluruh observasi yang valid. Prediksi dipakai sebagai demonstrasi `predict()`, bukan klaim akurasi out-of-sample.
- **Korelasi Pearson.** Dipilih karena keempat variabel model bertipe numerik. Spearman tidak dipakai dalam pipeline utama.
- **Modus manual.** R tidak punya `mode()` bawaan untuk vektor numerik, jadi script memakai `table()`.
- **Shapiro-Wilk pada sampel.** Uji normalitas memakai 5.000 residual acak karena Shapiro-Wilk pada 18.585 titik sensitif terhadap penyimpangan kecil.
- **Tanpa transformer atau robust standard error.** Tidak dijalankan supaya hasil tetap bisa dijelaskan dengan materi kuliah. Pelanggaran asumsi dilaporkan apa adanya.

Keterbatasan lain: dataset transaksi ini bukan eksperimen terkontrol. Hubungan yang ditemukan bersifat asosiasi. Tanpa desain eksperimen atau data longitudinal, kausalitas tidak dapat ditarik.

## Pemecahan Masalah

### Error: "could not find function"

Paket belum diload. Jalankan `library(ggplot2)`, `library(car)`, dan `library(lmtest)` di awal sesi, atau jalankan ulang `R/analysis.R` dari baris pertama.

### Nama kolom berubah menjadi `Total.Diskon`

Itu tanda `read.csv2()` dipanggil tanpa `check.names = FALSE`. Perbaiki baris import sesuai `R/analysis.R`.

### Error: "object not found" saat menjalankan dari folder lain

Working directory bukan root project. Cek `getwd()`, lalu pindah ke folder project atau gunakan `setwd()`.

### Hasil berubah setelah menjalankan ulang

Bagian uji normalitas memakai `sample()` dengan `set.seed(123)` di baris pertama. Nilai Shapiro-Wilk stabil selama script dijalankan dari awal. Kalau hanya menjalankan sebagian baris, sampelnya berubah.

### Render PDF gagal karena LaTeX

Pasang TinyTeX:

```r
tinytex::install_tinytex()
```

Lalu ulangi `rmarkdown::render("laporan/laporan.Rmd")`. Jika masih gagal, periksa `laporan/render_log.txt`.
