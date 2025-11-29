# ============================================================================
# 敘述性統計分析腳本
# ============================================================================
# 目的：對清理後的資料進行敘述性統計分析
# 符合 ReadMe.md 中的要求：使用 summary()、hist()、boxplot() 進行資料分析
# ============================================================================

# 載入必要的套件
library(dplyr)
library(ggplot2)
library(readr)

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("敘述性統計分析\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# ============================================================================
# 步驟 1: 載入清理後的資料
# ============================================================================

cat("步驟 1: 載入清理後的資料\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

# 載入資料（從 data_preprocessing 資料夾）
data <- read_csv("data_preprocessing/preprocessed_data.csv", 
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
summary(data)
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

# 繪製直方圖
cat("生成直方圖...\n")
png("plots/review_score_histogram.png", width = 800, height = 600)
hist(data$review_score, 
     breaks = 5,
     main = "評論分數分布（review_score）",
     xlab = "評論分數",
     ylab = "頻率",
     col = "steelblue",
     border = "white")
dev.off()
cat("✓ 已儲存至: plots/review_score_histogram.png\n\n")

# 繪製箱線圖
cat("生成箱線圖...\n")
png("plots/review_score_boxplot.png", width = 800, height = 600)
boxplot(data$review_score,
        main = "評論分數箱線圖（review_score）",
        ylab = "評論分數",
        col = "lightblue")
dev.off()
cat("✓ 已儲存至: plots/review_score_boxplot.png\n\n")

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

if (!dir.exists("plots")) {
  dir.create("plots")
}

for (var in main_vars) {
  if (var %in% names(data)) {
    png(sprintf("plots/%s_boxplot.png", var), width = 800, height = 600)
    boxplot(data[[var]],
            main = sprintf("%s 箱線圖", var),
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
    png(sprintf("plots/%s_histogram.png", var), width = 800, height = 600)
    hist(data[[var]],
         main = sprintf("%s 分布", var),
         xlab = var,
         ylab = "頻率",
         col = "steelblue",
         border = "white")
    dev.off()
    cat(sprintf("  ✓ %s 直方圖已儲存\n", var))
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
png("plots/delivery_gap_vs_review_score.png", width = 800, height = 600)
plot(data$delivery_gap, data$review_score,
     main = "送達差距與評論分數關係",
     xlab = "送達差距（天數）",
     ylab = "評論分數",
     pch = 19,
     col = rgb(0, 0, 1, 0.3))
abline(lm(review_score ~ delivery_gap, data = data), col = "red", lwd = 2)
dev.off()
cat("✓ delivery_gap vs review_score 散點圖已儲存\n")

# price vs review_score
png("plots/price_vs_review_score.png", width = 800, height = 600)
plot(log10(data$price + 1), data$review_score,
     main = "商品價格（對數尺度）與評論分數關係",
     xlab = "價格（log10）",
     ylab = "評論分數",
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
cat("敘述性統計分析完成！\n")
cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("\n所有圖表已儲存至 plots/ 資料夾\n")

