#!/system/bin/sh

# 飞书状态管理类查找脚本
# 使用 dumpsys 和 logcat 分析

echo "===== 飞书状态管理分析 ====="
echo ""

# 1. 获取飞书进程信息
echo "[1] 飞书进程信息:"
ps | grep lark
echo ""

# 2. 查看飞书的Activity
echo "[2] 当前Activity:"
dumpsys activity top | grep ACTIVITY | head -5
echo ""

# 3. 查看飞书的Service
echo "[3] 飞书服务列表:"
dumpsys activity services com.ss.android.lark | grep ServiceRecord | head -10
echo ""

# 4. 查找状态相关的类（从内存）
echo "[4] 内存中的状态相关类:"
dumpsys meminfo com.ss.android.lark | grep -i status | head -10
echo ""

# 5. 查看最近的日志（包含状态关键词）
echo "[5] 最近的状态相关日志:"
logcat -d -s Lark:* | grep -i "status\|custom\|presence" | tail -20
echo ""

echo "===== 分析完成 ====="
echo ""
echo "提示："
echo "1. 在手机上打开飞书，修改自定义状态"
echo "2. 运行: adb logcat -c && adb logcat | grep -i status"
echo "3. 观察输出的类名和方法"
