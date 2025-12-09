# 探索性資料分析（EDA）資料夾

此資料夾包含探索性資料分析的 R 腳本和輸出檔案。

## 檔案說明

### R 腳本
- **descriptive_statistics.R** - 全資料敘述性統計分析腳本
- **descriptive_statistics_non5.R** - 非滿分子集（1-4 分）分析腳本
- **multicollinearity_scatter.R** - 共線性檢查散點圖腳本

### 輸出檔案
- **descriptive_statistics_output.txt** - 全資料統計分析文字輸出
- **descriptive_statistics_non5_output.txt** - 非滿分子集統計輸出
- **../plots/** - 全資料 EDA 視覺化圖表（35 張）
- **../plots_non5/** - 非滿分子集 EDA 視覺化圖表（32 張）

## 使用方式

### 前置需求

確保已安裝必要的 R 套件：

```r
install.packages(c("dplyr", "readr", "ggplot2", "corrplot", "gridExtra", "car"))
```

**套件說明**：
- `dplyr`：資料處理與轉換
- `readr`：讀取 CSV 檔案
- `ggplot2`：進階繪圖
- `corrplot`：相關係數視覺化（共線性分析用）
- `gridExtra`：多圖排版
- `car`：VIF（變異數膨脹因子）計算

或使用安裝腳本：
```r
source("data_preprocessing/install_packages.R")
```

### 執行完整 EDA 流程

**方法 1：從命令列執行（推薦）**

```bash
# 進入專案根目錄
cd "/path/to/NTU_Statistical-Data-Analysis-Final-Report"

# 1. 全資料敘述性統計（生成 plots/ 目錄）
Rscript descriptive_analysis/descriptive_statistics.R

# 2. 非滿分子集敘述性統計（生成 plots_non5/ 目錄）
Rscript descriptive_analysis/descriptive_statistics_non5.R

# 3. 共線性檢查（生成共線性散點圖和 VIF 值）
Rscript descriptive_analysis/multicollinearity_scatter.R
```

**方法 2：在 RStudio 中執行**

1. 開啟 RStudio
2. 依序開啟各個 R 腳本檔案
3. 點擊 "Source" 按鈕執行

腳本會自動偵測並設定工作目錄為專案根目錄。

## EDA 分析內容

### 1. 全資料分析（descriptive_statistics.R）

**輸入**：`data_preprocessing/preprocessed_data.csv`（95,973 筆）

**輸出**：
- 文字輸出：`descriptive_statistics_output.txt`
- 圖表：`../plots/`（35 張圖）

**分析步驟**：

- 載入前處理後的資料

#### 步驟 2: 基本統計摘要
- 使用 `summary()` 檢視整體資料統計
- 顯示所有變數的描述性統計

#### 步驟 3: 應變數（review_score）分析
- 基本統計量（平均數、中位數、標準差、最小/最大值）
- 分數分布與比例
- **圖表**：
  - `review_score_histogram.png` - 離散次數統計（1-5 分）
  - `review_score_boxplot.png` - 箱線圖

#### 步驟 4: 主要數值變數分析

**分析變數**：`delivery_days`, `delivery_gap`, `price`, `freight_value`, `product_weight_g`, `product_photos_qty`, `payment_installments`

- 統計摘要（`summary()`）
- **圖表**（每個變數）：
  - `*_histogram.png` - 原始分布
  - `*_histogram_log.png` - 對數轉換分布（處理右偏）
  - `*_boxplot.png` - 異常值檢查

#### 步驟 5: 變數間關係探索
- 計算相關係數矩陣（數值變數）
- **圖表**：
  - `delivery_gap_vs_review_score.png` - 主要關係散點圖
  - `price_vs_review_score.png` - 價格與評分關係
  - `correlation_pairs_plot.png` - 8x8 變數關係矩陣

#### 步驟 6: 類別變數分析
- 付款方式分布（`payment_type`）
- 前 10 大商品類別（`product_category_name_english`）
- **圖表**：
  - `customer_state_distribution.png` - 顧客州別分布
  - `primary_seller_state_distribution.png` - 賣家州別分布
  - `product_categories_top15.png` - 商品類別分布

### 2. 非滿分子集分析（descriptive_statistics_non5.R）

**輸入**：`data_preprocessing/preprocessed_data_non5.csv`（39,117 筆，僅 1-4 分）

**輸出**：
- 文字輸出：`descriptive_statistics_non5_output.txt`
- 圖表：`../plots_non5/`（32 張圖）

**分析步驟**：與全資料分析相同，但僅針對非滿分訂單，用於了解「不滿意顧客」的特徵。

### 3. 共線性檢查（multicollinearity_scatter.R）

**目的**：檢查自變數間的多重共線性問題

**分析內容**：
- 生成 7 組變數對的散點圖（依相關性排序）
- 計算 VIF（變異數膨脹因子）值
- 判斷共線性程度（高/中/低）

**輸出**：
- **圖表**（`plots/` 和 `plots_non5/` 各 7 張）：
  - `collinearity_delivery_days_vs_gap.png` - **高度相關** (r≈0.60-0.73)
  - `collinearity_weight_vs_freight.png` - **中高度相關** (r≈0.50)
  - `collinearity_price_vs_freight.png` - 中度相關 (r≈0.41)
  - `collinearity_price_vs_weight.png` - 中度相關 (r≈0.33)
  - `collinearity_price_vs_installments.png` - 中度相關 (r≈0.30)
  - `collinearity_weight_vs_installments.png` - 低度相關 (r≈0.20)
  - `collinearity_freight_vs_installments.png` - 低度相關 (r≈0.20)

- **VIF 值**（輸出至控制台）：
  - 全部變數 VIF < 2.3 ✅
  - 無明顯共線性問題

## 輸出結果

### 文字輸出檔

- **`descriptive_statistics_output.txt`** - 全資料統計分析輸出（包含 summary, 相關係數等）
- **`descriptive_statistics_non5_output.txt`** - 非滿分子集統計輸出

### 視覺化圖表

**`plots/` 資料夾（35 張圖）**：

**單變數分析（16 張）：**
- `review_score_histogram.png` / `*_boxplot.png`
- `delivery_days_histogram.png` / `*_histogram_log.png` / `*_boxplot.png`
- `delivery_gap_histogram.png` / `*_boxplot.png`
- `price_histogram.png` / `*_histogram_log.png` / `*_boxplot.png`
- `freight_value_histogram.png` / `*_histogram_log.png` / `*_boxplot.png`
- `product_weight_g_histogram.png` / `*_histogram_log.png` / `*_boxplot.png`
- `product_photos_qty_histogram.png` / `*_histogram_log.png` / `*_boxplot.png`
- `payment_installments_histogram.png` / `*_histogram_log.png` / `*_boxplot.png`

**雙變數/多變數分析（12 張）：**
- `delivery_gap_vs_review_score.png` - 散點圖
- `price_vs_review_score.png` - 散點圖
- `correlation_pairs_plot.png` - 8x8 變數矩陣
- `collinearity_delivery_days_vs_gap.png` - 共線性檢查
- `collinearity_weight_vs_freight.png`
- `collinearity_price_vs_freight.png`
- `collinearity_price_vs_weight.png`
- `collinearity_price_vs_installments.png`
- `collinearity_weight_vs_installments.png`
- `collinearity_freight_vs_installments.png`

**類別變數分析（3 張）：**
- `customer_state_distribution.png` - 顧客地理分布
- `primary_seller_state_distribution.png` - 賣家地理分布
- `product_categories_top15.png` - 商品類別分布

**`plots_non5/` 資料夾（32 張圖）**：與 `plots/` 結構相同，但針對 1-4 分訂單

## 符合研究要求

### EDA 階段（目前完成）✅

根據專案要求，我們已完成：

**單變數分析：**
- ✅ 使用 `summary()` 檢查基本統計量
- ✅ 使用 `hist()` 檢查資料分布（原始 + log 轉換）
- ✅ 使用 `boxplot()` 檢查異常值

**雙變數/多變數分析：**
- ✅ 計算相關係數矩陣
- ✅ 繪製散點圖檢查變數關係
- ✅ 生成 pair plot 全覽變數關係
- ✅ 共線性檢查（scatter plots + VIF）

**類別變數分析：**
- ✅ 付款方式、商品類別、地理分布

### 建模階段（待續）⏳

接下來將進行：

**模型建立：**
- 使用 `lm()` 建立多元線性迴歸模型
- 使用 `step()` 進行逐步選模（AIC）
- 考慮 Ordinal Logistic Regression（review_score 為有序類別）

**模型診斷：**
- QQ plot 檢驗殘差常態性
- Residual plots 檢驗模型假設
- 變異數同質性檢驗
- 影響點分析（Cook's distance）

**結果解釋：**
- 量化各顯著變數的邊際影響
- 解釋模型係數的實務意義

## 主要發現（EDA）

### 評論分數分布
- **全資料**：59.24% 給 5 分（滿分），僅 9.75% 給 1 分
- **非滿分子集**：主要集中在 4 分（48.37%）

### 相關性分析
**與 review_score 相關性較高的變數：**
- `delivery_days`: -0.334（中度負相關）
- `delivery_gap`: -0.262（負相關）
- `freight_value`: -0.090（弱負相關）

**自變數間高相關性（共線性）：**
- `delivery_days` ↔ `delivery_gap`: 0.595（全資料）/ 0.730（非滿分）
- `product_weight_g` ↔ `freight_value`: 0.502

### VIF 檢查結果
- ✅ 所有變數 VIF < 2.3
- ✅ 無嚴重共線性問題
- ⚠️ `delivery_days` 和 `delivery_gap` 相關性較高，建模時可考慮只保留其一

## 注意事項

1. **資料層級**：所有分析基於「訂單層級」（一張訂單一筆記錄）

2. **圖表生成**：執行腳本後自動生成所有圖表，無需手動操作

3. **執行時間**：
   - 全資料分析：約 1-2 分鐘
   - 非滿分分析：約 1 分鐘
   - 共線性檢查：約 30 秒

4. **記憶體需求**：資料量約 95K 筆，一般電腦皆可執行

5. **輸出位置**：
   - 文字輸出：`descriptive_analysis/` 目錄
   - 圖表：專案根目錄的 `plots/` 和 `plots_non5/`

## 相關文件

- 專案整體說明：`../README.md`
- 資料前處理說明：`../data_preprocessing/README.md`
- SQL 資料合併：`../sql_merge/README.md`

