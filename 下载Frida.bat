@echo off
chcp 65001 >nul
echo.
echo ════════════════════════════════════════════════════════
echo   Frida Server 下载（国内镜像）
echo   设备: iPhone 14 Pro Max
echo   版本: frida-server-17.17.0-ios-arm64e
echo ════════════════════════════════════════════════════════
echo.
echo 正在使用国内镜像下载...
echo.

curl.exe -L -o frida-server-ios-arm64e.xz "https://ghproxy.com/https://github.com/frida/frida/releases/download/17.17.0/frida-server-17.17.0-ios-arm64e.xz"

if exist frida-server-ios-arm64e.xz (
    echo.
    echo ✓ 下载成功！
    echo.
    echo 文件位置: %cd%\frida-server-ios-arm64e.xz
    echo.
    echo ════════════════════════════════════════════════════════
    echo 下一步：
    echo 1. 使用7-Zip解压 frida-server-ios-arm64e.xz
    echo 2. 重命名为 frida-server
    echo 3. 用爱思助手传到手机 /var/root/ 目录
    echo 4. 在手机终端运行：
    echo    su
    echo    cd /var/root
    echo    chmod +x frida-server
    echo    ./frida-server ^&
    echo ════════════════════════════════════════════════════════
) else (
    echo.
    echo ✗ 下载失败
    echo.
    echo 请尝试：
    echo 1. 在浏览器中打开以下链接手动下载：
    echo    https://ghproxy.com/https://github.com/frida/frida/releases/download/17.17.0/frida-server-17.17.0-ios-arm64e.xz
    echo.
    echo 2. 或使用Sileo直接安装（推荐）
    echo    添加源：https://build.frida.re
    echo    搜索并安装 Frida
)

echo.
pause
