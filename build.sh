#!/bin/bash
set -e

echo "🔧 开始构建流程..."

# 1. 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

# 2. 强制设置特定的 nightly 版本
echo "🎯 强制设置 nightly-2024-04-20 工具链..."
rustup toolchain install nightly-2024-04-20 --profile minimal
rustup default nightly-2024-04-20
rustup target add wasm32-unknown-unknown

# 3. 设置环境变量，确保使用正确的工具链
export RUSTUP_TOOLCHAIN=nightly-2024-04-20
export CARGO_TARGET_DIR=./target-nightly-2024-04-20

# 4. 下载预编译的 Trunk
echo "📥 下载预编译的 Trunk..."
curl -L -o trunk.tar.gz https://github.com/thedodd/trunk/releases/download/v0.21.14/trunk-x86_64-unknown-linux-gnu.tar.gz
tar -xzf trunk.tar.gz
chmod +x trunk
export PATH="$PWD:$PATH"

echo "✅ 环境信息:"
echo "   Rust: $(rustc --version)"
echo "   Cargo: $(cargo --version)"
echo "   Trunk: $(trunk --version)"

# 5. 构建客户端
echo "🏗️ 构建客户端..."
cd client

# 确保在 client 目录中也使用正确的工具链
export RUSTUP_TOOLCHAIN=nightly-2024-04-20
export CARGO_TARGET_DIR=../target-nightly-2024-04-20

trunk build --release

echo "🎉 构建完成！"
ls -la dist/
