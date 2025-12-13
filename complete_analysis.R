# ============================================================================
# 巴西 Olist 電商平台完整分析腳本
# ============================================================================
# 此腳本整合了所有分析步驟：
# 1. 資料合併（從原始 CSV 檔案合併）
# 2. 資料載入與前處理
# 3. 敘述性統計分析
# 4. 研究一之一：關鍵預測變數分析
# 5. 研究一之二：物流服務品質深入分析
# 6. 研究二
# ============================================================================

# ============================================================================
# 第一部分：載入套件與設定
# ============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("巴西 Olist 電商平台完整分析\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# 載入必要的套件
cat("載入套件...\n")
library(dplyr)
library(readr)
library(ggplot2)
library(tidyr)
library(tidyverse)


# 檢查並載入可選套件
if (!requireNamespace("corrplot", quietly = TRUE)) {
  cat("警告：套件 'corrplot' 未安裝，部分視覺化功能將無法使用\n")
  cat("若要安裝，請執行: install.packages('corrplot')\n\n")
}

cat("✓ 套件載入完成\n\n")

# 自動設定工作目錄為專案根目錄
original_wd <- getwd()

# ============================================================================
# 第二部分：資料合併
# ============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("第二部分：資料合併\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# 檢查是否需要執行資料合併
merged_data_path <- "sql_merge/merged_olist_data.csv"
need_merge <- !file.exists(merged_data_path)

if (need_merge) {
  cat("步驟 0: 合併 CSV 檔案（使用 R/dplyr）\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n\n")
  
  cat("合併後的資料檔案不存在，開始執行資料合併...\n\n")
  
  # 載入所有 CSV 檔案
  cat("載入 CSV 檔案...\n")
  customers <- read_csv(file.path(csv_dir, "olist_customers_dataset.csv"), 
                        show_col_types = FALSE, locale = locale(encoding = "UTF-8"))
  cat(sprintf("  ✓ customers: %s 筆\n", format(nrow(customers), big.mark = ",")))
  
  orders <- read_csv(file.path(csv_dir, "olist_orders_dataset.csv"), 
                    show_col_types = FALSE, locale = locale(encoding = "UTF-8"))
  cat(sprintf("  ✓ orders: %s 筆\n", format(nrow(orders), big.mark = ",")))
  
  order_items <- read_csv(file.path(csv_dir, "olist_order_items_dataset.csv"), 
                          show_col_types = FALSE, locale = locale(encoding = "UTF-8"))
  cat(sprintf("  ✓ order_items: %s 筆\n", format(nrow(order_items), big.mark = ",")))
  
  order_payments <- read_csv(file.path(csv_dir, "olist_order_payments_dataset.csv"), 
                              show_col_types = FALSE, locale = locale(encoding = "UTF-8"))
  cat(sprintf("  ✓ order_payments: %s 筆\n", format(nrow(order_payments), big.mark = ",")))
  
  order_reviews <- read_csv(file.path(csv_dir, "olist_order_reviews_dataset.csv"), 
                            show_col_types = FALSE, locale = locale(encoding = "UTF-8"))
  cat(sprintf("  ✓ order_reviews: %s 筆\n", format(nrow(order_reviews), big.mark = ",")))
  
  products <- read_csv(file.path(csv_dir, "olist_products_dataset.csv"), 
                      show_col_types = FALSE, locale = locale(encoding = "UTF-8"))
  cat(sprintf("  ✓ products: %s 筆\n", format(nrow(products), big.mark = ",")))
  
  sellers <- read_csv(file.path(csv_dir, "olist_sellers_dataset.csv"), 
                     show_col_types = FALSE, locale = locale(encoding = "UTF-8"))
  cat(sprintf("  ✓ sellers: %s 筆\n", format(nrow(sellers), big.mark = ",")))
  
  category_translation <- read_csv(file.path(csv_dir, "product_category_name_translation.csv"), 
                                   show_col_types = FALSE, locale = locale(encoding = "UTF-8"))
  cat(sprintf("  ✓ category_translation: %s 筆\n", format(nrow(category_translation), big.mark = ",")))
  
  # 轉換日期欄位
  cat("處理日期欄位...\n")
  orders <- orders %>%
    mutate(
      order_purchase_timestamp = as.Date(order_purchase_timestamp),
      order_approved_at = as.Date(order_approved_at),
      order_delivered_carrier_date = as.Date(order_delivered_carrier_date),
      order_delivered_customer_date = as.Date(order_delivered_customer_date),
      order_estimated_delivery_date = as.Date(order_estimated_delivery_date)
    )
  
  order_reviews <- order_reviews %>%
    mutate(
      review_creation_date = as.Date(review_creation_date),
      review_answer_timestamp = as.Date(review_answer_timestamp)
    )
  
  # 步驟 1: 選擇最佳評論（最接近送達日期的評論）
  cat("步驟 1: 選擇最佳評論...\n")
  review_best_candidates <- order_reviews %>%
    filter(!is.na(review_score)) %>%
    inner_join(orders %>% select(order_id, order_delivered_customer_date), by = "order_id") %>%
    mutate(
      diff_days_to_delivery = abs(as.numeric(review_creation_date - order_delivered_customer_date))
    )
  
  review_best_min <- review_best_candidates %>%
    group_by(order_id) %>%
    summarise(min_diff = min(diff_days_to_delivery), .groups = "drop")
  
  review_best_ties <- review_best_candidates %>%
    inner_join(review_best_min, by = c("order_id", "diff_days_to_delivery" = "min_diff"))
  
  review_best <- review_best_ties %>%
    group_by(order_id) %>%
    slice_max(review_creation_date, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    select(order_id, review_id, review_score, review_creation_date, review_answer_timestamp)

  
  # 步驟 2: 聚合商品項目
  cat("步驟 2: 聚合商品項目...\n")
  items_agg <- order_items %>%
    left_join(products, by = "product_id") %>%
    group_by(order_id) %>%
    summarise(
      num_items = n(),
      num_products = n_distinct(product_id),
      total_price = sum(price, na.rm = TRUE),
      total_freight_value = sum(freight_value, na.rm = TRUE),
      avg_product_weight_g = mean(product_weight_g, na.rm = TRUE),
      avg_product_photos_qty = mean(product_photos_qty, na.rm = TRUE),
      .groups = "drop"
    )
  
  # 步驟 3: 列出所有商品ID和類別
  cat("步驟 3: 列出商品ID和類別...\n")
  items_list <- order_items %>%
    left_join(products, by = "product_id") %>%
    left_join(category_translation, by = "product_category_name") %>%
    group_by(order_id) %>%
    summarise(
      product_ids = paste(unique(product_id), collapse = ","),
      product_categories = paste(unique(product_category_name_english[!is.na(product_category_name_english)]), collapse = ","),
      num_distinct_categories = n_distinct(product_category_name_english, na.rm = TRUE),
      .groups = "drop"
    )
  
  # 步驟 4: 找出主要商品類別
  cat("步驟 4: 找出主要商品類別...\n")
  item_cats <- order_items %>%
    left_join(products, by = "product_id") %>%
    left_join(category_translation, by = "product_category_name") %>%
    group_by(order_id, product_category_name, product_category_name_english) %>%
    summarise(cnt = n(), .groups = "drop")
  
  order_cat <- item_cats %>%
    group_by(order_id) %>%
    slice_max(cnt, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    select(order_id, product_category_name, product_category_name_english, primary_category_count = cnt)

  # 步驟 5: 找出主要賣家
  cat("步驟 5: 找出主要賣家...\n")
  seller_counts <- order_items %>%
    group_by(order_id, seller_id) %>%
    summarise(seller_item_count = n(), .groups = "drop")
  
  seller_order <- seller_counts %>%
    group_by(order_id) %>%
    slice_max(seller_item_count, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    mutate(
      num_sellers = sapply(order_id, function(x) sum(seller_counts$order_id == x))
    ) %>%
    select(order_id, primary_seller_id = seller_id, primary_seller_item_count = seller_item_count, num_sellers)
  
  # 步驟 6: 聚合付款資訊
  cat("步驟 6: 聚合付款資訊...\n")
  pay_agg <- order_payments %>%
    group_by(order_id) %>%
    summarise(
      total_payment_value = sum(payment_value, na.rm = TRUE),
      max_payment_installments = max(payment_installments, na.rm = TRUE),
      .groups = "drop"
    )
  
  pay_first <- order_payments %>%
    group_by(order_id) %>%
    slice_min(payment_sequential, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    select(order_id, payment_type)
  
  # 步驟 7: 評論統計
  cat("步驟 7: 計算評論統計...\n")
  review_stats <- order_reviews %>%
    group_by(order_id) %>%
    summarise(
      review_count = n(),
      review_distinct_scores = n_distinct(review_score),
      first_review_creation_date = min(review_creation_date, na.rm = TRUE),
      last_review_creation_date = max(review_creation_date, na.rm = TRUE),
      first_review_score = review_score[which.min(review_creation_date)][1],
      last_review_score = review_score[which.max(review_creation_date)][1],
      .groups = "drop"
    )
  
  # 步驟 8: 合併所有資料
  cat("步驟 8: 合併所有資料...\n")
  merged_data <- review_best %>%
    inner_join(orders, by = "order_id") %>%
    inner_join(customers, by = "customer_id") %>%
    left_join(items_agg, by = "order_id") %>%
    left_join(order_cat, by = "order_id") %>%
    left_join(items_list, by = "order_id") %>%
    left_join(seller_order, by = "order_id") %>%
    left_join(sellers, by = c("primary_seller_id" = "seller_id")) %>%
    left_join(pay_agg, by = "order_id") %>%
    left_join(pay_first, by = "order_id") %>%
    left_join(review_stats, by = "order_id") %>%
    # 計算衍生變數
    mutate(
      delivery_days = as.integer(order_delivered_customer_date - order_purchase_timestamp),
      delivery_gap = as.integer(order_delivered_customer_date - order_estimated_delivery_date),
      has_multiple_reviews = ifelse(review_count > 1, 1, 0),
      has_mixed_review_scores = ifelse(review_distinct_scores > 1, 1, 0),
      primary_category_share = ifelse(!is.na(num_items) & num_items > 0, 
                                     primary_category_count / num_items, NA_real_),
      primary_seller_share = ifelse(!is.na(num_items) & num_items > 0, 
                                    primary_seller_item_count / num_items, NA_real_),
      price = total_price,
      freight_value = total_freight_value,
      product_weight_g = avg_product_weight_g,
      product_photos_qty = avg_product_photos_qty,
      payment_installments = max_payment_installments,
      payment_value = total_payment_value,
      primary_seller_zip_code_prefix = seller_zip_code_prefix,
      primary_seller_city = seller_city,
      primary_seller_state = seller_state
    ) %>%
    # 篩選條件
    filter(
      order_status == "delivered",
      !is.na(order_delivered_customer_date),
      !is.na(order_purchase_timestamp),
      !is.na(order_estimated_delivery_date),
      !is.na(review_score)
    ) %>%
    # 選擇最終欄位
    select(
      review_id, review_score, review_creation_date, review_answer_timestamp,
      review_count, review_distinct_scores, first_review_creation_date, 
      last_review_creation_date, first_review_score, last_review_score,
      has_multiple_reviews, has_mixed_review_scores,
      order_id, order_status, order_purchase_timestamp, order_approved_at,
      order_delivered_carrier_date, order_delivered_customer_date, 
      order_estimated_delivery_date,
      delivery_days, delivery_gap,
      customer_id, customer_unique_id, customer_zip_code_prefix,
      customer_city, customer_state,
      num_items, num_products, price, freight_value,
      product_category_name, product_category_name_english,
      product_photos_qty, product_weight_g,
      product_ids, product_categories, num_distinct_categories,
      primary_category_share,
      num_sellers, primary_seller_id, primary_seller_zip_code_prefix,
      primary_seller_city, primary_seller_state, primary_seller_share,
      payment_type, payment_installments, payment_value
    )
  
  cat(sprintf("  ✓ 合併完成，共 %s 筆記錄\n\n", format(nrow(merged_data), big.mark = ",")))
  
  # 儲存為 CSV
  if (!dir.exists("sql_merge")) {
    dir.create("sql_merge", recursive = TRUE)
  }
  write_csv(merged_data, merged_data_path)
  cat(sprintf("✓ 合併後的資料已儲存至: %s\n", merged_data_path))
  cat(sprintf("  總筆數: %s 筆\n", format(nrow(merged_data), big.mark = ",")))
  cat(sprintf("  欄位數: %d 欄\n\n", ncol(merged_data)))
} else {
  cat("合併後的資料檔案已存在，跳過合併步驟\n")
  cat(sprintf("使用現有檔案: %s\n\n", merged_data_path))
}

# ============================================================================
# 第三部分：資料載入與前處理
# ============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("第三部分：資料載入與前處理\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# 步驟 1: 載入資料
cat("步驟 1: 載入資料\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

# 優先使用已處理的資料，如果不存在則使用合併後的原始資料
if (file.exists("data_preprocessing/preprocessed_data.csv")) {
  cat("使用已處理的資料：data_preprocessing/preprocessed_data.csv\n")
  data_path <- "data_preprocessing/preprocessed_data.csv"
} else if (file.exists(merged_data_path)) {
  cat("使用合併後的原始資料：sql_merge/merged_olist_data.csv\n")
  cat("（將進行完整的前處理流程）\n")
  data_path <- merged_data_path
} else {
  stop("錯誤：找不到資料檔案！請確認資料檔案是否存在。")
}

data_raw <- read_csv(data_path, 
                     locale = locale(encoding = "UTF-8"),
                     show_col_types = FALSE)

data <- data_raw

cat("✓ 資料載入完成\n")
cat(sprintf("原始資料筆數: %s\n", format(nrow(data), big.mark = ",")))
cat(sprintf("原始資料欄位數: %d\n\n", ncol(data)))

# 如果使用的是原始合併資料，則進行完整前處理
if (data_path == "sql_merge/merged_olist_data.csv") {
  cat("開始進行資料前處理...\n\n")
  
  # 步驟 2: 處理缺失值
  cat("步驟 2: 處理缺失值\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n\n")
  
  # 刪除關鍵變數缺失的記錄
  cat("  - 刪除應變數（review_score）缺失的記錄\n")
  data <- data %>% filter(!is.na(review_score))
  cat(sprintf("    剩餘筆數: %s\n", format(nrow(data), big.mark = ",")))
  
  cat("  - 處理物流變數（delivery_days, delivery_gap）缺失\n")
  data <- data %>% filter(!is.na(delivery_days), !is.na(delivery_gap))
  cat(sprintf("    剩餘筆數: %s\n", format(nrow(data), big.mark = ",")))
  
  cat("  - 處理交易成本變數（price, freight_value）缺失\n")
  data <- data %>% filter(!is.na(price), !is.na(freight_value))
  cat(sprintf("    剩餘筆數: %s\n", format(nrow(data), big.mark = ",")))
  
  # 處理商品屬性變數的缺失值
  cat("  - 處理商品屬性變數缺失\n")
  data <- data %>%
    mutate(
      product_category_name = ifelse(is.na(product_category_name), 
                                     "unknown", 
                                     product_category_name),
      product_category_name_english = ifelse(is.na(product_category_name_english), 
                                             "unknown", 
                                             product_category_name_english)
    )
  
  # 商品重量：用中位數填補
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
    
    data <- data %>%
      mutate(
        product_weight_g = ifelse(is.na(product_weight_g), 
                                  median(data$product_weight_g, na.rm = TRUE), 
                                  product_weight_g)
      )
  }
  
  # 商品照片數量：用中位數填補
  if (sum(is.na(data$product_photos_qty)) > 0) {
    cat("    使用中位數填補 product_photos_qty 的缺失值\n")
    data <- data %>%
      mutate(
        product_photos_qty = ifelse(is.na(product_photos_qty), 
                                    median(product_photos_qty, na.rm = TRUE), 
                                    product_photos_qty)
      )
  }
  
  # 處理控制變數的缺失值
  cat("  - 處理控制變數（payment_type, payment_installments）缺失\n")
  data <- data %>%
    mutate(
      payment_type = ifelse(is.na(payment_type), "unknown", payment_type)
    )
  
  if (sum(is.na(data$payment_installments)) > 0) {
    data <- data %>%
      mutate(
        payment_installments = ifelse(is.na(payment_installments), 
                                      median(payment_installments, na.rm = TRUE), 
                                      payment_installments)
      )
  }
  
  cat("✓ 缺失值處理完成\n")
  cat(sprintf("處理後資料筆數: %s\n\n", format(nrow(data), big.mark = ",")))
  
  # 步驟 3: 檢查與處理異常值
  cat("步驟 3: 檢查與處理異常值\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n\n")
  
  # 移除不在 1-5 範圍的分數
  data <- data %>% filter(review_score >= 1 & review_score <= 5)
  
  # 移除價格 <= 0 的記錄
  price_invalid <- sum(data$price <= 0, na.rm = TRUE)
  if (price_invalid > 0) {
    cat(sprintf("移除價格 <= 0 的記錄: %d 筆\n", price_invalid))
    data <- data %>% filter(price > 0)
  }
  
  # 移除運費 < 0 的記錄
  freight_invalid <- sum(data$freight_value < 0, na.rm = TRUE)
  if (freight_invalid > 0) {
    cat(sprintf("移除運費 < 0 的記錄: %d 筆\n", freight_invalid))
    data <- data %>% filter(freight_value >= 0)
  }
  
  # 移除重量 <= 0 的記錄
  weight_invalid <- sum(data$product_weight_g <= 0, na.rm = TRUE)
  if (weight_invalid > 0) {
    cat(sprintf("移除重量 <= 0 的記錄: %d 筆\n", weight_invalid))
    data <- data %>% filter(product_weight_g > 0)
  }
  
  cat("✓ 異常值檢查完成\n")
  cat(sprintf("處理後資料筆數: %s\n\n", format(nrow(data), big.mark = ",")))
  
  # 步驟 4: 處理重複資料
  cat("步驟 4: 處理重複資料\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n\n")
  
  duplicate_count <- sum(duplicated(data))
  cat(sprintf("完全重複的記錄數: %d\n", duplicate_count))
  
  if (duplicate_count > 0) {
    cat("移除完全重複的記錄...\n")
    data <- data %>% distinct()
    cat(sprintf("  剩餘筆數: %s\n", format(nrow(data), big.mark = ",")))
  }
  
  
  # 步驟 5: 建立衍生變數
  cat("步驟 5: 建立衍生變數\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n\n")
  
  cat("建立衍生變數：\n")
  cat("  - total_value = price + freight_value\n")
  data <- data %>%
    mutate(total_value = price + freight_value)
  
  cat("  - price_above_mean（價格是否高於平均）\n")
  mean_price <- mean(data$price, na.rm = TRUE)
  data <- data %>%
    mutate(price_above_mean = ifelse(price > mean_price, 1, 0))
  
  cat("  - delivery_delayed（是否延遲送達）\n")
  data <- data %>%
    mutate(delivery_delayed = ifelse(delivery_gap > 0, 1, 0))
  
  cat("  - delivery_early（是否提前送達）\n")
  data <- data %>%
    mutate(delivery_early = ifelse(delivery_gap < 0, 1, 0))
  
  cat("✓ 衍生變數建立完成\n\n")
  
  # 步驟 6: 變數類型轉換
  cat("步驟 6: 變數類型轉換\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n\n")
  
  cat("轉換類別變數為因子：\n")
  data <- data %>%
    mutate(
      payment_type = as.factor(payment_type),
      product_category_name = as.factor(product_category_name),
      product_category_name_english = as.factor(product_category_name_english),
      order_status = as.factor(order_status)
    )
  
  cat("確保數值變數為數值型態：\n")
  data <- data %>%
    mutate(
      review_score = as.numeric(review_score),
      delivery_days = as.numeric(delivery_days),
      delivery_gap = as.numeric(delivery_gap),
      price = as.numeric(price),
      freight_value = as.numeric(freight_value),
      product_weight_g = as.numeric(product_weight_g),
      product_photos_qty = as.numeric(product_photos_qty),
      payment_installments = as.numeric(payment_installments)
    )
  
  cat("✓ 變數類型轉換完成\n\n")
  
  # 最終確認
  cat("最終確認：\n")
  data <- data %>% 
    filter(!is.na(review_score), 
           !is.na(delivery_days), 
           !is.na(delivery_gap),
           !is.na(price),
           !is.na(freight_value))
  
  cat(sprintf("  最終資料筆數: %s\n", format(nrow(data), big.mark = ",")))
  cat(sprintf("  最終資料欄位數: %d\n\n", ncol(data)))
  
} else {
  cat("✓ 使用已處理的資料，跳過前處理步驟\n\n")
}

# ============================================================================
# 第四部分：敘述性統計分析
# ============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("第四部分：敘述性統計分析\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# 步驟 1: 基本統計摘要
cat("步驟 1: 基本統計摘要\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

cat("整體資料摘要：\n")
print(summary(data))
cat("\n")

# 基本資料統計（唯一值統計）
cat("基本資料統計（唯一值）：\n")
cat("=", rep("=", 79), "\n", sep = "")

if ("order_id" %in% names(data)) {
  total_orders <- length(unique(data$order_id))
  cat(sprintf("總訂單數（唯一 order_id）: %s\n", format(total_orders, big.mark = ",")))
}

if ("review_id" %in% names(data)) {
  total_reviews <- length(unique(data$review_id))
  cat(sprintf("總評論數（唯一 review_id）: %s\n", format(total_reviews, big.mark = ",")))
}

if ("customer_unique_id" %in% names(data)) {
  total_customers <- length(unique(data$customer_unique_id))
  cat(sprintf("總顧客數（唯一 customer_unique_id）: %s\n", format(total_customers, big.mark = ",")))
}

if ("product_ids" %in% names(data)) {
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

if ("product_category_name_english" %in% names(data)) {
  total_categories <- length(unique(data$product_category_name_english[!is.na(data$product_category_name_english)]))
  cat(sprintf("總商品類別數（唯一 product_category_name_english）: %s\n", format(total_categories, big.mark = ",")))
}

if ("primary_seller_id" %in% names(data)) {
  total_sellers <- length(unique(data$primary_seller_id[!is.na(data$primary_seller_id)]))
  cat(sprintf("總賣家數（唯一 primary_seller_id）: %s\n", format(total_sellers, big.mark = ",")))
}

if ("customer_city" %in% names(data)) {
  total_customer_cities <- length(unique(data$customer_city[!is.na(data$customer_city)]))
  cat(sprintf("總顧客城市數（唯一 customer_city）: %s\n", format(total_customer_cities, big.mark = ",")))
}

if ("customer_state" %in% names(data)) {
  total_customer_states <- length(unique(data$customer_state[!is.na(data$customer_state)]))
  cat(sprintf("總顧客州數（唯一 customer_state）: %s\n", format(total_customer_states, big.mark = ",")))
}

cat("\n")

# 步驟 2: 應變數分析
cat("步驟 2: 應變數（review_score）分析\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

cat("評論分數（review_score）基本統計：\n")
cat(sprintf("  平均數: %.2f\n", mean(data$review_score)))
cat(sprintf("  中位數: %.2f\n", median(data$review_score)))
cat(sprintf("  標準差: %.2f\n", sd(data$review_score)))
cat(sprintf("  最小值: %.0f\n", min(data$review_score)))
cat(sprintf("  最大值: %.0f\n", max(data$review_score)))
cat("\n")

cat("評論分數分布：\n")
review_dist <- table(data$review_score)
print(review_dist)
cat("\n比例分布：\n")
print(round(prop.table(review_dist) * 100, 2))
cat("\n")

# 建立 plots 資料夾
if (!dir.exists("plots")) {
  dir.create("plots")
}

# 繪製直方圖
cat("生成直方圖...\n")
png("plots/review_score_histogram.png", width = 800, height = 600)
counts <- table(factor(data$review_score, levels = 1:5))
max_count <- max(counts, na.rm = TRUE)
bp <- barplot(counts,
              main = "Distribution of Review Score",
              xlab = "Review Score",
              ylab = "Count",
              col = "steelblue",
              border = "white",
              ylim = c(0, max_count * 1.15))
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

# 步驟 3: 主要數值變數分析
cat("步驟 3: 主要數值變數分析\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

main_vars <- c("delivery_days", "delivery_gap", "price", "freight_value",
               "product_weight_g", "product_photos_qty", "payment_installments")

cat("主要數值變數統計摘要：\n")
print(summary(data[main_vars]))
cat("\n")

# 生成箱線圖和直方圖
cat("生成箱線圖和直方圖...\n")
for (var in main_vars) {
  if (var %in% names(data)) {
    # 箱線圖
    png(sprintf("plots/%s_boxplot.png", var), width = 800, height = 600)
    boxplot(data[[var]],
            main = sprintf("%s Boxplot", var),
            ylab = var,
            col = "lightcoral")
    dev.off()
    
    # 直方圖
    png(sprintf("plots/%s_histogram.png", var), width = 800, height = 600)
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
    cat(sprintf("  ✓ %s 圖表已儲存\n", var))
  }
}
cat("\n")

# 步驟 4: 相關係數分析
cat("步驟 4: 相關係數分析\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

# 主要變數的相關係數矩陣
cat("主要變數相關係數矩陣：\n")
numeric_data <- data %>%
  select(all_of(c("review_score", main_vars))) %>%
  select_if(is.numeric)

cor_matrix <- cor(numeric_data, use = "complete.obs")
print(round(cor_matrix, 3))
cat("\n")

# 所有數值變數的相關係數矩陣
cat("所有數值變數相關係數矩陣：\n")
cat("（使用 cor(df[sapply(df, is.numeric)]) 自動選取所有數值變數）\n")
all_numeric_data <- data[sapply(data, is.numeric)]
all_cor_matrix <- cor(all_numeric_data, use = "complete.obs")
print(round(all_cor_matrix, 3))
cat("\n")

cat(sprintf("總共 %d 個數值變數已納入相關係數計算\n", ncol(all_numeric_data)))
cat("\n")

# 生成相關係數熱力圖
if (requireNamespace("corrplot", quietly = TRUE)) {
  library(corrplot)
  
  png("plots/correlation_heatmap_full.png", width = 1200, height = 1200, res = 100)
  corrplot(all_cor_matrix, 
           method = "color", 
           type = "upper",
           tl.cex = 0.6,
           tl.col = "black",
           number.cex = 0.4,
           addCoef.col = "black",
           col = colorRampPalette(c("#3498db", "white", "#e74c3c"))(200),
           title = "Correlation Matrix - All Numeric Variables",
           mar = c(0, 0, 2, 0))
  dev.off()
  cat("✓ 完整相關係數熱力圖已儲存至: plots/correlation_heatmap_full.png\n\n")
}

# 繪製散點圖
cat("生成重要變數關係散點圖...\n")

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

# 步驟 5: 類別變數分析（簡化版）
cat("步驟 5: 類別變數分析\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

if ("order_status" %in% names(data)) {
  cat("訂單狀態分布：\n")
  order_status_dist <- data %>%
    count(order_status, sort = TRUE) %>%
    mutate(percentage = round(n / nrow(data) * 100, 2))
  print(order_status_dist)
  cat("\n")
}

if ("payment_type" %in% names(data)) {
  cat("付款方式分布：\n")
  print(table(data$payment_type))
  cat("\n")
}

if ("product_category_name_english" %in% names(data)) {
  cat("前 10 大商品類別（主要類別 - 英文）：\n")
  top_categories <- data %>%
    count(product_category_name_english, sort = TRUE) %>%
    head(10) %>%
    mutate(percentage = round(n / nrow(data) * 100, 2))
  print(top_categories)
  cat("\n")
}

if ("customer_state" %in% names(data)) {
  cat("顧客州別分布：\n")
  cat(sprintf("  總州數: %d\n", length(unique(data$customer_state))))
  cat("\n各州訂單數分布：\n")
  state_dist <- data %>%
    count(customer_state, sort = TRUE) %>%
    mutate(percentage = round(n / nrow(data) * 100, 2))
  print(head(state_dist, 10))
  cat("\n")
}

cat("✓ 敘述性統計分析完成\n\n")

# ============================================================================
# 第五部分：研究一之一 - 關鍵預測變數分析
# ============================================================================

glm(formula = success ~ log_delivery_days + log_price + freight_value + 
    product_photos_qty + product_weight_g + payment_installments + 
    price_above_mean + delivery_delayed + delivery_early, family = binomial(link = "logit"), 
    data = db)

glm(formula = success ~ log_delivery_days + log_price + freight_value + 
    product_photos_qty + product_weight_g + payment_installments + 
    price_above_mean + delivery_delayed + delivery_early + log_delivery_days:log_price + 
    delivery_gap:freight_value, family = binomial(link = "logit"), 
    data = db)

model_optimized <- glm(formula = success ~ log_delivery_days + log_price + freight_value + delivery_delayed + delivery_early + freight_value:delivery_gap, family = binomial(link = "logit"), data = db)

vif(model_optimized)

plot(final) 

# ============================================================================
# 第六部分：研究一之二
# ============================================================================

final_model <- glm(formula = success ~ log_delivery_days + log_price + freight_value + 
                     delivery_delayed + delivery_early + 
                     freight_value:delivery_gap, 
                   family = binomial(link = "logit"), 
                   data = data)

# delivery_delayed

predict_data_scenarios <- data.frame(
  delivery_gap = c(-1, 0, 1), 
  delivery_delayed = c(0, 0, 1),
  delivery_early = c(1, 0, 0),
  log_delivery_days = mean(db$log_delivery_days, na.rm = TRUE),
  log_price = mean(db$log_price, na.rm = TRUE),
  freight_value = mean(db$freight_value, na.rm = TRUE)
)

predictions_scenarios <- predict(final_model, newdata = predict_data_scenarios, type = "response", se.fit = TRUE)

predict_data_scenarios$predicted_prob <- predictions_scenarios$fit
predict_data_scenarios$lower_ci <- predictions_scenarios$fit - 1.96 * predictions_scenarios$se.fit
predict_data_scenarios$upper_ci <- predictions_scenarios$fit + 1.96 * predictions_scenarios$se.fit

plot_data <- predict_data_scenarios[c(2, 3), ] 

png("plots/glm_delivery_delay_influence.png", width = 800, height = 600)
par(mar = c(5, 5, 4, 2))

bar_positions <- barplot(
  height = plot_data$predicted_prob,
  names.arg = c("On-time", "Delayed"),
  col = c("skyblue", "salmon"),
  main = "Influence of delay",
  xlab = "Status",
  ylab = "Probability of score of 5",
  ylim = c(0, max(plot_data$upper_ci, na.rm = TRUE) * 1.2),
  width = 0.5,  
  space = 1     
)

text(
  x = bar_positions,
  y = plot_data$predicted_prob,
  labels = paste0(round(plot_data$predicted_prob * 100, 1), "%"),
  pos = 3, 
  cex = 1.2 
)
dev.off()
cat("✓ 已儲存至: plots/glm_delivery_delay_influence.png\n\n")

# log_delivery_days

predict_data_days <- data.frame(
  log_delivery_days = seq(min(db$log_delivery_days, na.rm = TRUE), 
                          max(db$log_delivery_days, na.rm = TRUE), 
                          length.out = 100),
  log_price = mean(db$log_price, na.rm = TRUE),
  freight_value = mean(db$freight_value, na.rm = TRUE),
  delivery_gap = mean(db$delivery_gap, na.rm = TRUE),
  delivery_delayed = 0,
  delivery_early = 1
)

predict_data_days$predicted_prob <- predict(final_model, newdata = predict_data_days, type = "response")

png("plots/glm_delivery_days_influence.png", width = 800, height = 600)
plot(
  x = exp(predict_data_days$log_delivery_days) - 1, 
  y = predict_data_days$predicted_prob,
  type = "n", 
  main = "Influence of delivery days",
  xlab = "Delivery days",
  ylab = "Probability of score of 5"
)

lines(
  x = exp(predict_data_days$log_delivery_days) - 1,
  y = predict_data_days$predicted_prob,
  col = "darkred",
  lwd = 2 
)

# freight_value:delivery_gap

freight_levels <- quantile(db$freight_value, c(0.25, 0.75), na.rm = TRUE)
gap_sequence <- seq(-20, 20, length.out = 100) 

predict_data_interaction <- expand.grid(
  delivery_gap = gap_sequence,
  freight_value = freight_levels,
  log_delivery_days = mean(db$log_delivery_days, na.rm = TRUE),
  log_price = mean(db$log_price, na.rm = TRUE)
)

predict_data_interaction$delivery_delayed <- ifelse(predict_data_interaction$delivery_gap > 0, 1, 0)
predict_data_interaction$delivery_early <- ifelse(predict_data_interaction$delivery_gap < 0, 1, 0)

predict_data_interaction$predicted_prob <- predict(final_model, newdata = predict_data_interaction, type = "response")

low_freight_data <- subset(predict_data_interaction, freight_value == freight_levels[1])
high_freight_data <- subset(predict_data_interaction, freight_value == freight_levels[2])

png("plots/glm_freight_delivery_gap_interaction.png", width = 800, height = 600)
plot(
  x = low_freight_data$delivery_gap,
  y = low_freight_data$predicted_prob,
  type = "l",
  col = "blue",
  lwd = 2,
  ylim = range(predict_data_interaction$predicted_prob),
  main = "Influence of interaction of freight value and delivery gap",
  xlab = "Delivery gap", 
  ylab = "Probability of score of 5"
)

lines(
  x = high_freight_data$delivery_gap,
  y = high_freight_data$predicted_prob,
  col = "red",
  lwd = 2
)

abline(v = 0, lty = "dashed", col = "grey40")

legend(
  "bottomleft",
  legend = c(paste0("低運費 ($", round(freight_levels[1], 2), ")"), 
             paste0("高運費 ($", round(freight_levels[2], 2), ")")),
  col = c("blue", "red"),
  lwd = 2,
  bty = "n"
)


# 研究二
# =======================================================
# 階段一：EDA 與 資料準備
# =======================================================

# 清除 NA
olist_clean <- olist %>% filter(!is.na(product_category_name_english))

# 所有類別 Boxplot
category_ranks <- olist_clean %>%
  group_by(product_category_name_english) %>%
  summarise(mean_score = mean(review_score)) %>%
  arrange(mean_score) %>%  
  mutate(
    rank = row_number(),   
    group_label = case_when(
      rank <= 24 ~ "1. Low Score Group",
      rank <= 48 ~ "2. Medium Score Group",
      TRUE       ~ "3. High Score Group"
    )
  )

olist_for_plot <- olist_clean %>%
  inner_join(category_ranks, by = "product_category_name_english")
ggplot(olist_for_plot, aes(x = reorder(product_category_name_english, mean_score), 
                           y = review_score)) +
  geom_boxplot(fill = "lightblue", outlier.size = 0.5, outlier.alpha = 0.3, varwidth = TRUE) +
  coord_flip() +
  facet_wrap(~ group_label, scales = "free_y", ncol = 3) +
  labs(title = "Review Score Distribution (All 72 Categories)", 
       subtitle = "Split into 3 groups by score rank (Low -> High)",
       x = NULL, 
       y = "Review Score") +
  theme_minimal() +
  theme(
    axis.text.y = element_text(size = 7), 
    strip.text = element_text(face = "bold", size = 10), 
    panel.spacing = unit(1, "lines") 
  )


# 計算各組統計量72
category_stats72 <- olist_clean %>%
  group_by(product_category_name_english) %>%
  summarise(
    Mean_Score = mean(review_score, na.rm = TRUE), 
    SD_Score = sd(review_score, na.rm = TRUE),     
    Count = n()                                   
  ) %>%
  arrange(desc(Mean_Score)) 
print(category_stats72, n =72)

# 計算各組統計量10
category_stats10 <- olist_clean2 %>%
  group_by(New_Category) %>%
  summarise(
    Mean_Score = mean(review_score, na.rm = TRUE), 
    SD_Score = sd(review_score, na.rm = TRUE),     
    Count = n()                                    
  ) %>%
  arrange(desc(Mean_Score)) 
print(category_stats10)


# =======================================================
# 階段三：LM 模型分析（原始分類）
# =======================================================

olist_clean$product_category_name_english <- relevel(as.factor(olist_clean$product_category_name_english), 
                                                     ref = "books_general_interest")
lm.1 <- lm(review_score ~ product_category_name_english, 
                data = olist_clean)
summary(lm.1)

# =======================================================
# 階段四：LM 模型分析（十大類）
# =======================================================

library(dplyr)
library(readr) 

mapping_csv <- "
Original_Label,New_Category
agro_industry_and_commerce,Office_Industry_Auto
air_conditioning,Home_Furniture_Appliances
art,Books_Media_Arts
arts_and_craftmanship,Books_Media_Arts
audio,Electronics_Computers_Telecom
auto,Office_Industry_Auto
baby,Baby_Toys
bed_bath_table,Home_Furniture_Appliances
books_general_interest,Books_Media_Arts
books_imported,Books_Media_Arts
books_technical,Books_Media_Arts
cds_dvds_musicals,Books_Media_Arts
christmas_supplies,Office_Industry_Auto
cine_photo,Books_Media_Arts
computers,Electronics_Computers_Telecom
computers_accessories,Electronics_Computers_Telecom
consoles_games,Electronics_Computers_Telecom
construction_tools_construction,Construction_Tools_Garden
construction_tools_lights,Construction_Tools_Garden
construction_tools_safety,Construction_Tools_Garden
cool_stuff,Sports_Leisure
costruction_tools_garden,Construction_Tools_Garden
costruction_tools_tools,Construction_Tools_Garden
diapers_and_hygiene,Baby_Toys
drinks,Food_Drinks
dvds_blu_ray,Books_Media_Arts
electronics,Electronics_Computers_Telecom
fashio_female_clothing,Fashion_Accessories
fashion_bags_accessories,Fashion_Accessories
fashion_childrens_clothes,Baby_Toys
fashion_male_clothing,Fashion_Accessories
fashion_shoes,Fashion_Accessories
fashion_sport,Sports_Leisure
fashion_underwear_beach,Fashion_Accessories
fixed_telephony,Electronics_Computers_Telecom
flowers,Office_Industry_Auto
food,Food_Drinks
food_drink,Food_Drinks
furniture_bedroom,Home_Furniture_Appliances
furniture_decor,Home_Furniture_Appliances
furniture_living_room,Home_Furniture_Appliances
furniture_mattress_and_upholstery,Home_Furniture_Appliances
garden_tools,Construction_Tools_Garden
health_beauty,Health_Beauty
home_appliances,Home_Furniture_Appliances
home_appliances_2,Home_Furniture_Appliances
home_comfort_2,Home_Furniture_Appliances
home_confort,Home_Furniture_Appliances
home_construction,Construction_Tools_Garden
housewares,Home_Furniture_Appliances
industry_commerce_and_business,Office_Industry_Auto
kitchen_dining_laundry_garden_furniture,Home_Furniture_Appliances
la_cuisine,Home_Furniture_Appliances
luggage_accessories,Fashion_Accessories
market_place,Office_Industry_Auto
music,Books_Media_Arts
musical_instruments,Books_Media_Arts
office_furniture,Office_Industry_Auto
party_supplies,Office_Industry_Auto
perfumery,Health_Beauty
pet_shop,Office_Industry_Auto
security_and_services,Office_Industry_Auto
signaling_and_security,Electronics_Computers_Telecom
small_appliances,Home_Furniture_Appliances
small_appliances_home_oven_and_coffee,Home_Furniture_Appliances
sports_leisure,Sports_Leisure
stationery,Office_Industry_Auto
tablets_printing_image,Electronics_Computers_Telecom
telephony,Electronics_Computers_Telecom
toys,Baby_Toys
watches_gifts,Fashion_Accessories
"
category_map <- read_csv(mapping_csv)
olist_clean2 <- olist %>%
  left_join(category_map, by = c("product_category_name_english" = "Original_Label")) %>%
  mutate(
    New_Category = as.factor(New_Category),
    New_Category = tidyr::replace_na(New_Category, "Office_Industry_Auto") 
  )
table(olist_clean2$New_Category)


# 建立模型
olist_clean2$New_Category <- relevel(as.factor(olist_clean2$New_Category), 
                                     ref = "Books_Media_Arts")
lm.2 <- lm(review_score ~ New_Category, 
                 data = olist_clean2)
summary(lm.2)


# =======================================================
# 階段五：GLM 二元模型分析（原始資料）
# =======================================================

# 定義負評
olist_logit <- olist_clean2 %>%
  mutate(is_bad_review = ifelse(review_score <= 4, 1, 0))


# 跑GLM (family = binomial)
olist_logit$product_category_name_english <- relevel(as.factor(olist_logit$product_category_name_english), 
                                                     ref = "books_general_interest")
glm_b1 <- glm(is_bad_review ~ product_category_name_english, 
                 data = olist_logit, 
                 family = binomial)
summary(glm_b1)

# Odds Ratio
logit_results <- summary(glm_b1)$coefficients %>%
  as.data.frame() %>%
  rownames_to_column(var = "Category") %>%
  filter(`Pr(>|z|)` < 0.05) %>%
  mutate(Category = str_replace(Category, "product_category_name_english", "")) %>%
  mutate(Odds_Ratio = exp(Estimate)) %>%
  arrange(desc(Odds_Ratio)) 
cat("\n=== 最容易拿負評的類別 (Odds Ratio > 1) ===\n")
print(head(logit_results, 10))



# =======================================================
# 階段六：GLM 二元模型分析（十大類）
# =======================================================

# 跑GLM (family = binomial)
olist_logit$New_Category <- relevel(as.factor(olist_logit$New_Category), 
                                                     ref = "Books_Media_Arts")
glm.b2 <- glm(is_bad_review ~ New_Category, 
              data = olist_logit, 
                   family = binomial)
summary(glm.b2)

# Odds Ratio
logit_results_10 <- summary(glm.b2)$coefficients %>%
  as.data.frame() %>%
  rownames_to_column(var = "Category") %>%
  filter(`Pr(>|z|)` < 0.05) %>%
  mutate(Category = str_replace(Category, "New_Category", "")) %>%
  mutate(Odds_Ratio = exp(Estimate)) %>%
  arrange(desc(Odds_Ratio))
cat("\n=== 十大分類：最容易拿負評的類別 (Odds Ratio > 1) ===\n")
print(logit_results_10)

