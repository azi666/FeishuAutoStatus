#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
飞书IPA快速分析工具 - 优化版
只搜索关键区域，速度更快
"""

import re
from pathlib import Path

def search_pattern_in_binary(binary_path, pattern, context_size=100):
    """在二进制文件中搜索模式，返回上下文"""
    results = []
    pattern_bytes = pattern.encode('latin1', errors='ignore')
    
    with open(binary_path, 'rb') as f:
        chunk_size = 1024 * 1024  # 1MB chunks
        overlap = 200  # 重叠区域避免遗漏
        
        position = 0
        previous_chunk = b''
        
        while True:
            chunk = f.read(chunk_size)
            if not chunk:
                break
            
            # 合并上一块的尾部，避免边界遗漏
            search_data = previous_chunk + chunk
            
            # 搜索模式
            for match in re.finditer(pattern_bytes, search_data):
                start = max(0, match.start() - context_size)
                end = min(len(search_data), match.end() + context_size)
                context = search_data[start:end]
                
                # 提取可读字符串
                readable = re.findall(rb'[ -~]{4,}', context)
                text = b' '.join(readable).decode('ascii', errors='ignore')
                results.append(text)
            
            # 保留尾部用于下次搜索
            previous_chunk = chunk[-overlap:] if len(chunk) >= overlap else chunk
            position += len(chunk)
    
    return results

def extract_class_names(results):
    """从结果中提取类名"""
    classes = set()
    
    # Objective-C类名模式
    patterns = [
        r'\b([A-Z][A-Za-z0-9_]*Status[A-Z][A-Za-z0-9_]*)\b',
        r'\b([A-Z][A-Za-z0-9_]*UserStatus[A-Za-z0-9_]*)\b',
        r'\b([A-Z][A-Za-z0-9_]*StatusManager)\b',
        r'\b([A-Z][A-Za-z0-9_]*StatusController)\b',
        r'\b([A-Z][A-Za-z0-9_]*StatusService)\b',
        r'\b([A-Z][A-Za-z0-9_]*StatusModel)\b',
        r'\b(LK[A-Za-z0-9_]*Status[A-Za-z0-9_]*)\b',  # Lark前缀
        r'\b(TT[A-Za-z0-9_]*Status[A-Za-z0-9_]*)\b',  # TouTiao前缀
    ]
    
    for result in results:
        for pattern in patterns:
            matches = re.findall(pattern, result)
            classes.update(matches)
    
    return sorted(classes)

def extract_methods(results):
    """提取方法名"""
    methods = set()
    
    patterns = [
        r'\b(set[A-Z]\w*Status\w*:?)\b',
        r'\b(update[A-Z]\w*Status\w*:?)\b',
        r'\b(change[A-Z]\w*Status\w*:?)\b',
        r'\b(get[A-Z]\w*Status\w*)\b',
        r'\b(\w*StatusWithType:?)\b',
        r'\b(\w*UserStatus:?)\b',
    ]
    
    for result in results:
        for pattern in patterns:
            matches = re.findall(pattern, result)
            methods.update(matches)
    
    return sorted(methods)

def main():
    binary_path = r"D:\Users\2403050002\Desktop\py\优化\FeishuAutoStatus\FeishuApp\Payload\Lark.app\Lark"
    
    print("=" * 70)
    print("飞书 v7.73.17 快速静态分析")
    print("=" * 70)
    print()
    
    # 搜索关键字
    keywords = [
        b'Status',
        b'status',
        b'UserStatus',
        b'setStatus',
        b'updateStatus',
        b'changeStatus',
    ]
    
    all_results = []
    
    for i, keyword in enumerate(keywords, 1):
        print(f"[{i}/{len(keywords)}] 搜索: {keyword.decode()}")
        results = search_pattern_in_binary(binary_path, keyword.decode())
        all_results.extend(results)
        print(f"     找到 {len(results)} 处匹配")
    
    print(f"\n总共找到 {len(all_results)} 个匹配项")
    print("\n" + "=" * 70)
    print("分析结果")
    print("=" * 70)
    
    # 提取类名
    print("\n【状态相关类名】\n")
    classes = extract_class_names(all_results)
    
    if classes:
        for cls in classes[:50]:  # 显示前50个
            print(f"  {cls}")
        if len(classes) > 50:
            print(f"\n  ... 还有 {len(classes) - 50} 个")
    else:
        print("  未找到明确的类名")
    
    # 提取方法
    print("\n【状态相关方法】\n")
    methods = extract_methods(all_results)
    
    if methods:
        for method in methods[:50]:
            print(f"  {method}")
        if len(methods) > 50:
            print(f"\n  ... 还有 {len(methods) - 50} 个")
    else:
        print("  未找到明确的方法名")
    
    # 保存详细结果
    output_file = "feishu_analysis_quick.txt"
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("=" * 70 + "\n")
        f.write("飞书 v7.73.17 快速分析结果\n")
        f.write("=" * 70 + "\n\n")
        
        f.write("=== 类名 ===\n\n")
        for cls in classes:
            f.write(f"{cls}\n")
        
        f.write("\n=== 方法名 ===\n\n")
        for method in methods:
            f.write(f"{method}\n")
        
        f.write("\n=== 原始上下文（前100个）===\n\n")
        for i, result in enumerate(all_results[:100], 1):
            f.write(f"--- [{i}] ---\n")
            f.write(result[:500] + "\n\n")  # 限制每个结果的长度
    
    print("\n" + "=" * 70)
    print(f"✓ 详细结果已保存: {output_file}")
    print("=" * 70)
    
    # 给出建议
    print("\n💡 分析建议：")
    if classes:
        print(f"\n找到 {len(classes)} 个可能的状态管理类")
        print("最有可能的候选类：")
        # 优先级排序
        priority_classes = [c for c in classes if 'Manager' in c or 'Service' in c or 'Controller' in c]
        for cls in priority_classes[:5]:
            print(f"  ⭐ {cls}")
    else:
        print("\n未找到明确的类名，可能需要：")
        print("  1. 使用Dopamine越狱后用Frida动态分析")
        print("  2. 使用IDA Pro/Hopper进行更深入的静态分析")
        print("  3. 查看完整结果文件，手动分析上下文")

if __name__ == "__main__":
    main()
