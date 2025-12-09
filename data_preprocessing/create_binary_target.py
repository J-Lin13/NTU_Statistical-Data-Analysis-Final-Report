#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
將 review_score 二分化處理腳本
目的：將評論分數轉換為二元目標變數，用於 Binomial GLM 分析
- review_score = 5 → success = 1 (成功)
- review_score = 1-4 → success = 0 (失敗)
"""

import pandas as pd
import os

def create_binary_target():
    """
    讀取 preprocessed_data.csv 並創建二元目標變數
    """
    # 設定路徑
    script_dir = os.path.dirname(os.path.abspath(__file__))
    input_file = os.path.join(script_dir, "preprocessed_data.csv")
    output_file = os.path.join(script_dir, "preprocessed_data_binary.csv")
    
    print("=" * 80)
    print("創建二元目標變數資料集")
    print("=" * 80)
    print()
    
    # 檢查輸入檔案是否存在
    if not os.path.exists(input_file):
        print(f"錯誤：找不到輸入檔案 {input_file}")
        return
    
    # 讀取資料
    print(f"讀取資料：{input_file}")
    df = pd.read_csv(input_file)
    print(f"✓ 資料載入完成：{len(df):,} 筆記錄，{len(df.columns)} 個欄位")
    print()
    
    # 檢查 review_score 分布
    print("原始 review_score 分布：")
    print(df['review_score'].value_counts().sort_index())
    print()
    
    # 創建二元目標變數
    # review_score = 5 → success = 1
    # review_score = 1-4 → success = 0
    df['success'] = (df['review_score'] == 5).astype(int)
    
    print("創建二元目標變數 'success'：")
    print("  - review_score = 5 → success = 1 (成功)")
    print("  - review_score = 1-4 → success = 0 (失敗)")
    print()
    
    # 驗證轉換
    print("二元目標變數 (success) 分布：")
    success_dist = df['success'].value_counts().sort_index()
    print(success_dist)
    print()
    print("比例分布：")
    print(f"  失敗 (0): {success_dist[0]:,} ({success_dist[0]/len(df)*100:.2f}%)")
    print(f"  成功 (1): {success_dist[1]:,} ({success_dist[1]/len(df)*100:.2f}%)")
    print()
    
    # 交叉驗證
    print("交叉驗證 (review_score vs success)：")
    cross_tab = pd.crosstab(df['review_score'], df['success'])
    print(cross_tab)
    print()
    
    # 儲存資料
    print(f"儲存資料至：{output_file}")
    df.to_csv(output_file, index=False, encoding='utf-8')
    print(f"✓ 資料已成功儲存：{len(df):,} 筆記錄")
    print()
    
    # 輸出欄位資訊
    print("輸出資料集包含以下欄位：")
    print(f"  總欄位數: {len(df.columns)}")
    print(f"  新增欄位: success (二元目標變數)")
    print()
    
    # 顯示前幾筆資料的相關欄位
    print("資料範例 (前 5 筆)：")
    print(df[['order_id', 'review_score', 'success', 'delivery_gap', 'price']].head())
    print()
    
    print("=" * 80)
    print("處理完成！")
    print("=" * 80)
    print()
    print(f"輸出檔案：{output_file}")
    print(f"總記錄數：{len(df):,}")
    print(f"成功率：{success_dist[1]/len(df)*100:.2f}%")
    print()
    print("接下來可以使用此資料進行 Binomial GLM 分析。")
    print()

if __name__ == "__main__":
    create_binary_target()

