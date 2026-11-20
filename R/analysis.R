set.seed(123)

suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(car))
suppressPackageStartupMessages(library(lmtest))

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("output/plots", recursive = TRUE, showWarnings = FALSE)

log_file <- file("output/analisis_log.txt", open = "wt")
sink(log_file, split = TRUE)

cat("Analisis regresi e-commerce Indonesia\n")
cat("Sumber: data/raw/ec_indonesia.csv\n\n")

df <- read.csv2(
  "data/raw/ec_indonesia.csv",
  check.names = FALSE,
  stringsAsFactors = FALSE,
  fileEncoding = "UTF-8",
  na.strings = c("", "NA")
)
baris_awal <- nrow(df)
cat("Baris awal:", baris_awal, "\n")
cat("Kolom awal:", ncol(df), "\n\n")

peta_nama <- c(
  "Total Diskon" = "total_diskon",
  "Ongkos Kirim Dibayar oleh Pembeli" = "ongkos_kirim_dibayar_oleh_pembeli",
  "Total Pembayaran" = "total_pembayaran",
  "Waktu Pesanan Dibuat" = "waktu_pesan_dibuat",
  "Perkiraan Ongkos Kirim" = "perkiraan_ongkos_kirim"
)
for (nama_lama in names(peta_nama)) {
  if (nama_lama %in% names(df)) {
    names(df)[names(df) == nama_lama] <- peta_nama[[nama_lama]]
    cat("Rename:", nama_lama, "->", peta_nama[[nama_lama]], "\n")
  }
}

variabel_model <- c(
  "total_pembayaran",
  "total_qty",
  "total_diskon",
  "ongkos_kirim_dibayar_oleh_pembeli"
)
hilang <- setdiff(variabel_model, names(df))
if (length(hilang) > 0) {
  stop("Kolom wajib tidak ditemukan: ", paste(hilang, collapse = ", "))
}

# Desimal memakai titik; koma hanya dipakai jika ada format desimal alternatif.
ke_numerik <- function(x) {
  z <- trimws(as.character(x))
  z[z %in% c("", "NA")] <- NA_character_
  suppressWarnings(as.numeric(gsub(",", ".", z)))
}
for (v in variabel_model) {
  df[[v]] <- ke_numerik(df[[v]])
}

cat("\nStruktur data setelah rename dan konversi tipe:\n")
str(df)

cat("\nJumlah NA per kolom:\n")
na_per_kolom <- data.frame(
  kolom = names(df),
  n_na = vapply(df, function(x) sum(is.na(x)), integer(1)),
  stringsAsFactors = FALSE
)
print(na_per_kolom, row.names = FALSE)

n_duplikat <- sum(duplicated(df))
cat("\nBaris duplikat:", n_duplikat, "\n")
df <- df[!duplicated(df), ]
cat("Baris setelah hapus duplikat:", nrow(df), "\n")

n_sebelum_na <- nrow(df)
df <- df[stats::complete.cases(df[, variabel_model]), ]
df <- df[order(df$order_id), ]
rownames(df) <- NULL
cat("Baris dibuang karena NA pada variabel model:", n_sebelum_na - nrow(df), "\n")
cat("Jumlah baris final:", nrow(df), "\n")

write.csv(df, "data/processed/ec_indonesia_clean.csv", row.names = FALSE)
cat("Tersimpan: data/processed/ec_indonesia_clean.csv\n")

cat("\n=== STATISTIKA DESKRIPTIF ===\n")
modus <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NA_real_)
  tab <- table(x)
  as.numeric(names(tab)[which.max(tab)])
}
statistik_satu <- function(x) {
  x <- x[!is.na(x)]
  q <- stats::quantile(x, c(0.25, 0.5, 0.75), na.rm = TRUE, names = FALSE)
  data.frame(
    variabel = NA_character_,
    n = length(x),
    mean = mean(x),
    median = stats::median(x),
    modus = modus(x),
    varians = stats::var(x),
    sd = stats::sd(x),
    min = min(x),
    q1 = q[1],
    q2 = q[2],
    q3 = q[3],
    max = max(x),
    stringsAsFactors = FALSE
  )
}
deskriptif <- do.call(rbind, lapply(variabel_model, function(v) {
  out <- statistik_satu(df[[v]])
  out$variabel <- v
  out
}))
rownames(deskriptif) <- NULL
deskriptif_tampil <- deskriptif
kolom_bulat <- setdiff(names(deskriptif), c("variabel", "n"))
deskriptif_tampil[kolom_bulat] <- lapply(deskriptif_tampil[kolom_bulat], round, 3)
print(deskriptif_tampil, row.names = FALSE)
write.csv(deskriptif, "output/tables/statistik_deskriptif.csv", row.names = FALSE)
cat("Tersimpan: output/tables/statistik_deskriptif.csv\n")

cat("\n=== KORELASI PEARSON ===\n")
matriks_korelasi <- stats::cor(df[, variabel_model], use = "complete.obs", method = "pearson")
print(round(matriks_korelasi, 4))
write.csv(matriks_korelasi, "output/tables/korelasi.csv")
cat("Tersimpan: output/tables/korelasi.csv\n")

cat("\n=== SCATTER PLOT ===\n")
pasangan_scatter <- list(
  list(x = "total_qty", y = "total_pembayaran", file = "scatter_qty_y.png",
       label = "Total Kuantitas", judul = "Kuantitas vs Total Pembayaran"),
  list(x = "total_diskon", y = "total_pembayaran", file = "scatter_diskon_y.png",
       label = "Total Diskon", judul = "Total Diskon vs Total Pembayaran"),
  list(x = "ongkos_kirim_dibayar_oleh_pembeli", y = "total_pembayaran",
       file = "scatter_ongkir_y.png", label = "Ongkos Kirim Dibayar Pembeli",
       judul = "Ongkos Kirim vs Total Pembayaran")
)
for (p in pasangan_scatter) {
  plot_obj <- ggplot(df, aes(.data[[p$x]], .data[[p$y]])) +
    geom_point(alpha = 0.25, size = 0.7, colour = "#2C6E8F") +
    geom_smooth(method = "lm", se = FALSE, colour = "#C0392B", linewidth = 0.8) +
    labs(title = p$judul, x = p$label, y = "Total Pembayaran") +
    theme_minimal(base_size = 11)
  ggsave(file.path("output/plots", p$file), plot_obj, width = 8, height = 5.5, dpi = 120)
  cat("Tersimpan: output/plots/", p$file, "\n", sep = "")
}

cat("\n=== REGRESI LINEAR SEDERHANA ===\n")
model_sederhana <- lm(total_pembayaran ~ total_qty, data = df)
ringkasan_sederhana <- capture.output(print(summary(model_sederhana)))
cat(ringkasan_sederhana, sep = "\n")
cat("\n")
writeLines(c("REGRESI LINEAR SEDERHANA: total_pembayaran ~ total_qty", "",
             ringkasan_sederhana),
           "output/tables/regresi_sederhana.txt")
cat("Tersimpan: output/tables/regresi_sederhana.txt\n")

cat("\n=== REGRESI LINEAR BERGANDA ===\n")
model_berganda <- lm(
  total_pembayaran ~ total_qty + total_diskon + ongkos_kirim_dibayar_oleh_pembeli,
  data = df
)
ringkasan_berganda <- capture.output(print(summary(model_berganda)))
cat(ringkasan_berganda, sep = "\n")
cat("\n")
writeLines(c("REGRESI LINEAR BERGANDA: total_pembayaran ~ total_qty + total_diskon + ongkos_kirim_dibayar_oleh_pembeli",
             "", ringkasan_berganda),
           "output/tables/regresi_berganda.txt")
cat("Tersimpan: output/tables/regresi_berganda.txt\n")
r2_berganda <- summary(model_berganda)$r.squared
r2_adjusted <- summary(model_berganda)$adj.r.squared
cat(sprintf("R-squared model berganda: %.6f\n", r2_berganda))
cat(sprintf("R-squared adjusted model berganda: %.6f\n", r2_adjusted))

cat("\n=== UJI ASUMSI ===\n")
nilai_vif <- car::vif(model_berganda)
teks_vif <- capture.output(print(nilai_vif))
cat("Multikolinearitas (VIF):\n")
cat(teks_vif, sep = "\n")
cat("\n")

resid_model <- stats::residuals(model_berganda)
ukuran_sampel <- min(5000, length(resid_model))
uji_normal <- stats::shapiro.test(sample(resid_model, ukuran_sampel))
teks_normal <- capture.output(print(uji_normal))
cat("Normalitas residual (Shapiro-Wilk pada sampel acak):\n")
cat("Ukuran sampel:", ukuran_sampel, "\n")
cat(teks_normal, sep = "\n")
cat("\n")

uji_hetero <- lmtest::bptest(model_berganda)
teks_hetero <- capture.output(print(uji_hetero))
cat("Heteroskedastisitas (Breusch-Pagan):\n")
cat(teks_hetero, sep = "\n")
cat("\n")

writeLines(c(
  "UJI ASUMSI MODEL REGRESI BERGANDA", "",
  "Multikolinearitas (VIF):", teks_vif, "",
  paste("Normalitas residual (Shapiro-Wilk, sampel acak n =", ukuran_sampel, "):"),
  teks_normal, "",
  "Heteroskedastisitas (Breusch-Pagan):", teks_hetero
), "output/tables/uji_asumsi.txt")
cat("Tersimpan: output/tables/uji_asumsi.txt\n")

cat("\n=== PREDIKSI ===\n")
newdata <- data.frame(
  total_qty = c(1, stats::median(df$total_qty), stats::quantile(df$total_qty, 0.75)),
  total_diskon = c(0, stats::median(df$total_diskon), 0),
  ongkos_kirim_dibayar_oleh_pembeli = c(
    stats::median(df$ongkos_kirim_dibayar_oleh_pembeli),
    stats::quantile(df$ongkos_kirim_dibayar_oleh_pembeli, 0.75),
    stats::median(df$ongkos_kirim_dibayar_oleh_pembeli)
  )
)
prediksi <- stats::predict(model_berganda, newdata = newdata,
                           interval = "confidence", level = 0.95)
tabel_prediksi <- data.frame(
  skenario = paste0("Skenario ", seq_len(nrow(newdata))),
  total_qty = newdata$total_qty,
  total_diskon = newdata$total_diskon,
  ongkos_kirim_dibayar_oleh_pembeli = newdata$ongkos_kirim_dibayar_oleh_pembeli,
  prediksi = prediksi[, "fit"],
  batas_bawah_95 = prediksi[, "lwr"],
  batas_atas_95 = prediksi[, "upr"],
  stringsAsFactors = FALSE
)
print(tabel_prediksi, row.names = FALSE)
write.csv(tabel_prediksi, "output/tables/prediksi.csv", row.names = FALSE)
cat("Tersimpan: output/tables/prediksi.csv\n")

cat("\n=== PLOT TAMBAHAN ===\n")
plot_hist <- ggplot(df, aes(x = total_pembayaran)) +
  geom_histogram(bins = 50, fill = "#2C6E8F", colour = "white", linewidth = 0.2) +
  labs(title = "Distribusi Total Pembayaran", x = "Total Pembayaran", y = "Frekuensi") +
  theme_minimal(base_size = 11)
ggsave("output/plots/hist_y.png", plot_hist, width = 8, height = 5.5, dpi = 120)
cat("Tersimpan: output/plots/hist_y.png\n")

plot_box <- ggplot(df, aes(y = total_pembayaran)) +
  geom_boxplot(fill = "#A8C6D4", outlier.colour = "#C0392B", outlier.size = 0.7) +
  labs(title = "Boxplot Total Pembayaran", y = "Total Pembayaran") +
  theme_minimal(base_size = 11)
ggsave("output/plots/box_y.png", plot_box, width = 5, height = 6, dpi = 120)
cat("Tersimpan: output/plots/box_y.png\n")

plot_residual <- ggplot(data.frame(fitted = stats::fitted(model_berganda),
                                   residual = resid_model),
                        aes(x = fitted, y = residual)) +
  geom_point(alpha = 0.25, size = 0.7, colour = "#2C6E8F") +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "#C0392B") +
  labs(title = "Residual vs Nilai Fitted", x = "Fitted", y = "Residual") +
  theme_minimal(base_size = 11)
ggsave("output/plots/residual_vs_fitted.png", plot_residual, width = 8, height = 5.5, dpi = 120)
cat("Tersimpan: output/plots/residual_vs_fitted.png\n")

png("output/plots/qq_plot.png", width = 1600, height = 1200, res = 200)
stats::qqnorm(resid_model, main = "QQ-Plot Residual Model Berganda")
stats::qqline(resid_model, col = "#C0392B", lwd = 1.5)
dev.off()
cat("Tersimpan: output/plots/qq_plot.png\n")

cat("\nBaris awal:", baris_awal, "\n")
cat("Baris final:", nrow(df), "\n")
cat(sprintf("R-squared model berganda: %.6f\n", r2_berganda))
cat("Analisis selesai tanpa error.\n")

sink()
close(log_file)
