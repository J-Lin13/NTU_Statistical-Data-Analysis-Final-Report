# 資料合併使用指南

## 概述
此資料合併作業使用 SQL 來整合多個 Olist 電商平台的 CSV 資料表，準備進行後續的資料前處理和統計分析。

## 資料表關係圖

```
olist_order_reviews_dataset (應變數：review_score)
    ↓ (order_id)
olist_orders_dataset
    ↓ (customer_id)                    ↓ (order_id)
olist_customers_dataset         olist_order_items_dataset
                                    ↓ (product_id)     ↓ (seller_id)
                                olist_products_dataset    olist_sellers_dataset
                                    ↓ (product_category_name)
                                product_category_name_translation
    
                                olist_order_payments_dataset (order_id)
```

## 檔案說明

1. **merge_data.sql** - 完整的 SQL 腳本，包含 VIEW 建立和多個查詢語句
2. **merge_query.sql** - 核心合併查詢語句（可直接執行）
3. **load_and_merge_data.py** - Python 自動化腳本，會自動載入 CSV 並執行合併

## 使用方法

### 方法一：使用 Python 自動化腳本（推薦）

這是最簡單的方法，腳本會自動完成所有步驟：

```bash
# 安裝必要的套件（如果尚未安裝）
pip install pandas

# 執行腳本
python load_and_merge_data.py
```

執行後會：
1. 自動載入所有 CSV 檔案到 SQLite 資料庫
2. 執行 SQL 合併查詢
3. 匯出合併後的資料為 `merged_olist_data.csv`

### 方法二：手動使用 SQLite 資料庫

如果您想手動操作 SQL：

1. **安裝 SQLite**
   - 下載並安裝 SQLite：https://www.sqlite.org/download.html

2. **載入 CSV 檔案到 SQLite**
   ```bash
   sqlite3 olist_data.db
   ```
   
   在 SQLite 命令列中：
   ```sql
   .mode csv
   .import olist_customers_dataset.csv olist_customers_dataset
   .import olist_orders_dataset.csv olist_orders_dataset
   .import olist_order_items_dataset.csv olist_order_items_dataset
   .import olist_order_payments_dataset.csv olist_order_payments_dataset
   .import olist_order_reviews_dataset.csv olist_order_reviews_dataset
   .import olist_products_dataset.csv olist_products_dataset
   .import olist_sellers_dataset.csv olist_sellers_dataset
   .import product_category_name_translation.csv product_category_name_translation
   ```

3. **執行 SQL 合併查詢**
   ```sql
   .read merge_query.sql
   ```

4. **匯出結果**
   ```sql
   .mode csv
   .headers on
   .output merged_olist_data.csv
   -- 執行 merge_query.sql 中的查詢
   ```

### 方法三：使用其他 SQL 工具

您也可以使用其他支援 SQL 的工具，如：
- **DB Browser for SQLite**（圖形化介面）
- **DBeaver**
- **Microsoft SQL Server Management Studio**（需要先轉換資料）

## 合併後的資料欄位說明

### 應變數（Dependent Variable）
- `review_score`: 顧客評論分數（1-5分）

### 自變數（Independent Variables）

#### 物流效率變數
- `delivery_days`: 從訂單購買到送達顧客的天數
- `delivery_gap`: 實際送達日期與預估送達日期的差距（正數=延遲，負數=提前）

#### 交易成本變數
- `price`: 商品價格
- `freight_value`: 運費

#### 商品屬性變數
- `product_category_name`: 商品類別（葡萄牙文）
- `product_category_name_english`: 商品類別（英文）
- `product_weight_g`: 商品重量（公克）
- `product_photos_qty`: 商品照片數量

#### 控制變數
- `payment_type`: 付款方式
- `payment_installments`: 分期付款期數

### 其他欄位
- 訂單相關：`order_id`, `order_status`, `order_purchase_timestamp` 等
- 顧客相關：`customer_id`, `customer_state`, `customer_city` 等
- 商品相關：`product_id`, `product_length_cm`, `product_height_cm` 等
- 賣家相關：`seller_id`, `seller_state`, `seller_city` 等

## 資料篩選條件

合併查詢會自動過濾：
- 只保留 `order_status = 'delivered'` 的訂單
- 必須有完整的送達日期資訊（用於計算物流變數）
- 必須有評論分數（應變數）

## 注意事項

1. **一對多關係處理**：
   - 一個訂單可能有多個商品（order_items）
   - 一個訂單可能有多筆付款記錄（payments）
   - 因此合併後的資料可能會有重複的 order_id

2. **日期格式**：
   - SQLite 使用 `julianday()` 函數計算日期差
   - 確保日期欄位格式正確（YYYY-MM-DD HH:MM:SS）

3. **缺失值處理**：
   - 使用 `LEFT JOIN` 保留所有評論記錄
   - 部分欄位可能會有 NULL 值，需要在後續資料前處理中處理

## 後續步驟

合併完成後，建議進行：
1. 資料前處理（處理缺失值、異常值）
2. 敘述性統計分析
3. 變數探索性分析
4. 模型建立與評估

## 問題排除

如果遇到問題：

1. **CSV 檔案找不到**：確認所有 CSV 檔案都在同一目錄下
2. **日期計算錯誤**：檢查日期欄位格式是否正確
3. **記憶體不足**：考慮分批處理資料或增加系統記憶體
4. **編碼問題**：確保 CSV 檔案使用 UTF-8 編碼

## 聯絡資訊

如有任何問題，請參考專案 README 或聯繫專案成員。

