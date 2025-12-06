# 敘述性統計分析資料夾

此資料夾包含敘述性統計分析的 R 腳本和相關檔案。

## 檔案說明

- **descriptive_statistics.R** - 主要的敘述性統計分析腳本
- **plots/** - 視覺化圖表資料夾（執行腳本後生成）

## 使用方式

### 前置需求

確保已安裝必要的 R 套件：

```r
install.packages(c("dplyr", "readr", "ggplot2", "tidyr"))
```

**套件說明**：
- `dplyr`：資料處理與轉換
- `readr`：讀取 CSV 檔案
- `ggplot2`：繪圖（目前主要使用基礎 R 繪圖）
- `tidyr`：資料整理（用於 `separate_rows` 函數，展開 `product_categories`）

### 執行統計分析

**推薦方式：在 RStudio 中執行**

1. 開啟 RStudio
2. 開啟 `descriptive_statistics.R` 檔案
3. 點擊 "Source" 按鈕執行整個腳本

腳本會自動偵測並設定工作目錄為專案根目錄，無需手動設定。

**其他方式：從 R 控制台執行**

```r
# 先設定工作目錄為專案根目錄
setwd('C:\\Users\\User\\OneDrive\\Desktop\\NTU\\商統分\\NTU_Statistical-Data-Analysis-Final-Report')

# 執行分析腳本
source("descriptive_analysis/descriptive_statistics.R")
```

## 分析內容

腳本會執行以下分析：

### 步驟 1: 載入清理後的資料
- 從 `../data_preprocessing/preprocessed_data.csv` 載入資料

### 步驟 2: 基本統計摘要
- 使用 `summary()` 檢視整體資料統計
- **基本資料統計（唯一值）**：
  - 總訂單數（唯一 order_id）
  - 總評論數（唯一 review_id）
  - 總顧客數（唯一 customer_unique_id）
  - 總商品種類數（從 product_ids 展開後去重）
  - 總商品類別數（唯一 product_category_name_english）
  - 總賣家數（唯一 primary_seller_id）
  - 總顧客城市數（唯一 customer_city）
  - 總顧客州數（唯一 customer_state）

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
- **訂單狀態分布**：統計各訂單狀態的分布與比例
- **付款方式分布**：統計各付款方式的分布
- **商品類別分布**：
  - 前 10 大商品類別（葡萄牙文版本）
  - 前 10 大商品類別（英文版本）
- **顧客地理分布**：
  - 顧客城市分布（前 10 大城市）
  - 顧客州別分布（各州訂單數與比例）
- **商品ID與類別清單分析**：
  - 每筆訂單的商品ID數量統計
  - 每筆訂單的商品類別數量統計
  - 展開所有商品類別並統計出現次數
- **賣家地理分布**：
  - 賣家城市分布（前 10 大城市）
  - 賣家州別分布（各州訂單數與比例）

## 輸出結果

執行完成後，會生成以下檔案：

### 文字輸出檔

- **`descriptive_statistics_output.txt`** - 完整的分析輸出日誌（包含所有統計摘要、分析結果等）

### 視覺化圖表

所有圖表會儲存在 `plots/` 資料夾中，包括：

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
- `customer_state_distribution.png` - 顧客州別分布圖
- `primary_seller_state_distribution.png` - 賣家州別分布圖
- `product_categories_top15.png` - 前 15 大商品類別分布圖

## 符合研究要求

根據 ReadMe.md 的要求，此腳本會：
- 使用 `summary()` 檢查基本統計量
- 使用 `hist()` 檢查資料分布
- 使用 `boxplot()` 檢查異常值
- 進行初步的資料探索和分析

## 文字變數（類別變數）處理說明

### 已處理的文字變數

#### 1. **order_status**（訂單狀態）
- 統計各訂單狀態的分布與比例

#### 2. **payment_type**（付款方式）
- 統計各付款方式的分布

#### 3. **product_category_name**（商品類別 - 葡萄牙文）
- 統計前 10 大商品類別（葡萄牙文版本）及其比例

#### 4. **product_category_name_english**（商品類別 - 英文）
- 統計前 10 大商品類別（英文版本）及其比例

#### 5. **customer_city**（顧客城市）
- 總城市數統計
- 前 10 大城市及其訂單數與比例

#### 6. **customer_state**（顧客州別）
- 總州數統計
- 各州訂單數與比例分布
- 生成州別分布長條圖

#### 7. **product_ids**（商品ID清單）
- **資料型態**：逗號分隔的字串（例如："abc123,def456,ghi789"）
- **處理方式**：計算每筆訂單的商品ID數量（透過分割逗號）
- **分析內容**：
  - 商品ID數量的平均數、中位數、最大值、最小值
  - 商品ID數量分布表（文字輸出）
  - **注意**：由於絕大多數訂單只有 1 個商品，分布極度偏斜，因此不生成直方圖

#### 8. **product_categories**（商品類別清單）
- **資料型態**：逗號分隔的字串（例如："bed_bath_table,health_beauty"）
- **處理方式**：
  - 計算每筆訂單的商品類別數量
  - 展開所有類別並統計每個類別的總出現次數
- **分析內容**：
  - 商品類別數量的平均數、中位數、最大值、最小值
  - 商品類別數量分布表（文字輸出）
  - 前 15 大商品類別分布（從所有訂單展開後統計）
  - 生成前 15 大商品類別分布圖
  - **注意**：由於絕大多數訂單只有 1 個類別，分布極度偏斜，因此不生成數量分布直方圖

#### 9. **primary_seller_city**（賣家城市）
- 總城市數統計
- 有效記錄數與比例
- 前 10 大賣家城市及其訂單數與比例

#### 10. **primary_seller_state**（賣家州別）
- 總州數統計
- 有效記錄數與比例
- 各州賣家訂單數與比例分布
- 生成賣家州別分布長條圖

### 不需要統計分析的ID變數

以下變數為識別碼（ID），在 `summary()` 中會顯示基本資訊，但不需要額外的分布分析：
- `review_id` - 評論ID
- `order_id` - 訂單ID
- `customer_id` - 顧客ID
- `customer_unique_id` - 顧客唯一ID
- `primary_seller_id` - 主要賣家ID

### 資料合併時的處理邏輯

在 `sql_merge/merge_query.sql` 中：
- `product_ids`：使用 `GROUP_CONCAT(DISTINCT oi.product_id)` 將每筆訂單的所有商品ID合併成逗號分隔的字串
- `product_categories`：使用 `GROUP_CONCAT(DISTINCT pc.product_category_name_english)` 將每筆訂單的所有商品類別合併成逗號分隔的字串

### 注意事項

1. **`product_ids` 和 `product_categories` 是聚合變數**：
   - 這些變數包含多個值（以逗號分隔）
   - 在分析時需要先分割才能計算統計量
   - 分析腳本會自動計算每筆訂單的項目數量

2. **缺失值處理**：
   - `customer_city` 和 `customer_state`：如果原始資料缺失，會在資料合併時保留為 NULL
   - `product_category_name` 和 `product_category_name_english`：缺失值以 "unknown" 填補
   - `product_ids` 和 `product_categories`：如果訂單沒有商品，可能為空字串或 NULL

3. **資料層級**：
   - 所有變數都在「訂單層級」（order-level）
   - 每筆記錄代表一筆訂單，而非單一商品

## 相關文件

- 資料前處理說明：`../data_preprocessing/README.md`
- 專案整體說明：`../ReadMe.md`

## 注意事項

1. **資料路徑**：腳本會自動從 `../data_preprocessing/preprocessed_data.csv` 讀取資料
2. **輸出位置**：
   - 所有圖表會儲存在 `plots/` 資料夾中
   - 所有文字輸出會自動儲存至 `descriptive_statistics_output.txt` 檔案中
   - 輸出會同時顯示在控制台和保存到文件中
3. **執行時間**：根據資料量，可能需要幾分鐘時間
4. **套件需求**：確保已安裝所有必要的 R 套件（包括 `tidyr`，用於 `separate_rows` 函數）
5. **上傳 GitHub**：執行完成後，可以將 `descriptive_statistics_output.txt` 和 `plots/` 資料夾中的圖表一起上傳到 GitHub，方便檢視分析結果

