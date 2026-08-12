#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
精确搜索飞书用户状态相关API
"""

import re
from pathlib import Path

def search_user_status_apis(binary_path):
    """搜索用户状态相关的API"""
    
    print("=" * 70)
    print("精确搜索用户状态API")
    print("=" * 70)
    print()
    
    # 定义搜索目标
    search_targets = [
        # 类名模式
        (b'UserStatusManager', '用户状态管理器'),
        (b'UserStatusService', '用户状态服务'),
        (b'UserStatusController', '用户状态控制器'),
        (b'PersonalStatusManager', '个人状态管理器'),
        (b'PresenceManager', '在线状态管理器'),
        (b'IMUserStatus', 'IM用户状态'),
        (b'LKUserStatus', 'Lark用户状态'),
        (b'TTUserStatus', 'TT用户状态'),
        
        # 方法模式
        (b'setUserStatus:', '设置用户状态'),
        (b'updateUserStatus:', '更新用户状态'),
        (b'changeUserStatus:', '改变用户状态'),
        (b'setPersonalStatus:', '设置个人状态'),
        (b'updatePersonalStatus:', '更新个人状态'),
        (b'getUserStatus', '获取用户状态'),
        (b'currentUserStatus', '当前用户状态'),
        
        # 属性模式
        (b'userStatusType', '用户状态类型'),
        (b'statusText', '状态文本'),
        (b'customStatus', '自定义状态'),
    ]
    
    results = {}
    
    with open(binary_path, 'rb') as f:
        data = f.read()
    
    for pattern, description in search_targets:
        print(f"搜索: {pattern.decode()} ({description})")
        
        matches = []
        for match in re.finditer(re.escape(pattern), data):
            # 提取前后200字节的上下文
            start = max(0, match.start() - 200)
            end = min(len(data), match.end() + 200)
            context = data[start:end]
            
            # 提取可读字符串
            readable_parts = re.findall(rb'[ -~]{3,}', context)
            text = b' '.join(readable_parts).decode('ascii', errors='ignore')
            matches.append(text)
        
        if matches:
            results[description] = matches
            print(f"  ✓ 找到 {len(matches)} 处")
        else:
            print(f"  ✗ 未找到")
        print()
    
    return results

def analyze_results(results):
    """分析结果并提取关键信息"""
    
    print("\n" + "=" * 70)
    print("分析结果")
    print("=" * 70)
    print()
    
    all_classes = set()
    all_methods = set()
    all_protocols = set()
    
    for desc, matches in results.items():
        for match in matches:
            # 提取Objective-C类名 (大写字母开头)
            classes = re.findall(r'\b([A-Z][A-Za-z0-9_]{2,}(?:Manager|Service|Controller|Status|Handler))\b', match)
            all_classes.update(classes)
            
            # 提取方法名 (包含冒号的)
            methods = re.findall(r'\b([a-z][A-Za-z0-9_]*(?:UserStatus|PersonalStatus|Status)[A-Za-z0-9_]*:?)\b', match)
            all_methods.update(methods)
            
            # 提取协议名
            protocols = re.findall(r'@protocol\s+([A-Za-z0-9_]+)', match)
            all_protocols.update(protocols)
    
    print("【可能的状态管理类】\n")
    priority_classes = sorted([c for c in all_classes if 'Status' in c and 
                               ('Manager' in c or 'Service' in c or 'Controller' in c)])
    
    if priority_classes:
        for cls in priority_classes[:20]:
            print(f"  ⭐ {cls}")
    else:
        print("  未找到明确的状态管理类")
    
    print("\n【可能的状态方法】\n")
    if all_methods:
        for method in sorted(all_methods)[:30]:
            print(f"  • {method}")
    else:
        print("  未找到明确的方法")
    
    print("\n【协议】\n")
    if all_protocols:
        for protocol in sorted(all_protocols)[:20]:
            print(f"  • {protocol}")
    else:
        print("  未找到协议")
    
    return all_classes, all_methods

def save_detailed_results(results, output_file):
    """保存详细结果"""
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("=" * 70 + "\n")
        f.write("飞书用户状态API详细分析\n")
        f.write("=" * 70 + "\n\n")
        
        for desc, matches in results.items():
            f.write(f"\n### {desc} ###\n")
            f.write(f"找到 {len(matches)} 处匹配\n\n")
            
            for i, match in enumerate(matches[:10], 1):  # 每个只保存前10个
                f.write(f"--- 匹配 {i} ---\n")
                # 清理并截断文本
                cleaned = ' '.join(match.split())[:500]
                f.write(cleaned + "\n\n")

def main():
    binary_path = r"D:\Users\2403050002\Desktop\py\优化\FeishuAutoStatus\FeishuApp\Payload\Lark.app\Lark"
    
    if not Path(binary_path).exists():
        print(f"错误: 找不到文件 {binary_path}")
        return
    
    # 搜索API
    results = search_user_status_apis(binary_path)
    
    # 分析结果
    classes, methods = analyze_results(results)
    
    # 保存详细结果
    output_file = "user_status_api_analysis.txt"
    save_detailed_results(results, output_file)
    
    print("\n" + "=" * 70)
    print(f"✓ 详细结果已保存: {output_file}")
    print("=" * 70)
    
    # 给出最终建议
    print("\n💡 下一步建议：\n")
    
    if classes and methods:
        print("✓ 找到了一些可能的类和方法")
        print("\n推荐方案：")
        print("  1. 基于找到的类名更新Tweak.x代码")
        print("  2. 使用Dopamine临时越狱验证")
        print("  3. 或者我帮你制作注入版IPA直接用巨魔安装\n")
    else:
        print("⚠ 静态分析信息有限")
        print("\n推荐方案：")
        print("  1. 安装Dopamine越狱（推荐，iOS 16.4.1支持）")
        print("  2. 使用Frida动态分析获取准确信息")
        print("  3. 或者我基于经验猜测常见的类名先试试看\n")

if __name__ == "__main__":
    main()
