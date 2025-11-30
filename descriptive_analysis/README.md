# 敘述性統計分析資料夾

此資料夾包含敘述性統計分析的 R 腳本和相關檔案。

## 📁 檔案說明

- **descriptive_statistics.R** - 主要的敘述性統計分析腳本
- **plots/** - 視覺化圖表資料夾（執行腳本後生成）

## 🚀 使用方式

### 前置需求

確保已安裝必要的 R 套件：

```r
install.packages(c("dplyr", "readr", "ggplot2"))
```

### 執行統計分析

#### 方法一：從專案根目錄執行

```r
source("descriptive_analysis/descriptive_statistics.R")
```

#### 方法二：在 RStudio 中開啟

1. 開啟 RStudio
2. 開啟 `descriptive_statistics.R` 檔案
3. 點擊 "Source" 按鈕執行

#### 方法三：設定工作目錄後執行

```r
setwd("descriptive_analysis")
source("descriptive_statistics.R")
```

## 📊 分析內容

腳本會執行以下分析：

### 步驟 1: 載入清理後的資料
- 從 `../data_preprocessing/preprocessed_data.csv` 載入資料

### 步驟 2: 基本統計摘要
- 使用 `summary()` 檢視整體資料統計

### 步驟 3: 應變數（review_score）分析
- 基本統計量（平均數、中位數、標準差等）
- 分布分析
- 生成直方圖和箱線圖

### 步驟 4: 主要數值變數分析
- 統計摘要
- 為每個變數生成箱線圖（檢查異常值）
- 為每個變數生成直方圖（檢查分布）

### 步驟 5: 變數間關係探索
- 計算相關係數矩陣
- 繪製重要變數的散點圖

### 步驟 6: 類別變數分析
- 付款方式分布
- 商品類別分布

## 📈 輸出結果

執行完成後，會在 `plots/` 資料夾中生成以下圖表：

- `review_score_histogram.png` - 評論分數直方圖
- `review_score_boxplot.png` - 評論分數箱線圖
- `delivery_days_boxplot.png` - 送達天數箱線圖
- `delivery_days_histogram.png` - 送達天數直方圖
- `delivery_gap_boxplot.png` - 送達差距箱線圖
- `delivery_gap_histogram.png` - 送達差距直方圖
- `price_boxplot.png` - 價格箱線圖
- `price_histogram.png` - 價格直方圖
- `freight_value_boxplot.png` - 運費箱線圖
- `freight_value_histogram.png` - 運費直方圖
- `product_weight_g_boxplot.png` - 商品重量箱線圖
- `product_weight_g_histogram.png` - 商品重量直方圖
- `product_photos_qty_boxplot.png` - 商品照片數量箱線圖
- `product_photos_qty_histogram.png` - 商品照片數量直方圖
- `payment_installments_boxplot.png` - 分期期數箱線圖
- `payment_installments_histogram.png` - 分期期數直方圖
- `delivery_gap_vs_review_score.png` - 送達差距與評論分數關係圖
- `price_vs_review_score.png` - 價格與評論分數關係圖

## 🔍 符合研究要求

根據 ReadMe.md 的要求，此腳本會：
- ✅ 使用 `summary()` 檢查基本統計量
- ✅ 使用 `hist()` 檢查資料分布
- ✅ 使用 `boxplot()` 檢查異常值
- ✅ 進行初步的資料探索和分析

## 📖 相關文件

- 資料前處理說明：`../data_preprocessing/README.md`
- 專案整體說明：`../ReadMe.md`

## ⚠️ 注意事項

1. **資料路徑**：腳本會自動從 `../data_preprocessing/preprocessed_data.csv` 讀取資料
2. **輸出位置**：所有圖表會儲存在 `plots/` 資料夾中
3. **執行時間**：根據資料量，可能需要幾分鐘時間
4. **套件需求**：確保已安裝所有必要的 R 套件

