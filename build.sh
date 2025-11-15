#!/bin/bash
set -e

echo "🔧 设置构建环境"

# 设置 Rust 工具链
rustup toolchain install nightly-2024-04-20 --profile minimal
rustup default nightly-2024-04-20
rustup target add wasm32-unknown-unknown

# 确保 trunk 可用
if ! command -v trunk &> /dev/null; then
    echo "📥 下载 Trunk"
    curl -LsS https://github.com/thedodd/trunk/releases/download/v0.21.14/trunk-x86_64-unknown-linux-gnu.tar.gz | tar -xzf -
    chmod +x trunk
    export PATH="$PWD:$PATH"
fi

echo "✅ 环境就绪:"
echo "   Rust: $(rustc --version)"
echo "   Trunk: $(trunk --version)"

# 构建客户端
echo "🏗️  构建客户端"
cd client
trunk build --release

echo "🎉 构建完成"
ls -la dist/
