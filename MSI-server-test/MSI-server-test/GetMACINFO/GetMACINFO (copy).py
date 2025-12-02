import requests
import os
import re  # 引入正則表達式模組

# 指定儲存條碼的文字檔路徑
barcode_file_path = "/TestAP/PPID/PPID.TXT"

# 從文字檔中讀取 BARCODE_NO_V 的值
def read_barcode_from_file(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as file:
            barcode = file.read().strip()  # 讀取並移除首尾空白字符
            return barcode
    except FileNotFoundError:
        print(f"錯誤：找不到指定的檔案 {file_path}")
        return None
    except Exception as e:
        print(f"讀取檔案時發生錯誤: {e}")
        return None

# 調用函式讀取條碼
barcode_no_v = read_barcode_from_file(barcode_file_path)

# 多個 COMPONENT_TYPE_ID_V 的清單
# LIST : [MAC1 = 1122],[MAC2 = 1123],[MAC3 = 1124],[BMCMAC1 = 2977],[BMCMAC2 = 3060],[BMCMAC3 = 3061]
########  PE INPUT  ########
component_type_ids = [2211,2212]  # 這裡可以根據需求添加更多 ID

# 設定 IP 地址為變數
#ip_address = "172.16.0.220"

# 指定 API 基本 URL
url = f"https://sbc-la.msi.com/MES.WebApi/api/CommonDataExchangeIOW/ExcangeGetData"

# 指定資料夾路徑
folder_path = "/TestAP/Scan/"

# 確保資料夾存在，如果不存在就創建
os.makedirs(folder_path, exist_ok=True)

#分割 COMPONENT_TYPE_NAME 並插入 "MAC"  

def insert_mac_in_component_name(name):
    if "MAC" in name:
    	return name

    match = re.match(r"([A-Za-z]+)(\d+)", name)
    if match:
        letters, numbers = match.groups()
        return f"{letters}MAC{numbers}"
    else:
        # 如果無法匹配，則直接返回原始名稱加上 MAC
        return f"{name}MAC"

# 確保條碼值存在
if barcode_no_v:
    for component_type_id in component_type_ids:
        # 設置參數
        params = {
            "SystemFunction": "MES|WIP|Component|GetNormalComponentDataByBarcode|FromMesToOtherSystem",
            "SystemParam": f"BARCODE_NO_V:{barcode_no_v}|COMPONENT_TYPE_ID_V:{component_type_id}"
        }

        try:
            response = requests.get(url, params=params)
            response.raise_for_status()  # 確保請求成功
            data = response.json()

            # 顯示完整回應資料
            print(f"Response Data for COMPONENT_TYPE_ID_V={component_type_id}:", data)

            # 確保資料存在並處理
            if data["StatusCode"] == 0 and "T1" in data["Data"] and data["Data"]["T1"]:
                component_no = data["Data"]["T1"][0]["COMPONENT_NO"]
                component_type_name = data["Data"]["T1"][0]["COMPONENT_TYPE_NAME"]
                print(f"COMPONENT_NO for COMPONENT_TYPE_ID_V={component_type_id}:", component_no)

                # 將 COMPONENT_TYPE_NAME 插入 "MAC"
                modified_name = insert_mac_in_component_name(component_type_name)

                # 動態創建檔名
                filename = os.path.join(folder_path, f"{modified_name}.TXT")

                # 將 COMPONENT_NO 寫入指定檔案
                with open(filename, "w", encoding="utf-8") as file:
                    file.write(component_no)
                print(f"COMPONENT_NO 已成功保存到 {filename}")

            else:
                print(f"未找到 COMPONENT_TYPE_ID_V={component_type_id} 的有效數據。")

        except requests.exceptions.RequestException as e:
            print(f"Error with COMPONENT_TYPE_ID_V={component_type_id}: {e}")

else:
    print("未能從文字檔中讀取到有效的 BARCODE_NO_V 值。")
