# SQL 資料合併資料夾

此資料夾包含所有與資料合併相關的檔案。

## 檔案說明

- **load_and_merge_data.py** - Python 自動化腳本，用於載入 CSV 並執行 SQL 合併
- **merge_data.sql** - 完整的 SQL 腳本（包含 VIEW 建立和查詢）
- **merge_query.sql** - 核心合併查詢語句
- **merged_olist_data.csv** - 合併後的資料輸出檔
- **olist_data.db** - SQLite 資料庫檔案（包含載入的所有 CSV 資料）
- **DATA_MERGE_GUIDE.md** - 詳細的使用指南

## 使用方法

### 執行資料合併

從專案根目錄執行：
```bash
cd sql_merge
python load_and_merge_data.py
```

或在根目錄執行：
```bash
python sql_merge/load_and_merge_data.py
```

### 注意事項

- 原始 CSV 檔案位於 `../csv/` 資料夾
- 腳本會自動從 `csv` 資料夾讀取 CSV 檔案
- 合併後的資料會輸出為 `merged_olist_data.csv`（在此資料夾中）

## 資料結構

合併後的資料包含以下主要欄位：
- **應變數**: review_score (1-5分)
- **物流變數**: delivery_days, delivery_gap
- **交易成本**: price, freight_value
- **商品屬性**: product_category_name, product_weight_g, product_photos_qty
- **控制變數**: payment_type, payment_installments

詳見 `DATA_MERGE_GUIDE.md` 獲取更多資訊。


