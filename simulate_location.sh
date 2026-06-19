#!/bin/bash
#
# iOS 17+ 模擬 GPS 位置 一鍵腳本
# 用法: ./simulate_location.sh <緯度> <經度>
# 範例: ./simulate_location.sh 22.98667112038 120.233674915616
#
# 需求: pymobiledevice3 已安裝, iPhone 已開啟開發者模式並用 USB 連接
#

set -e

PYTHON_BIN="/usr/local/bin/python"
LOG_FILE="/tmp/tunneld_log_$$.txt"

# 檢查參數
if [ $# -ne 2 ]; then
  echo "用法: $0 <緯度> <經度>"
  echo "範例: $0 22.98667112038 120.233674915616"
  exit 1
fi

LAT="$1"
LON="$2"

echo "🚀 準備將 iOS 設備定位修改為 緯度: $LAT, 經度: $LON ..."

# 清理函數: 結束時關閉 tunneld
cleanup() {
  if [ -n "$TUNNELD_PID" ]; then
    echo "🛑 正在關閉 tunneld (PID: $TUNNELD_PID)..."
    sudo kill "$TUNNELD_PID" 2>/dev/null || true
  fi
  rm -f "$LOG_FILE"
}
trap cleanup EXIT

# 啟動 tunneld 並在背景執行，輸出寫入 log 檔
echo "📡 啟動 tunneld..."
sudo "$PYTHON_BIN" -m pymobiledevice3 remote tunneld > "$LOG_FILE" 2>&1 &
TUNNELD_PID=$!

# 等待 tunnel 建立並抓取 RSD 資訊（USB 連線）
echo "⏳ 等待 USB 隧道建立 (最長等待 30 秒)..."
RSD_ADDR=""
RSD_PORT=""

for i in $(seq 1 30); do
  sleep 1
  if grep -q "start-tunnel-task-usbmux" "$LOG_FILE" 2>/dev/null; then
    LINE=$(grep "start-tunnel-task-usbmux" "$LOG_FILE" | grep "Created tunnel" | tail -1)
    if [ -n "$LINE" ]; then
      RSD_ADDR=$(echo "$LINE" | grep -oE 'rsd [a-fA-F0-9:]+' | awk '{print $2}')
      RSD_PORT=$(echo "$LINE" | grep -oE 'rsd [a-fA-F0-9:]+ [0-9]+' | awk '{print $3}')
      break
    fi
  fi
done

if [ -z "$RSD_ADDR" ] || [ -z "$RSD_PORT" ]; then
  echo "❌ 無法取得 RSD 位址，請確認 iPhone 已用 USB 連接並信任此電腦"
  echo "--- tunneld log ---"
  cat "$LOG_FILE"
  exit 1
fi

echo "✅ 取得 RSD 位址: $RSD_ADDR  Port: $RSD_PORT"

# 執行模擬位置指令
echo "📍 正在設定模擬位置..."
"$PYTHON_BIN" -m pymobiledevice3 developer dvt simulate-location set \
  --rsd "$RSD_ADDR" "$RSD_PORT" \
  -- "$LAT" "$LON"

echo "✅ 完成！設備位置已設為 緯度: $LAT, 經度: $LON"
echo ""
echo "💡 若要清除模擬位置，請手動執行："
echo "$PYTHON_BIN -m pymobiledevice3 developer dvt simulate-location clear --rsd $RSD_ADDR $RSD_PORT"
echo ""
echo "按 Enter 鍵結束並關閉 tunneld..."
read -r
