#!/bin/bash
set -e

echo "🔧 开始构建流程..."

# 1. 安装 Rust（如果未安装）
if ! command -v rustc &> /dev/null; then
    echo "📥 安装 Rust 工具链..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

echo "✅ Rust 版本: $(rustc --version)"

# 2. 设置特定工具链
echo "🎯 设置 nightly-2024-04-20 工具链..."
rustup toolchain install nightly-2024-04-20 --profile minimal
rustup default nightly-2024-04-20
rustup target add wasm32-unknown-unknown

# 3. 下载预编译的 Trunk（使用正确的链接）
echo "📥 下载预编译的 Trunk..."
if ! command -v trunk &> /dev/null; then
    # 使用正确的下载链接
    TRUNK_URL="https://github.com/thedodd/trunk/releases/download/v0.21.14/trunk-x86_64-unknown-linux-gnu.tar.gz"
    echo "下载链接: $TRUNK_URL"
    
    # 下载并解压
    curl -L "$TRUNK_URL" | tar -xzf -
    chmod +x trunk
    
    # 验证下载的文件
    if [ -f "trunk" ]; then
        echo "✅ Trunk 下载成功，文件大小: $(wc -c < trunk) 字节"
        export PATH="$PWD:$PATH"
    else
        echo "❌ Trunk 下载失败"
        exit 1
    fi
fi

echo "✅ Trunk 版本: $(trunk --version)"

# 4. 构建客户端
echo "🏗️ 构建客户端..."
cd client
trunk build --release

echo "🎉 构建完成！"
ls -la dist/
