#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Frida Server 自动下载脚本 - 国内加速版
适用于 iPhone 14 Pro Max (arm64e)
"""

import os
import sys
import urllib.request
import subprocess
from pathlib import Path

def download_file(url, filename):
    """下载文件并显示进度"""
    print(f"开始下载: {filename}")
    print(f"源地址: {url}\n")
    
    try:
        def show_progress(block_num, block_size, total_size):
            downloaded = block_num * block_size
            percent = min(100, downloaded * 100 / total_size)
            bar_length = 50
            filled = int(bar_length * downloaded / total_size)
            bar = '█' * filled + '░' * (bar_length - filled)
            sys.stdout.write(f'\r进度: [{bar}] {percent:.1f}% ({downloaded/1024/1024:.1f}MB/{total_size/1024/1024:.1f}MB)')
            sys.stdout.flush()
        
        urllib.request.urlretrieve(url, filename, show_progress)
        print("\n✓ 下载完成！\n")
        return True
    except Exception as e:
        print(f"\n✗ 下载失败: {e}\n")
        return False

def extract_xz(xz_file):
    """解压.xz文件"""
    output_file = xz_file.replace('.xz', '')
    
    print(f"开始解压: {xz_file}")
    
    # 尝试使用Python的lzma模块
    try:
        import lzma
        with lzma.open(xz_file, 'rb') as f_in:
            with open(output_file, 'wb') as f_out:
                f_out.write(f_in.read())
        print(f"✓ 解压完成: {output_file}\n")
        return output_file
    except ImportError:
        print("✗ Python没有lzma模块")
        
        # 尝试使用7zip
        try:
            subprocess.run(['7z', 'x', xz_file, '-y'], check=True, capture_output=True)
            print(f"✓ 解压完成: {output_file}\n")
            return output_file
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("✗ 需要安装7-Zip: https://www.7-zip.org/download.html")
            return None

def main():
    print("=" * 70)
    print("Frida Server 下载工具 - iPhone 14 Pro Max")
    print("=" * 70)
    print()
    
    # Frida版本
    version = "16.5.9"
    arch = "ios-arm64e"
    filename = f"frida-server-{version}-{arch}.xz"
    output_file = filename.replace('.xz', '')
    
    # 如果已经存在，跳过下载
    if os.path.exists(output_file):
        print(f"✓ 文件已存在: {output_file}")
        print("直接使用已下载的文件\n")
    else:
        # 多个镜像源
        mirrors = [
            f"https://ghproxy.com/https://github.com/frida/frida/releases/download/{version}/{filename}",
            f"https://github.com/frida/frida/releases/download/{version}/{filename}",
            f"https://mirror.ghproxy.com/https://github.com/frida/frida/releases/download/{version}/{filename}",
        ]
        
        success = False
        for i, url in enumerate(mirrors, 1):
            print(f"[{i}/{len(mirrors)}] 尝试镜像源 {i}...")
            if download_file(url, filename):
                success = True
                break
        
        if not success:
            print("✗ 所有镜像源都下载失败")
            print("\n建议：")
            print("1. 检查网络连接")
            print("2. 或手动下载后放到当前目录")
            print(f"   文件名: {filename}")
            return
        
        # 解压文件
        result = extract_xz(filename)
        if not result:
            print("\n手动解压说明：")
            print(f"1. 安装7-Zip: https://www.7-zip.org/")
            print(f"2. 右键 {filename} → 7-Zip → 解压到当前文件夹")
            return
    
    # 生成传输脚本
    print("=" * 70)
    print("下一步：传输到iPhone")
    print("=" * 70)
    print()
    
    print("📱 方法一：使用爱思助手（最简单）")
    print("1. 打开爱思助助手，连接iPhone")
    print("2. 点击 文件管理 → 文件系统（越狱）")
    print("3. 导航到 /usr/bin/")
    print(f"4. 上传文件: {output_file}")
    print(f"5. 重命名为: frida-server")
    print()
    
    print("📱 方法二：使用SCP（需要知道iPhone IP）")
    
    # 创建SCP脚本
    with open("上传到iPhone.bat", "w", encoding="utf-8") as f:
        f.write("@echo off\n")
        f.write("chcp 65001 >nul\n")
        f.write("echo ====================================\n")
        f.write("echo Frida Server 上传工具\n")
        f.write("echo ====================================\n")
        f.write("echo.\n")
        f.write("set /p IP=请输入iPhone的IP地址: \n")
        f.write("echo.\n")
        f.write("echo 正在上传到 %IP%...\n")
        f.write(f"scp {output_file} root@%IP%:/usr/bin/frida-server\n")
        f.write("echo.\n")
        f.write("echo 设置权限...\n")
        f.write("ssh root@%IP% \"chmod +x /usr/bin/frida-server\"\n")
        f.write("echo.\n")
        f.write("echo ✓ 完成！\n")
        f.write("pause\n")
    
    print(f"   已创建: 上传到iPhone.bat")
    print(f"   双击运行，输入iPhone的IP地址\n")
    
    print("📱 方法三：使用iFunBox")
    print("1. 打开iFunBox，连接iPhone")
    print("2. 进入文件系统 → /usr/bin/")
    print(f"3. 拖拽 {output_file} 到该目录")
    print(f"4. 重命名为 frida-server")
    print()
    
    print("=" * 70)
    print("传输完成后，在iPhone上执行：")
    print("=" * 70)
    print()
    print("  su")
    print("  chmod +x /usr/bin/frida-server")
    print("  frida-server &")
    print()
    print("然后在电脑上验证：")
    print("  frida-ps -U")
    print()

if __name__ == "__main__":
    main()
