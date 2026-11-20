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
| `processed/customer_behavior_clean.csv` | Data bersih, 46.500 baris, dipakai pipeline R |

## Variabel model

| Simbol | Kolom | Peran |
|---|---|---|
| Y | `Lifetime_Value` | Variabel terikat |
| X1 | `Total_Purchases` | Prediktor |
| X2 | `Average_Order_Value` | Prediktor |
| X3 | `Discount_Usage_Rate` | Prediktor |

## Pra-pengolahan

Empat kolom variabel model dikonversi ke numerik. Baris yang memiliki nilai
kosong pada salah satu variabel model dibuang. Tidak ada filter lain. Dataset
bersifat global dan bukan data transaksi Indonesia.
