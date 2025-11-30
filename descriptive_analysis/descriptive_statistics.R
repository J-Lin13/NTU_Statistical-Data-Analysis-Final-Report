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

# ============================================================================
# 工作目錄設定（重要！）
# ============================================================================
# 在執行此腳本前，請確保工作目錄設定為專案根目錄
# 如果無法自動判斷，請手動執行：
#   setwd('C:\\Users\\User\\Downloads\\商統分\\NTU_Statistical-Data-Analysis-Final-Report')
# ============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("敘述性統計分析\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# ============================================================================
# 自動設定工作目錄（如果需要的話）
# ============================================================================

# 獲取當前工作目錄
original_wd <- getwd()

# 從腳本檔案路徑推導專案根目錄
# 腳本位於：專案根目錄/descriptive_analysis/descriptive_statistics.R
# 所以專案根目錄 = 腳本所在目錄的上一層

# 嘗試從 RStudio 獲取腳本路徑
script_path <- NULL
tryCatch({
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    context <- rstudioapi::getSourceEditorContext()
    if (!is.null(context) && length(context$path) > 0 && context$path != "") {
      script_path <- context$path
    }
  }
}, error = function(e) {})

# 如果無法從 RStudio 獲取，嘗試從命令列參數獲取
if (is.null(script_path) || script_path == "") {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd_args, value = TRUE)
  if (length(file_arg) > 0) {
    script_path <- sub("^--file=", "", file_arg)
  }
}

# 如果還是無法獲取，嘗試從 sys.frame 獲取（適用於 source() 情況）
if (is.null(script_path) || script_path == "") {
  tryCatch({
    # 嘗試從呼叫堆疊中獲取檔案路徑
    frames <- sys.frames()
    for (frame in frames) {
      if (!is.null(frame$ofile) && file.exists(frame$ofile)) {
        script_path <- frame$ofile
        break
      }
    }
  }, error = function(e) {})
}

# 從腳本路徑計算專案根目錄
if (!is.null(script_path) && script_path != "" && file.exists(script_path)) {
  script_dir <- dirname(normalizePath(script_path))
  project_root <- dirname(script_dir)  # 上一層就是專案根目錄
  
  # 驗證這是否真的是專案根目錄
  if (dir.exists(file.path(project_root, "data_preprocessing"))) {
    setwd(project_root)
    cat(sprintf("已自動設定工作目錄為專案根目錄: %s\n\n", project_root))
  } else {
    project_root <- NULL
  }
} else {
  project_root <- NULL
}

# 如果從腳本路徑無法找到，嘗試從當前工作目錄找
if (is.null(project_root)) {
  if (dir.exists("data_preprocessing")) {
    project_root <- getwd()
    cat(sprintf("當前工作目錄即為專案根目錄: %s\n\n", project_root))
  } else if (dir.exists("../data_preprocessing")) {
    project_root <- normalizePath("..")
    setwd(project_root)
    cat(sprintf("已自動設定工作目錄為專案根目錄: %s\n\n", project_root))
  } else {
    # 最後嘗試：從絕對路徑直接構建（假設腳本路徑包含完整路徑）
    if (!is.null(script_path) && script_path != "") {
      script_dir <- dirname(normalizePath(script_path))
      potential_root <- dirname(script_dir)
      if (dir.exists(file.path(potential_root, "data_preprocessing"))) {
        project_root <- potential_root
        setwd(project_root)
        cat(sprintf("已從腳本路徑自動設定工作目錄為專案根目錄: %s\n\n", project_root))
      }
    }
    
    if (is.null(project_root)) {
      cat("警告：無法自動找到專案根目錄\n")
      cat("當前工作目錄: ", original_wd, "\n")
      if (!is.null(script_path) && script_path != "") {
        cat("腳本路徑: ", script_path, "\n")
      }
      cat("\n請先設定工作目錄為專案根目錄：\n")
      cat("  setwd('C:\\\\Users\\\\User\\\\Downloads\\\\商統分\\\\NTU_Statistical-Data-Analysis-Final-Report')\n")
      cat("然後重新執行此腳本。\n\n")
    }
  }
}

cat("\n")

# ============================================================================
# 設定輸出日誌文件（保存所有輸出結果）
# ============================================================================

# 輸出文件路徑（保存在 descriptive_analysis 資料夾中，與腳本同目錄）
# 因為工作目錄已設定為專案根目錄，所以使用相對路徑
output_log_file <- file.path("descriptive_analysis", "descriptive_statistics_output.txt")

# 開始記錄輸出到文件（同時也會顯示在控制台）
sink(file = output_log_file, split = TRUE, type = "output")

cat("=", rep("=", 79), "\n", sep = "")
cat("敘述性統計分析輸出日誌\n")
cat("執行時間：", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("=", rep("=", 79), "\n\n", sep = "")

# ============================================================================
# 步驟 1: 載入清理後的資料
# ============================================================================

cat("步驟 1: 載入清理後的資料\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

# 載入資料（從專案根目錄）
data_path <- "data_preprocessing/preprocessed_data.csv"

if (!file.exists(data_path)) {
  cat("錯誤：找不到資料檔案！\n")
  cat("預期路徑: ", file.path(getwd(), data_path), "\n")
  cat("當前工作目錄: ", getwd(), "\n")
  cat("\n請確認：\n")
  cat("1. 工作目錄是否為專案根目錄\n")
  cat("2. 資料檔案是否存在於 data_preprocessing/preprocessed_data.csv\n")
  cat("\n解決方法：\n")
  cat("  setwd('C:\\\\Users\\\\User\\\\Downloads\\\\商統分\\\\NTU_Statistical-Data-Analysis-Final-Report')\n")
  stop("請先設定正確的工作目錄！")
}

cat(sprintf("資料檔案路徑: %s\n", normalizePath(data_path)))
data <- read_csv(data_path, 
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

# 建立 plots 資料夾（如果不存在）
if (!dir.exists("plots")) {
  dir.create("plots")
}

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

# 結束輸出記錄
cat("\n執行完成時間：", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
sink()

cat("\n✓ 所有輸出已儲存至：", output_log_file, "\n")
cat("✓ 所有圖表已儲存至 plots/ 資料夾\n")

