# ============================================================================
# 巴西 Olist 電商平台資料前處理腳本
# ============================================================================
# 目的：清理和檢查合併後的資料，為後續統計分析做準備
# 
# 主要步驟：
# 1. 載入資料與基本檢視
# 2. 處理缺失值
# 3. 檢查與處理異常值
# 4. 處理重複資料
# 5. 建立衍生變數
# 6. 變數類型轉換
# 7. 資料分布檢查
# 8. 資料篩選
# 9. 儲存清理後的資料
# ============================================================================

# 載入必要的套件
library(dplyr)
library(readr)
library(ggplot2)
library(tidyr)  # 用於資料整理（gather 函數）
# library(VIM)  # 用於視覺化缺失值（可選，需要安裝）

# ============================================================================
# 步驟 1: 載入資料與基本檢視
# ============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("步驟 1: 載入資料與基本檢視\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# 載入合併後的資料（從 sql_merge 資料夾）
data_raw <- read_csv("../sql_merge/merged_olist_data.csv", 
                     locale = locale(encoding = "UTF-8"),
                     show_col_types = FALSE)

# 建立資料副本（保留原始資料）
data <- data_raw

cat("✓ 資料載入完成\n")
cat(sprintf("原始資料筆數: %s\n", format(nrow(data), big.mark = ",")))
cat(sprintf("原始資料欄位數: %d\n\n", ncol(data)))

# 檢視資料結構
cat("資料結構：\n")
str(data, give.attr = FALSE)
cat("\n")

# 檢視前幾筆資料
cat("前 5 筆資料：\n")
print(head(data, 5))
cat("\n")

# 基本統計摘要
cat("基本統計摘要：\n")
summary(data)
cat("\n")

# ============================================================================
# 步驟 2: 處理缺失值
# ============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("步驟 2: 處理缺失值\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# 檢查缺失值
missing_summary <- data %>%
  summarise_all(~ sum(is.na(.))) %>%
  gather(key = "variable", value = "missing_count") %>%
  arrange(desc(missing_count))

cat("各欄位缺失值統計：\n")
print(missing_summary)
cat("\n")

# 計算缺失比例
missing_summary <- missing_summary %>%
  mutate(missing_percentage = round(missing_count / nrow(data) * 100, 2))

cat("缺失值比例：\n")
print(filter(missing_summary, missing_count > 0))
cat("\n")

# 處理缺失值的策略
cat("處理缺失值...\n")

# 2.1 刪除關鍵變數缺失的記錄
cat("  - 刪除應變數（review_score）缺失的記錄\n")
data <- data %>%
  filter(!is.na(review_score))

cat(sprintf("    剩餘筆數: %s\n", format(nrow(data), big.mark = ",")))

# 2.2 處理物流變數的缺失值
cat("  - 處理物流變數（delivery_days, delivery_gap）缺失\n")
data <- data %>%
  filter(!is.na(delivery_days), !is.na(delivery_gap))

cat(sprintf("    剩餘筆數: %s\n", format(nrow(data), big.mark = ",")))

# 2.3 處理交易成本變數的缺失值
cat("  - 處理交易成本變數（price, freight_value）缺失\n")
data <- data %>%
  filter(!is.na(price), !is.na(freight_value))

cat(sprintf("    剩餘筆數: %s\n", format(nrow(data), big.mark = ",")))

# 2.4 處理商品屬性變數的缺失值
cat("  - 處理商品屬性變數缺失\n")

# 商品類別缺失：新增「未知」類別
data <- data %>%
  mutate(
    product_category_name = ifelse(is.na(product_category_name), 
                                   "unknown", 
                                   product_category_name),
    product_category_name_english = ifelse(is.na(product_category_name_english), 
                                           "unknown", 
                                           product_category_name_english)
  )

# 商品重量：如果缺失，用中位數填補（保留商品類別的中位數）
if (sum(is.na(data$product_weight_g)) > 0) {
  cat("    使用中位數填補 product_weight_g 的缺失值\n")
  data <- data %>%
    group_by(product_category_name) %>%
    mutate(
      product_weight_g = ifelse(is.na(product_weight_g), 
                                median(product_weight_g, na.rm = TRUE), 
                                product_weight_g)
    ) %>%
    ungroup()
  
  # 如果類別中位數也是 NA，使用整體中位數
  data <- data %>%
    mutate(
      product_weight_g = ifelse(is.na(product_weight_g), 
                                median(data$product_weight_g, na.rm = TRUE), 
                                product_weight_g)
    )
}

# 商品照片數量：如果缺失，用 0 或中位數填補
if (sum(is.na(data$product_photos_qty)) > 0) {
  cat("    使用中位數填補 product_photos_qty 的缺失值\n")
  data <- data %>%
    mutate(
      product_photos_qty = ifelse(is.na(product_photos_qty), 
                                  median(product_photos_qty, na.rm = TRUE), 
                                  product_photos_qty)
    )
}

# 2.5 處理控制變數的缺失值
cat("  - 處理控制變數（payment_type, payment_installments）缺失\n")

# 付款方式缺失：新增「unknown」類別
data <- data %>%
  mutate(
    payment_type = ifelse(is.na(payment_type), "unknown", payment_type)
  )

# 分期期數：如果缺失，用中位數填補
if (sum(is.na(data$payment_installments)) > 0) {
  data <- data %>%
    mutate(
      payment_installments = ifelse(is.na(payment_installments), 
                                    median(payment_installments, na.rm = TRUE), 
                                    payment_installments)
    )
}

cat("\n✓ 缺失值處理完成\n")
cat(sprintf("處理後資料筆數: %s\n", format(nrow(data), big.mark = ",")))

# 再次檢查缺失值
cat("\n處理後的缺失值統計：\n")
missing_after <- data %>%
  summarise_all(~ sum(is.na(.))) %>%
  gather(key = "variable", value = "missing_count") %>%
  filter(missing_count > 0)

if (nrow(missing_after) > 0) {
  print(missing_after)
} else {
  cat("  無缺失值 ✓\n")
}
cat("\n")

# ============================================================================
# 步驟 3: 檢查與處理異常值
# ============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("步驟 3: 檢查與處理異常值\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# 3.1 檢查應變數（review_score）
cat("檢查應變數（review_score）：\n")
cat(sprintf("  範圍: %d - %d\n", min(data$review_score, na.rm = TRUE), 
            max(data$review_score, na.rm = TRUE)))
cat(sprintf("  分布: \n"))
print(table(data$review_score))
cat("\n")

# 移除不在 1-5 範圍的分數（如果有的話）
data <- data %>%
  filter(review_score >= 1 & review_score <= 5)

cat(sprintf("✓ 篩選後筆數: %s\n\n", format(nrow(data), big.mark = ",")))

# 3.2 檢查物流變數
cat("檢查物流變數：\n")

# delivery_days（應該 >= 0）
cat("  delivery_days:\n")
cat(sprintf("    最小值: %.1f\n", min(data$delivery_days, na.rm = TRUE)))
cat(sprintf("    最大值: %.1f\n", max(data$delivery_days, na.rm = TRUE)))
cat(sprintf("    平均數: %.2f\n", mean(data$delivery_days, na.rm = TRUE)))
cat(sprintf("    中位數: %.2f\n", median(data$delivery_days, na.rm = TRUE)))

# 檢查異常值（使用 IQR 方法）
Q1_days <- quantile(data$delivery_days, 0.25, na.rm = TRUE)
Q3_days <- quantile(data$delivery_days, 0.75, na.rm = TRUE)
IQR_days <- Q3_days - Q1_days
lower_bound_days <- Q1_days - 3 * IQR_days  # 使用 3*IQR 作為更寬鬆的標準
upper_bound_days <- Q3_days + 3 * IQR_days

outliers_days <- sum(data$delivery_days < lower_bound_days | 
                     data$delivery_days > upper_bound_days, na.rm = TRUE)
cat(sprintf("    異常值數量（3*IQR）: %d (%.2f%%)\n", outliers_days,
            outliers_days/nrow(data)*100))

# delivery_gap
cat("\n  delivery_gap:\n")
cat(sprintf("    最小值: %.1f\n", min(data$delivery_gap, na.rm = TRUE)))
cat(sprintf("    最大值: %.1f\n", max(data$delivery_gap, na.rm = TRUE)))
cat(sprintf("    平均數: %.2f\n", mean(data$delivery_gap, na.rm = TRUE)))
cat(sprintf("    中位數: %.2f\n", median(data$delivery_gap, na.rm = TRUE)))

# 3.3 檢查交易成本變數
cat("\n檢查交易成本變數：\n")

# price（應該 > 0）
cat("  price:\n")
cat(sprintf("    最小值: %.2f\n", min(data$price, na.rm = TRUE)))
cat(sprintf("    最大值: %.2f\n", max(data$price, na.rm = TRUE)))
cat(sprintf("    平均數: %.2f\n", mean(data$price, na.rm = TRUE)))
cat(sprintf("    中位數: %.2f\n", median(data$price, na.rm = TRUE)))

# 移除價格 <= 0 的記錄
price_invalid <- sum(data$price <= 0, na.rm = TRUE)
if (price_invalid > 0) {
  cat(sprintf("    移除價格 <= 0 的記錄: %d 筆\n", price_invalid))
  data <- data %>% filter(price > 0)
}

# freight_value（應該 >= 0）
cat("\n  freight_value:\n")
cat(sprintf("    最小值: %.2f\n", min(data$freight_value, na.rm = TRUE)))
cat(sprintf("    最大值: %.2f\n", max(data$freight_value, na.rm = TRUE)))
cat(sprintf("    平均數: %.2f\n", mean(data$freight_value, na.rm = TRUE)))

# 移除運費 < 0 的記錄
freight_invalid <- sum(data$freight_value < 0, na.rm = TRUE)
if (freight_invalid > 0) {
  cat(sprintf("    移除運費 < 0 的記錄: %d 筆\n", freight_invalid))
  data <- data %>% filter(freight_value >= 0)
}

# 3.4 檢查商品屬性變數
cat("\n檢查商品屬性變數：\n")

# product_weight_g（應該 > 0）
cat("  product_weight_g:\n")
cat(sprintf("    最小值: %.1f\n", min(data$product_weight_g, na.rm = TRUE)))
cat(sprintf("    最大值: %.1f\n", max(data$product_weight_g, na.rm = TRUE)))
cat(sprintf("    平均數: %.1f\n", mean(data$product_weight_g, na.rm = TRUE)))

# 移除重量 <= 0 的記錄
weight_invalid <- sum(data$product_weight_g <= 0, na.rm = TRUE)
if (weight_invalid > 0) {
  cat(sprintf("    移除重量 <= 0 的記錄: %d 筆\n", weight_invalid))
  data <- data %>% filter(product_weight_g > 0)
}

# product_photos_qty（應該 >= 0）
cat("\n  product_photos_qty:\n")
cat(sprintf("    最小值: %d\n", min(data$product_photos_qty, na.rm = TRUE)))
cat(sprintf("    最大值: %d\n", max(data$product_photos_qty, na.rm = TRUE)))
cat(sprintf("    平均數: %.2f\n", mean(data$product_photos_qty, na.rm = TRUE)))

cat("\n✓ 異常值檢查完成\n")
cat(sprintf("處理後資料筆數: %s\n\n", format(nrow(data), big.mark = ",")))

# ============================================================================
# 步驟 4: 處理重複資料
# ============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("步驟 4: 處理重複資料\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# 檢查完全重複的記錄
duplicate_count <- sum(duplicated(data))
cat(sprintf("完全重複的記錄數: %d\n", duplicate_count))

if (duplicate_count > 0) {
  cat("移除完全重複的記錄...\n")
  data <- data %>% distinct()
  cat(sprintf("  剩餘筆數: %s\n", format(nrow(data), big.mark = ",")))
}

# 檢查 order_id 的重複情況（因為一個訂單可能有多個商品）
cat("\n檢查 order_id 重複情況：\n")
order_dup <- table(table(data$order_id))
cat("每個 order_id 出現次數的分布：\n")
print(order_dup)

# 注意：根據分析目標決定是否要聚合
# 這裡先保留所有記錄，因為可能需要分析商品層級的資料
cat("\n保留所有記錄（包含同一訂單的多個商品）\n")

cat("\n✓ 重複資料檢查完成\n\n")

# ============================================================================
# 步驟 5: 建立衍生變數
# ============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("步驟 5: 建立衍生變數\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# 5.1 總交易金額
cat("建立衍生變數：\n")
cat("  - total_value = price + freight_value\n")
data <- data %>%
  mutate(total_value = price + freight_value)

# 5.2 價格是否高於平均（二元變數）
cat("  - price_above_mean（價格是否高於平均）\n")
mean_price <- mean(data$price, na.rm = TRUE)
data <- data %>%
  mutate(price_above_mean = ifelse(price > mean_price, 1, 0))

# 5.3 延遲或提前送達（二元變數）
cat("  - delivery_delayed（是否延遲送達）\n")
data <- data %>%
  mutate(delivery_delayed = ifelse(delivery_gap > 0, 1, 0))

# 5.4 提前送達（二元變數）
cat("  - delivery_early（是否提前送達）\n")
data <- data %>%
  mutate(delivery_early = ifelse(delivery_gap < 0, 1, 0))

cat("\n✓ 衍生變數建立完成\n\n")

# ============================================================================
# 步驟 6: 變數類型轉換
# ============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("步驟 6: 變數類型轉換\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# 6.1 類別變數轉為因子
cat("轉換類別變數為因子：\n")
cat("  注意：review_score 視為連續型變數，不轉為因子\n")
data <- data %>%
  mutate(
    payment_type = as.factor(payment_type),
    product_category_name = as.factor(product_category_name),
    product_category_name_english = as.factor(product_category_name_english),
    order_status = as.factor(order_status)
  )

cat("  ✓ payment_type\n")
cat("  ✓ product_category_name\n")
cat("  ✓ product_category_name_english\n")
cat("  ✓ order_status\n")

# 6.2 數值變數確保為數值型態
cat("\n確保數值變數為數值型態：\n")
data <- data %>%
  mutate(
    review_score = as.numeric(review_score),  # 應變數視為連續型
    delivery_days = as.numeric(delivery_days),
    delivery_gap = as.numeric(delivery_gap),
    price = as.numeric(price),
    freight_value = as.numeric(freight_value),
    product_weight_g = as.numeric(product_weight_g),
    product_photos_qty = as.numeric(product_photos_qty),
    payment_installments = as.numeric(payment_installments)
  )

cat("  ✓ review_score（應變數，連續型）\n")
cat("  ✓ 所有數值變數已轉換\n")

cat("\n✓ 變數類型轉換完成\n\n")

# ============================================================================
# 步驟 7: 資料分布檢查
# ============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("步驟 7: 資料分布檢查\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# 7.1 應變數分布（數值型變數）
cat("應變數（review_score）分布：\n")
cat(sprintf("  平均數: %.2f\n", mean(data$review_score, na.rm = TRUE)))
cat(sprintf("  中位數: %.2f\n", median(data$review_score, na.rm = TRUE)))
cat(sprintf("  標準差: %.2f\n", sd(data$review_score, na.rm = TRUE)))
cat(sprintf("\n分布：\n"))
review_dist <- table(data$review_score)
print(review_dist)
cat(sprintf("\n比例分布：\n"))
print(prop.table(review_dist))

# 7.2 主要數值變數的基本統計量
cat("\n主要數值變數的基本統計量：\n")
numeric_vars <- c("delivery_days", "delivery_gap", "price", "freight_value",
                  "product_weight_g", "product_photos_qty", "payment_installments")
summary_stats <- data %>%
  select(all_of(numeric_vars)) %>%
  summary()
print(summary_stats)

cat("\n✓ 資料分布檢查完成\n")
cat("\n注意：請查看後續生成的圖表以了解詳細分布情況\n\n")

# ============================================================================
# 步驟 8: 資料篩選（最終確認）
# ============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("步驟 8: 最終資料篩選\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# 最終確認所有必要欄位都不為空
cat("最終確認：\n")

# 確認應變數存在
data <- data %>% filter(!is.na(review_score))

# 確認關鍵自變數存在
data <- data %>% 
  filter(!is.na(delivery_days), 
         !is.na(delivery_gap),
         !is.na(price),
         !is.na(freight_value))

cat(sprintf("  最終資料筆數: %s\n", format(nrow(data), big.mark = ",")))
cat(sprintf("  最終資料欄位數: %d\n", ncol(data)))

cat("\n✓ 最終篩選完成\n\n")

# ============================================================================
# 步驟 9: 儲存清理後的資料
# ============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("步驟 9: 儲存清理後的資料\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# 儲存清理後的資料
output_file <- "preprocessed_data.csv"
write_csv(data, output_file)
cat(sprintf("✓ 清理後的資料已儲存至: %s\n", output_file))

# 儲存處理摘要報告
cat("\n生成處理摘要報告...\n")

summary_report <- list(
  original_rows = nrow(data_raw),
  final_rows = nrow(data),
  removed_rows = nrow(data_raw) - nrow(data),
  removal_rate = round((nrow(data_raw) - nrow(data)) / nrow(data_raw) * 100, 2),
  final_variables = ncol(data),
  processing_date = Sys.time()
)

# 將摘要儲存為文字檔
summary_text <- sprintf(
  "資料前處理摘要報告\n%s\n%s\n\n原始資料筆數: %s\n最終資料筆數: %s\n移除資料筆數: %s\n移除比例: %.2f%%\n最終欄位數: %d\n處理日期: %s\n",
  paste(rep("=", 60), collapse = ""),
  "巴西 Olist 電商平台資料前處理",
  format(summary_report$original_rows, big.mark = ","),
  format(summary_report$final_rows, big.mark = ","),
  format(summary_report$removed_rows, big.mark = ","),
  summary_report$removal_rate,
  summary_report$final_variables,
  summary_report$processing_date
)

writeLines(summary_text, "preprocessing_summary.txt")
cat("✓ 處理摘要已儲存至: preprocessing_summary.txt\n")

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("資料前處理完成！\n")
cat(paste0(rep("=", 80), collapse = ""), "\n")

# ============================================================================
# 步驟 10: 生成視覺化圖表（選項）
# ============================================================================

cat("\n是否要生成視覺化圖表？(建議在互動模式下執行)\n")
cat("可以使用以下程式碼生成圖表：\n")
cat("\n# 查看 hist_boxplot.R 檔案中的視覺化程式碼\n")

