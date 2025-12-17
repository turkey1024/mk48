#!/bin/bash
set -euo pipefail

# ===================== 配置项 =====================
TAR_FILE="mk48-linux-x64.tar.gz"
ARTIFACTS_DIR="./mk48_artifacts"
BIN_DEST="./mk48-plus-bin"        # 注意：二进制文件叫 mk48-plus-bin
# ==================================================

echo "===== 检查依赖 ====="
required_tools=("tar" "chmod")
for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo "错误：未找到依赖工具 $tool"
        exit 1
    fi
done

echo "===== 检查压缩包 ====="
if [ ! -f "${TAR_FILE}" ]; then
    echo "错误：未找到 ${TAR_FILE}"
    ls -la
    exit 1
fi
echo "✅ 找到压缩包：${TAR_FILE}"

echo "===== 初始化临时目录 ====="
rm -rf "${ARTIFACTS_DIR}"
mkdir -p "${ARTIFACTS_DIR}"

echo "===== 解压 ${TAR_FILE} ====="
tar -zxf "${TAR_FILE}" -C "${ARTIFACTS_DIR}"

echo "===== 查找可执行文件 ====="
# 先查找 mk48-plus-bin
BIN_FILE=$(find "${ARTIFACTS_DIR}" -type f -name "mk48-plus-bin" | head -n 1)

# 如果没找到，查找 mk48-server（根据之前的发现）
if [ -z "${BIN_FILE}" ]; then
    echo "未找到 mk48-plus-bin，尝试查找 mk48-server"
    BIN_FILE=$(find "${ARTIFACTS_DIR}" -type f -name "mk48-server" | head -n 1)
fi

# 兜底：查找任何可执行文件
if [ -z "${BIN_FILE}" ]; then
    echo "警告：未找到指定名称，查找所有可执行文件"
    BIN_FILE=$(find "${ARTIFACTS_DIR}" -type f -executable | head -n 1)
fi

if [ -z "${BIN_FILE}" ]; then
    echo "错误：未找到任何可执行文件"
    echo "解压内容："
    find "${ARTIFACTS_DIR}" -type f | head -20
    exit 1
fi

echo "找到文件：${BIN_FILE}"

# 复制并重命名为 mk48-plus-bin
cp "${BIN_FILE}" "${BIN_DEST}"
chmod +x "${BIN_DEST}"

# 复制public目录（前端文件）
if [ -d "${ARTIFACTS_DIR}/public" ]; then
    echo "复制前端文件..."
    cp -r "${ARTIFACTS_DIR}/public" .
fi

# 清理
rm -rf "${ARTIFACTS_DIR}"

echo "===== 部署完成 ====="
echo "可执行文件：$(realpath "${BIN_DEST}")"
echo "文件大小：$(ls -lh "${BIN_DEST}" | awk '{print $5}')"
echo "前端文件：$(find ./public -type f 2>/dev/null | wc -l) 个"
