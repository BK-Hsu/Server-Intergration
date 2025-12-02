import requests
import os
import re

# 路徑設置
barcode_file_path = "/TestAP/PPID/PPID.TXT"
folder_path = "/TestAP/Scan/"
os.makedirs(folder_path, exist_ok=True)

# 讀取條碼
def read_barcode_from_file(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as file:
            return file.read().strip()
    except FileNotFoundError:
        print(f"錯誤：找不到指定的檔案 {file_path}")
        return None
    except Exception as e:
        print(f"讀取檔案時發生錯誤: {e}")
        return None

# 將 COMPONENT_TYPE_NAME 轉換為合法檔名
def convert_component_name_to_filename(name):
    name = name.upper()  # 統一大小寫

    # 處理 BMC-MAC 類型（例如：Node-A-BMC-MAC-1 ➜ BMCMAC1）
    match = re.search(r'BMC.*?MAC[-_]?(?P<index>\d+)', name)
    if match:
        index = match.group("index")
        return f"BMCMAC{index}"

    # 通用 fallback：取英文+數字，移除特殊符號
    match = re.match(r"([A-Z]+)(\d*)", name.replace("-", "").replace("_", ""))
    if match:
        prefix, suffix = match.groups()
        return f"{prefix}{suffix}"

    # fallback：移除特殊字元直接使用
    return name.replace("-", "").replace("_", "")

# 要查詢的 COMPONENT_TYPE_ID 列表
component_type_ids = [2209, 2210]  # 根據需求擴充

# MES API URL
url = "https://sbc-la.msi.com/MES.WebApi/api/CommonDataExchangeIOW/ExcangeGetData"

# 讀取條碼
barcode_no_v = read_barcode_from_file(barcode_file_path)

if barcode_no_v:
    for component_type_id in component_type_ids:
        params = {
            "SystemFunction": "MES|WIP|Component|GetNormalComponentDataByBarcode|FromMesToOtherSystem",
            "SystemParam": f"BARCODE_NO_V:{barcode_no_v}|COMPONENT_TYPE_ID_V:{component_type_id}"
        }

        try:
            response = requests.get(url, params=params)
            response.raise_for_status()
            data = response.json()

            print(f"Response Data for COMPONENT_TYPE_ID_V={component_type_id}:", data)

            # 處理成功回傳
            if data["StatusCode"] == 0 and "T1" in data["Data"] and data["Data"]["T1"]:
                item = data["Data"]["T1"][0]
                component_no = item.get("COMPONENT_NO", "").strip()
                component_type_name = item.get("COMPONENT_TYPE_NAME", "").strip()

                if not component_no:
                    print(f"[警告] COMPONENT_NO 為空，COMPONENT_TYPE_ID={component_type_id}")
                    continue

                filename_base = convert_component_name_to_filename(component_type_name)
                filename = os.path.join(folder_path, f"{filename_base}.TXT")

                with open(filename, "w", encoding="utf-8") as f:
                    f.write(component_no)
                print(f"✅ 已儲存 {component_no} 到 {filename}")

            else:
                print(f"[注意] 未找到 COMPONENT_TYPE_ID_V={component_type_id} 的有效資料。")

        except requests.exceptions.RequestException as e:
            print(f"[錯誤] COMPONENT_TYPE_ID_V={component_type_id} 請求失敗：{e}")

else:
    print("❌ 無法讀取 PPID 條碼。")