# ============================================================================
# 共線性檢查散點圖
# ============================================================================
# 目的：檢查自變數之間的共線性問題（multicollinearity）
# ============================================================================

library(dplyr)
library(readr)
library(ggplot2)
library(gridExtra)

# ============================================================================
# 工作目錄設定
# ============================================================================

original_wd <- getwd()
script_path <- NULL
tryCatch({
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    context <- rstudioapi::getSourceEditorContext()
    if (!is.null(context) && length(context$path) > 0 && context$path != "") {
      script_path <- context$path
    }
  }
}, error = function(e) {})

if (is.null(script_path) || script_path == "") {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd_args, value = TRUE)
  if (length(file_arg) > 0) {
    script_path <- sub("^--file=", "", file_arg)
  }
}

if (!is.null(script_path) && script_path != "" && file.exists(script_path)) {
  script_dir <- dirname(normalizePath(script_path))
  project_root <- dirname(script_dir)
  if (dir.exists(file.path(project_root, "data_preprocessing"))) {
    setwd(project_root)
    cat(sprintf("已自動設定工作目錄為專案根目錄: %s\n\n", project_root))
  }
}

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("共線性檢查散點圖\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# ============================================================================
# 函數定義
# ============================================================================

create_collinearity_scatter <- function(data, x_var, y_var, title_suffix = "", 
                                       output_file) {
  
  # 計算相關係數
  cor_val <- cor(data[[x_var]], data[[y_var]], use = "complete.obs")
  
  # 建立線性模型
  lm_model <- lm(as.formula(paste(y_var, "~", x_var)), data = data)
  r_squared <- summary(lm_model)$r.squared
  
  # 判斷共線性程度
  collinearity_level <- ifelse(abs(cor_val) > 0.7, "High",
                               ifelse(abs(cor_val) > 0.5, "Moderate", "Low"))
  
  # 繪圖
  p <- ggplot(data, aes_string(x = x_var, y = y_var)) +
    geom_point(alpha = 0.3, color = "steelblue", size = 1.5) +
    geom_smooth(method = "lm", color = "red", se = TRUE, size = 1.2, alpha = 0.2) +
    labs(
      title = paste(y_var, "vs", x_var, title_suffix),
      subtitle = sprintf("Correlation: %.3f | R²: %.3f | Collinearity: %s", 
                        cor_val, r_squared, collinearity_level),
      x = x_var,
      y = y_var
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 13, face = "bold"),
      plot.subtitle = element_text(hjust = 0.5, size = 10, 
                                   color = ifelse(abs(cor_val) > 0.7, "red",
                                                 ifelse(abs(cor_val) > 0.5, "orange", "gray40"))),
      axis.title = element_text(size = 11),
      axis.text = element_text(size = 10),
      panel.grid.minor = element_blank()
    )
  
  ggsave(output_file, plot = p, width = 10, height = 7, dpi = 150)
  cat(sprintf("✓ %s vs %s (r=%.3f) - %s\n", y_var, x_var, cor_val, output_file))
  
  return(list(plot = p, cor = cor_val, r_squared = r_squared))
}

# ============================================================================
# 載入資料
# ============================================================================

cat("載入資料...\n")
data_all <- read_csv("data_preprocessing/preprocessed_data.csv", 
                     locale = locale(encoding = "UTF-8"), show_col_types = FALSE)
cat(sprintf("✓ 全部資料：%s 筆\n", format(nrow(data_all), big.mark = ",")))

data_non5 <- read_csv("data_preprocessing/preprocessed_data_non5.csv", 
                      locale = locale(encoding = "UTF-8"), show_col_types = FALSE)
cat(sprintf("✓ 非滿分資料：%s 筆\n\n", format(nrow(data_non5), big.mark = ",")))

# 建立輸出目錄
if (!dir.exists("plots")) dir.create("plots")
if (!dir.exists("plots_non5")) dir.create("plots_non5")

# ============================================================================
# 共線性檢查：重要變數配對
# ============================================================================

cat("生成共線性檢查散點圖\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

# 根據相關係數矩陣，重點檢查可能有共線性的變數對

# 1. delivery_days vs delivery_gap（高相關性 0.595/0.730）
cat("1. delivery_days vs delivery_gap [高度相關]\n")
create_collinearity_scatter(data_all, "delivery_days", "delivery_gap", 
                           "(All Data)", 
                           "plots/collinearity_delivery_days_vs_gap.png")
create_collinearity_scatter(data_non5, "delivery_days", "delivery_gap", 
                           "(Non-5)", 
                           "plots_non5/collinearity_delivery_days_vs_gap.png")

# 2. product_weight_g vs freight_value（高相關性 0.502）
cat("\n2. product_weight_g vs freight_value [中高度相關]\n")
create_collinearity_scatter(data_all, "product_weight_g", "freight_value", 
                           "(All Data)", 
                           "plots/collinearity_weight_vs_freight.png")
create_collinearity_scatter(data_non5, "product_weight_g", "freight_value", 
                           "(Non-5)", 
                           "plots_non5/collinearity_weight_vs_freight.png")

# 3. price vs freight_value（中度相關性 0.410）
cat("\n3. price vs freight_value [中度相關]\n")
create_collinearity_scatter(data_all, "price", "freight_value", 
                           "(All Data)", 
                           "plots/collinearity_price_vs_freight.png")
create_collinearity_scatter(data_non5, "price", "freight_value", 
                           "(Non-5)", 
                           "plots_non5/collinearity_price_vs_freight.png")

# 4. price vs product_weight_g（中度相關性 0.334）
cat("\n4. price vs product_weight_g [中度相關]\n")
create_collinearity_scatter(data_all, "price", "product_weight_g", 
                           "(All Data)", 
                           "plots/collinearity_price_vs_weight.png")
create_collinearity_scatter(data_non5, "price", "product_weight_g", 
                           "(Non-5)", 
                           "plots_non5/collinearity_price_vs_weight.png")

# 5. price vs payment_installments（中度相關性 0.315）
cat("\n5. price vs payment_installments [中度相關]\n")
create_collinearity_scatter(data_all, "price", "payment_installments", 
                           "(All Data)", 
                           "plots/collinearity_price_vs_installments.png")
create_collinearity_scatter(data_non5, "price", "payment_installments", 
                           "(Non-5)", 
                           "plots_non5/collinearity_price_vs_installments.png")

# 6. product_weight_g vs payment_installments（低相關性 0.198）
cat("\n6. product_weight_g vs payment_installments [低度相關]\n")
create_collinearity_scatter(data_all, "product_weight_g", "payment_installments", 
                           "(All Data)", 
                           "plots/collinearity_weight_vs_installments.png")
create_collinearity_scatter(data_non5, "product_weight_g", "payment_installments", 
                           "(Non-5)", 
                           "plots_non5/collinearity_weight_vs_installments.png")

# 7. freight_value vs payment_installments（低相關性 0.199）
cat("\n7. freight_value vs payment_installments [低度相關]\n")
create_collinearity_scatter(data_all, "freight_value", "payment_installments", 
                           "(All Data)", 
                           "plots/collinearity_freight_vs_installments.png")
create_collinearity_scatter(data_non5, "freight_value", "payment_installments", 
                           "(Non-5)", 
                           "plots_non5/collinearity_freight_vs_installments.png")

# ============================================================================
# 生成 VIF 參考資訊（僅供參考，不繪圖）
# ============================================================================

cat("\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")
cat("變異數膨脹因子（VIF）計算\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

# 安裝並載入 car 套件（如果需要）
if (!requireNamespace("car", quietly = TRUE)) {
  cat("正在安裝 car 套件...\n")
  install.packages("car", repos = "https://cran.rstudio.com/", quiet = TRUE)
}
library(car)

# 計算 VIF（全部資料）
cat("全部資料的 VIF 值：\n")
independent_vars <- c("delivery_days", "delivery_gap", "price", "freight_value",
                     "product_weight_g", "product_photos_qty", "payment_installments")

model_all <- lm(review_score ~ delivery_days + delivery_gap + price + 
                freight_value + product_weight_g + product_photos_qty + 
                payment_installments, data = data_all)
vif_all <- vif(model_all)
print(round(vif_all, 3))

cat("\n非滿分資料的 VIF 值：\n")
model_non5 <- lm(review_score ~ delivery_days + delivery_gap + price + 
                 freight_value + product_weight_g + product_photos_qty + 
                 payment_installments, data = data_non5)
vif_non5 <- vif(model_non5)
print(round(vif_non5, 3))

cat("\n")
cat("VIF 判斷標準：\n")
cat("  VIF < 5    ：無明顯共線性\n")
cat("  5 ≤ VIF < 10：中度共線性\n")
cat("  VIF ≥ 10   ：嚴重共線性\n")
cat("\n")

# ============================================================================
# 完成
# ============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("共線性檢查散點圖生成完成！\n")
cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("\n生成的散點圖（依相關性排序）：\n\n")
cat("【高度相關（可能有共線性問題）】\n")
cat("  1. collinearity_delivery_days_vs_gap.png (r≈0.60-0.73)\n")
cat("  2. collinearity_weight_vs_freight.png (r≈0.50)\n\n")
cat("【中度相關（需注意）】\n")
cat("  3. collinearity_price_vs_freight.png (r≈0.41-0.42)\n")
cat("  4. collinearity_price_vs_weight.png (r≈0.33)\n")
cat("  5. collinearity_price_vs_installments.png (r≈0.30-0.31)\n\n")
cat("【低度相關（無問題）】\n")
cat("  6. collinearity_weight_vs_installments.png (r≈0.20)\n")
cat("  7. collinearity_freight_vs_installments.png (r≈0.20)\n\n")
cat("所有圖表都生成了 plots/ 和 plots_non5/ 兩個版本。\n")
cat("VIF 值也已計算，請查看上方輸出。\n\n")

