# Data

## Sumber

Dataset: **Ecommerce Customer Behavior Dataset**  
Akun Kaggle: `dhairyajeetsingh`  
URL: https://www.kaggle.com/datasets/dhairyajeetsingh/ecommerce-customer-behavior-dataset  
Lisensi: Database: Open Database, Contents: Database Contents  
Tanggal pembaruan: 2025-12-13

## Berkas

| Berkas | Isi |
|---|---|
| `raw/customer_behavior.csv` | Data mentah, 50.000 baris, 25 kolom |
| `processed/customer_behavior_clean.csv` | Data bersih, 46.500 baris akhir, dipakai pipeline R |

## Variabel model

| Simbol | Kolom | Peran |
|---|---|---|
| Y | `Lifetime_Value` | Variabel terikat |
| X1 | `Total_Purchases` | Prediktor |
| X2 | `Average_Order_Value` | Prediktor |
| X3 | `Discount_Usage_Rate` | Prediktor |

## Pra-pengolahan

Empat kolom variabel model dikonversi ke numerik. Baris dengan nilai kosong pada
salah satu variabel model dibuang, menyisakan 46.500 baris dari 50.000 baris
awal. Pemeriksaan duplikat setelah itu membuang 0 baris, sehingga baris final
tetap 46.500 dan total baris dibuang 3.500. Tidak ada filter tambahan lain. Dataset
bersifat global dan bukan data transaksi Indonesia.
