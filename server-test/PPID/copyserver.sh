#!/bin/bash

# 強制使用 UTF-8 編碼
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# === 需修改的路徑設定 ===
FOLDER1="/TestAP/PPID"        # PPID 資料夾
FOLDER2="/TestAP/Scan"        # Scan 資料夾
PPID_FOLDER="/TestAP/PPID"    # PPID.TXT 所在資料夾
REMOTE_USER="mes"             # server 帳號
REMOTE_HOST="192.168.250.8"   # server IP
PASSWORD="msi@1377"           # server 密碼
MOUNT_POINT="/mnt/remote_server" # 掛載點
node_selected="/TestAP/PPID"
# 設定生產線資料夾名稱變數
LINE_FOLDER="709-S381-L10"

# === 保留的 REMOTE_SHARE 設定（用於上傳檔案） ===
if [ "$1" = "Fail" ]; then
    REMOTE_SHARE="//192.168.250.8/TestLog/SI/${LINE_FOLDER}/TESTFAIL"
else
    REMOTE_SHARE="//192.168.250.8/TestLog/SI/${LINE_FOLDER}/TEST"
fi

# === 🆕 第一步：掛載 SI 資料夾並創建結構 ===
REMOTE_SHARE_BASE="//192.168.250.8/TestLog/SI"
mkdir -p $MOUNT_POINT

# 掛載 base 共享資料夾（SI）
mount -t cifs -o username=$REMOTE_USER,password=$PASSWORD $REMOTE_SHARE_BASE $MOUNT_POINT

if [ $? -ne 0 ]; then
    echo "❌ 無法掛載遠端 SI 路徑: $REMOTE_SHARE_BASE"
    exit 1
fi

# 創建 709-S381-L10 資料夾與子資料夾 TEST、TESTFAIL、BURN
mkdir -p "$MOUNT_POINT/$LINE_FOLDER/TEST" \
         "$MOUNT_POINT/$LINE_FOLDER/TESTFAIL" \
         "$MOUNT_POINT/$LINE_FOLDER/BURN"

if [ $? -ne 0 ]; then
    echo "❌ 建立資料夾結構失敗"
    umount $MOUNT_POINT
    exit 1
fi

echo "✅ 遠端資料夾結構已建立：$LINE_FOLDER/{TEST, TESTFAIL, BURN}"

# 卸載 base 掛載點
umount $MOUNT_POINT

# === 第二步：壓縮資料夾 ===
MY_DATE=$(date +'%Y%m%d%H%M%S')
MY_PPID=$(tr -d '\r' < "$PPID_FOLDER/PPID.TXT")
MY_Node=$(tr -d '\r' < "$node_selected/node_selected.txt")
ARCHIVE_NAME="${MY_DATE}_${MY_PPID}_${MY_Node}.tar.gz"
echo "Archive name: $ARCHIVE_NAME"

cd /TestAP || exit 1
LC_ALL=C tar -czf "$ARCHIVE_NAME" "PPID" "Scan"

# === 第三步：掛載目標分享路徑上傳壓縮檔 ===
mount -t cifs -o username=$REMOTE_USER,password=$PASSWORD $REMOTE_SHARE $MOUNT_POINT

if [ $? -ne 0 ]; then
    echo "❌ 無法掛載上傳路徑: $REMOTE_SHARE"
    exit 1
fi

cp "$ARCHIVE_NAME" $MOUNT_POINT

# 卸載上傳目錄
umount $MOUNT_POINT

# 清理本地壓縮檔
rm "$ARCHIVE_NAME" || { echo "❌ 移除本地壓縮檔失敗"; exit 1; }

# 返回原目錄
cd -               
