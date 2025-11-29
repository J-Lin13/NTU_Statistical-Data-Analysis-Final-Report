"""
巴西 Olist 電商平台資料合併腳本
此腳本將 CSV 檔案載入 SQLite 資料庫，然後使用 SQL 進行資料合併
"""

import sqlite3
import pandas as pd
import os
from datetime import datetime

def load_csv_to_database():
    """將所有 CSV 檔案載入 SQLite 資料庫"""
    
    # 取得腳本所在目錄
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    
    # 建立 SQLite 資料庫連線（在腳本所在目錄）
    db_path = os.path.join(script_dir, 'olist_data.db')
    conn = sqlite3.connect(db_path)
    
    # CSV 檔案路徑（位於 csv 資料夾中）
    csv_dir = os.path.join(project_root, 'csv')
    
    # CSV 檔案列表
    csv_files = {
        'olist_customers_dataset': os.path.join(csv_dir, 'olist_customers_dataset.csv'),
        'olist_orders_dataset': os.path.join(csv_dir, 'olist_orders_dataset.csv'),
        'olist_order_items_dataset': os.path.join(csv_dir, 'olist_order_items_dataset.csv'),
        'olist_order_payments_dataset': os.path.join(csv_dir, 'olist_order_payments_dataset.csv'),
        'olist_order_reviews_dataset': os.path.join(csv_dir, 'olist_order_reviews_dataset.csv'),
        'olist_products_dataset': os.path.join(csv_dir, 'olist_products_dataset.csv'),
        'olist_sellers_dataset': os.path.join(csv_dir, 'olist_sellers_dataset.csv'),
        'product_category_name_translation': os.path.join(csv_dir, 'product_category_name_translation.csv')
    }
    
    print("開始載入 CSV 檔案到資料庫...")
    
    for table_name, csv_file in csv_files.items():
        if os.path.exists(csv_file):
            print(f"載入 {csv_file}...")
            df = pd.read_csv(csv_file, low_memory=False)
            
            # 處理日期欄位（轉換為 datetime 格式以便 SQLite 使用）
            # SQLite 可以接受 ISO 格式的字串，所以我們保持字串格式即可
            # 但如果需要計算，可以轉換為 datetime 後再轉回字串（ISO 格式）
            
            # 將 DataFrame 寫入 SQLite
            df.to_sql(table_name, conn, if_exists='replace', index=False)
            print(f"  ✓ {table_name}: {len(df)} 筆記錄")
        else:
            print(f"  ✗ 找不到檔案: {csv_file}")
    
    print("\n所有 CSV 檔案已成功載入資料庫！")
    return conn

def create_merged_view(conn):
    """建立合併資料的 VIEW"""
    
    print("\n建立合併資料 VIEW...")
    
    # 取得腳本所在目錄
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # 讀取 SQL 檔案（與腳本同一目錄）
    sql_file = os.path.join(script_dir, 'merge_data.sql')
    with open(sql_file, 'r', encoding='utf-8') as f:
        sql_script = f.read()
    
    # 執行 SQL 腳本
    cursor = conn.cursor()
    
    # 分割 SQL 語句（以分號分隔）
    sql_statements = [stmt.strip() for stmt in sql_script.split(';') if stmt.strip()]
    
    for sql in sql_statements:
        if sql.strip():
            try:
                cursor.execute(sql)
                conn.commit()
            except sqlite3.Error as e:
                # 跳過 VIEW 已存在的錯誤
                if "already exists" not in str(e):
                    print(f"SQL 執行警告: {e}")
    
    print("✓ 合併資料 VIEW 已建立")

def export_merged_data(conn):
    """匯出合併後的資料為 CSV"""
    
    print("\n匯出合併後的資料...")
    
    # 查詢合併後的資料
    query = """
    SELECT 
        -- Review 相關變數（應變數）
        rev.review_id,
        rev.review_score,
        rev.review_creation_date,
        
        -- Order 相關變數
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        
        -- 計算物流效率變數
        CAST((julianday(o.order_delivered_customer_date) - julianday(o.order_purchase_timestamp)) AS INTEGER) AS delivery_days,
        CAST((julianday(o.order_delivered_customer_date) - julianday(o.order_estimated_delivery_date)) AS INTEGER) AS delivery_gap,
        
        -- Customer 相關變數
        c.customer_id,
        c.customer_unique_id,
        c.customer_state,
        c.customer_city,
        
        -- Order Items 相關變數（交易成本變數）
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        oi.price,
        oi.freight_value,
        
        -- Product 相關變數（商品屬性變數）
        p.product_category_name,
        pc.product_category_name_english,
        p.product_photos_qty,
        p.product_weight_g,
        
        -- Payment 相關變數（控制變數）
        pay.payment_type,
        pay.payment_installments,
        pay.payment_value
        
    FROM olist_order_reviews_dataset rev
    INNER JOIN olist_orders_dataset o ON rev.order_id = o.order_id
    INNER JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
    LEFT JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
    LEFT JOIN olist_products_dataset p ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
    LEFT JOIN olist_order_payments_dataset pay ON o.order_id = pay.order_id
    LEFT JOIN olist_sellers_dataset s ON oi.seller_id = s.seller_id
    
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_purchase_timestamp IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
    """
    
    df_merged = pd.read_sql_query(query, conn)
    
    # 取得腳本所在目錄
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # 儲存為 CSV（與腳本同一目錄）
    output_file = os.path.join(script_dir, 'merged_olist_data.csv')
    df_merged.to_csv(output_file, index=False, encoding='utf-8')
    
    print(f"✓ 合併後的資料已匯出至: {output_file}")
    print(f"  總筆數: {len(df_merged):,} 筆")
    print(f"  欄位數: {len(df_merged.columns)} 欄")
    
    # 顯示資料摘要
    print("\n=== 資料摘要 ===")
    print(f"唯一訂單數: {df_merged['order_id'].nunique():,}")
    print(f"唯一顧客數: {df_merged['customer_id'].nunique():,}")
    print(f"唯一商品數: {df_merged['product_id'].nunique():,}")
    print(f"\n平均評論分數: {df_merged['review_score'].mean():.2f}")
    print(f"評論分數分布:")
    print(df_merged['review_score'].value_counts().sort_index())
    
    return df_merged

def main():
    """主程式"""
    print("=" * 60)
    print("巴西 Olist 電商平台資料合併工具")
    print("=" * 60)
    
    # 載入 CSV 到資料庫
    conn = load_csv_to_database()
    
    # 建立合併 VIEW
    create_merged_view(conn)
    
    # 匯出合併後的資料
    df_merged = export_merged_data(conn)
    
    # 關閉資料庫連線
    conn.close()
    
    print("\n" + "=" * 60)
    print("資料合併完成！")
    print("=" * 60)

if __name__ == "__main__":
    main()

