# 使用 R 進行資料分析的說明

## 🎯 目前狀況

您已經：
- ✅ 完成資料合併（SQL + Python）
- ✅ 完成資料前處理（Python 版本）
- ✅ 已下載 R 軟體

清理後的資料已儲存在：
- `preprocessed_data.csv` （根目錄）
- `data_preprocessing/preprocessed_data.csv` （資料夾內）

## 🔧 R 安裝後的設定

### 方法一：使用 RStudio（推薦，較簡單）

1. **下載並安裝 RStudio Desktop**（如果還沒安裝）
   - 網址：https://www.rstudio.com/products/rstudio/download/
   - 選擇免費版本（RStudio Desktop）

2. **開啟 RStudio**
   - 啟動 RStudio
   - 在 RStudio 中可以執行所有 R 腳本

3. **設定工作目錄**
   ```r
   # 在 RStudio 的 Console 中執行
   setwd("C:/Users/User/Downloads/商統分/NTU_Statistical-Data-Analysis-Final-Report/data_preprocessing")
   ```
   
   或者：在 RStudio 中開啟專案資料夾

### 方法二：在命令列使用 Rscript

如果 R 已安裝但還無法使用，可能需要：

1. **將 R 加入系統 PATH**
   - R 通常安裝在：`C:\Program Files\R\R-4.x.x\bin`
   - 或：`C:\Program Files\R\R-4.x.x\bin\x64`
   - 將此路徑加入 Windows 環境變數 PATH

2. **重新啟動終端機或電腦**
   - 重新開啟 PowerShell 或 Cursor

3. **測試 R 是否可用**
   ```bash
   Rscript --version
   ```

## 📊 接下來可以做什麼？

### 選項 A：用 R 重新執行資料前處理（學習 R）

如果想用 R 重新執行前處理步驟：

1. **安裝 R 套件**
   ```r
   source("data_preprocessing/install_packages.R")
   ```

2. **執行 R 前處理腳本**
   ```r
   source("data_preprocessing/preprocessing.R")
   ```

### 選項 B：直接用 R 進行統計分析（推薦）

既然前處理已經用 Python 完成，可以直接用 R 進行後續分析：

1. **載入清理後的資料**
   ```r
   library(dplyr)
   library(readr)
   
   # 載入前處理後的資料
   data <- read_csv("preprocessed_data.csv")
   ```

2. **進行敘述性統計**
   - 使用 `summary()`, `hist()`, `boxplot()` 等
   - 符合您的 ReadMe.md 要求

3. **建立迴歸模型**
   - 使用 `lm()` 建立多元迴歸模型
   - 使用 `step()` 進行逐步選模

## 🚀 建議的下一步

### 在 RStudio 中開啟專案

1. **開啟 RStudio**
2. **File > Open Project** 或直接開啟資料夾
3. **建立新的 R Script 檔案**，例如：`descriptive_statistics.R`

### 建立敘述性統計分析腳本

可以建立一個新的 R 腳本進行分析：

```r
# 載入必要的套件
library(dplyr)
library(ggplot2)
library(readr)

# 載入清理後的資料
data <- read_csv("preprocessed_data.csv")

# 基本統計摘要
summary(data)

# 應變數分布
hist(data$review_score, main = "評論分數分布")
boxplot(data$review_score, main = "評論分數箱線圖")

# 主要變數的統計
summary(data[c("delivery_days", "delivery_gap", "price", "freight_value")])

# 繪製箱線圖檢查異常值
boxplot(data$delivery_days, main = "送達天數")
boxplot(data$price, main = "商品價格")
```

## 💡 重要提示

1. **Python 版本的前處理已經完成**，資料可以直接使用
2. **不需要重新執行 R 前處理腳本**（除非想學習或比較結果）
3. **建議直接開始統計分析**，這是您分工的下一步

## 📁 可用的資料檔案

- `preprocessed_data.csv` - 清理後的資料（已可用）
- `sql_merge/merged_olist_data.csv` - 合併後的原始資料

## ❓ 需要幫助？

如果遇到問題：
1. 確認 R 和 RStudio 已正確安裝
2. 檢查工作目錄是否正確
3. 確認所需的 R 套件已安裝

