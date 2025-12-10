#!/usr/bin/env bash
set -euo pipefail

ROOT=/srv/http_root

echo "[*] 建立 HTTP 根目錄 $ROOT ..."
sudo mkdir -p "$ROOT"
sudo chown -R www-data:www-data "$ROOT"

echo "[*] 放一個測試 index.html ..."
sudo tee "$ROOT/index.html" >/dev/null << 'EOC'
<!doctype html>
<html>
  <head><title>BK HTTP Test</title></head>
  <body>
    <h1>HTTP service from BK server</h1>
  </body>
</html>
EOC

echo "[*] 使用預設 nginx 站台，只調整根目錄..."
NGX_SITE=/etc/nginx/sites-available/default
sudo sed -i "s@root /var/www/html;@root $ROOT;@" "$NGX_SITE"

echo "[*] 重新啟動 nginx ..."
sudo systemctl enable nginx
sudo systemctl restart nginx
sudo systemctl status nginx --no-pager
