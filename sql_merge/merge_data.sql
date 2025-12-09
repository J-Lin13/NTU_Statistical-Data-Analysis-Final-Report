-- 巴西 Olist 電商平台資料合併 SQL 腳本（訂單層級，一單一列）
-- 重點：避免多對多 JOIN 倍增；將付款與商品聚合至「每訂單」層級

DROP VIEW IF EXISTS merged_olist_data;

CREATE VIEW merged_olist_data AS
WITH
-- 一筆訂單只保留一筆評論（選「最接近實際送達日」的評論，若有並列取較晚的）
review_best_candidates AS (
  SELECT 
    r.order_id,
    r.review_id,
    r.review_score,
    r.review_creation_date,
    r.review_answer_timestamp,
    ABS(julianday(r.review_creation_date) - julianday(o.order_delivered_customer_date)) AS diff_days_to_delivery
  FROM olist_order_reviews_dataset r
  JOIN olist_orders_dataset o ON r.order_id = o.order_id
  WHERE r.review_score IS NOT NULL
),
review_best_min AS (
  SELECT 
    order_id,
    MIN(diff_days_to_delivery) AS min_diff
  FROM review_best_candidates
  GROUP BY order_id
),
review_best_ties AS (
  SELECT c.*
  FROM review_best_candidates c
  JOIN review_best_min m
    ON c.order_id = m.order_id
   AND c.diff_days_to_delivery = m.min_diff
),
review_best AS (
  SELECT t.order_id,
         t.review_id,
         t.review_score,
         t.review_creation_date,
         t.review_answer_timestamp
  FROM review_best_ties t
  JOIN (
    SELECT order_id, MAX(review_creation_date) AS last_dt
    FROM review_best_ties
    GROUP BY order_id
  ) mx
  ON t.order_id = mx.order_id AND t.review_creation_date = mx.last_dt
),
-- 商品層級聚合到訂單層級
items_agg AS (
  SELECT 
    oi.order_id,
    COUNT(*) AS num_items,
    COUNT(DISTINCT oi.product_id) AS num_products,
    SUM(oi.price) AS total_price,
    SUM(oi.freight_value) AS total_freight_value,
    AVG(p.product_weight_g) AS avg_product_weight_g,
    AVG(p.product_photos_qty) AS avg_product_photos_qty
  FROM olist_order_items_dataset oi
  LEFT JOIN olist_products_dataset p ON oi.product_id = p.product_id
  GROUP BY oi.order_id
),
-- 產品/類別清單（每訂單）
items_list AS (
  SELECT 
    oi.order_id,
    GROUP_CONCAT(DISTINCT oi.product_id) AS product_ids,
    GROUP_CONCAT(DISTINCT pc.product_category_name_english) AS product_categories,
    COUNT(DISTINCT pc.product_category_name_english) AS num_distinct_categories
  FROM olist_order_items_dataset oi
  LEFT JOIN olist_products_dataset p ON oi.product_id = p.product_id
  LEFT JOIN product_category_name_translation pc 
    ON p.product_category_name = pc.product_category_name
  GROUP BY oi.order_id
),
-- 每訂單的主商品類別（出現次數最多者，平手時取字母序最小）
item_cats AS (
  SELECT 
    oi.order_id,
    p.product_category_name AS product_category_name,
    pc.product_category_name_english AS product_category_name_english,
    COUNT(*) AS cnt
  FROM olist_order_items_dataset oi
  LEFT JOIN olist_products_dataset p ON oi.product_id = p.product_id
  LEFT JOIN product_category_name_translation pc 
    ON p.product_category_name = pc.product_category_name
  GROUP BY oi.order_id, p.product_category_name, pc.product_category_name_english
),
order_cat AS (
  SELECT DISTINCT ic.order_id,
    -- 以次數排序，平手用名稱字母序，取第一筆
    (SELECT ic2.product_category_name
     FROM item_cats ic2
     WHERE ic2.order_id = ic.order_id
     ORDER BY ic2.cnt DESC, ic2.product_category_name
     LIMIT 1) AS product_category_name,
    (SELECT ic3.product_category_name_english
     FROM item_cats ic3
     WHERE ic3.order_id = ic.order_id
     ORDER BY ic3.cnt DESC, ic3.product_category_name_english
     LIMIT 1) AS product_category_name_english,
    (SELECT ic4.cnt
     FROM item_cats ic4
     WHERE ic4.order_id = ic.order_id
     ORDER BY ic4.cnt DESC, ic4.product_category_name
     LIMIT 1) AS primary_category_count
  FROM item_cats ic
),
-- Seller 聚合與主賣家識別
seller_counts AS (
  SELECT oi.order_id, oi.seller_id, COUNT(*) AS seller_item_count
  FROM olist_order_items_dataset oi
  GROUP BY oi.order_id, oi.seller_id
),
seller_order AS (
  SELECT DISTINCT sc.order_id,
    (SELECT sc2.seller_id
     FROM seller_counts sc2
     WHERE sc2.order_id = sc.order_id
     ORDER BY sc2.seller_item_count DESC, sc2.seller_id
     LIMIT 1) AS primary_seller_id,
    (SELECT sc3.seller_item_count
     FROM seller_counts sc3
     WHERE sc3.order_id = sc.order_id
     ORDER BY sc3.seller_item_count DESC, sc3.seller_id
     LIMIT 1) AS primary_seller_item_count,
    (SELECT COUNT(*)
     FROM seller_counts sc4
     WHERE sc4.order_id = sc.order_id) AS num_sellers
  FROM seller_counts sc
),
-- 付款彙總與第一筆付款方式
pay_agg AS (
  SELECT 
    order_id,
    SUM(payment_value) AS total_payment_value,
    MAX(payment_installments) AS max_payment_installments
  FROM olist_order_payments_dataset
  GROUP BY order_id
),
pay_first AS (
  SELECT order_id, MIN(payment_sequential) AS min_seq
  FROM olist_order_payments_dataset
  GROUP BY order_id
),
pay_method AS (
  SELECT p.order_id, p.payment_type
  FROM olist_order_payments_dataset p
  JOIN pay_first pf 
    ON p.order_id = pf.order_id AND p.payment_sequential = pf.min_seq
),
-- 評論統計（每訂單）
review_stats AS (
  SELECT 
    r.order_id,
    COUNT(*) AS review_count,
    COUNT(DISTINCT r.review_score) AS review_distinct_scores,
    MIN(r.review_creation_date) AS first_review_creation_date,
    MAX(r.review_creation_date) AS last_review_creation_date,
    -- 首次與最後一次的評分
    (SELECT r2.review_score 
     FROM olist_order_reviews_dataset r2 
     WHERE r2.order_id = r.order_id 
     ORDER BY r2.review_creation_date ASC 
     LIMIT 1) AS first_review_score,
    (SELECT r3.review_score 
     FROM olist_order_reviews_dataset r3 
     WHERE r3.order_id = r.order_id 
     ORDER BY r3.review_creation_date DESC 
     LIMIT 1) AS last_review_score
  FROM olist_order_reviews_dataset r
  GROUP BY r.order_id
)
SELECT 
  -- Review（應變數）
  rv.review_id,
  rv.review_score,
  rv.review_creation_date,
  rv.review_answer_timestamp,
  -- Review 統計（診斷用）
  rs.review_count,
  rs.review_distinct_scores,
  rs.first_review_creation_date,
  rs.last_review_creation_date,
  rs.first_review_score,
  rs.last_review_score,
  CASE WHEN rs.review_count > 1 THEN 1 ELSE 0 END AS has_multiple_reviews,
  CASE WHEN rs.review_distinct_scores > 1 THEN 1 ELSE 0 END AS has_mixed_review_scores,
    
  -- Order
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    
  -- 物流效率
    CAST(julianday(o.order_delivered_customer_date) - julianday(o.order_purchase_timestamp) AS INTEGER) AS delivery_days,
    CAST(julianday(o.order_delivered_customer_date) - julianday(o.order_estimated_delivery_date) AS INTEGER) AS delivery_gap,
    
  -- Customer
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,
    
  -- Items（已聚合，並保留與原欄位同名以兼容後續腳本）
  ia.num_items,
  ia.num_products,
  ia.total_price AS price,
  ia.total_freight_value AS freight_value,
  oc.product_category_name,
  oc.product_category_name_english,
  ia.avg_product_photos_qty AS product_photos_qty,
  ia.avg_product_weight_g AS product_weight_g,
  il.product_ids,
  il.product_categories,
  il.num_distinct_categories,
  CASE 
    WHEN ia.num_items IS NOT NULL AND ia.num_items > 0 
    THEN 1.0 * oc.primary_category_count / ia.num_items 
    ELSE NULL 
  END AS primary_category_share,
  
  -- Seller（訂單層級）
  so.num_sellers,
  so.primary_seller_id,
  s.seller_zip_code_prefix AS primary_seller_zip_code_prefix,
  s.seller_city AS primary_seller_city,
  s.seller_state AS primary_seller_state,
  CASE 
    WHEN ia.num_items IS NOT NULL AND ia.num_items > 0 
    THEN 1.0 * so.primary_seller_item_count / ia.num_items 
    ELSE NULL 
  END AS primary_seller_share,
  
  -- Payments（已聚合，並保留欄位名稱以兼容後續腳本）
  pm.payment_type,
  pa.max_payment_installments AS payment_installments,
  pa.total_payment_value AS payment_value
FROM review_best rv
JOIN olist_orders_dataset o 
  ON rv.order_id = o.order_id
JOIN olist_customers_dataset c 
    ON o.customer_id = c.customer_id
LEFT JOIN items_agg ia 
  ON o.order_id = ia.order_id
LEFT JOIN order_cat oc
  ON o.order_id = oc.order_id
LEFT JOIN items_list il
  ON o.order_id = il.order_id
LEFT JOIN seller_order so
  ON o.order_id = so.order_id
LEFT JOIN olist_sellers_dataset s 
  ON so.primary_seller_id = s.seller_id
LEFT JOIN pay_agg pa
  ON o.order_id = pa.order_id
LEFT JOIN pay_method pm
  ON o.order_id = pm.order_id
LEFT JOIN review_stats rs
  ON rv.order_id = rs.order_id
WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_purchase_timestamp IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND rv.review_score IS NOT NULL;

