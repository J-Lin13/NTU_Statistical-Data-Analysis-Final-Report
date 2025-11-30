# 資料前處理資料夾

此資料夾包含資料前處理的腳本和相關檔案。提供 **兩種方式**（Python 和 R）來進行資料前處理。

## 📁 檔案說明

### 前處理腳本（兩種版本）
- **preprocessing.py** - Python 版本的資料前處理腳本 ⭐ **（已執行，資料已清理完成）**
- **preprocessing.R** - R 版本的資料前處理腳本

### 其他檔案
- **preprocessed_data.csv** - 清理後的資料（已生成，可直接使用）
- **preprocessing_summary.txt** - 處理摘要報告
- **visualization.R** - 資料分布視覺化腳本（R 版本）
- **install_packages.R** - R 套件安裝腳本

## 🚀 使用方式

### ✅ 當前狀態

**資料前處理已完成！** 已使用 Python 版本（`preprocessing.py`）執行，清理後的資料位於 `preprocessed_data.csv`。

### 兩種前處理方式

#### 方式 1：Python 版本（已完成）⭐

```bash
# 從專案根目錄執行
python data_preprocessing/preprocessing.py
```

**優點**：
- 不需要安裝 R
- 已執行完成，資料可直接使用

#### 方式 2：R 版本（可選）

如果您想用 R 重新執行前處理（學習或比較結果）：

1. **安裝必要的 R 套件**：
   ```r
   install.packages(c("dplyr", "readr", "ggplot2", "tidyr"))
   ```
   或執行：
   ```r
   source("data_preprocessing/install_packages.R")
   ```

2. **執行前處理腳本**：
   ```r
   setwd("data_preprocessing")
   source("preprocessing.R")
   ```

**注意**：兩種方式會產生相同的結果，您只需要執行其中一種即可。

### 執行視覺化

前處理完成後，可以生成視覺化圖表：

```r
source("visualization.R")
```

這會生成各種圖表並儲存在 `plots/` 資料夾中。

## 📋 前處理步驟

腳本會自動執行以下步驟：

1. **載入資料與基本檢視**
   - 從 `../sql_merge/merged_olist_data.csv` 載入資料
   - 檢視資料結構和基本統計

2. **處理缺失值**
   - 檢查各欄位的缺失值
   - 刪除關鍵變數缺失的記錄
   - 填補或處理其他缺失值

3. **檢查與處理異常值**
   - 檢查數值變數的異常值
   - 移除不合理數值（如價格 <= 0）
   - 使用箱線圖和統計方法識別異常值

4. **處理重複資料**
   - 檢查完全重複的記錄
   - 檢查 order_id 重複情況

5. **建立衍生變數**
   - total_value = price + freight_value
   - price_above_mean（價格是否高於平均）
   - delivery_delayed（是否延遲送達）
   - delivery_early（是否提前送達）

6. **變數類型轉換**
   - 類別變數轉為因子（factor）
   - 確保數值變數為數值型態

7. **資料分布檢查**
   - 檢查應變數分布
   - 檢查主要數值變數的基本統計量

8. **資料篩選**
   - 最終確認所有必要欄位都不為空

9. **儲存清理後的資料**
   - 儲存為 `preprocessed_data.csv`
   - 生成處理摘要報告

## 📊 輸出檔案

### preprocessed_data.csv

清理後的資料，包含：
- 所有原始欄位（已清理）
- 新增的衍生變數
- 適合進行統計分析的格式

### preprocessing_summary.txt

處理摘要報告，包含：
- 原始資料筆數
- 最終資料筆數
- 移除的資料筆數和比例
- 處理日期

### plots/ 資料夾

視覺化圖表，包括：
- 應變數分布圖
- 物流變數分布圖（直方圖、箱線圖）
- 交易成本變數分布圖
- 商品屬性變數分布圖
- 變數關係散點圖
- 商品類別分布圖
- 付款方式分布圖

## ⚠️ 注意事項

1. **資料前處理已完成**：已使用 Python 版本執行，`preprocessed_data.csv` 可直接使用

2. **兩種方式任選其一**：Python 或 R 版本都可以，功能相同，執行其中一種即可

3. **資料路徑**：腳本會自動從 `sql_merge/merged_olist_data.csv` 讀取資料

4. **輸出位置**：兩種版本的輸出都會儲存在 `data_preprocessing/` 資料夾中

5. **執行時間**：前處理腳本可能需要幾分鐘時間執行

6. **備份**：腳本不會修改原始資料，但建議先備份

## 🔍 與研究目標的對應

根據 ReadMe.md 的要求，前處理腳本會：

- ✅ 使用 `summary()` 檢查基本統計量
- ✅ 使用 `hist()` 檢查資料分布（在 visualization.R 中）
- ✅ 使用 `boxplot()` 檢查異常值（在 visualization.R 中）
- ✅ 處理缺失值和異常值
- ✅ 準備資料供後續迴歸分析使用

## 📖 相關文件

- 詳細的前處理說明請參考：`../DATA_PREPROCESSING_GUIDE.md`
- 專案整體說明請參考：`../ReadMe.md`

## ❓ 問題排除

如果遇到問題：

1. **套件未安裝**：執行 `install.packages()` 安裝所需套件
2. **檔案找不到**：確認工作目錄正確，檔案路徑正確
3. **記憶體不足**：考慮分批處理資料或增加 R 記憶體
4. **編碼問題**：確保 CSV 檔案使用 UTF-8 編碼


