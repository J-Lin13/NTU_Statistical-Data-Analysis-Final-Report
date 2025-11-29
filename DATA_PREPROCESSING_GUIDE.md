# 資料前處理說明指南

## 🤔 資料前處理是什麼？

資料前處理（Data Preprocessing）是在進行統計分析或建立模型**之前**，對原始資料進行清理、檢查和轉換的過程。就像做菜前要先洗菜、切菜一樣，資料前處理是為了確保後續分析的結果準確可靠。

## 🎯 為什麼需要資料前處理？

合併後的資料（`merged_olist_data.csv`）可能還存在以下問題：

1. **缺失值（Missing Values）**：某些欄位可能有空值（NULL/NA）
2. **異常值（Outliers）**：某些數值可能不合理（如價格為負數、重量為 0 等）
3. **資料格式不一致**：日期格式、文字大小寫等
4. **資料重複**：因為 JOIN 關係可能產生重複記錄
5. **資料分布問題**：資料可能偏態或不符常態假設

如果直接使用未處理的資料，可能會導致：
- ❌ 統計分析結果不準確
- ❌ 迴歸模型預測能力差
- ❌ 無法正確解釋變數關係

## 📋 本專案的資料前處理步驟

根據您的研究目標和變數規劃，建議進行以下前處理：

### 1. 資料檢視與基本資訊（Exploratory Data Analysis）

**目的**：了解資料的基本情況

```r
# 查看資料結構
str(data)
summary(data)

# 查看資料筆數和欄位數
dim(data)
head(data)

# 檢查缺失值
colSums(is.na(data))
```

**重點檢查**：
- 總共有幾筆資料？
- 每個欄位的資料型態是什麼？
- 哪些欄位有缺失值？缺失比例多少？

### 2. 處理缺失值（Missing Value Treatment）

**可能出現缺失值的欄位**：
- `product_category_name`：商品類別可能為空
- `product_weight_g`：商品重量可能缺失
- `product_photos_qty`：照片數量可能缺失
- `payment_installments`：分期期數可能缺失

**處理策略**：
- **數值變數**：可以用平均數、中位數填補，或刪除該筆記錄
- **類別變數**：可以新增「未知」類別，或刪除該筆記錄
- **關鍵變數**：如果應變數或重要自變數缺失，建議刪除該筆記錄

### 3. 檢查與處理異常值（Outlier Detection）

**需要檢查的數值變數**：

- **物流變數**：
  - `delivery_days`：不應該為負數，應該在合理範圍內（例如 0-100 天）
  - `delivery_gap`：可能會有極端值（延遲或提前很多天）

- **交易成本變數**：
  - `price`：不應該為負數或 0
  - `freight_value`：不應該為負數

- **商品屬性變數**：
  - `product_weight_g`：應該大於 0
  - `product_photos_qty`：應該大於等於 0

**處理方法**：
```r
# 使用箱線圖（boxplot）檢查異常值
boxplot(data$price)
boxplot(data$delivery_days)

# 使用直方圖（histogram）檢查分布
hist(data$price)
hist(data$delivery_days)

# 識別極端值（例如：超過 3 個標準差）
outliers <- which(abs(data$price - mean(data$price)) > 3*sd(data$price))
```

**處理策略**：
- 如果異常值是合理的（如高價商品），保留
- 如果異常值明顯是錯誤資料，刪除或修正
- 考慮對偏態嚴重的變數進行對數轉換

### 4. 處理重複資料（Duplicate Records）

**原因**：
- 一個訂單可能有多個商品（order_items）
- 一個訂單可能有多筆付款記錄（payments）

**檢查方法**：
```r
# 檢查是否有完全重複的記錄
duplicated(data)
sum(duplicated(data))

# 檢查 order_id 的重複情況
table(table(data$order_id))
```

**處理策略**：
- 根據分析目標決定處理方式
- 如果需要以訂單為單位，可能需要聚合（aggregate）資料
- 如果需要保留所有商品項目，則保持現狀

### 5. 建立衍生變數（Derived Variables）

**已建立的變數**（在 SQL 合併時已計算）：
- ✅ `delivery_days`：從購買到送達的天數
- ✅ `delivery_gap`：實際送達與預估送達的差距

**可能需要新增的變數**：
```r
# 總金額 = 商品價格 + 運費
data$total_value <- data$price + data$freight_value

# 商品類別的虛擬變數（用於迴歸分析）
# 需要根據 product_category_name 建立 dummy variables

# 付款方式的虛擬變數
# 需要根據 payment_type 建立 dummy variables
```

### 6. 變數類型轉換（Type Conversion）

**檢查與轉換**：
```r
# 確保應變數為數值型態
data$review_score <- as.numeric(data$review_score)

# 確保日期欄位為日期型態
data$order_purchase_timestamp <- as.Date(data$order_purchase_timestamp)

# 類別變數轉為因子（factor）
data$payment_type <- as.factor(data$payment_type)
data$product_category_name_english <- as.factor(data$product_category_name_english)
```

### 7. 資料分布檢查（Distribution Check）

**目的**：為後續的統計檢定和模型假設做準備

```r
# 檢查應變數（review_score）的分布
table(data$review_score)
barplot(table(data$review_score))

# 檢查連續型自變數的分布
hist(data$delivery_days)
hist(data$price)
hist(data$product_weight_g)

# 檢查是否接近常態分布
shapiro.test(data$delivery_days)  # 注意：樣本太大時可能不適用
```

### 8. 資料篩選（Data Filtering）

**根據研究需求篩選資料**：
```r
# 只保留評論分數在 1-5 分的記錄（應該是全部，但檢查一下）
data <- data[data$review_score >= 1 & data$review_score <= 5, ]

# 只保留價格大於 0 的記錄
data <- data[data$price > 0, ]

# 只保留重量大於 0 的記錄（如果需要）
data <- data[data$product_weight_g > 0 | is.na(data$product_weight_g), ]
```

## 🎓 參考 ReadMe.md 中的前處理要求

根據您的 ReadMe.md，前處理應該包括：

> 透過 summary()、hist()、boxplot() 進行初步資料分布與異常值檢查

這對應到：
1. ✅ 使用 `summary()` 檢查基本統計量
2. ✅ 使用 `hist()` 檢查資料分布
3. ✅ 使用 `boxplot()` 檢查異常值

## 📊 前處理後的資料品質檢查清單

完成前處理後，確認：

- [ ] 沒有明顯的缺失值（或已妥善處理）
- [ ] 沒有明顯的異常值（或已妥善處理）
- [ ] 所有數值變數在合理範圍內
- [ ] 類別變數已轉換為因子
- [ ] 日期變數已正確轉換
- [ ] 資料分布已檢查（知道哪些變數需要轉換）
- [ ] 重複資料已處理（根據分析需求）

## 🚀 下一步

完成資料前處理後，就可以進行：

1. **敘述性統計分析**：
   - 計算各變數的平均數、標準差、中位數等
   - 製作各種圖表（直方圖、箱線圖、散點圖等）
   - 分析變數之間的相關性

2. **迴歸模型建立**：
   - 使用清理後的資料建立多元線性迴歸模型
   - 進行模型診斷和假設檢定

## 💡 建議

- **保留原始資料**：前處理時不要直接修改原始 CSV，而是建立新的清理後資料檔
- **記錄處理過程**：記錄刪除了哪些資料、為什麼刪除，以便在報告中說明
- **逐步處理**：一次處理一個問題，避免同時做太多變更，難以追蹤問題

---

**提示**：資料前處理是一個迭代的過程，可能需要根據初步分析的結果回頭調整處理方式。

