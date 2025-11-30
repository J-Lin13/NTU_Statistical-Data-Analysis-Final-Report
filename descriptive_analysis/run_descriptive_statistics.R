# ============================================================================
# 快速執行敘述性統計分析
# ============================================================================
# 此腳本會自動設定工作目錄並執行敘述性統計分析
# ============================================================================

# 設定工作目錄為專案根目錄
project_root <- 'C:\\Users\\User\\OneDrive\\Desktop\\NTU\\商統分\\NTU_Statistical-Data-Analysis-Final-Report'

# 檢查目錄是否存在
if (!dir.exists(project_root)) {
  stop("專案根目錄不存在：", project_root, "\n請確認路徑是否正確。")
}

# 設定工作目錄
setwd(project_root)
cat("工作目錄已設定為：", getwd(), "\n\n")

# 執行敘述性統計分析腳本
source('descriptive_analysis/descriptive_statistics.R')

