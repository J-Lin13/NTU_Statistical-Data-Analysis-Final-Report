-- 巴西 Olist 電商平台資料合併查詢
-- 這是核心的合併查詢語句，可以直接執行並匯出結果

SELECT 
    -- Review 相關變數（應變數）
    rev.review_id,
    rev.review_score,  -- 應變數：1-5分
    rev.review_creation_date,
    rev.review_answer_timestamp,
    
    -- Order 相關變數
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    
    -- 計算物流效率變數
    -- delivery_days: 從訂單購買到送達顧客的天數
    CAST((julianday(o.order_delivered_customer_date) - julianday(o.order_purchase_timestamp)) AS INTEGER) AS delivery_days,
    
    -- delivery_gap: 實際送達日期與預估送達日期的差距（天數）
    -- 正數表示延遲，負數表示提前
    CAST((julianday(o.order_delivered_customer_date) - julianday(o.order_estimated_delivery_date)) AS INTEGER) AS delivery_gap,
    
    -- Customer 相關變數
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,
    
    -- Order Items 相關變數（交易成本變數）
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.price,  -- 商品價格
    oi.freight_value,  -- 運費
    oi.shipping_limit_date,
    
    -- Product 相關變數（商品屬性變數）
    p.product_category_name,  -- 商品類別（葡萄牙文）
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,  -- 商品照片數量
    p.product_weight_g,  -- 商品重量（公克）
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    
    -- 商品類別英文翻譯
    pc.product_category_name_english,
    
    -- Payment 相關變數（控制變數）
    pay.payment_sequential,
    pay.payment_type,  -- 付款方式
    pay.payment_installments,  -- 分期付款期數
    pay.payment_value,  -- 付款金額
    
    -- Seller 相關變數
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state
    
FROM olist_order_reviews_dataset rev
-- JOIN orders 表（一個 review 對應一個 order）
INNER JOIN olist_orders_dataset o 
    ON rev.order_id = o.order_id
    
-- JOIN customers 表（一個 order 對應一個 customer）
INNER JOIN olist_customers_dataset c 
    ON o.customer_id = c.customer_id
    
-- JOIN order_items 表（一個 order 可能有多個 items）
LEFT JOIN olist_order_items_dataset oi 
    ON o.order_id = oi.order_id
    
-- JOIN products 表（一個 item 對應一個 product）
LEFT JOIN olist_products_dataset p 
    ON oi.product_id = p.product_id
    
-- JOIN product category translation 表
LEFT JOIN product_category_name_translation pc 
    ON p.product_category_name = pc.product_category_name
    
-- JOIN payments 表（一個 order 可能有多個 payment records）
LEFT JOIN olist_order_payments_dataset pay 
    ON o.order_id = pay.order_id
    
-- JOIN sellers 表（一個 item 對應一個 seller）
LEFT JOIN olist_sellers_dataset s 
    ON oi.seller_id = s.seller_id

-- 過濾條件：只保留已送達的訂單（因為需要 delivery date 來計算物流變數）
WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_purchase_timestamp IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
    AND rev.review_score IS NOT NULL
;

