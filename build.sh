#!/bin/bash
set -e

echo "🔧 开始构建流程..."

# 检查并安装 Rust
if ! command -v rustc &> /dev/null; then
    echo "📥 安装 Rust 工具链..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly-2024-04-20 --profile minimal
    source "$HOME/.cargo/env"
else
    echo "✅ Rust 已安装: $(rustc --version)"
    # 确保使用正确的工具链
    rustup default nightly-2024-04-20
fi

# 设置 WASM 目标
echo "🎯 设置 WASM 目标..."
rustup target add wasm32-unknown-unknown

# 安装 Trunk
if ! command -v trunk &> /dev/null; then
    echo "📥 安装 Trunk..."
    cargo install trunk --locked
else
    echo "✅ Trunk 已安装: $(trunk --version)"
fi

# 构建客户端
echo "🏗️ 切换到 client 目录构建..."
cd client
trunk build --release

echo "🎉 构建成功！"
echo "📁 输出文件在: client/dist/"
ls -la dist/
