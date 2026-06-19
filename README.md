# iOS GPS Simulate Location Script

一鍵腳本，自動透過 `pymobiledevice3` 在 iOS 17+ 裝置上模擬 GPS 位置（適用 macOS + USB 連線）。

> ⚠️ **免責聲明**
> 本工具僅供開發測試使用（如測試地理圍欄功能、App 定位邏輯等）。
> 請勿用於違反 App 服務條款或法律規範的用途，使用者需自行承擔相關風險與責任。

---

## 環境需求

- macOS
- Python 3（建議搭配 `pymobiledevice3`）
- iPhone（iOS 17 / 18.x）
- USB 連接線

---

## 前置條件

- iPhone 已開啟 **開發者模式**
  設定 → 隱私權與安全性 → 開發者模式
- iPhone 透過 **USB** 連接 Mac，並點選「信任此電腦」
- 已安裝 `pymobiledevice3`：

```bash
pip install pymobiledevice3
```

- iPhone 螢幕保持解鎖狀態

---

## 安裝

```bash
git clone https://github.com/你的帳號/repo名稱.git
cd repo名稱
chmod +x simulate_location.sh
```

> 沒有 `chmod +x` 也可以，改用 `bash simulate_location.sh ...` 執行即可。

---

## 使用方式

```bash
./simulate_location.sh <緯度> <經度>
```

### 範例

```bash
./simulate_location.sh 22.98667112038 120.233674915616
```

或不給執行權限的版本：

```bash
bash simulate_location.sh 22.98667112038 120.233674915616
```

---

## 腳本執行流程

1. 在背景啟動 `tunneld`，建立 USB 通道
2. 自動輪詢並擷取 **RSD IPv6 位址與 Port**（最長等待 30 秒）
3. 自動帶入 `simulate-location set` 指令，設定模擬位置
4. 按下 `Enter` 結束時自動關閉 tunneld，避免殘留背景程序

---

## 清除模擬位置

腳本執行完成後會印出對應指令，格式如下：

```bash
python -m pymobiledevice3 developer dvt simulate-location clear --rsd <IPv6位址> <Port>
```

---

## 常見問題

| 錯誤訊息 | 原因 | 解決方法 |
|---|---|---|
| `Unable to connect to Tunneld` | tunneld 沒有執行 | 確認腳本是否正常啟動 tunneld |
| `QuicProtocolNotSupportedError` | iOS 18.2+ 不支援 QUIC（WiFi） | 改用 USB 連線（腳本預設使用 USB） |
| `DeveloperDiskImage already mounted` | 正常訊息，不影響使用 | 忽略即可 |
| `Waiting user pairing consent` | iPhone 尚未授權此電腦 | 手機畫面點選「信任」 |
| `Failed to start service` | CoreDevice 服務卡死 | 重新開機 iPhone，再重新執行腳本 |
| 抓不到 RSD 位址（逾時） | iPhone 未連接 USB 或未信任 | 確認 USB 連線與信任狀態後重試 |

---

## 常用座標參考

| 地點 | 緯度 | 經度 |
|---|---|---|
| 台北 101 | 25.033964 | 121.564468 |
| 台南市區 | 22.98667 | 120.23367 |

---

## 注意事項

- iOS 18.2+ 的 WiFi 隧道已不支援 QUIC，**僅支援 USB 連線**
- 每次重新連接 USB 或重啟 tunneld，RSD 位址都會變動（腳本會自動重新擷取）
- 模擬位置期間請保持 USB 連接；拔除連接線後，位置會恢復正常

---

## License

MIT
