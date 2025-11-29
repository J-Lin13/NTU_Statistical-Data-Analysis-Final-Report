***巴西 Olist 電商平台顧客評論分數之預測模型分析***

本專案在探討巴西最大電商平台 Olist 的顧客購物體驗，並建立一個多元線性迴歸模型，以預測顧客留下的評論分數 (1-5分)。我們將整合來自多個資料表的訂單、商品、運送與顧客數據，分析影響顧客滿意度的變數，特別是物流效率與商品屬性等角色。

## 1. 研究問題
本研究希望回答以下商業問題：
1. 在影響顧客評論分數的眾多因素中，哪些是最關鍵的預測變數？
   例如：物流效率、交易成本、商品本身的規格？
2. 如何精確量化物流服務品質對顧客滿意度的影響？
   例如：訂單每延遲一天送達，預期會對評論分數造成多大的負面效果？
3. 是否存在特定的商品類別，顧客滿意度有系統性的偏高或偏低？

## 2. 資料來源
本專案將使用 Kaggle 平台上的公開資料集：「Brazilian E-Commerce Public Dataset by Olist」。此資料集由 Olist 官方提供，包含從 2016 年至 2018 年間約 10 萬筆真實交易數據，其結構由多個關聯的 CSV 檔案組成。
資料集網址： https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

## 3. 變數規劃
**應變數** : review_score: (1-5分)。此變數將被視為連續型變數處理。

**自變數** : 
- 物流效率變數 : delivery_days、delivery_gap
- 交易成本變數 : price、freight_value
- 商品屬性變數 : product_category_name、product_weight_g、product_photos_qty
- 其他控制變數 : payment_type、payment_installments

## 4. 預期結果與分析方法
在資料前處理上，我們將以 dplyr 合併多個資料表，並建立 delivery_days、delivery_gap 等衍生變數；透過 summary()、hist()、boxplot() 進行初步資料分布與異常值檢查。接著使用 lm() 建立多元迴歸模型，並以 step() 搭配 AIC 進行逐步選模，以得到解釋力佳且結構精簡的變數組合，避免多重共線性問題。

模型建立後，我們將透過殘差圖與 QQ Plot 檢驗常態性、獨立性與變異數同質性；若觀察到異質性變異或偏態，會視情況對相關自變數進行適度轉換，以提升模型適配度。

在結果與應用方面，我們預期 delivery_gap 會呈現顯著正向效果，支持「準時或提前送達能提升顧客滿意度」的假設。我們亦將量化各顯著變數的邊際影響，並透過product_category_name 的虛擬變數辨識滿意度較低的品類，作為平台優化的依據。

---

## 📁 專案結構

本專案使用 SQL 進行資料合併，並準備進行後續的資料前處理和統計分析。

```
NTU_Statistical-Data-Analysis-Final-Report/
│
├── csv/                          # 原始 CSV 資料夾
│   ├── olist_customers_dataset.csv
│   ├── olist_orders_dataset.csv
│   ├── olist_order_items_dataset.csv
│   ├── olist_order_payments_dataset.csv
│   ├── olist_order_reviews_dataset.csv
│   ├── olist_products_dataset.csv
│   ├── olist_sellers_dataset.csv
│   ├── olist_geolocation_dataset.csv
│   ├── product_category_name_translation.csv
│   └── README.md
│
├── sql_merge/                    # SQL 資料合併資料夾
│   ├── load_and_merge_data.py   # Python 自動化腳本
│   ├── merge_data.sql           # 完整 SQL 腳本
│   ├── merge_query.sql          # 核心合併查詢
│   ├── merged_olist_data.csv    # 合併後的資料輸出
│   ├── olist_data.db            # SQLite 資料庫（儲存所有 CSV 資料）
│   ├── DATA_MERGE_GUIDE.md      # 詳細使用指南
│   └── README.md
│
├── ReadMe.md                     # 本檔案（專案說明文件）
├── requirements.txt              # Python 套件依賴
└── PROJECT_STRUCTURE.md          # 專案結構說明（可選參考）
```

## 📝 資料夾說明

### `csv/` - 原始資料
存放所有來自 Kaggle 的原始 CSV 資料檔案，包括：
- 顧客、訂單、商品、賣家等各類資料表
- 商品類別翻譯對照表
- **建議：不要直接修改這些原始檔案**

### `sql_merge/` - 資料合併
包含所有與資料合併相關的檔案：
- **Python 腳本**：自動載入 CSV 並執行 SQL 合併
- **SQL 檔案**：資料合併的查詢語句
- **合併後的資料**：`merged_olist_data.csv` 包含所有需要的欄位
- **資料庫檔案**：`olist_data.db` 是 SQLite 資料庫，用於儲存所有 CSV 資料並執行 SQL 查詢。當執行 `load_and_merge_data.py` 時，腳本會將所有 CSV 檔案載入到這個資料庫中，然後在資料庫中執行 SQL 查詢來合併資料。

## 🚀 使用方式

### 執行資料合併

從專案根目錄執行：
```bash
python sql_merge/load_and_merge_data.py
```

或進入 sql_merge 資料夾執行：
```bash
cd sql_merge
python load_and_merge_data.py
```

### 下一步工作

合併後的資料 (`sql_merge/merged_olist_data.csv`) 可用於：
1. ✅ 資料合併（已完成）
2. ⏳ 資料前處理
3. ⏳ 敘述性統計分析
4. ⏳ 迴歸模型建立

## 📊 合併後的資料欄位

- **應變數**：`review_score` (1-5分)
- **物流變數**：`delivery_days`, `delivery_gap`
- **交易成本**：`price`, `freight_value`
- **商品屬性**：`product_category_name`, `product_weight_g`, `product_photos_qty`
- **控制變數**：`payment_type`, `payment_installments`

詳見各資料夾中的 README.md 獲取更多資訊。
