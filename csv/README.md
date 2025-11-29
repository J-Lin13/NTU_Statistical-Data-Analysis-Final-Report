# CSV 原始資料夾

此資料夾包含所有 Olist 電商平台的原始 CSV 資料檔案。

## 檔案清單

- **olist_customers_dataset.csv** - 顧客資料
- **olist_orders_dataset.csv** - 訂單資料
- **olist_order_items_dataset.csv** - 訂單項目資料
- **olist_order_payments_dataset.csv** - 付款資料
- **olist_order_reviews_dataset.csv** - 評論資料（包含應變數 review_score）
- **olist_products_dataset.csv** - 商品資料
- **olist_sellers_dataset.csv** - 賣家資料
- **olist_geolocation_dataset.csv** - 地理位置資料
- **product_category_name_translation.csv** - 商品類別英文翻譯對照表

## 資料來源

資料集來自 Kaggle: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

## 使用方式

這些原始 CSV 檔案會由 `sql_merge/load_and_merge_data.py` 腳本讀取並進行合併處理。

建議不要直接修改這些原始資料檔案，以保持資料完整性。

