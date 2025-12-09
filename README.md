# NTU_Statistical-Data-Analysis-Final-Report

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
- 物流效率變數 : delivery_days、delivery_gap（以訂單層級日期計算）
- 交易成本變數 : price（每單總價）、freight_value（每單總運費）
- 商品屬性變數 : 
  - product_category_name_english（主類別；每單出現最多的品類）
  - product_photos_qty（每單平均）、product_weight_g（每單平均）
  - num_products、num_items、num_distinct_categories、primary_category_share
  - product_categories、product_ids（每單去重清單，逗號分隔）
- 付款控制變數 : payment_type（以第一筆付款為代表）、payment_installments（每單最大期數）、payment_value（每單總額）
- 賣家控制變數 : num_sellers、primary_seller_id、primary_seller_city/state/zip、primary_seller_share

## 4. 預期結果與分析方法
在資料前處理上，我們以 SQL 於訂單層級整併多表（每單一列）、建立 delivery_days、delivery_gap 等衍生變數；透過 summary()、hist()、boxplot() 進行初步資料分布與異常值檢查。接著使用 lm() 建立多元迴歸模型，並以 step() 搭配 AIC 進行逐步選模，以得到解釋力佳且結構精簡的變數組合，避免多重共線性問題。

模型建立後，我們將透過殘差圖與 QQ Plot 檢驗常態性、獨立性與變異數同質性；若觀察到異質性變異或偏態，會視情況對相關自變數進行適度轉換，以提升模型適配度。

在結果與應用方面，我們預期 delivery_gap 會呈現顯著正向效果，支持「準時或提前送達能提升顧客滿意度」的假設。我們亦將量化各顯著變數的邊際影響，並透過product_category_name 的虛擬變數辨識滿意度較低的品類，作為平台優化的依據。

---

## 專案結構

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
├── data_preprocessing/           # 資料前處理資料夾
│   ├── preprocessing.py         # Python 前處理腳本
│   ├── preprocessing.R          # R 前處理腳本
│   ├── create_binary_target.py  # 創建二元目標變數腳本
│   ├── preprocessed_data.csv    # 清理後的資料（全部）
│   ├── preprocessed_data_non5.csv # 清理後的資料（非滿分子集）
│   ├── preprocessed_data_binary.csv # 二元目標變數資料（用於 Binomial GLM）
│   └── README.md
│
├── descriptive_analysis/         # 探索性資料分析（EDA）資料夾
│   ├── descriptive_statistics.R # 敘述性統計分析腳本（全資料）
│   ├── descriptive_statistics_non5.R # 敘述性統計分析腳本（非滿分）
│   ├── multicollinearity_scatter.R # 共線性檢查散點圖腳本
│   ├── descriptive_statistics_output.txt # 統計分析輸出
│   ├── descriptive_statistics_non5_output.txt # 非滿分統計輸出
│   └── README.md
│
├── plots/                       # EDA 視覺化圖表（全資料）
│   ├── *_histogram.png          # 單變數分布圖
│   ├── *_boxplot.png            # 異常值檢查圖
│   ├── collinearity_*.png       # 共線性檢查散點圖
│   ├── correlation_pairs_plot.png # 變數關係矩陣圖
│   └── ...
│
├── plots_non5/                  # EDA 視覺化圖表（非滿分子集）
│   └── README.md
│
├── ReadMe.md                     # 本檔案（專案說明文件）
└── requirements.txt              # Python 套件依賴
```

## 資料夾說明

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
 - 合併規則（重點）：每訂單僅保留一筆評論，選擇「最接近實際送達日」的評論（如並列則取較晚者）；付款/商品/賣家皆聚合至訂單層級。

### `data_preprocessing/` - 資料前處理
包含所有與資料前處理相關的檔案：
- **Python 腳本**：自動化資料清理和檢查
- **R 腳本**：R 版本的資料前處理腳本
- **清理後的資料**：`preprocessed_data.csv` 包含清理後的所有資料，可直接用於統計分析
- **處理摘要**：`preprocessing_summary.txt` 記錄處理過程和結果

### `descriptive_analysis/` - 敘述性統計分析
包含所有與敘述性統計分析相關的檔案：
- **R 腳本**：`descriptive_statistics.R` 進行敘述性統計分析（腳本會自動設定工作目錄）
- **視覺化圖表**：執行腳本後會在 `plots/` 資料夾中生成各種統計圖表
- 符合 ReadMe.md 要求：使用 `summary()`, `hist()`, `boxplot()` 進行資料分析

## 使用方式

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

### 一鍵執行流程（合併 → 前處理 → 敘述統計）

從專案根目錄：
```bash
# 1) 合併所有 CSV 並輸出 merged_olist_data.csv
python3 sql_merge/load_and_merge_data.py

# 2) 產生清理後資料（含 non-5 子集）
python3 data_preprocessing/preprocessing.py

# 2B) [可選] 產生二元目標變數資料（用於 Binomial GLM）
python3 data_preprocessing/create_binary_target.py

# 3A) 敘述統計 - 全部資料（輸出到 descriptive_analysis/plots/）
Rscript descriptive_analysis/descriptive_statistics.R

# 3B) 敘述統計 - 非滿分子集 1~4（輸出到 descriptive_analysis/plots_non5/）
Rscript descriptive_analysis/descriptive_statistics_non5.R
```


## 合併後的資料欄位（訂單層級，一單一列）

- **應變數**：`review_score` (1-5分)
- **物流變數**：`delivery_days`, `delivery_gap`
- **交易成本**：`price`, `freight_value`, `payment_value`
- **付款控制**：`payment_type`, `payment_installments`
- **商品屬性（聚合）**：
  - `product_category_name_english`（主類別）
  - `product_photos_qty`（平均）、`product_weight_g`（平均）
  - `num_items`, `num_products`, `num_distinct_categories`, `primary_category_share`
  - `product_categories`, `product_ids`（清單，逗號分隔）
- **賣家屬性（聚合）**：
  - `num_sellers`, `primary_seller_id`, `primary_seller_city`, `primary_seller_state`, `primary_seller_zip_code_prefix`, `primary_seller_share`
- **評論診斷**：`review_count`, `review_distinct_scores`, `has_multiple_reviews`, `has_mixed_review_scores`, `first_review_*`, `last_review_*`

詳見各資料夾中的 README.md 獲取更多資訊。

---

## 使用 R 進行統計分析


**清理後的資料**：`data_preprocessing/preprocessed_data.csv`


#### 1. 安裝必要的 R 套件

在 R 或 RStudio 中執行：

```r
# 安裝套件（只需要執行一次）
install.packages(c("dplyr", "readr", "ggplot2", "tidyr"))
```

或執行我們提供的安裝腳本：

```r
source("data_preprocessing/install_packages.R")
```

#### 2. 載入清理後的資料

```r
library(dplyr)
library(readr)

# 載入前處理後的資料
data <- read_csv("data_preprocessing/preprocessed_data.csv")
```

#### 3. 探索性資料分析（EDA）

**完整分析流程（從命令列執行）：**

```bash
# 1. 全資料敘述性統計（生成 plots/ 目錄）
Rscript descriptive_analysis/descriptive_statistics.R

# 2. 非滿分子集敘述性統計（生成 plots_non5/ 目錄）
Rscript descriptive_analysis/descriptive_statistics_non5.R

# 3. 共線性檢查（生成共線性散點圖和 VIF 值）
Rscript descriptive_analysis/multicollinearity_scatter.R
```

**或在 RStudio 中執行：**

開啟對應的 R 檔案（`.R`），點擊 "Source" 按鈕執行。腳本會自動設定工作目錄。

**生成的 EDA 內容：**

- **單變數分析**：histogram (原始 + log), boxplot, bar plot
- **雙變數分析**：scatter plots, pair plot
- **共線性檢查**：7 組變數對的散點圖 + VIF 值
- **統計摘要**：描述性統計、相關係數矩陣

#### 4. 開始建立迴歸模型（待續）

根據專案要求，接下來需要：

1. 檢視 EDA 結果，確認變數特性
2. 使用 `lm()` 建立多元線性迴歸模型
3. 使用 `step()` 進行逐步選模（AIC）
4. 檢驗模型假設（殘差診斷、QQ plot）

### 可用的檔案

**資料檔案：**
- `data_preprocessing/preprocessed_data.csv` - 清理後的資料（全部，95,973 筆）
- `data_preprocessing/preprocessed_data_non5.csv` - 非滿分子集（1-4 分，39,117 筆）
- `data_preprocessing/preprocessed_data_binary.csv` - 二元目標變數（用於 Binomial GLM，95,973 筆）
  - 新增 `success` 欄位：5分=1（成功），1-4分=0（失敗）
  - 適用於 Logistic Regression 分析

**分析腳本：**
- `descriptive_analysis/descriptive_statistics.R` - 全資料敘述性統計
- `descriptive_analysis/descriptive_statistics_non5.R` - 非滿分子集分析
- `descriptive_analysis/multicollinearity_scatter.R` - 共線性檢查
- `data_preprocessing/preprocessing.py` - Python 資料前處理腳本
- `data_preprocessing/create_binary_target.py` - 創建二元目標變數腳本

**輸出結果：**
- `descriptive_analysis/descriptive_statistics_output.txt` - 統計分析文字輸出
- `plots/` - 全資料 EDA 圖表（35 張）
- `plots_non5/` - 非滿分 EDA 圖表（32 張）

### 快速開始範例

在 RStudio 中建立新的 R Script：

```r
# 載入套件
library(dplyr)
library(readr)
library(ggplot2)

# 載入資料（從 data_preprocessing 資料夾）
data <- read_csv("data_preprocessing/preprocessed_data.csv")

# 基本統計
summary(data)

# 應變數分布
hist(data$review_score, main = "評論分數分布")

# 箱線圖檢查異常值
boxplot(data$delivery_days, main = "送達天數")
boxplot(data$price, main = "商品價格")
```

### 遇到問題？

如果 R 無法執行：
1. 確認 R 和 RStudio 已正確安裝
2. 重新啟動 RStudio 或終端機
3. 檢查工作目錄是否正確（使用 `getwd()` 查看）

**建議：直接開啟 RStudio 開始分析！**
