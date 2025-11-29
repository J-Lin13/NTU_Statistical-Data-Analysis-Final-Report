# ============================================================================
# 資料分布視覺化腳本
# ============================================================================
# 目的：生成資料分布圖表，包括直方圖、箱線圖等
# 使用方法：先執行 preprocessing.R，然後執行此腳本
# ============================================================================

library(ggplot2)
library(dplyr)
library(gridExtra)

# 檢查是否有清理後的資料
if (!file.exists("preprocessed_data.csv")) {
  stop("請先執行 preprocessing.R 生成清理後的資料！")
}

# 載入清理後的資料
data <- read_csv("preprocessed_data.csv", 
                 locale = locale(encoding = "UTF-8"),
                 show_col_types = FALSE)

cat("開始生成視覺化圖表...\n")

# 建立輸出目錄
if (!dir.exists("plots")) {
  dir.create("plots")
}

# ============================================================================
# 1. 應變數（review_score）分布
# ============================================================================

cat("生成應變數分布圖...\n")

# 直方圖（review_score 應為數值型）
p1 <- ggplot(data, aes(x = review_score)) +
  geom_bar(fill = "steelblue", alpha = 0.7) +
  labs(title = "應變數分布：評論分數 (review_score)",
       x = "評論分數",
       y = "頻率") +
  scale_x_continuous(breaks = 1:5) +
  theme_minimal()

ggsave("plots/review_score_distribution.png", p1, width = 8, height = 6, dpi = 300)

# ============================================================================
# 2. 物流變數分布
# ============================================================================

cat("生成物流變數分布圖...\n")

# delivery_days 直方圖
p2 <- ggplot(data, aes(x = delivery_days)) +
  geom_histogram(bins = 50, fill = "steelblue", alpha = 0.7, color = "white") +
  labs(title = "物流變數分布：送達天數 (delivery_days)",
       x = "送達天數",
       y = "頻率") +
  theme_minimal()

# delivery_days 箱線圖
p3 <- ggplot(data, aes(y = delivery_days)) +
  geom_boxplot(fill = "steelblue", alpha = 0.7) +
  labs(title = "物流變數箱線圖：送達天數 (delivery_days)",
       y = "送達天數") +
  theme_minimal()

# delivery_gap 直方圖
p4 <- ggplot(data, aes(x = delivery_gap)) +
  geom_histogram(bins = 50, fill = "coral", alpha = 0.7, color = "white") +
  labs(title = "物流變數分布：送達差距 (delivery_gap)",
       x = "送達差距（天數，正=延遲，負=提前）",
       y = "頻率") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  theme_minimal()

# delivery_gap 箱線圖
p5 <- ggplot(data, aes(y = delivery_gap)) +
  geom_boxplot(fill = "coral", alpha = 0.7) +
  labs(title = "物流變數箱線圖：送達差距 (delivery_gap)",
       y = "送達差距（天數）") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  theme_minimal()

ggsave("plots/delivery_days_histogram.png", p2, width = 8, height = 6, dpi = 300)
ggsave("plots/delivery_days_boxplot.png", p3, width = 8, height = 6, dpi = 300)
ggsave("plots/delivery_gap_histogram.png", p4, width = 8, height = 6, dpi = 300)
ggsave("plots/delivery_gap_boxplot.png", p5, width = 8, height = 6, dpi = 300)

# ============================================================================
# 3. 交易成本變數分布
# ============================================================================

cat("生成交易成本變數分布圖...\n")

# price 直方圖（對數尺度）
p6 <- ggplot(data, aes(x = price)) +
  geom_histogram(bins = 50, fill = "darkgreen", alpha = 0.7, color = "white") +
  labs(title = "交易成本分布：商品價格 (price)",
       x = "價格",
       y = "頻率") +
  scale_x_log10(labels = scales::comma) +
  theme_minimal()

# price 箱線圖
p7 <- ggplot(data, aes(y = price)) +
  geom_boxplot(fill = "darkgreen", alpha = 0.7) +
  labs(title = "交易成本箱線圖：商品價格 (price)",
       y = "價格") +
  scale_y_log10(labels = scales::comma) +
  theme_minimal()

# freight_value 直方圖
p8 <- ggplot(data, aes(x = freight_value)) +
  geom_histogram(bins = 50, fill = "darkorange", alpha = 0.7, color = "white") +
  labs(title = "交易成本分布：運費 (freight_value)",
       x = "運費",
       y = "頻率") +
  theme_minimal()

ggsave("plots/price_histogram.png", p6, width = 8, height = 6, dpi = 300)
ggsave("plots/price_boxplot.png", p7, width = 8, height = 6, dpi = 300)
ggsave("plots/freight_value_histogram.png", p8, width = 8, height = 6, dpi = 300)

# ============================================================================
# 4. 商品屬性變數分布
# ============================================================================

cat("生成商品屬性變數分布圖...\n")

# product_weight_g 直方圖（對數尺度）
p9 <- ggplot(data, aes(x = product_weight_g)) +
  geom_histogram(bins = 50, fill = "purple", alpha = 0.7, color = "white") +
  labs(title = "商品屬性分布：商品重量 (product_weight_g)",
       x = "重量（公克）",
       y = "頻率") +
  scale_x_log10(labels = scales::comma) +
  theme_minimal()

# product_photos_qty 直方圖
p10 <- ggplot(data, aes(x = product_photos_qty)) +
  geom_bar(fill = "pink", alpha = 0.7, color = "white") +
  labs(title = "商品屬性分布：商品照片數量 (product_photos_qty)",
       x = "照片數量",
       y = "頻率") +
  theme_minimal()

ggsave("plots/product_weight_histogram.png", p9, width = 8, height = 6, dpi = 300)
ggsave("plots/product_photos_qty_barplot.png", p10, width = 8, height = 6, dpi = 300)

# ============================================================================
# 5. 變數關係探索
# ============================================================================

cat("生成變數關係圖...\n")

# delivery_gap vs review_score
p11 <- ggplot(data, aes(x = delivery_gap, y = review_score)) +
  geom_point(alpha = 0.3, size = 0.5) +
  geom_smooth(method = "lm", color = "red") +
  labs(title = "物流效率與評論分數關係",
       x = "送達差距（天數）",
       y = "評論分數") +
  theme_minimal()

# price vs review_score
p12 <- ggplot(data, aes(x = log10(price + 1), y = review_score)) +
  geom_point(alpha = 0.3, size = 0.5) +
  geom_smooth(method = "lm", color = "red") +
  labs(title = "商品價格與評論分數關係",
       x = "價格（對數尺度）",
       y = "評論分數") +
  theme_minimal()

ggsave("plots/delivery_gap_vs_review_score.png", p11, width = 8, height = 6, dpi = 300)
ggsave("plots/price_vs_review_score.png", p12, width = 8, height = 6, dpi = 300)

# ============================================================================
# 6. 商品類別分布
# ============================================================================

cat("生成商品類別分布圖...\n")

# 前 10 大商品類別
top_categories <- data %>%
  count(product_category_name_english, sort = TRUE) %>%
  head(10)

p13 <- ggplot(top_categories, aes(x = reorder(product_category_name_english, n), y = n)) +
  geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
  coord_flip() +
  labs(title = "前 10 大商品類別",
       x = "商品類別",
       y = "數量") +
  theme_minimal()

ggsave("plots/top_categories.png", p13, width = 10, height = 6, dpi = 300)

# ============================================================================
# 7. 付款方式分布
# ============================================================================

cat("生成付款方式分布圖...\n")

p14 <- ggplot(data, aes(x = payment_type)) +
  geom_bar(fill = "darkblue", alpha = 0.7) +
  labs(title = "付款方式分布",
       x = "付款方式",
       y = "數量") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("plots/payment_type_distribution.png", p14, width = 8, height = 6, dpi = 300)

cat("\n✓ 所有圖表已生成並儲存至 plots/ 資料夾\n")
cat(sprintf("  共生成 %d 個圖表\n", 14))

