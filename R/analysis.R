suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(car))
suppressPackageStartupMessages(library(lmtest))

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("output", recursive = TRUE, showWarnings = FALSE)
dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("output/plots", recursive = TRUE, showWarnings = FALSE)

log_file <- file("output/analisis_log.txt", open = "wt")
sink(log_file, split = TRUE)

cat("Analisis regresi data perilaku pelanggan e-commerce\n")
cat("Sumber data: data/raw/customer_behavior.csv\n")
cat("Dataset bersifat global dan bukan data transaksi Indonesia.\n")
cat("Seluruh nilai memakai satuan dataset tanpa simbol mata uang.\n\n")

data_mentah <- read.csv(
  "data/raw/customer_behavior.csv",
  stringsAsFactors = FALSE,
  fileEncoding = "UTF-8"
)

kolom_model <- c(
  "Lifetime_Value",
  "Total_Purchases",
  "Average_Order_Value",
  "Discount_Usage_Rate"
)

kolom_hilang <- setdiff(kolom_model, names(data_mentah))
if (length(kolom_hilang) > 0) {
  stop("Kolom wajib tidak ditemukan: ", paste(kolom_hilang, collapse = ", "))
}

baris_awal <- nrow(data_mentah)
cat("Baris awal:", baris_awal, "\n")

ke_numerik <- function(x) {
  if (is.numeric(x)) {
    x
  } else {
    suppressWarnings(as.numeric(as.character(x)))
  }
}

data_mentah[kolom_model] <- lapply(data_mentah[kolom_model], ke_numerik)

na_model <- vapply(
  data_mentah[kolom_model],
  function(x) sum(is.na(x)),
  integer(1)
)
cat("\nJumlah NA pada variabel model sebelum penyaringan:\n")
print(na_model)

baris_lengkap <- stats::complete.cases(data_mentah[, kolom_model, drop = FALSE])
data_bersih <- data_mentah[baris_lengkap, , drop = FALSE]
rownames(data_bersih) <- NULL

baris_final <- nrow(data_bersih)
baris_dibuang <- baris_awal - baris_final

cat("\nBaris final:", baris_final, "\n")
cat("Baris dibuang karena NA pada variabel model:", baris_dibuang, "\n")

if (baris_final == 0) {
  stop("Tidak ada baris lengkap pada variabel model.")
}

write.csv(
  data_bersih,
  "data/processed/customer_behavior_clean.csv",
  row.names = FALSE
)
cat("Tersimpan: data/processed/customer_behavior_clean.csv\n")

cat("\nStatistika deskriptif\n")

modus_manual <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) {
    return(NA_real_)
  }
  tabel <- table(x)
  as.numeric(names(tabel)[which.max(tabel)])
}

statistik_satu <- function(x, nama) {
  x <- x[!is.na(x)]
  kuartil <- stats::quantile(
    x,
    probs = c(0.25, 0.5, 0.75),
    na.rm = TRUE,
    names = FALSE
  )
  data.frame(
    variabel = nama,
    n = length(x),
    mean = mean(x),
    median = stats::median(x),
    modus = modus_manual(x),
    varians = stats::var(x),
    sd = stats::sd(x),
    min = min(x),
    q1 = kuartil[1],
    q2 = kuartil[2],
    q3 = kuartil[3],
    max = max(x),
    stringsAsFactors = FALSE
  )
}

deskriptif <- do.call(
  rbind,
  lapply(kolom_model, function(v) statistik_satu(data_bersih[[v]], v))
)
rownames(deskriptif) <- NULL

deskriptif_tampil <- deskriptif
kolom_dibulatkan <- setdiff(names(deskriptif), c("variabel", "n"))
deskriptif_tampil[kolom_dibulatkan] <- lapply(
  deskriptif_tampil[kolom_dibulatkan],
  round,
  3
)
print(deskriptif_tampil, row.names = FALSE)

write.csv(
  deskriptif,
  "output/tables/statistik_deskriptif.csv",
  row.names = FALSE
)
cat("Tersimpan: output/tables/statistik_deskriptif.csv\n")

cat("\nKorelasi Pearson\n")
matriks_korelasi <- stats::cor(
  data_bersih[, kolom_model, drop = FALSE],
  use = "complete.obs",
  method = "pearson"
)
print(round(matriks_korelasi, 4))
write.csv(matriks_korelasi, "output/tables/korelasi.csv", row.names = TRUE)
cat("Tersimpan: output/tables/korelasi.csv\n")

cat("\nScatter plot\n")
pasangan_scatter <- list(
  list(
    x = "Total_Purchases",
    file = "scatter_purchases_y.png",
    judul = "Total Purchases dan Lifetime Value",
    label = "Total Purchases (X1)"
  ),
  list(
    x = "Average_Order_Value",
    file = "scatter_order_value_y.png",
    judul = "Average Order Value dan Lifetime Value",
    label = "Average Order Value (X2)"
  ),
  list(
    x = "Discount_Usage_Rate",
    file = "scatter_discount_y.png",
    judul = "Discount Usage Rate dan Lifetime Value",
    label = "Discount Usage Rate (X3)"
  )
)

for (p in pasangan_scatter) {
  plot_scatter <- ggplot(
    data_bersih,
    aes(x = .data[[p$x]], y = .data[["Lifetime_Value"]])
  ) +
    geom_point(alpha = 0.2, size = 0.6, colour = "#2C6E8F") +
    geom_smooth(
      method = "lm",
      formula = y ~ x,
      se = FALSE,
      colour = "#C0392B",
      linewidth = 0.8
    ) +
    labs(
      title = p$judul,
      x = p$label,
      y = "Lifetime Value (Y)"
    ) +
    theme_minimal(base_size = 11)

  ggsave(
    file.path("output/plots", p$file),
    plot_scatter,
    width = 8,
    height = 5.5,
    dpi = 120
  )
  cat("Tersimpan: output/plots/", p$file, "\n", sep = "")
}

cat("\nRegresi linear sederhana\n")
model_sederhana <- lm(
  Lifetime_Value ~ Total_Purchases,
  data = data_bersih
)
ringkasan_sederhana <- capture.output(print(summary(model_sederhana)))
cat(ringkasan_sederhana, sep = "\n")
cat("\n")
writeLines(
  c(
    "REGRESI LINEAR SEDERHANA",
    "Formula: Lifetime_Value ~ Total_Purchases",
    "",
    ringkasan_sederhana
  ),
  "output/tables/regresi_sederhana.txt"
)
cat("Tersimpan: output/tables/regresi_sederhana.txt\n")

cat("\nRegresi linear berganda\n")
model_berganda <- lm(
  Lifetime_Value ~ Total_Purchases + Average_Order_Value + Discount_Usage_Rate,
  data = data_bersih
)
ringkasan_berganda <- capture.output(print(summary(model_berganda)))
cat(ringkasan_berganda, sep = "\n")
cat("\n")
writeLines(
  c(
    "REGRESI LINEAR BERGANDA",
    "Formula: Lifetime_Value ~ Total_Purchases + Average_Order_Value + Discount_Usage_Rate",
    "",
    ringkasan_berganda
  ),
  "output/tables/regresi_berganda.txt"
)
cat("Tersimpan: output/tables/regresi_berganda.txt\n")

r2_berganda <- summary(model_berganda)$r.squared
r2_adjusted <- summary(model_berganda)$adj.r.squared
cat(sprintf("R-squared model berganda: %.6f\n", r2_berganda))
cat(sprintf("R-squared adjusted model berganda: %.6f\n", r2_adjusted))

cat("\nUji asumsi\n")
nilai_vif <- car::vif(model_berganda)
teks_vif <- capture.output(print(nilai_vif))
cat("Multikolinearitas dengan VIF:\n")
cat(teks_vif, sep = "\n")
cat("\n")

residu <- stats::residuals(model_berganda)
set.seed(123)
ukuran_shapiro <- min(5000L, length(residu))
sampel_residu <- sample(residu, size = ukuran_shapiro, replace = FALSE)
uji_normal <- stats::shapiro.test(sampel_residu)
teks_normal <- capture.output(print(uji_normal))
cat("Normalitas residual dengan Shapiro-Wilk:\n")
cat("Ukuran sampel:", ukuran_shapiro, "\n")
cat(teks_normal, sep = "\n")
cat("\n")

uji_hetero <- lmtest::bptest(model_berganda)
teks_hetero <- capture.output(print(uji_hetero))
cat("Heteroskedastisitas dengan Breusch-Pagan:\n")
cat(teks_hetero, sep = "\n")
cat("\n")

writeLines(
  c(
    "UJI ASUMSI MODEL REGRESI BERGANDA",
    "",
    "Multikolinearitas dengan VIF:",
    teks_vif,
    "",
    paste(
      "Normalitas residual dengan Shapiro-Wilk, sampel acak n =",
      ukuran_shapiro,
      ":"
    ),
    teks_normal,
    "",
    "Heteroskedastisitas dengan Breusch-Pagan:",
    teks_hetero
  ),
  "output/tables/uji_asumsi.txt"
)
cat("Tersimpan: output/tables/uji_asumsi.txt\n")

cat("\nPrediksi tiga skenario\n")
kuantil_x1 <- stats::quantile(
  data_bersih$Total_Purchases,
  probs = c(0.25, 0.5, 0.75),
  names = FALSE
)
kuantil_x2 <- stats::quantile(
  data_bersih$Average_Order_Value,
  probs = c(0.25, 0.5, 0.75),
  names = FALSE
)
kuantil_x3 <- stats::quantile(
  data_bersih$Discount_Usage_Rate,
  probs = c(0.25, 0.5, 0.75),
  names = FALSE
)

data_skenario <- data.frame(
  Total_Purchases = kuantil_x1,
  Average_Order_Value = kuantil_x2,
  Discount_Usage_Rate = kuantil_x3
)
prediksi <- stats::predict(
  model_berganda,
  newdata = data_skenario,
  interval = "confidence",
  level = 0.95
)
tabel_prediksi <- data.frame(
  skenario = c("Rendah", "Menengah", "Tinggi"),
  total_purchases = data_skenario$Total_Purchases,
  average_order_value = data_skenario$Average_Order_Value,
  discount_usage_rate = data_skenario$Discount_Usage_Rate,
  prediksi = prediksi[, "fit"],
  batas_bawah_95 = prediksi[, "lwr"],
  batas_atas_95 = prediksi[, "upr"],
  stringsAsFactors = FALSE
)
print(tabel_prediksi, row.names = FALSE)
write.csv(
  tabel_prediksi,
  "output/tables/prediksi.csv",
  row.names = FALSE
)
cat("Tersimpan: output/tables/prediksi.csv\n")

cat("\nPlot tambahan\n")
plot_hist <- ggplot(data_bersih, aes(x = Lifetime_Value)) +
  geom_histogram(
    bins = 60,
    fill = "#2C6E8F",
    colour = "white",
    linewidth = 0.2
  ) +
  labs(
    title = "Distribusi Lifetime Value",
    x = "Lifetime Value (Y)",
    y = "Frekuensi"
  ) +
  theme_minimal(base_size = 11)
ggsave(
  "output/plots/hist_y.png",
  plot_hist,
  width = 8,
  height = 5.5,
  dpi = 120
)
cat("Tersimpan: output/plots/hist_y.png\n")

plot_box <- ggplot(data_bersih, aes(y = Lifetime_Value)) +
  geom_boxplot(
    fill = "#A8C6D4",
    outlier.colour = "#C0392B",
    outlier.size = 0.7
  ) +
  labs(
    title = "Boxplot Lifetime Value",
    y = "Lifetime Value (Y)"
  ) +
  theme_minimal(base_size = 11)
ggsave(
  "output/plots/box_y.png",
  plot_box,
  width = 5,
  height = 6,
  dpi = 120
)
cat("Tersimpan: output/plots/box_y.png\n")

plot_residual <- ggplot(
  data.frame(
    fitted = stats::fitted(model_berganda),
    residual = residu
  ),
  aes(x = fitted, y = residual)
) +
  geom_point(alpha = 0.2, size = 0.6, colour = "#2C6E8F") +
  geom_hline(
    yintercept = 0,
    linetype = "dashed",
    colour = "#C0392B"
  ) +
  labs(
    title = "Residual dan Nilai Fitted",
    x = "Nilai fitted",
    y = "Residual"
  ) +
  theme_minimal(base_size = 11)
ggsave(
  "output/plots/residual_vs_fitted.png",
  plot_residual,
  width = 8,
  height = 5.5,
  dpi = 120
)
cat("Tersimpan: output/plots/residual_vs_fitted.png\n")

png("output/plots/qq_plot.png", width = 1600, height = 1200, res = 200)
stats::qqnorm(residu, main = "QQ-Plot Residual Model Berganda")
stats::qqline(residu, col = "#C0392B", lwd = 1.5)
dev.off()
cat("Tersimpan: output/plots/qq_plot.png\n")

cat("\nRingkasan akhir\n")
cat("Baris awal:", baris_awal, "\n")
cat("Baris final:", baris_final, "\n")
cat("Baris dibuang:", baris_dibuang, "\n")
cat(sprintf("R-squared model berganda: %.6f\n", r2_berganda))
cat("Analisis selesai.\n")

sink()
close(log_file)