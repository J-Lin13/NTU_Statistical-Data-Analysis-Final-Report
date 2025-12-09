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
library(tidyr)  # 用於 separate_rows 函數

# ============================================================================
# 工作目錄設定（重要！）
# ============================================================================
# 在執行此腳本前，請確保工作目錄設定為專案根目錄
# 如果無法自動判斷，請手動執行：
#   setwd("C:/Users/User/OneDrive/Desktop/NTU/商統分/NTU_Statistical-Data-Analysis-Final-Report")
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
      cat("  setwd('C:/Users/User/OneDrive/Desktop/NTU/商統分/NTU_Statistical-Data-Analysis-Final-Report')\n")
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
  cat("  setwd('C:/Users/User/OneDrive/Desktop/NTU/商統分/NTU_Statistical-Data-Analysis-Final-Report')\n")
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

# 基本資料統計（唯一值統計）
cat("基本資料統計（唯一值）：\n")
cat("=", rep("=", 79), "\n", sep = "")

# 總訂單數
if ("order_id" %in% names(data)) {
  total_orders <- length(unique(data$order_id))
  cat(sprintf("總訂單數（唯一 order_id）: %s\n", format(total_orders, big.mark = ",")))
}

# 總評論數
if ("review_id" %in% names(data)) {
  total_reviews <- length(unique(data$review_id))
  cat(sprintf("總評論數（唯一 review_id）: %s\n", format(total_reviews, big.mark = ",")))
}

# 總顧客數（unique_id）
if ("customer_unique_id" %in% names(data)) {
  total_customers <- length(unique(data$customer_unique_id))
  cat(sprintf("總顧客數（唯一 customer_unique_id）: %s\n", format(total_customers, big.mark = ",")))
}

# 總商品種類數（從 product_ids 展開）
if ("product_ids" %in% names(data)) {
  # 展開所有 product_ids 並計算唯一值
  all_product_ids <- data %>%
    filter(!is.na(product_ids) & product_ids != "") %>%
    select(product_ids) %>%
    separate_rows(product_ids, sep = ",") %>%
    mutate(product_ids = trimws(product_ids)) %>%
    filter(product_ids != "") %>%
    distinct(product_ids)
  
  total_products <- nrow(all_product_ids)
  cat(sprintf("總商品種類數（從 product_ids 展開後去重）: %s\n", format(total_products, big.mark = ",")))
}

# 總商品類別數
if ("product_category_name_english" %in% names(data)) {
  total_categories <- length(unique(data$product_category_name_english[!is.na(data$product_category_name_english)]))
  cat(sprintf("總商品類別數（唯一 product_category_name_english）: %s\n", format(total_categories, big.mark = ",")))
}

# 總賣家數
if ("primary_seller_id" %in% names(data)) {
  total_sellers <- length(unique(data$primary_seller_id[!is.na(data$primary_seller_id)]))
  cat(sprintf("總賣家數（唯一 primary_seller_id）: %s\n", format(total_sellers, big.mark = ",")))
}

# 總城市數（顧客）
if ("customer_city" %in% names(data)) {
  total_customer_cities <- length(unique(data$customer_city[!is.na(data$customer_city)]))
  cat(sprintf("總顧客城市數（唯一 customer_city）: %s\n", format(total_customer_cities, big.mark = ",")))
}

# 總州數（顧客）
if ("customer_state" %in% names(data)) {
  total_customer_states <- length(unique(data$customer_state[!is.na(data$customer_state)]))
  cat(sprintf("總顧客州數（唯一 customer_state）: %s\n", format(total_customer_states, big.mark = ",")))
}

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
# 以離散等級 1~5 的次數統計繪製長條圖（避免連續區間分箱）
counts <- table(factor(data$review_score, levels = 1:5))
max_count <- max(counts, na.rm = TRUE)
bp <- barplot(counts,
              main = "Distribution of Review Score",
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
cat("✓ 已儲存至: plots/review_score_histogram.png\n\n")

# 繪製箱線圖
cat("生成箱線圖...\n")
png("plots/review_score_boxplot.png", width = 800, height = 600)
boxplot(data$review_score,
        main = "Review Score Boxplot",
        ylab = "Review Score",
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
            main = sprintf("%s Boxplot", var),
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
    # 預先取得分箱與計數以便標示數字並調整 y 軸
    x <- data[[var]]
    h <- hist(x, plot = FALSE)
    hist(x,
         breaks = h$breaks,
         main = sprintf("%s Distribution", var),
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
      png(sprintf("plots/%s_histogram_log.png", var), width = 800, height = 600)
      hlog <- hist(x_log, plot = FALSE)
      hist(x_log,
           breaks = hlog$breaks,
           main = sprintf("%s Distribution (log scale)", var),
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
png("plots/delivery_gap_vs_review_score.png", width = 800, height = 600)
plot(data$delivery_gap, data$review_score,
     main = "Delivery Gap vs Review Score",
     xlab = "Delivery Gap (days)",
     ylab = "Review Score",
     pch = 19,
     col = rgb(0, 0, 1, 0.3))
abline(lm(review_score ~ delivery_gap, data = data), col = "red", lwd = 2)
dev.off()
cat("✓ delivery_gap vs review_score 散點圖已儲存\n")

# price vs review_score
png("plots/price_vs_review_score.png", width = 800, height = 600)
plot(log10(data$price + 1), data$review_score,
     main = "Log Price vs Review Score",
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

# order_status 分析
if ("order_status" %in% names(data)) {
  cat("訂單狀態分布：\n")
  order_status_dist <- data %>%
    count(order_status, sort = TRUE) %>%
    mutate(percentage = round(n / nrow(data) * 100, 2))
  print(order_status_dist)
  cat("\n")
}

# payment_type 分布
if ("payment_type" %in% names(data)) {
  cat("付款方式分布：\n")
  print(table(data$payment_type))
  cat("\n")
}

# product_category_name 前 10 大類別（葡萄牙文版本）
if ("product_category_name" %in% names(data)) {
  cat("前 10 大商品類別（主要類別 - 葡萄牙文）：\n")
  top_categories_pt <- data %>%
    count(product_category_name, sort = TRUE) %>%
    head(10) %>%
    mutate(percentage = round(n / nrow(data) * 100, 2))
  print(top_categories_pt)
  cat("\n")
}

# product_category_name_english 前 10 大類別（英文版本）
if ("product_category_name_english" %in% names(data)) {
  cat("前 10 大商品類別（主要類別 - 英文）：\n")
  top_categories <- data %>%
    count(product_category_name_english, sort = TRUE) %>%
    head(10) %>%
    mutate(percentage = round(n / nrow(data) * 100, 2))
  print(top_categories)
  cat("\n")
}

# customer_city 分析
if ("customer_city" %in% names(data)) {
  cat("顧客城市分布：\n")
  cat(sprintf("  總城市數: %d\n", length(unique(data$customer_city))))
  cat("\n前 10 大城市（按訂單數）：\n")
  top_cities <- data %>%
    count(customer_city, sort = TRUE) %>%
    head(10) %>%
    mutate(percentage = round(n / nrow(data) * 100, 2))
  print(top_cities)
  cat("\n")
}

# customer_state 分析
if ("customer_state" %in% names(data)) {
  cat("顧客州別分布：\n")
  cat(sprintf("  總州數: %d\n", length(unique(data$customer_state))))
  cat("\n各州訂單數分布：\n")
  state_dist <- data %>%
    count(customer_state, sort = TRUE) %>%
    mutate(percentage = round(n / nrow(data) * 100, 2))
  print(state_dist)
  cat("\n")
  
  # 生成州別分布圖
  if (nrow(state_dist) > 0 && nrow(state_dist) <= 30) {
    png("plots/customer_state_distribution.png", width = 1000, height = 600)
    par(mar = c(5, 8, 4, 2))
    barplot(rev(state_dist$n), 
            names.arg = rev(state_dist$customer_state),
            horiz = TRUE,
            las = 1,
            main = "Distribution of Orders by Customer State",
            xlab = "Number of Orders",
            col = "steelblue")
    dev.off()
    cat("✓ 州別分布圖已儲存：plots/customer_state_distribution.png\n\n")
  }
}

# product_ids 分析（逗號分隔的商品ID字串）
if ("product_ids" %in% names(data)) {
  cat("商品ID分析（product_ids）：\n")
  # 計算每筆訂單的商品ID數量
  data <- data %>%
    mutate(
      num_product_ids = ifelse(is.na(product_ids) | product_ids == "", 
                               0, 
                               lengths(strsplit(product_ids, ",")))
    )
  
  cat("每筆訂單的商品ID數量統計：\n")
  cat(sprintf("  平均數: %.2f\n", mean(data$num_product_ids, na.rm = TRUE)))
  cat(sprintf("  中位數: %.0f\n", median(data$num_product_ids, na.rm = TRUE)))
  cat(sprintf("  最大值: %.0f\n", max(data$num_product_ids, na.rm = TRUE)))
  cat(sprintf("  最小值: %.0f\n", min(data$num_product_ids, na.rm = TRUE)))
  cat("\n商品ID數量分布：\n")
  print(table(data$num_product_ids))
  cat("\n")
}

# product_categories 分析（逗號分隔的商品類別字串）
if ("product_categories" %in% names(data)) {
  cat("商品類別分析（product_categories）：\n")
  # 計算每筆訂單的商品類別數量
  data <- data %>%
    mutate(
      num_product_categories = ifelse(is.na(product_categories) | product_categories == "", 
                                      0, 
                                      lengths(strsplit(product_categories, ",")))
    )
  
  cat("每筆訂單的商品類別數量統計：\n")
  cat(sprintf("  平均數: %.2f\n", mean(data$num_product_categories, na.rm = TRUE)))
  cat(sprintf("  中位數: %.0f\n", median(data$num_product_categories, na.rm = TRUE)))
  cat(sprintf("  最大值: %.0f\n", max(data$num_product_categories, na.rm = TRUE)))
  cat(sprintf("  最小值: %.0f\n", min(data$num_product_categories, na.rm = TRUE)))
  cat("\n商品類別數量分布：\n")
  print(table(data$num_product_categories))
  cat("\n")
  
  # 展開所有商品類別並統計
  cat("所有出現的商品類別（從 product_categories 展開）：\n")
  all_categories <- data %>%
    filter(!is.na(product_categories) & product_categories != "") %>%
    select(product_categories) %>%
    separate_rows(product_categories, sep = ",") %>%
    mutate(product_categories = trimws(product_categories)) %>%
    filter(product_categories != "") %>%
    count(product_categories, sort = TRUE)
  
  cat(sprintf("  總類別數（去重後）: %d\n", nrow(all_categories)))
  cat("\n前 15 大商品類別（按出現次數）：\n")
  print(head(all_categories, 15))
  cat("\n")
  
  # 生成前 15 大類別分布圖
  if (nrow(all_categories) > 0) {
    top_15_cats <- head(all_categories, 15)
    png("plots/product_categories_top15.png", width = 1000, height = 600)
    par(mar = c(5, 10, 4, 2))
    barplot(rev(top_15_cats$n),
            names.arg = rev(top_15_cats$product_categories),
            horiz = TRUE,
            las = 1,
            main = "Top 15 Product Categories",
            xlab = "Frequency",
            col = "steelblue")
    dev.off()
    cat("✓ 前 15 大商品類別分布圖已儲存：plots/product_categories_top15.png\n\n")
  }
}

# primary_seller_city 分析（賣家城市）
if ("primary_seller_city" %in% names(data)) {
  cat("賣家城市分布（primary_seller_city）：\n")
  seller_city_valid <- data %>% filter(!is.na(primary_seller_city))
  cat(sprintf("  總城市數: %d\n", length(unique(seller_city_valid$primary_seller_city))))
  cat(sprintf("  有效記錄數: %d (%.2f%%)\n", 
              nrow(seller_city_valid), 
              round(nrow(seller_city_valid) / nrow(data) * 100, 2)))
  cat("\n前 10 大賣家城市（按訂單數）：\n")
  top_seller_cities <- seller_city_valid %>%
    count(primary_seller_city, sort = TRUE) %>%
    head(10) %>%
    mutate(percentage = round(n / nrow(seller_city_valid) * 100, 2))
  print(top_seller_cities)
  cat("\n")
}

# primary_seller_state 分析（賣家州別）
if ("primary_seller_state" %in% names(data)) {
  cat("賣家州別分布（primary_seller_state）：\n")
  seller_state_valid <- data %>% filter(!is.na(primary_seller_state))
  cat(sprintf("  總州數: %d\n", length(unique(seller_state_valid$primary_seller_state))))
  cat(sprintf("  有效記錄數: %d (%.2f%%)\n", 
              nrow(seller_state_valid), 
              round(nrow(seller_state_valid) / nrow(data) * 100, 2)))
  cat("\n各州賣家訂單數分布：\n")
  seller_state_dist <- seller_state_valid %>%
    count(primary_seller_state, sort = TRUE) %>%
    mutate(percentage = round(n / nrow(seller_state_valid) * 100, 2))
  print(seller_state_dist)
  cat("\n")
  
  # 生成賣家州別分布圖
  if (nrow(seller_state_dist) > 0 && nrow(seller_state_dist) <= 30) {
    png("plots/primary_seller_state_distribution.png", width = 1000, height = 600)
    par(mar = c(5, 8, 4, 2))
    barplot(rev(seller_state_dist$n), 
            names.arg = rev(seller_state_dist$primary_seller_state),
            horiz = TRUE,
            las = 1,
            main = "Distribution of Orders by Seller State",
            xlab = "Number of Orders",
            col = "lightcoral")
    dev.off()
    cat("✓ 賣家州別分布圖已儲存：plots/primary_seller_state_distribution.png\n\n")
  }
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
