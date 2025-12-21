#!/bin/bash
# 服务器状态诊断脚本
set -e

TARGET="turkey-mk.onrender.com"
echo "🔍 诊断服务器: $TARGET"
echo "="========================================="

# 1. 检查 DNS 解析
echo "1. DNS 解析:"
dig +short $TARGET || nslookup $TARGET 2>/dev/null | grep -A2 "Address:"
echo

# 2. 检查端口开放状态
echo "2. 端口扫描 (常见端口):"
for port in 80 443 8080 8443 10000 10001; do
    timeout 2 nc -zv $TARGET $port 2>/dev/null && \
        echo "  ✅ 端口 $port 开放" || \
        echo "  ❌ 端口 $port 关闭"
done
echo

# 3. 测试 HTTP/HTTPS 重定向
echo "3. HTTP → HTTPS 重定向测试:"
curl -s -I http://$TARGET/ 2>/dev/null | \
    grep -E "HTTP|Location|Server" | \
    sed 's/^/  /'
echo

# 4. 测试所有可能的健康端点
echo "4. 健康检查端点测试:"
for endpoint in "/" "/health" "/healthz" "/index.html" "/api/health"; do
    echo -n "  $endpoint: "
    status=$(curl -s -o /dev/null -w "%{http_code}" -k https://$TARGET$endpoint 2>/dev/null)
    if [ "$status" = "200" ] || [ "$status" = "204" ]; then
        echo "✅ $status"
    elif [ "$status" = "307" ] || [ "$status" = "301" ] || [ "$status" = "302" ]; then
        location=$(curl -s -I -k https://$TARGET$endpoint 2>/dev/null | grep -i "location:" | head -1)
        echo "🔄 $status → $(echo $location | cut -d' ' -f2-)"
    elif [ -n "$status" ]; then
        echo "⚠️  $status"
    else
        echo "❌ 无响应"
    fi
done
echo

# 5. 详细追踪单个请求
echo "5. 详细请求追踪 (到 /health):"
echo "  请求:" | sed 's/^/  /'
curl -v -k --max-time 10 https://$TARGET/health 2>&1 | \
    grep -E ">|<|HTTP|Location|Content-Type|Server" | \
    sed 's/^/    /' | \
    head -20
echo

# 6. 检查响应头
echo "6. 响应头分析:"
curl -s -I -k https://$TARGET/ 2>&1 | \
    grep -v "^$" | \
    while read line; do
        echo "  $line"
    done
echo

# 7. 检查 CDN 信息
echo "7. CDN/代理层检测:"
curl -s -I -k https://$TARGET/ 2>&1 | \
    grep -E "cf-ray|rndr-id|x-render|server:|via:" | \
    sed 's/^/  /'
echo

# 8. 模拟 Render 健康检查
echo "8. 模拟 Render 健康检查:"
curl -s -I -k https://$TARGET/health \
  -H "User-Agent: Render-Health-Check/1.0" \
  -H "X-Render-Health-Check: true" 2>/dev/null | \
    grep -E "HTTP|Content-Type|Content-Length" | \
    sed 's/^/  /'
echo

# 9. 测试 WebSocket 连接（如果适用）
echo "9. WebSocket 测试:"
echo -n "  WebSocket 握手: "
ws_status=$(echo -e "GET / HTTP/1.1\r\nHost: $TARGET\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n" | \
    nc $TARGET 443 2>/dev/null | head -1)
if echo "$ws_status" | grep -q "101"; then
    echo "✅ 支持 WebSocket"
else
    echo "❌ 不支持 WebSocket: $ws_status"
fi
echo

# 10. 总结
echo "="========================================="
echo "📋 诊断总结:"

# 分析结果
if curl -s -I -k https://$TARGET/health 2>/dev/null | grep -q "200"; then
    echo "✅ 健康检查通过"
elif curl -s -I -k https://$TARGET/health 2>/dev/null | grep -q "307"; then
    echo "🔄 重定向循环检测到"
    echo "   可能原因:"
    echo "   1. Render CDN 检测到后端不健康"
    echo "   2. 应用返回重定向而不是 200"
    echo "   3. 网络配置问题"
else
    echo "❌ 服务不可达"
fi

echo "建议:"
echo "  1. 检查 Render 服务日志"
echo "  2. 验证 MK48 是否在监听正确端口"
echo "  3. 检查容器内 netstat 输出"
echo "  4. 查看 MK48 启动日志"
