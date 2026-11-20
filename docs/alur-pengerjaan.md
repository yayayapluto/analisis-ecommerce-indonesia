# Alur Pengerjaan: Dari Pencarian Data sampai Publikasi

Dokumen ini merangkum alur kerja analisis regresi `Lifetime_Value` pada dataset
perilaku pelanggan e-commerce. Cakupannya mulai dari penentuan kebutuhan data,
pencarian dan unduhan dataset, pra-pengolahan, eksekusi pipeline R, penyusunan
laporan dan slide, sampai publikasi di GitHub. Prosedur di sini ditulis supaya
bisa diulang dari awal. Angka yang disebut berasal dari berkas output di repo.

## Ringkasan keputusan

| Aspek | Keputusan |
|---|---|
| Sumber data | Kaggle `dhairyajeetsingh/ecommerce-customer-behavior-dataset` |
| Lisensi | Database: Open Database, Contents: Database Contents |
| Tanggal pembaruan | 2025-12-13 |
| Karakter data | Global, bukan data transaksi produksi riil Indonesia |
| Variabel terikat | `Y = Lifetime_Value` |
| Prediktor | `X1 = Total_Purchases`, `X2 = Average_Order_Value`, `X3 = Discount_Usage_Rate` |
| Baris awal | 50.000 |
| Baris setelah `complete.cases()` | 46.500 |
| Baris dibuang karena `NA` | 3.500 |
| Baris duplikat dibuang | 0 |
| Baris final | 46.500 |
| Total baris dibuang | 3.500 |
| Repo publik | `yayayapluto/analisis-perilaku-pelanggan-ecommerce`, branch `main` |

---

## Tahap 1: Menetapkan kebutuhan data

Analisis memakai regresi linear dengan satu variabel terikat dan tiga prediktor.
Karena itu, kandidat dataset harus memenuhi syarat berikut.

1. Memuat kolom `Lifetime_Value`, `Total_Purchases`, `Average_Order_Value`, dan
   `Discount_Usage_Rate` dengan nama yang sama atau hampir sama.
2. Nilai keempat kolom bisa dikonversi ke numerik.
3. Jumlah baris cukup besar untuk estimasi regresi berganda.
4. Lisensi dan pemilik dataset tercantum jelas.
5. Metadata memuat tanggal pembaruan sehingga versi data bisa dilacak.
6. Dataset tidak diklaim sebagai data e-commerce Indonesia. Proyek ini memakai
   satuan nilai dataset tanpa simbol mata uang.

Kriteria ini dipakai untuk memilih data yang memberi hasil dapat diaudit, bukan
sekadar dataset dengan jumlah baris besar.

---

## Tahap 2: Mencari dataset di Kaggle

Langkah berikut dipakai untuk menemukan dan menilai kandidat dataset.

1. Buka https://www.kaggle.com/datasets.
2. Cari dengan kata kunci `ecommerce customer behavior`.
3. Buka hasil pada tab **Datasets**, lalu periksa satu per satu deskripsi,
   jumlah baris, daftar kolom, lisensi, dan tanggal pembaruan.
4. Tolak kandidat yang tidak memuat keempat variabel model atau tidak punya
   lisensi yang jelas.
5. Pilih dataset `Ecommerce Customer Behavior Dataset` dari akun
   `dhairyajeetsingh`. Dataset ini memuat 25 fitur, 50.000 baris, dan keempat
   kolom yang dibutuhkan.
6. Simpan URL, pemilik, lisensi, dan tanggal pembaruan ke
   `output/tables/provenance.txt` dan `data/README.md`.

Tautan final:
https://www.kaggle.com/datasets/dhairyajeetsingh/ecommerce-customer-behavior-dataset

---

## Tahap 3: Mengunduh dan menyimpan data mentah

### Cara manual

1. Masuk ke akun Kaggle.
2. Buka tautan dataset di atas.
3. Klik **Download**.
4. Jika hasil unduhan berupa arsip, ekstrak isinya.
5. Simpan berkas CSV ke `data/raw/customer_behavior.csv`. Jika nama berkas
   hasil unduhan berbeda, samakan menjadi `customer_behavior.csv`.

### Alternatif baris perintah

Jika Kaggle CLI sudah terpasang, jalankan:

```bash
kaggle datasets download -d dhairyajeetsingh/ecommerce-customer-behavior-dataset -p data/raw --unzip
```

Periksa hasil unduhan dari konsol R:

```r
data_mentah <- read.csv("data/raw/customer_behavior.csv")
nrow(data_mentah)  # 50000
ncol(data_mentah)  # 25
names(data_mentah)
```

---

## Tahap 4: Mencatat provenance

Provenance ditulis sebelum analisis lanjutan supaya sumber data tidak tercampur
dengan hasil olahan. Berkas `output/tables/provenance.txt` memuat:

- nama dataset dan pemilik,
- URL Kaggle,
- lisensi,
- tanggal pembaruan lengkap,
- jumlah baris dan kolom awal,
- deskripsi singkat,
- definisi `Y`, `X1`, `X2`, dan `X3`,
- jumlah baris setelah `NA`, duplikat, final, dan total baris dibuang.

`data/README.md` memuat versi ringkas untuk pembaca repo. Keduanya harus
mengacu pada dataset yang sama dengan CSV di `data/raw/`.

---

## Tahap 5: Pra-pengolahan

Script `R/analysis.R` melakukan pra-pengolahan sebelum pemodelan.

1. Membaca `data/raw/customer_behavior.csv` dengan `read.csv()`.
2. Memeriksa keberadaan keempat kolom wajib. Jika ada yang hilang, script
   berhenti dengan pesan kolom tidak ditemukan.
3. Mengonversi keempat kolom model ke numerik. Nilai yang tidak bisa dikonversi
   menjadi `NA`.
4. Menghitung jumlah `NA` per variabel model dan menyimpan hasil penyaringan
   `complete.cases()` ke `data_setelah_na`.
5. Menghitung `baris_na` dari selisih baris awal dan baris setelah penyaringan.
6. Membuang duplikat dari `data_setelah_na` dengan `!duplicated()`, lalu
   menghitung `baris_duplikat`, `baris_final`, dan `baris_dibuang`.
7. Menyimpan hasil akhir ke `data/processed/customer_behavior_clean.csv` dan
   menulis ketiga jumlah baris ke `output/analisis_log.txt`.

Hasil terverifikasi: 50.000 baris awal, 46.500 baris setelah `NA`, 3.500 baris
dibuang karena `NA`, 0 baris duplikat, 46.500 baris final, dan 3.500 total
baris dibuang. Tidak ada filter tambahan lain, seperti penghapusan outlier atau
pembatasan rentang nilai.

---

## Tahap 6: Menjalankan pipeline R

Paket yang dipakai: `ggplot2`, `car`, `lmtest`, `knitr`, dan `rmarkdown`.
Jalankan dari root proyek:

```bash
Rscript R/analysis.R
```

Ringkasan tahap dan berkas yang dihasilkan:

| Tahap analisis | Fungsi utama | Output |
|---|---|---|
| Statistik deskriptif | `mean`, `median`, `var`, `sd`, kuartil | `output/tables/statistik_deskriptif.csv` |
| Korelasi | `cor()` pada variabel model | `output/tables/korelasi.csv` |
| Regresi sederhana | `lm(Y ~ X1)` | `output/tables/regresi_sederhana.txt` |
| Regresi berganda | `lm(Y ~ X1 + X2 + X3)` | `output/tables/regresi_berganda.txt` |
| Multikolinearitas | `car::vif()` | `output/tables/uji_asumsi.txt` |
| Normalitas residual | `shapiro.test()` pada sampel 5.000 residual | `output/tables/uji_asumsi.txt` |
| Heteroskedastisitas | `lmtest::bptest()` | `output/tables/uji_asumsi.txt` |
| Prediksi tiga skenario | `predict()` dengan interval 95 persen | `output/tables/prediksi.csv` |
| Visualisasi | `ggplot2`, `qqnorm()` | `output/plots/*.png` |
| Log eksekusi | `sink()` | `output/analisis_log.txt` |

Skenario prediksi dibentuk dari kuartil 0,25; 0,50; dan 0,75 pada masing-masing
prediktor. Karena itu, baris **Rendah**, **Menengah**, dan **Tinggi** tidak
diambil dari data mentah, melainkan dari kombinasi kuartil yang dibuat oleh
script.

Cara menjalankan lewat RStudio ada di `README.md` bagian 4.1.

---

## Tahap 7: Membaca hasil

Angka berikut dibaca langsung dari output R.

| Ringkasan | Nilai |
|---|---|
| `kor(Y, X1)` | 0,620 |
| `kor(Y, X2)` | 0,153 |
| `kor(Y, X3)` | 0,001 |
| R-squared `Y ~ X1` | 0,3846 |
| R-squared `Y ~ X1 + X2 + X3` | 0,4075 |
| VIF `X1`, `X2`, `X3` | 1,001436; 1,000021; 1,001415 |
| Shapiro-Wilk | `W = 0.79227`, `p < 2.2e-16` |
| Breusch-Pagan | `BP = 17058`, `df = 3`, `p < 2.2e-16` |
| Prediksi Rendah, Menengah, Tinggi | 1020,543; 1345,335; 1752,364 |

`Total_Purchases` memberi kontribusi paling besar. `Average_Order_Value`
berhubungan lemah, sedangkan `Discount_Usage_Rate` hampir tidak berkorelasi
dengan `Lifetime_Value`. VIF mendekati 1, sehingga multikolinearitas tidak
masalah. Uji Shapiro-Wilk dan Breusch-Pagan menolak normalitas residual dan
homoskedastisitas. Interpretasi model perlu disertai catatan keterbatasan ini.

---

## Tahap 8: Menyusun laporan, slide, dan ringkasan hasil

1. Render laporan dari root proyek:

   ```bash
   Rscript -e "rmarkdown::render('laporan/laporan.Rmd')"
   ```

   `laporan/laporan.Rmd` membaca angka dari `output/tables/`, jadi tidak ada
   nilai regresi yang ditulis manual di dalam laporan.

2. Periksa `laporan/laporan.pdf`. Bab 2 membahas sumber data dan
   pra-pengolahan, Bab 3 sampai Bab 7 membahas hasil analisis, Bab 8 memuat
   kesimpulan.

3. Salin tujuh plot ke `assets/` dengan nama `g1_` sampai `g7_` agar
   `RESULT.md` punya aset lokal.

4. Perbarui `RESULT.md` dengan ringkasan pipeline, visualisasi, tabel hasil,
   prediksi, dan keterbatasan.

5. Perbarui `presentasi/slide.md`. Slide 3 memuat sumber data, Slide 4
   preprocessing, Slide 11 demo RStudio.

6. Perbarui `README.md` jika struktur folder, paket, atau cara menjalankan
   berubah.

---

## Tahap 9: Publikasi

Repo publik memakai nama `analisis-perilaku-pelanggan-ecommerce` agar tidak
mengira data ini sebagai e-commerce Indonesia. Branch utamanya `main`.

Push langsung ke branch utama diblokir oleh guard, jadi perubahan masuk lewat
pull request. Alurnya:

1. Buat branch kerja dari `main`.
2. Commit perubahan dengan pesan yang menjelaskan isi perubahan.
3. Push branch kerja.
4. Buat pull request ke `main`.
5. Merge pull request, lalu hapus branch kerja.
6. Perbarui checkout lokal dengan `git pull --ff-only`.

URL repo: https://github.com/yayayapluto/analisis-perilaku-pelanggan-ecommerce

---

## Checklist selesai

- [ ] `data/raw/customer_behavior.csv` ada, berisi 50.000 baris dan 25 kolom.
- [ ] `data/processed/customer_behavior_clean.csv` ada, berisi 46.500 baris akhir setelah 3.500 baris `NA` dan 0 duplikat dibuang.
- [ ] Seluruh berkas di `output/tables/` dan `output/plots/` terbentuk.
- [ ] `laporan/laporan.pdf` lebih baru daripada `laporan/laporan.Rmd`.
- [ ] Angka di `README.md`, `RESULT.md`, `laporan/laporan.Rmd`, dan
      `presentasi/slide.md` cocok dengan output R.
- [ ] Tidak ada sisa nama dataset, path, atau klaim lama di dokumentasi.
- [ ] `git status --short` bersih dan `main` sudah sinkron dengan remote.
- [ ] URL repo publik mengembalikan status HTTP 200.

Untuk langkah teknis membuka proyek di RStudio, lihat `README.md` bagian 4.1.
Untuk daftar output dan penjelasan tiap berkas, lihat `README.md` bagian 6.
