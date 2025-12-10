# ============================================================================
# R 套件安裝腳本
# ============================================================================
# 執行此腳本以安裝資料前處理所需的所有 R 套件
# ============================================================================

cat("開始安裝必要的 R 套件...\n\n")

# 定義需要安裝的套件
required_packages <- c(
  "dplyr",      # 資料整理與操作
  "readr",      # 讀取 CSV 檔案
  "ggplot2",    # 資料視覺化
  "tidyr",      # 資料整理（pivot_longer, pivot_wider 等）
  "corrplot"    # 相關係數熱力圖視覺化
)

# 檢查並安裝套件
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(sprintf("安裝 %s...\n", pkg))
    install.packages(pkg, dependencies = TRUE)
    cat(sprintf("  ✓ %s 安裝完成\n", pkg))
  } else {
    cat(sprintf("  ✓ %s 已安裝\n", pkg))
  }
}

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("所有套件安裝完成！\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")

