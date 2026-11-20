# Projek Analisis Data E-Commerce: Nilai Lifetime Value

**Tujuan**  
Mengeksplorasi hubungan antara aktivitas belanja pelanggan dan nilai lifetime value (Y) menggunakan dataset e-commerce dari Kaggle. Dokumentasi ini mencakup struktur proyek, kebutuhan sistem, alur pengerjaan, cara menjalankan ulang, penjelasan script, daftar output, catatan metodologi, serta panduan pemecahan masalah. Ringkasan hasil dan visualisasi tersedia di [RESULT.md](RESULT.md).

---

## 1. Struktur Proyek

```
D:/Kuliah/statistik/projek_uas/
│
├─ data/
│   ├─ README.md                               # Sumber, lisensi, dan variabel
│   ├─ raw/
│   │   └─ customer_behavior.csv               # 50.000 baris, 25 kolom
│   └─ processed/
│       └─ customer_behavior_clean.csv         # 46.500 baris setelah NA dibuang
│
├─ assets/                                     # Salinan plot untuk RESULT.md
│   ├─ g1_distribusi_lifetime_value.png
│   ├─ g2_boxplot_lifetime_value.png
│   ├─ g3_scatter_total_purchases.png
│   ├─ g4_scatter_average_order_value.png
│   ├─ g5_scatter_discount_usage_rate.png
│   ├─ g6_residual_vs_fitted.png
│   └─ g7_qq_plot.png
│
├─ output/
│   ├─ tables/
│   │   ├─ statistik_deskriptif.csv
│   │   ├─ korelasi.csv
│   │   ├─ regresi_sederhana.txt
│   │   ├─ regresi_berganda.txt
│   │   ├─ uji_asumsi.txt
│   │   ├─ prediksi.csv
│   │   └─ provenance.txt
│   ├─ plots/
│   │   ├─ hist_y.png
│   │   ├─ box_y.png
│   │   ├─ scatter_purchases_y.png
│   │   ├─ scatter_order_value_y.png
│   │   ├─ scatter_discount_y.png
│   │   ├─ residual_vs_fitted.png
│   │   └─ qq_plot.png
│   └─ analisis_log.txt
│
├─ R/
│   └─ analysis.R                              # Script utama menghasilkan semua output
│
├─ laporan/
│   └─ laporan.Rmd                             # Membaca output secara dinamis
│
├─ presentasi/
│   └─ slide.md
│
├─ RESULT.md                                   # Ringkasan hasil dan visualisasi
└─ README.md                                   # Dokumen ini
```

---

## 2. Kebutuhan Sistem

- **R** versi 4.3 atau lebih tinggi
- **Paket R**: `ggplot2`, `car`, `lmtest`, `knitr`, `rmarkdown`
- **Python** (opsional) untuk verifikasi: `pandas`, `numpy`, `scipy`, `statsmodels`
- **Git** untuk kontrol versi (tidak wajib)
- **Lisensi data**: Dataset berasal dari Kaggle `dhairyajeetsingh/ecommerce-customer-behavior-dataset`; penggunaan sesuai kontrak bersama (tidak termasuk data transaksi produksi riil Indonesia).

---

## 3. Alur Pengerjaan

1. **Download dataset** dari Kaggle dan tempatkan di `data/raw/customer_behavior.csv` (50.000 baris, 25 kolom).  
2. **Bersihkan data**:  
   - Baca CSV.  
   - Konversi empat kolom variabel model ke numerik.  
   - Hapus baris yang memiliki `NA` pada keempat variabel model (`Y`, `X1`, `X2`, `X3`).  
   - Simpan hasil ke `data/processed/customer_behavior_clean.csv` (46.500 baris).  
3. **Jalankan script R** `R/analysis.R` yang menghasilkan:  
   - Tabel statistik deskriptif.  
   - Matriks korelasi.  
   - Model regresi sederhana `Y ~ X1`.  
   - Model regresi berganda `Y ~ X1 + X2 + X3`.  
   - Uji asumsi (tidak perlu diisi angka secara manual).  
   - Prediksi dengan interval 95 %.  
   - Laporan analisis (`output/analisis_log.txt`).  
   - Plot-plot wajib di `output/plots/`.  
4. **Bangun laporan** dengan `laporan.Rmd` yang membaca otomatis berkas output yang telah dihasilkan.  
5. **Review slide.md** dan **README.md** untuk presentasi dan dokumentasi akhir.

---

## 4. Cara Menjalankan Ulang

```bash
# 1. Pastikan R terinstal dan paket-paket dibutuhkan terinstall
R --version

# 2. Install paket R yang dibutuhkan (jika belum ada)
install.packages(c("ggplot2", "car", "lmtest", "knitr", "rmarkdown"))

# 3. Jalankan script analisis
Rscript R/analysis.R

# 4. Generate laporan Rmd
Rscript -e "rmarkdown::render('laporan/laporan.Rmd')"
```

Setelah langkah-langkah di atas, berkas output di `output/` akan diperbarui dan plot akan tersimpan di `output/plots/`.

---

## 5. Penjelasan Script `R/analysis.R`

Script memakai base R untuk membaca dan menulis CSV, `ggplot2` untuk plot,
`car` untuk VIF, dan `lmtest` untuk Breusch-Pagan. Urutan kerjanya:

1. Membaca `data/raw/customer_behavior.csv`.
2. Mengonversi empat kolom variabel model ke numerik.
3. Membuang baris dengan `NA` pada keempat variabel model.
4. Menghitung statistik deskriptif dan matriks korelasi.
5. Menaksir model `Y ~ X1` dan `Y ~ X1 + X2 + X3`.
6. Menjalankan VIF, Shapiro-Wilk, dan Breusch-Pagan.
7. Memprediksi tiga skenario kuartil dengan interval kepercayaan 95 persen.
8. Menyimpan tujuh plot dan menulis log ke `output/analisis_log.txt`.

Semua angka kunci dihasilkan langsung dari output R. Laporan dan `RESULT.md`
membaca berkas output tersebut, sehingga tidak ada angka yang diisi manual.

---

## 6. Daftar Output

| Nama Berkas | Deskripsi |
|-------------|-----------|
| `output/tables/statistik_deskriptif.csv` | Tabel statistik deskriptif (n, mean, median, varians, sd, min, q1, q2, q3, max) per variabel model. |
| `output/tables/korelasi.csv` | Matriks korelasi dengan row names untuk Y, X1, X2, X3. |
| `output/tables/regresi_sederhana.txt` | Intercept, slope X1, dan R² model `Y ~ X1`. |
| `output/tables/regresi_berganda.txt` | Intercept, koefisien X1, X2, X3, R², adjusted R² model `Y ~ X1 + X2 + X3`. |
| `output/tables/uji_asumsi.txt` | Hasil VIF, Shapiro-Wilk, dan Breusch-Pagan dari R. |
| `output/tables/prediksi.csv` | Skenario per baris: total_purchases, average_order_value, discount_usage_rate, prediksi, batas_bawah_95, batas_atas_95. |
| `output/tables/provenance.txt` | Sumber, lisensi, dan metadata dataset. |
| `output/analisis_log.txt` | Log lengkap dari eksekusi script R (termasuk baris awal/akhir, korelasi, koefisien model). |
| `data/processed/customer_behavior_clean.csv` | Data yang sudah dibersihkan (46.500 baris, 4 variabel model numerik). |
| `output/plots/*.png` | Tujuh plot wajib (lihat section 5). |

---

## 7. Catatan Metodologi

- **Sumber data**: dataset dari Kaggle `dhairyajeetsingh/ecommerce-customer-behavior-dataset`. Lisensi penggunaan sesuai kontrak proyek; dataset bersifat global, bukan data transaksi produksi Indonesia.
- **Variabel model**
  - `Y` = Lifetime_Value (nilai total selama masa hidup pelanggan).
  - `X1` = Total_Purchases (total pembelian).
  - `X2` = Average_Order_Value (rata-rata nilai per order).
  - `X3` = Discount_Usage_Rate (tingkat penggunaan diskon).
- **Penghapusan baris**: hanya hapus baris dengan `NA` pada keempat variabel model `Y`, `X1`, `X2`, `X3`. Filter lain tidak diterapkan.
- **Korelasi kunci** (nilai yang muncul di output):
  - kor(Y, X1) = 0,620
  - kor(Y, X2) = 0,153
  - kor(Y, X3) = 0,001
  - kor(X1, X2) = 0,005
- **Model sederhana** `Y ~ X1`: intercept 394,764; slope X1 79,725; R² 0,3846.
- **Model berganda** `Y ~ X1 + X2 + X3`: intercept 339,451; X1 79,746; X2 0,772; X3 -0,953; R² 0,4075; adjusted R² 0,4075; uji keseluruhan signifikan.
- **Uji asumsi**: nilai VIF, Shapiro, dan BP dilaporkan langsung dari output R.
- **Dataset global**: data ini berasal dari pasar e-commerce global dan tidak mewakili pasar Indonesia.

---

## 8. Pemecahan Masalah

| Masalah | Solusi |
|---------|--------|
| **Gagal membaca CSV** | Pastikan file `data/raw/customer_behavior.csv` ada dan tidak rusak. Coba baca dengan `read.csv()` langsung dari konsol R untuk melihat pesan error. |
| **Terlalu banyak NA** | Cek kolom yang menyebabkan NA; pastikan konversi ke numerik (`as.numeric`) dilakukan sebelum filter. |
| **Plot tidak muncul** | Pastikan paket `ggplot2` terinstall dan versi R cukup baru. Cek direktori kerja: plot disimpan relatif terhadap `getwd()`. |
| **Output tabel kosong** | Periksa apakah langkah filter NA sukses menghasilkan 46.500 baris. Jika baris lebih sedikit, periksa kembali kolom NA. |
| **Laporan Rmd error** | Jalankan `rmarkdown::render()` dari direktori project dan lihat pesan error di konsol. Umumnya disebabkan oleh path file yang salah. |
| **Peringatan kontras warna** | Warna plot dihasilkan default ggplot2; jika diperlukan penyesuaian kontras, sesuaikan di dalam kode plot sebelum `ggsave`. |

Jika kendala lainnya, cek log `output/analisis_log.txt` untuk pesan error R dan arahkan perbaikannya sesuai pesan tersebut.

---

## 9. Referensi Singkat

- `dhairyajeetsingh`, *Ecommerce Customer Behavior Dataset*, Kaggle, 2025. https://www.kaggle.com/datasets/dhairyajeetsingh/ecommerce-customer-behavior-dataset
- Kontrak proyek: variabel model, penghapusan NA, korelasi, dan hasil regresi mengikuti rancangan yang ditetapkan pada awal pengerjaan.
- Metodologi analisis regresi linier sederhana dan berganda memakai paket `stats` bawaan R.

--- 

*End of README.md*