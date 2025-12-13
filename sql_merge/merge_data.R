# ============================================================================
# 巴西 Olist 電商平台資料合併腳本（R 版本）
# ============================================================================
# 使用 R/dplyr 將多個 CSV 檔案合併為單一訂單層級資料集
# ============================================================================

merge_olist_data <- function(csv_dir = "csv", output_path = "sql_merge/merged_olist_data.csv") {
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
  cat("\n處理日期欄位...\n")
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
  cat("  ✓ 日期欄位轉換完成\n")
  
  # 步驟 1: 選擇最佳評論（最接近送達日期的評論）
  cat("\n步驟 1: 選擇最佳評論...\n")
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
  cat(sprintf("  ✓ 選出 %s 筆最佳評論\n", format(nrow(review_best), big.mark = ",")))
  
  # 步驟 2: 聚合商品項目
  cat("\n步驟 2: 聚合商品項目...\n")
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
  cat(sprintf("  ✓ 聚合 %s 筆訂單的商品資訊\n", format(nrow(items_agg), big.mark = ",")))
  
  # 步驟 3: 列出所有商品ID和類別
  cat("\n步驟 3: 列出商品ID和類別...\n")
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
  cat(sprintf("  ✓ 處理 %s 筆訂單的商品列表\n", format(nrow(items_list), big.mark = ",")))
  
  # 步驟 4: 找出主要商品類別
  cat("\n步驟 4: 找出主要商品類別...\n")
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
  cat(sprintf("  ✓ 找出 %s 筆訂單的主要類別\n", format(nrow(order_cat), big.mark = ",")))
  
  # 步驟 5: 找出主要賣家
  cat("\n步驟 5: 找出主要賣家...\n")
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
  cat(sprintf("  ✓ 找出 %s 筆訂單的主要賣家\n", format(nrow(seller_order), big.mark = ",")))
  
  # 步驟 6: 聚合付款資訊
  cat("\n步驟 6: 聚合付款資訊...\n")
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
  cat(sprintf("  ✓ 處理 %s 筆訂單的付款資訊\n", format(nrow(pay_agg), big.mark = ",")))
  
  # 步驟 7: 評論統計
  cat("\n步驟 7: 計算評論統計...\n")
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
  cat(sprintf("  ✓ 計算 %s 筆訂單的評論統計\n", format(nrow(review_stats), big.mark = ",")))
  
  # 步驟 8: 合併所有資料
  cat("\n步驟 8: 合併所有資料...\n")
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
    filter(
      order_status == "delivered",
      !is.na(order_delivered_customer_date),
      !is.na(order_purchase_timestamp),
      !is.na(order_estimated_delivery_date),
      !is.na(review_score)
    ) %>%
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
  
  cat(sprintf("  ✓ 合併完成，共 %s 筆記錄\n", format(nrow(merged_data), big.mark = ",")))
  
  # 儲存為 CSV
  if (!dir.exists(dirname(output_path))) {
    dir.create(dirname(output_path), recursive = TRUE)
  }
  write_csv(merged_data, output_path)
  cat(sprintf("\n✓ 合併後的資料已儲存至: %s\n", output_path))
  cat(sprintf("  總筆數: %s 筆\n", format(nrow(merged_data), big.mark = ",")))
  cat(sprintf("  欄位數: %d 欄\n", ncol(merged_data)))
  
  return(merged_data)
}

