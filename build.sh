#!/bin/bash
set -e

echo "=== 构建 MK48 服务器 ==="

TAR_FILE="mk48-linux-x64.tar.gz"
ARTIFACTS_DIR="./tmp_artifacts"
BIN_DEST="./mk48-plus-bin"

# 检查压缩包
[ -f "$TAR_FILE" ] || { echo "错误: 未找到 $TAR_FILE"; exit 1; }

# 解压
rm -rf "$ARTIFACTS_DIR"
mkdir -p "$ARTIFACTS_DIR"
tar -zxf "$TAR_FILE" -C "$ARTIFACTS_DIR"

# 查找二进制
BIN_FILE=$(find "$ARTIFACTS_DIR" -type f \( -name "mk48-plus-bin" -o -name "mk48-server" -o -executable \) | head -1)
[ -z "$BIN_FILE" ] && { echo "错误: 未找到可执行文件"; exit 1; }

# 复制二进制
cp "$BIN_FILE" "$BIN_DEST"
chmod +x "$BIN_DEST"
echo "✅ 二进制: $BIN_DEST"

# 复制前端文件（关键！）
if find "$ARTIFACTS_DIR" -type d -name "public" | grep -q .; then
    PUBLIC_SRC=$(find "$ARTIFACTS_DIR" -type d -name "public" | head -1)
    cp -r "$PUBLIC_SRC" .
    echo "✅ 复制前端: public/ ($(find public -type f 2>/dev/null | wc -l) 文件)"
else
    mkdir -p public
    echo '<html><body><h1>MK48 Server</h1><p>Running</p></body></html>' > public/index.html
    echo "⚠️  创建了简易 public/index.html"
fi

# 清理
rm -rf "$ARTIFACTS_DIR"
echo "✅ 构建完成"
