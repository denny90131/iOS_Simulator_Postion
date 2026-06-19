#!/bin/bash
#
# iOS 17+ 模擬 GPS 位置 一鍵腳本
#
# 用法:
#   ./simulate_location.sh <緯度> <經度>
#
# 範例:
#   ./simulate_location.sh 22.98667112038 120.233674915616
#

set -e

LOG_FILE="/tmp/tunneld_log_$$.txt"

echo "🔍 正在檢查環境..."

# ============================
# Homebrew
# ============================
if ! command -v brew >/dev/null 2>&1; then
    echo "⚠️ 未偵測到 Homebrew，正在安裝..."

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew 已安裝"
fi

# ============================
# Python
# ============================
if ! command -v python3 >/dev/null 2>&1; then
    echo "⚠️ 未偵測到 Python3，正在安裝..."

    brew install python
else
    echo "✅ 已安裝 $(python3 --version)"
fi

if ! command -v pip3 >/dev/null 2>&1; then
    echo "❌ 找不到 pip3"
    exit 1
fi

# ============================
# User PATH
# ============================
PY_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')

export PATH="$HOME/Library/Python/$PY_VER/bin:$PATH"

# ============================
# pymobiledevice3
# ============================
if ! command -v pymobiledevice3 >/dev/null 2>&1; then
    echo "⚠️ 未偵測到 pymobiledevice3，正在安裝..."

    python3 -m pip install \
        --user \
        --break-system-packages \
        pymobiledevice3

    export PATH="$HOME/Library/Python/$PY_VER/bin:$PATH"
fi

if ! command -v pymobiledevice3 >/dev/null 2>&1; then
    echo "❌ pymobiledevice3 安裝失敗"
    exit 1
fi

echo "✅ 已安裝 pymobiledevice3"
echo ""

# ============================
# 參數檢查
# ============================
if [ $# -ne 2 ]; then
    echo "用法: $0 <緯度> <經度>"
    echo "範例: $0 22.98667112038 120.233674915616"
    exit 1
fi

LAT="$1"
LON="$2"

echo "🚀 準備將設備位置修改為："
echo "   Latitude : $LAT"
echo "   Longitude: $LON"
echo ""

# ============================
# Cleanup
# ============================
cleanup() {
    if [ -n "$TUNNELD_PID" ]; then
        echo ""
        echo "🛑 關閉 tunneld..."
        sudo kill "$TUNNELD_PID" >/dev/null 2>&1 || true
    fi

    rm -f "$LOG_FILE"
}

trap cleanup EXIT

# ============================
# 啟動 tunneld
# ============================
echo "📡 啟動 tunneld..."

sudo pymobiledevice3 remote tunneld \
    > "$LOG_FILE" 2>&1 &

TUNNELD_PID=$!

echo "⏳ 等待 USB Tunnel 建立..."

RSD_ADDR=""
RSD_PORT=""

for i in $(seq 1 30)
do
    sleep 1

    if grep -q "Created tunnel" "$LOG_FILE" 2>/dev/null; then

        LINE=$(grep "Created tunnel" "$LOG_FILE" | tail -1)

        RSD_ADDR=$(echo "$LINE" | grep -oE 'rsd [a-fA-F0-9:]+' | awk '{print $2}')

        RSD_PORT=$(echo "$LINE" | grep -oE 'rsd [a-fA-F0-9:]+ [0-9]+' | awk '{print $3}')

        if [ -n "$RSD_ADDR" ] && [ -n "$RSD_PORT" ]; then
            break
        fi
    fi
done

# ============================
# 檢查 RSD
# ============================
if [ -z "$RSD_ADDR" ] || [ -z "$RSD_PORT" ]; then

    echo ""
    echo "❌ 無法取得 RSD 位址"
    echo ""
    echo "請確認："
    echo "1. iPhone 已 USB 連接"
    echo "2. 已按下『信任此電腦』"
    echo "3. 開發者模式已啟用"
    echo ""

    echo "===== tunneld log ====="
    cat "$LOG_FILE"

    exit 1
fi

echo ""
echo "✅ Tunnel 建立成功"
echo "RSD Address : $RSD_ADDR"
echo "RSD Port    : $RSD_PORT"
echo ""

# ============================
# 設定模擬位置
# ============================
echo "📍 設定模擬位置..."

pymobiledevice3 developer dvt simulate-location set \
    --rsd "$RSD_ADDR" "$RSD_PORT" \
    -- \
    "$LAT" "$LON"

echo ""
echo "✅ 模擬位置設定完成"
echo "📍 Latitude : $LAT"
echo "📍 Longitude: $LON"
echo ""

echo "若要清除模擬位置："
echo ""
echo "pymobiledevice3 developer dvt simulate-location clear --rsd $RSD_ADDR $RSD_PORT"
echo ""

echo "按 Enter 結束..."
read -r
