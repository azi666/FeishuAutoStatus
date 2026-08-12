#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
飞书IPA静态分析工具
提取Objective-C类名和方法名
"""

import re
import sys
from pathlib import Path

def extract_strings(binary_path, min_length=4):
    """从二进制文件中提取可打印字符串"""
    print(f"正在读取: {binary_path}")
    print(f"文件大小: {Path(binary_path).stat().st_size / 1024 / 1024:.2f} MB\n")
    
    with open(binary_path, 'rb') as f:
        data = f.read()
    
    # 提取ASCII可打印字符串
    ascii_pattern = rb'[ -~]{' + str(min_length).encode() + rb',}'
    strings = re.findall(ascii_pattern, data)
    
    return [s.decode('ascii', errors='ignore') for s in strings]

def find_objc_classes(strings):
    """查找Objective-C类名"""
    print("=== 查找状态相关的Objective-C类 ===\n")
    
    patterns = {
        'Status管理': r'[A-Z]\w*Status[A-Z]\w*|[A-Z]\w*状态[A-Z]\w*',
        'User相关': r'[A-Z]\w*User[A-Z]\w*Status[A-Z]\w*',
        'Manager': r'[A-Z]\w*StatusManager[A-Z]*',
        'Controller': r'[A-Z]\w*Status[A-Z]\w*Controller',
        'ViewController': r'[A-Z]\w*Status[A-Z]\w*ViewController',
        'Model': r'[A-Z]\w*Status[A-Z]\w*Model',
        'Service': r'[A-Z]\w*Status[A-Z]\w*Service',
        'Handler': r'[A-Z]\w*Status[A-Z]\w*Handler',
    }
    
    results = {}
    for category, pattern in patterns.items():
        matches = set()
        for s in strings:
            found = re.findall(pattern, s)
            matches.update(found)
        
        if matches:
            results[category] = sorted(matches)
    
    return results

def find_objc_methods(strings):
    """查找Objective-C方法名"""
    print("\n=== 查找状态相关的方法 ===\n")
    
    # Objective-C方法模式: - (void)methodName: 或 + (void)methodName:
    method_patterns = [
        r'[-+]\s*\([^)]+\)\s*\w*[Ss]tatus\w*',  # 包含status的方法
        r'[-+]\s*\([^)]+\)\s*set\w*[Ss]tatus\w*',  # set开头的status方法
        r'[-+]\s*\([^)]+\)\s*update\w*[Ss]tatus\w*',  # update开头的status方法
        r'[-+]\s*\([^)]+\)\s*change\w*[Ss]tatus\w*',  # change开头的status方法
        r'[-+]\s*\([^)]+\)\s*get\w*[Ss]tatus\w*',  # get开头的status方法
    ]
    
    methods = set()
    for pattern in method_patterns:
        for s in strings:
            found = re.findall(pattern, s)
            methods.update(found)
    
    return sorted(methods)

def find_selectors(strings):
    """查找SEL选择器"""
    print("\n=== 查找SEL选择器 ===\n")
    
    # 选择器模式
    selector_patterns = [
        r'\b\w*[Ss]tatus\w*:',  # status相关的选择器
        r'\bset\w*[Ss]tatus\w*:',
        r'\bupdate\w*[Ss]tatus\w*:',
        r'\bchange\w*[Ss]tatus\w*:',
        r'\bget\w*[Ss]tatus\w*\b',
    ]
    
    selectors = set()
    for pattern in selector_patterns:
        for s in strings:
            found = re.findall(pattern, s)
            selectors.update(found)
    
    return sorted(selectors)

def find_property_names(strings):
    """查找属性名"""
    print("\n=== 查找属性名 ===\n")
    
    # 属性通常是camelCase
    prop_patterns = [
        r'\b[a-z]\w*Status\b',
        r'\buser[A-Z]\w*Status\b',
        r'\bcurrent[A-Z]\w*Status\b',
    ]
    
    properties = set()
    for pattern in prop_patterns:
        for s in strings:
            found = re.findall(pattern, s)
            properties.update(found)
    
    return sorted(properties)

def main():
    binary_path = r"D:\Users\2403050002\Desktop\py\优化\FeishuAutoStatus\FeishuApp\Payload\Lark.app\Lark"
    
    if not Path(binary_path).exists():
        print(f"错误: 找不到文件 {binary_path}")
        return
    
    print("=" * 60)
    print("飞书 v7.73.17 静态分析")
    print("=" * 60)
    print()
    
    # 提取字符串
    strings = extract_strings(binary_path)
    print(f"提取到 {len(strings)} 个字符串\n")
    
    # 查找类
    classes = find_objc_classes(strings)
    for category, matches in classes.items():
        print(f"【{category}】")
        for match in matches[:30]:  # 限制显示数量
            print(f"  {match}")
        if len(matches) > 30:
            print(f"  ... 还有 {len(matches) - 30} 个")
        print()
    
    # 查找方法
    methods = find_objc_methods(strings)
    if methods:
        print("【方法】")
        for method in methods[:30]:
            print(f"  {method}")
        if len(methods) > 30:
            print(f"  ... 还有 {len(methods) - 30} 个")
        print()
    
    # 查找选择器
    selectors = find_selectors(strings)
    if selectors:
        print("【SEL选择器】")
        for sel in selectors[:50]:
            print(f"  {sel}")
        if len(selectors) > 50:
            print(f"  ... 还有 {len(selectors) - 50} 个")
        print()
    
    # 查找属性
    properties = find_property_names(strings)
    if properties:
        print("【属性名】")
        for prop in properties[:30]:
            print(f"  {prop}")
        if len(properties) > 30:
            print(f"  ... 还有 {len(properties) - 30} 个")
        print()
    
    # 保存完整结果
    output_file = "feishu_analysis_result.txt"
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("=" * 60 + "\n")
        f.write("飞书 v7.73.17 完整分析结果\n")
        f.write("=" * 60 + "\n\n")
        
        f.write("=== 类名 ===\n\n")
        for category, matches in classes.items():
            f.write(f"【{category}】\n")
            for match in matches:
                f.write(f"  {match}\n")
            f.write("\n")
        
        f.write("\n=== 方法 ===\n\n")
        for method in methods:
            f.write(f"  {method}\n")
        
        f.write("\n=== SEL选择器 ===\n\n")
        for sel in selectors:
            f.write(f"  {sel}\n")
        
        f.write("\n=== 属性名 ===\n\n")
        for prop in properties:
            f.write(f"  {prop}\n")
    
    print("=" * 60)
    print(f"✓ 完整结果已保存到: {output_file}")
    print("=" * 60)

if __name__ == "__main__":
    main()
