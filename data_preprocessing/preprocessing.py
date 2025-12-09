# ============================================================================
# 巴西 Olist 電商平台資料前處理腳本 (Python 版本)
# ============================================================================
# 目的：清理和檢查合併後的資料，為後續統計分析做準備
# 
# 主要步驟：
# 1. 載入資料與基本檢視
# 2. 處理缺失值
# 3. 檢查與處理異常值
# 4. 處理重複資料
# 5. 建立衍生變數
# 6. 變數類型轉換
# 7. 資料分布檢查
# 8. 資料篩選
# 9. 儲存清理後的資料
# ============================================================================

import pandas as pd
import numpy as np
import os
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')

# ============================================================================
# 步驟 1: 載入資料與基本檢視
# ============================================================================

print("=" * 80)
print("步驟 1: 載入資料與基本檢視")
print("=" * 80)
print()

# 載入合併後的資料（從 sql_merge 資料夾）
# 自動判斷腳本所在目錄，然後找到 sql_merge 資料夾
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
data_path = os.path.join(project_root, "sql_merge", "merged_olist_data.csv")

if not os.path.exists(data_path):
    print(f"錯誤：找不到檔案 {data_path}")
    print("請確認已執行資料合併腳本！")
    exit(1)

print(f"載入資料: {data_path}")
data_raw = pd.read_csv(data_path, encoding='utf-8', low_memory=False)

# 建立資料副本（保留原始資料）
data = data_raw.copy()

print("✓ 資料載入完成")
print(f"原始資料筆數: {len(data):,}")
print(f"原始資料欄位數: {len(data.columns)}\n")

# 檢視資料結構
print("資料結構：")
print(data.info())
print()

# 檢視前幾筆資料
print("前 5 筆資料：")
print(data.head(5))
print()

# 基本統計摘要
print("基本統計摘要：")
print(data.describe())
print()

# ============================================================================
# 步驟 2: 處理缺失值
# ============================================================================

print("=" * 80)
print("步驟 2: 處理缺失值")
print("=" * 80)
print()

# 檢查缺失值
missing_summary = pd.DataFrame({
    'variable': data.columns,
    'missing_count': data.isnull().sum().values,
    'missing_percentage': (data.isnull().sum() / len(data) * 100).values
}).sort_values('missing_count', ascending=False)

print("各欄位缺失值統計：")
print(missing_summary[missing_summary['missing_count'] > 0])
print()

# 處理缺失值的策略
print("處理缺失值...")

# 2.1 刪除關鍵變數缺失的記錄
print("  - 刪除應變數（review_score）缺失的記錄")
data = data[data['review_score'].notna()]
print(f"    剩餘筆數: {len(data):,}")

# 2.2 處理物流變數的缺失值
print("  - 處理物流變數（delivery_days, delivery_gap）缺失")
data = data[data['delivery_days'].notna() & data['delivery_gap'].notna()]
print(f"    剩餘筆數: {len(data):,}")

# 2.3 處理交易成本變數的缺失值
print("  - 處理交易成本變數（price, freight_value）缺失")
data = data[data['price'].notna() & data['freight_value'].notna()]
print(f"    剩餘筆數: {len(data):,}")

# 2.4 處理商品屬性變數的缺失值
print("  - 處理商品屬性變數缺失")

# 商品類別缺失：新增「未知」類別
if 'product_category_name' in data.columns:
    data['product_category_name'] = data['product_category_name'].fillna('unknown')
if 'product_category_name_english' in data.columns:
    data['product_category_name_english'] = data['product_category_name_english'].fillna('unknown')

# 商品重量：如果缺失，用中位數填補（按商品類別）
if 'product_weight_g' in data.columns and data['product_weight_g'].isnull().sum() > 0:
    print("    使用中位數填補 product_weight_g 的缺失值")
    # 先按類別填補
    if 'product_category_name' in data.columns:
        data['product_weight_g'] = data.groupby('product_category_name')['product_weight_g'].transform(
            lambda x: x.fillna(x.median())
        )
    # 如果還有缺失，用整體中位數填補
    data['product_weight_g'] = data['product_weight_g'].fillna(data['product_weight_g'].median())

# 商品照片數量：如果缺失，用中位數填補
if 'product_photos_qty' in data.columns and data['product_photos_qty'].isnull().sum() > 0:
    print("    使用中位數填補 product_photos_qty 的缺失值")
    data['product_photos_qty'] = data['product_photos_qty'].fillna(data['product_photos_qty'].median())

# 2.5 處理控制變數的缺失值
print("  - 處理控制變數（payment_type, payment_installments）缺失")

# 付款方式缺失：新增「unknown」類別
if 'payment_type' in data.columns:
    data['payment_type'] = data['payment_type'].fillna('unknown')

# 分期期數：如果缺失，用中位數填補
if 'payment_installments' in data.columns and data['payment_installments'].isnull().sum() > 0:
    data['payment_installments'] = data['payment_installments'].fillna(data['payment_installments'].median())

print("\n✓ 缺失值處理完成")
print(f"處理後資料筆數: {len(data):,}")

# 再次檢查缺失值
print("\n處理後的缺失值統計：")
missing_after = data.isnull().sum()
missing_vars = missing_after[missing_after > 0]
if len(missing_vars) > 0:
    print(missing_vars)
else:
    print("  無缺失值 ✓")
print()

# ============================================================================
# 步驟 3: 檢查與處理異常值
# ============================================================================

print("=" * 80)
print("步驟 3: 檢查與處理異常值")
print("=" * 80)
print()

# 3.1 檢查應變數（review_score）
print("檢查應變數（review_score）：")
print(f"  範圍: {data['review_score'].min()} - {data['review_score'].max()}")
print(f"  分布: \n{data['review_score'].value_counts().sort_index()}")
print()

# 移除不在 1-5 範圍的分數
data = data[(data['review_score'] >= 1) & (data['review_score'] <= 5)]
print(f"✓ 篩選後筆數: {len(data):,}\n")

# 3.2 檢查物流變數
print("檢查物流變數：")

# delivery_days（應該 >= 0）
print("  delivery_days:")
print(f"    最小值: {data['delivery_days'].min():.1f}")
print(f"    最大值: {data['delivery_days'].max():.1f}")
print(f"    平均數: {data['delivery_days'].mean():.2f}")
print(f"    中位數: {data['delivery_days'].median():.2f}")

# 檢查異常值（使用 IQR 方法）
Q1_days = data['delivery_days'].quantile(0.25)
Q3_days = data['delivery_days'].quantile(0.75)
IQR_days = Q3_days - Q1_days
lower_bound_days = Q1_days - 3 * IQR_days
upper_bound_days = Q3_days + 3 * IQR_days

outliers_days = ((data['delivery_days'] < lower_bound_days) | 
                 (data['delivery_days'] > upper_bound_days)).sum()
print(f"    異常值數量（3*IQR）: {outliers_days} ({outliers_days/len(data)*100:.2f}%)")

# delivery_gap
print("\n  delivery_gap:")
print(f"    最小值: {data['delivery_gap'].min():.1f}")
print(f"    最大值: {data['delivery_gap'].max():.1f}")
print(f"    平均數: {data['delivery_gap'].mean():.2f}")
print(f"    中位數: {data['delivery_gap'].median():.2f}")

# 3.3 檢查交易成本變數
print("\n檢查交易成本變數：")

# price（應該 > 0）
print("  price:")
print(f"    最小值: {data['price'].min():.2f}")
print(f"    最大值: {data['price'].max():.2f}")
print(f"    平均數: {data['price'].mean():.2f}")
print(f"    中位數: {data['price'].median():.2f}")

# 移除價格 <= 0 的記錄
price_invalid = (data['price'] <= 0).sum()
if price_invalid > 0:
    print(f"    移除價格 <= 0 的記錄: {price_invalid} 筆")
    data = data[data['price'] > 0]

# freight_value（應該 >= 0）
print("\n  freight_value:")
print(f"    最小值: {data['freight_value'].min():.2f}")
print(f"    最大值: {data['freight_value'].max():.2f}")
print(f"    平均數: {data['freight_value'].mean():.2f}")

# 移除運費 < 0 的記錄
freight_invalid = (data['freight_value'] < 0).sum()
if freight_invalid > 0:
    print(f"    移除運費 < 0 的記錄: {freight_invalid} 筆")
    data = data[data['freight_value'] >= 0]

# 3.4 檢查商品屬性變數
print("\n檢查商品屬性變數：")

# product_weight_g（應該 > 0）
if 'product_weight_g' in data.columns:
    print("  product_weight_g:")
    print(f"    最小值: {data['product_weight_g'].min():.1f}")
    print(f"    最大值: {data['product_weight_g'].max():.1f}")
    print(f"    平均數: {data['product_weight_g'].mean():.1f}")
    
    # 移除重量 <= 0 的記錄
    weight_invalid = (data['product_weight_g'] <= 0).sum()
    if weight_invalid > 0:
        print(f"    移除重量 <= 0 的記錄: {weight_invalid} 筆")
        data = data[data['product_weight_g'] > 0]

# product_photos_qty（應該 >= 0）
if 'product_photos_qty' in data.columns:
    print("\n  product_photos_qty:")
    print(f"    最小值: {data['product_photos_qty'].min()}")
    print(f"    最大值: {data['product_photos_qty'].max()}")
    print(f"    平均數: {data['product_photos_qty'].mean():.2f}")

print("\n✓ 異常值檢查完成")
print(f"處理後資料筆數: {len(data):,}\n")

# ============================================================================
# 步驟 4: 處理重複資料
# ============================================================================

print("=" * 80)
print("步驟 4: 處理重複資料")
print("=" * 80)
print()

# 檢查完全重複的記錄
duplicate_count = data.duplicated().sum()
print(f"完全重複的記錄數: {duplicate_count}")

if duplicate_count > 0:
    print("移除完全重複的記錄...")
    data = data.drop_duplicates()
    print(f"  剩餘筆數: {len(data):,}")

# 檢查 order_id 的重複情況
print("\n檢查 order_id 重複情況：")
order_dup = data['order_id'].value_counts()
print("每個 order_id 出現次數的分布：")
print(order_dup.value_counts().head(10))
print("\n保留所有記錄（包含同一訂單的多個商品）")

print("\n✓ 重複資料檢查完成\n")

# ============================================================================
# 步驟 5: 建立衍生變數
# ============================================================================

print("=" * 80)
print("步驟 5: 建立衍生變數")
print("=" * 80)
print()

print("建立衍生變數：")
print("  - total_value = price + freight_value")
data['total_value'] = data['price'] + data['freight_value']

print("  - price_above_mean（價格是否高於平均）")
mean_price = data['price'].mean()
data['price_above_mean'] = (data['price'] > mean_price).astype(int)

print("  - delivery_delayed（是否延遲送達）")
data['delivery_delayed'] = (data['delivery_gap'] > 0).astype(int)

print("  - delivery_early（是否提前送達）")
data['delivery_early'] = (data['delivery_gap'] < 0).astype(int)

print("\n✓ 衍生變數建立完成\n")

# ============================================================================
# 步驟 6: 變數類型轉換
# ============================================================================

print("=" * 80)
print("步驟 6: 變數類型轉換")
print("=" * 80)
print()

# 確保數值變數為數值型態
print("確保數值變數為數值型態：")
numeric_vars = ['review_score', 'delivery_days', 'delivery_gap', 'price', 
                'freight_value', 'product_weight_g', 'product_photos_qty', 
                'payment_installments']

for var in numeric_vars:
    if var in data.columns:
        data[var] = pd.to_numeric(data[var], errors='coerce')

print("  ✓ 所有數值變數已轉換")

# 類別變數轉為 category 型態（選項，節省記憶體）
print("\n轉換類別變數為 category 型態：")
categorical_vars = ['payment_type', 'product_category_name', 
                    'product_category_name_english', 'order_status']
for var in categorical_vars:
    if var in data.columns:
        data[var] = data[var].astype('category')

print("  ✓ 類別變數已轉換")

print("\n✓ 變數類型轉換完成\n")

# ============================================================================
# 步驟 7: 資料分布檢查
# ============================================================================

print("=" * 80)
print("步驟 7: 資料分布檢查")
print("=" * 80)
print()

# 7.1 應變數分布（數值型變數）
print("應變數（review_score）分布：")
print(f"  平均數: {data['review_score'].mean():.2f}")
print(f"  中位數: {data['review_score'].median():.2f}")
print(f"  標準差: {data['review_score'].std():.2f}")
print(f"\n分布：")
print(data['review_score'].value_counts().sort_index())
print(f"\n比例分布：")
print((data['review_score'].value_counts(normalize=True).sort_index() * 100).round(2))

# 7.2 主要數值變數的基本統計量
print("\n主要數值變數的基本統計量：")
numeric_vars_to_summarize = ['delivery_days', 'delivery_gap', 'price', 
                              'freight_value', 'product_weight_g', 
                              'product_photos_qty', 'payment_installments']
available_vars = [var for var in numeric_vars_to_summarize if var in data.columns]
print(data[available_vars].describe())

print("\n✓ 資料分布檢查完成")
print("\n注意：請查看後續生成的圖表以了解詳細分布情況\n")

# ============================================================================
# 步驟 8: 資料篩選（最終確認）
# ============================================================================

print("=" * 80)
print("步驟 8: 最終資料篩選")
print("=" * 80)
print()

# 最終確認所有必要欄位都不為空
print("最終確認：")

# 確認應變數存在
data = data[data['review_score'].notna()]

# 確認關鍵自變數存在
data = data[data['delivery_days'].notna() & 
            data['delivery_gap'].notna() &
            data['price'].notna() &
            data['freight_value'].notna()]

print(f"  最終資料筆數: {len(data):,}")
print(f"  最終資料欄位數: {len(data.columns)}")

print("\n✓ 最終篩選完成\n")

# ============================================================================
# 步驟 9: 儲存清理後的資料
# ============================================================================

print("=" * 80)
print("步驟 9: 儲存清理後的資料")
print("=" * 80)
print()

# 儲存清理後的資料（儲存在腳本所在目錄）
script_dir = os.path.dirname(os.path.abspath(__file__))
output_file = os.path.join(script_dir, "preprocessed_data.csv")
data.to_csv(output_file, index=False, encoding='utf-8')
print(f"✓ 清理後的資料已儲存至: {output_file}")

# 輸出處理摘要到控制台（不再輸出 txt 檔）
print("\n處理摘要（Console）：")

summary_report = {
    'original_rows': len(data_raw),
    'final_rows': len(data),
    'removed_rows': len(data_raw) - len(data),
    'removal_rate': round((len(data_raw) - len(data)) / len(data_raw) * 100, 2),
    'final_variables': len(data.columns),
    'processing_date': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
}

print(f"原始資料筆數: {summary_report['original_rows']:,}")
print(f"最終資料筆數: {summary_report['final_rows']:,}")
print(f"移除資料筆數: {summary_report['removed_rows']:,}")
print(f"移除比例: {summary_report['removal_rate']:.2f}%")
print(f"最終欄位數: {summary_report['final_variables']}")
print(f"處理日期: {summary_report['processing_date']}")

# 另存「非滿分（1~4 分）」子集，供專注分析
print("\n輸出僅含 1~4 分（非滿分）之資料子集...")
non5 = data[data['review_score'] < 5].copy()
non5_file = os.path.join(script_dir, "preprocessed_data_non5.csv")
non5.to_csv(non5_file, index=False, encoding='utf-8')
print(f"✓ 已輸出: {non5_file} （筆數: {len(non5):,}）")

# 在控制台同時輸出非滿分子集比例（不產生 txt）
print("非滿分子集摘要（Console）：")
print(f"筆數: {len(non5):,}")
print(f"比例: {len(non5)/summary_report['final_rows']*100:.2f}%")
print(f"生成時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

print("\n" + "=" * 80)
print("資料前處理完成！")
print("=" * 80)

