# ============================================================================
# 敘述性統計分析腳本（非滿分子集 1~4 分）
# ============================================================================
# 目的：針對 preprocessed_data_non5.csv 進行敘述性統計並輸出圖表至 plots_non5/
# ============================================================================

library(dplyr)
library(ggplot2)
library(readr)

# 工作目錄處理（同主腳本）
original_wd <- getwd()
script_path <- NULL
tryCatch({
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    context <- rstudioapi::getSourceEditorContext()
    if (!is.null(context) && length(context$path) > 0 && context$path != "") {
      script_path <- context$path
    }
  }
}, error = function(e) {})
if (is.null(script_path) || script_path == "") {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd_args, value = TRUE)
  if (length(file_arg) > 0) {
    script_path <- sub("^--file=", "", file_arg)
  }
}
if (!is.null(script_path) && script_path != "" && file.exists(script_path)) {
  script_dir <- dirname(normalizePath(script_path))
  project_root <- dirname(script_dir)
  if (dir.exists(file.path(project_root, "data_preprocessing"))) {
    setwd(project_root)
    cat(sprintf("已自動設定工作目錄為專案根目錄: %s\n\n", project_root))
  }
}

# 設定輸出日誌
output_log_file <- file.path("descriptive_analysis", "descriptive_statistics_non5_output.txt")
sink(file = output_log_file, split = TRUE, type = "output")

cat("=", rep("=", 79), "\n", sep = "")
cat("非滿分子集 敘述性統計輸出日誌\n")
cat("執行時間：", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("=", rep("=", 79), "\n\n", sep = "")

# ============================================================================
# 步驟 1: 載入清理後的資料
# ============================================================================

cat("步驟 1: 載入清理後的資料（非滿分子集）\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

non5_path <- "data_preprocessing/preprocessed_data_non5.csv"

if (!file.exists(non5_path)) {
  cat("錯誤：找不到資料檔案！\n")
  cat("預期路徑: ", file.path(getwd(), non5_path), "\n")
  cat("當前工作目錄: ", getwd(), "\n")
  stop("請先執行 data_preprocessing/preprocessing.py 產出非滿分子集資料！")
}

cat(sprintf("資料檔案路徑: %s\n", normalizePath(non5_path)))
data <- read_csv(non5_path, 
                 locale = locale(encoding = "UTF-8"),
                 show_col_types = FALSE)

cat(sprintf("✓ 資料載入完成：%s 筆記錄，%d 個欄位\n\n", 
            format(nrow(data), big.mark = ","), ncol(data)))

# ============================================================================
# 步驟 2: 基本統計摘要
# ============================================================================

cat("步驟 2: 基本統計摘要\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

# 整體資料摘要
cat("整體資料摘要：\n")
print(summary(data))
cat("\n")

# ============================================================================
# 步驟 3: 應變數（review_score）分析
# ============================================================================

cat("步驟 3: 應變數（review_score）分析\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

# 基本統計
cat("評論分數（review_score）基本統計：\n")
cat(sprintf("  平均數: %.2f\n", mean(data$review_score)))
cat(sprintf("  中位數: %.2f\n", median(data$review_score)))
cat(sprintf("  標準差: %.2f\n", sd(data$review_score)))
cat(sprintf("  最小值: %.0f\n", min(data$review_score)))
cat(sprintf("  最大值: %.0f\n", max(data$review_score)))
cat("\n")

# 分布
cat("評論分數分布：\n")
review_dist <- table(data$review_score)
print(review_dist)
cat("\n比例分布：\n")
print(round(prop.table(review_dist) * 100, 2))
cat("\n")

# 建立 plots_non5 資料夾（如果不存在）
plots_dir <- "plots_non5"
if (!dir.exists(plots_dir)) {
  dir.create(plots_dir)
}

# 繪製直方圖
cat("生成直方圖...\n")
png(file.path(plots_dir, "review_score_histogram.png"), width = 800, height = 600)
# 以離散等級 1~5 的次數統計繪製長條圖（避免連續區間分箱）
counts <- table(factor(data$review_score, levels = 1:5))
max_count <- max(counts, na.rm = TRUE)
bp <- barplot(counts,
              main = "Distribution of Review Score (non-5 subset)",
              xlab = "Review Score",
              ylab = "Count",
              col = "steelblue",
              border = "white",
              ylim = c(0, max_count * 1.15))
# 在每根長條上方標示數值
text(x = bp, y = counts, 
     labels = format(as.numeric(counts), big.mark = ","), 
     pos = 3, cex = 1.0, col = "black")
dev.off()
cat("✓ 已儲存至: plots_non5/review_score_histogram.png\n\n")

# 繪製箱線圖
cat("生成箱線圖...\n")
png(file.path(plots_dir, "review_score_boxplot.png"), width = 800, height = 600)
boxplot(data$review_score,
        main = "Review Score Boxplot (non-5 subset)",
        ylab = "Review Score",
        col = "lightblue")
dev.off()
cat("✓ 已儲存至: plots_non5/review_score_boxplot.png\n\n")

# ============================================================================
# 步驟 4: 主要數值變數分析
# ============================================================================

cat("步驟 4: 主要數值變數分析\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

# 定義主要變數
main_vars <- c("delivery_days", "delivery_gap", "price", "freight_value",
               "product_weight_g", "product_photos_qty", "payment_installments")

cat("主要數值變數統計摘要：\n")
print(summary(data[main_vars]))
cat("\n")

# 為每個變數生成箱線圖（檢查異常值）
cat("生成箱線圖（檢查異常值）...\n")
for (var in main_vars) {
  if (var %in% names(data)) {
    png(file.path(plots_dir, sprintf("%s_boxplot.png", var)), width = 800, height = 600)
    boxplot(data[[var]],
            main = sprintf("%s Boxplot (non-5 subset)", var),
            ylab = var,
            col = "lightcoral")
    dev.off()
    cat(sprintf("  ✓ %s 箱線圖已儲存\n", var))
  }
}
cat("\n")

# 為每個變數生成直方圖（檢查分布）
cat("生成直方圖（檢查分布）...\n")
for (var in main_vars) {
  if (var %in% names(data)) {
    png(file.path(plots_dir, sprintf("%s_histogram.png", var)), width = 800, height = 600)
    # 預先取得分箱與計數以便標示數字並調整 y 軸
    x <- data[[var]]
    h <- hist(x, plot = FALSE)
    hist(x,
         breaks = h$breaks,
         main = sprintf("%s Distribution (non-5 subset)", var),
         xlab = var,
         ylab = "Frequency",
         col = "steelblue",
         border = "white",
         ylim = c(0, max(h$counts, na.rm = TRUE) * 1.15))
    if (length(h$mids) == length(h$counts) && length(h$counts) > 0) {
      text(x = h$mids, y = h$counts,
           labels = ifelse(h$counts > 0, format(h$counts, big.mark = ","), ""),
           pos = 3, cex = 0.9, col = "black")
    }
    dev.off()
    cat(sprintf("  ✓ %s 直方圖已儲存\n", var))

    # 若變數為非負，另外輸出 log 版本（log1p）
    x_min <- suppressWarnings(min(x, na.rm = TRUE))
    if (is.finite(x_min) && x_min >= 0) {
      x_log <- log1p(x)
      png(file.path(plots_dir, sprintf("%s_histogram_log.png", var)), width = 800, height = 600)
      hlog <- hist(x_log, plot = FALSE)
      hist(x_log,
           breaks = hlog$breaks,
           main = sprintf("%s Distribution (log scale, non-5 subset)", var),
           xlab = sprintf("%s (log1p)", var),
           ylab = "Frequency",
           col = "steelblue",
           border = "white",
           ylim = c(0, max(hlog$counts, na.rm = TRUE) * 1.15))
      if (length(hlog$mids) == length(hlog$counts) && length(hlog$counts) > 0) {
        text(x = hlog$mids, y = hlog$counts,
             labels = ifelse(hlog$counts > 0, format(hlog$counts, big.mark = ","), ""),
             pos = 3, cex = 0.9, col = "black")
      }
      dev.off()
      cat(sprintf("  ✓ %s 直方圖（log）已儲存\n", var))
    }
  }
}
cat("\n")

# ============================================================================
# 步驟 5: 變數間關係探索
# ============================================================================

cat("步驟 5: 變數間關係探索\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

# 計算相關係數（數值變數）
cat("數值變數相關係數矩陣：\n")
numeric_data <- data %>%
  select(all_of(c("review_score", main_vars))) %>%
  select_if(is.numeric)

cor_matrix <- cor(numeric_data, use = "complete.obs")
print(round(cor_matrix, 3))
cat("\n")

# 繪製散點圖（重要關係）
cat("生成重要變數關係散點圖...\n")

# delivery_gap vs review_score
png(file.path(plots_dir, "delivery_gap_vs_review_score.png"), width = 800, height = 600)
plot(data$delivery_gap, data$review_score,
     main = "Delivery Gap vs Review Score (non-5 subset)",
     xlab = "Delivery Gap (days)",
     ylab = "Review Score",
     pch = 19,
     col = rgb(0, 0, 1, 0.3))
abline(lm(review_score ~ delivery_gap, data = data), col = "red", lwd = 2)
dev.off()
cat("✓ delivery_gap vs review_score 散點圖已儲存\n")

# price vs review_score
png(file.path(plots_dir, "price_vs_review_score.png"), width = 800, height = 600)
plot(log10(data$price + 1), data$review_score,
     main = "Log Price vs Review Score (non-5 subset)",
     xlab = "Price (log10)",
     ylab = "Review Score",
     pch = 19,
     col = rgb(0, 0, 1, 0.3))
abline(lm(review_score ~ log10(price + 1), data = data), col = "red", lwd = 2)
dev.off()
cat("✓ price vs review_score 散點圖已儲存\n\n")

# ============================================================================
# 步驟 6: 類別變數分析
# ============================================================================

cat("步驟 6: 類別變數分析\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

# payment_type 分布
if ("payment_type" %in% names(data)) {
  cat("付款方式分布：\n")
  print(table(data$payment_type))
  cat("\n")
}

# product_category_name 前 10 大類別
if ("product_category_name_english" %in% names(data)) {
  cat("前 10 大商品類別：\n")
  top_categories <- data %>%
    count(product_category_name_english, sort = TRUE) %>%
    head(10)
  print(top_categories)
  cat("\n")
}

# ============================================================================
# 完成
# ============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("敘述性統計分析完成！（非滿分子集）\n")
cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("\n所有圖表已儲存至 plots_non5/ 資料夾\n")

# 結束輸出記錄
cat("\n執行完成時間：", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
sink()

cat("\n✓ 所有輸出已儲存至：", output_log_file, "\n")
cat("✓ 所有圖表已儲存至 plots_non5/ 資料夾\n")


