# SQL 資料合併（sql_merge）

此資料夾包含所有與資料合併與匯出相關的檔案與說明。內容已整合原本的 DATA_MERGE_GUIDE，並更新為「每訂單一列」的合併規則。

## 檔案說明

- `load_and_merge_data.py`：自動化腳本，載入 CSV→建立索引→建立合併 VIEW→匯出 CSV
- `merge_data.sql`：完整 SQL（建立 VIEW `merged_olist_data`，訂單層級聚合）
- `merge_query.sql`：與 VIEW 同邏輯的查詢（可直接在 SQLite 執行）
- `merged_olist_data.csv`：合併後輸出
- `olist_data.db`：SQLite 資料庫（載入所有 CSV 後的工作庫）

## 使用方法（推薦）

從專案根目錄執行：
```bash
python sql_merge/load_and_merge_data.py
```
或進入本資料夾執行：
```bash
cd sql_merge
python load_and_merge_data.py
```

腳本流程：
1) 載入 `csv/` 內所有原始 CSV 至 `olist_data.db`
2) 建立主要索引以加速（orders/reviews/items/products/payments/sellers 等）
3) 依 `merge_data.sql` 建立 VIEW：`merged_olist_data`
4) 以 `SELECT * FROM merged_olist_data` 匯出為 `merged_olist_data.csv`
5) 輸出摘要統計（含唯一訂單/顧客數等）

## 合併規則（重點）

- 層級：每訂單一列（one order per row）
- 評論選取：同一訂單若有多筆 review，選「距離實際送達日最近」者；若有並列，取時間較晚者
- 運送變數：以 `orders` 的日期欄位計算
  - `delivery_days = delivered_customer_date - purchase_timestamp`
  - `delivery_gap = delivered_customer_date - estimated_delivery_date`
- 付款聚合（per order）：
  - `payment_type`：以第一筆付款（payment_sequential 最小）代表
  - `payment_installments`：最大期數
  - `payment_value`：總付款金額
- 商品聚合（per order）：
  - 價格與運費：`price`（總價）、`freight_value`（總運費）
  - 數量：`num_items`、`num_products`
  - 平均屬性：`product_photos_qty`（平均）、`product_weight_g`（平均）
  - 主類別：`product_category_name_english`（出現次數最多）
  - 類別與商品清單：`product_categories`、`product_ids`（去重後以逗號分隔）
  - 類別多樣性：`num_distinct_categories`、`primary_category_share`
- 賣家聚合（per order）：
  - `num_sellers`、`primary_seller_id`、`primary_seller_city/state/zip`
  - `primary_seller_share`（主賣家品項占比）
- 評論診斷欄位：
  - `review_count`、`review_distinct_scores`、`has_multiple_reviews`、`has_mixed_review_scores`
  - `first_review_*`、`last_review_*`（時間與分數）

## 主要欄位

- 應變數：`review_score`
- 物流：`delivery_days`, `delivery_gap`
- 交易/付款：`price`, `freight_value`, `payment_type`, `payment_installments`, `payment_value`
- 商品聚合：`product_category_name_english`, `product_photos_qty`, `product_weight_g`,
  `num_items`, `num_products`, `num_distinct_categories`, `primary_category_share`,
  `product_categories`, `product_ids`
- 賣家聚合：`num_sellers`, `primary_seller_id`, `primary_seller_city`, `primary_seller_state`,
  `primary_seller_zip_code_prefix`, `primary_seller_share`
- 診斷：`review_count`, `review_distinct_scores`, `has_multiple_reviews`, `has_mixed_review_scores`,
  `first_review_creation_date`, `last_review_creation_date`, `first_review_score`, `last_review_score`

## 手動（SQLite）操作

列出資料表與 VIEW：
```sql
.tables
```
查看合併後資料：
```sql
SELECT COUNT(*) FROM merged_olist_data;
SELECT * FROM merged_olist_data LIMIT 5;
```
若需直接執行查詢（不使用 VIEW）：
```sql
.read merge_query.sql
```

## 效能建議

- 索引：腳本已自動建立主要索引（orders/reviews/items/products/payments/sellers）
- 可選 PRAGMA（手動一次性測試）：
```sql
PRAGMA journal_mode=WAL;
PRAGMA synchronous=OFF;
PRAGMA temp_store=MEMORY;
PRAGMA cache_size=-200000;   -- 約 200k pages
PRAGMA mmap_size=134217728;  -- 128MB
```
- 實體化：如需重複查詢，可先建立實體表加索引再輸出

## 常見問題

- CSV 找不到：確認 `csv/` 路徑與檔名
- 欄位不存在：訂單層級輸出不包含逐商品欄位（例如 `product_id`），請改用聚合欄位或清單欄位
- 匯出很慢：先建立索引、必要時啟用 PRAGMA 或先實體化再匯出
