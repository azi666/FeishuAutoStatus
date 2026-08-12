@echo off
chcp 65001 >nul
echo.
echo ========================================
echo 飞书自动状态切换插件 - 一键推送脚本
echo ========================================
echo.

:check_git
where git >nul 2>nul
if errorlevel 1 (
    echo [错误] 未检测到Git，正在尝试安装...
    winget install Git.Git
    if errorlevel 1 (
        echo [失败] 无法自动安装Git
        echo 请手动安装: https://git-scm.com/download/win
        pause
        exit /b 1
    )
    echo [成功] Git安装完成，请重启此脚本
    pause
    exit /b 0
)

echo [✓] Git已安装
echo.

:input_repo
echo 请输入你的GitHub仓库地址（格式：https://github.com/用户名/仓库名.git）
echo 示例：https://github.com/yourname/FeishuAutoStatus.git
echo.
set /p REPO_URL="仓库地址: "

if "%REPO_URL%"=="" (
    echo [错误] 仓库地址不能为空
    goto input_repo
)

echo.
echo 你输入的仓库地址: %REPO_URL%
echo.
set /p CONFIRM="确认推送？(y/n): "
if /i not "%CONFIRM%"=="y" goto input_repo

echo.
echo [1/5] 检查Git仓库状态...
git status >nul 2>nul
if errorlevel 1 (
    echo [错误] 这不是一个Git仓库
    pause
    exit /b 1
)

echo [✓] Git仓库已初始化
echo.

echo [2/5] 检查远程仓库...
git remote -v | findstr origin >nul 2>nul
if not errorlevel 1 (
    echo [!] 检测到已有远程仓库，正在更新...
    git remote set-url origin %REPO_URL%
) else (
    echo [+] 添加远程仓库...
    git remote add origin %REPO_URL%
)

if errorlevel 1 (
    echo [错误] 添加远程仓库失败
    pause
    exit /b 1
)

echo [✓] 远程仓库配置完成
echo.

echo [3/5] 检查分支...
git branch -M main
echo [✓] 切换到main分支
echo.

echo [4/5] 开始推送到GitHub...
echo [提示] 如果提示输入用户名密码：
echo   - Username: 你的GitHub用户名
echo   - Password: Personal Access Token (不是密码！)
echo.
echo 如何获取Token：
echo 1. 访问 https://github.com/settings/tokens
echo 2. Generate new token (classic)
echo 3. 勾选 repo 权限
echo 4. 复制token (ghp_xxx...)
echo.
pause

git push -u origin main

if errorlevel 1 (
    echo.
    echo [错误] 推送失败！
    echo.
    echo 常见原因：
    echo 1. 认证失败 - 使用Personal Access Token而不是密码
    echo 2. 仓库不存在 - 先在GitHub创建仓库
    echo 3. 网络问题 - 检查代理设置
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo [✓] 推送成功！
echo ========================================
echo.
echo 接下来的步骤：
echo.
echo 1. 访问你的仓库: %REPO_URL:~0,-4%
echo 2. 点击 "Actions" 标签
echo 3. 查看编译进度（约3-5分钟）
echo 4. 编译成功后下载 Artifacts 中的 .deb 文件
echo.
echo 详细说明请查看: GitHub自动编译部署指南.md
echo.
pause
