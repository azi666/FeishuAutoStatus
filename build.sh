#!/bin/bash

# FeishuAutoStatus 编译脚本

set -e

echo "🚀 开始编译 FeishuAutoStatus..."

# 检查Theos环境
if [ -z "$THEOS" ]; then
    echo "❌ 错误: THEOS 环境变量未设置"
    echo "请设置: export THEOS=~/theos"
    exit 1
fi

if [ ! -d "$THEOS" ]; then
    echo "❌ 错误: THEOS 目录不存在: $THEOS"
    exit 1
fi

echo "✓ THEOS 环境: $THEOS"

# 清理旧的编译文件
echo "🧹 清理旧文件..."
make clean 2>/dev/null || true

# 编译主Tweak
echo "🔨 编译 Tweak..."
make

# 编译偏好设置Bundle
echo "🔨 编译偏好设置..."
cd feishuautostatusprefs
make clean 2>/dev/null || true
make
cd ..

# 打包deb
echo "📦 打包 deb..."
make package

# 显示结果
echo ""
echo "✅ 编译完成！"
echo ""
echo "生成的包："
ls -lh packages/*.deb | tail -n 1

# 询问是否安装到设备
echo ""
read -p "是否安装到设备？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -z "$THEOS_DEVICE_IP" ]; then
        read -p "请输入设备IP地址: " device_ip
        export THEOS_DEVICE_IP=$device_ip
    fi
    
    echo "📲 安装到设备 $THEOS_DEVICE_IP..."
    make install
    
    echo "🔄 重启飞书..."
    ssh root@$THEOS_DEVICE_IP "killall -9 com.ss.iphone.lark" 2>/dev/null || true
    
    echo ""
    echo "✅ 安装完成！"
    echo "请打开飞书应用测试功能"
fi

echo ""
echo "📝 后续步骤："
echo "1. 打开设置 → 飞书自动状态"
echo "2. 启用插件并设置切换间隔"
echo "3. 打开飞书查看Console日志验证"
