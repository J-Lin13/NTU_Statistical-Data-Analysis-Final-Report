# 使用 R 進行統計分析指南

## ✅ 目前狀況

您已經完成：
- ✅ 資料合併（使用 SQL + Python）
- ✅ 資料前處理（使用 Python）
- ✅ 安裝 R 軟體

**清理後的資料已準備好**：`preprocessed_data.csv`

## 🚀 立即開始使用 R

### 方法一：使用 RStudio（最簡單）

1. **下載並安裝 RStudio Desktop**（如果還沒安裝）
   - 網址：https://www.rstudio.com/products/rstudio/download/
   - 選擇免費版本：RStudio Desktop

2. **開啟 RStudio 並載入專案**
   - 啟動 RStudio
   - File → Open Folder
   - 選擇專案資料夾：`C:\Users\User\Downloads\商統分\NTU_Statistical-Data-Analysis-Final-Report`

3. **開始分析**
   - 開啟或建立新的 R Script
   - 開始撰寫或執行統計分析程式碼

### 方法二：在 Cursor 中使用 R（需設定）

如果您想在 Cursor 終端機直接使用 R：

1. **將 R 加入系統 PATH**
   - 找到 R 安裝路徑（通常：`C:\Program Files\R\R-4.x.x\bin`）
   - 將此路徑加入 Windows 環境變數 PATH
   - 重新啟動終端機

2. **測試 R**
   ```bash
   Rscript --version
   ```

## 📊 建議的下一步

### 1. 安裝必要的 R 套件

在 R 或 RStudio 中執行：

```r
# 安裝套件（只需要執行一次）
install.packages(c("dplyr", "readr", "ggplot2", "tidyr"))
```

或執行我們提供的安裝腳本：

```r
source("data_preprocessing/install_packages.R")
```

### 2. 載入清理後的資料

```r
library(dplyr)
library(readr)

# 載入前處理後的資料
data <- read_csv("preprocessed_data.csv")
```

### 3. 進行敘述性統計分析

可以使用我為您建立的腳本：

```r
# 從專案根目錄執行敘述性統計分析腳本
source("descriptive_analysis/descriptive_statistics.R")
```

或在 RStudio 中開啟 `descriptive_analysis/descriptive_statistics.R` 檔案，然後執行。

### 4. 開始建立迴歸模型

根據您的 ReadMe.md，接下來需要：

1. 使用 `summary()` 檢視資料
2. 使用 `hist()` 和 `boxplot()` 檢查分布
3. 使用 `lm()` 建立迴歸模型
4. 使用 `step()` 進行逐步選模

## 📁 可用的檔案

- **`data_preprocessing/preprocessed_data.csv`** - 清理後的資料（可直接使用）
- **`descriptive_statistics.R`** - 敘述性統計分析腳本（已為您準備好）
- **`data_preprocessing/preprocessing.R`** - R 版本的資料前處理腳本（可選）

## 💡 重要提示

1. **資料前處理已完成**，不需要重新執行
2. **直接開始統計分析**即可
3. **建議使用 RStudio**，操作較簡單且功能完整

## 📝 快速開始範例

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

## ❓ 遇到問題？

如果 R 無法執行：
1. 確認 R 和 RStudio 已正確安裝
2. 重新啟動 RStudio 或終端機
3. 檢查工作目錄是否正確（使用 `getwd()` 查看）

---

**建議：直接開啟 RStudio 開始分析！**

