# FeishuAutoStatus 开发文档

## 项目架构

### 核心组件

1. **Tweak.x** - 主注入代码
   - 负责Hook飞书应用的状态管理类
   - 实现定时器逻辑
   - 处理状态切换和通知

2. **FeishuAutoStatusPrefs** - 偏好设置Bundle
   - 提供用户界面配置
   - 集成到系统设置应用
   - 保存用户偏好

3. **配置文件**
   - `control` - deb包元信息
   - `FeishuAutoStatus.plist` - MobileSubstrate过滤器
   - `Root.plist` - 设置界面定义

## 关键技术点

### 1. MobileSubstrate注入

通过plist文件指定目标Bundle ID：
```plist
{ Filter = { Bundles = ( "com.ss.iphone.lark" ); }; }
```

### 2. Objective-C Runtime Hook

使用Logos语法Hook目标类：
```objective-c
%hook LKStatusManager
- (id)init {
    id result = %orig;
    // 自定义逻辑
    return result;
}
%end
```

### 3. NSTimer定时器

主线程定时执行状态切换：
```objective-c
statusTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                               target:[NSObject class]
                                             selector:@selector(timerFired:)
                                             userInfo:nil
                                              repeats:YES];
```

### 4. 通知机制

使用NSNotificationCenter和Darwin通知：
```objective-c
// 应用内通知
[[NSNotificationCenter defaultCenter] postNotificationName:@"FeishuAutoStatusChanged"
                                                    object:nil
                                                  userInfo:status];

// 系统级通知（跨进程）
CFNotificationCenterPostNotification(
    CFNotificationCenterGetDarwinNotifyCenter(),
    CFSTR("com.yourname.feishuautostatus/ReloadPrefs"),
    NULL, NULL, YES
);
```

## 逆向分析步骤

### 1. 获取飞书可执行文件

```bash
# SSH连接到越狱设备
ssh root@设备IP

# 找到飞书应用路径
find /var/containers/Bundle/Application -name "com.ss.iphone.lark"

# 导出可执行文件
scp root@设备IP:/path/to/飞书.app/飞书 ~/Desktop/
```

### 2. class-dump导出头文件

```bash
# 安装class-dump
brew install class-dump

# 导出头文件
class-dump -H ~/Desktop/飞书 -o ~/Desktop/feishu_headers/

# 搜索状态相关类
cd ~/Desktop/feishu_headers/
grep -r "Status" . | grep "@interface"
```

### 3. 使用Frida动态分析

```bash
# 安装Frida
pip install frida-tools

# 连接设备
frida-ps -U

# 运行Hook脚本
frida -U -f com.ss.iphone.lark -l frida_hook_status.js --no-pause
```

### 4. 查找关键类和方法

重点关注：
- `*StatusManager` - 状态管理器
- `*StatusViewController` - 状态视图控制器
- `-setStatus:`, `-updateStatus:` - 状态设置方法
- `*UserInfo`, `*Profile` - 用户信息类

## 适配新版本

当飞书更新导致插件失效时：

### 1. 确认Bundle ID未变

```bash
# 查看应用信息
ssh root@设备IP
cd /var/containers/Bundle/Application/*/飞书.app
plutil -p Info.plist | grep CFBundleIdentifier
```

### 2. 重新逆向分析

使用上述Frida脚本找到新的类名和方法名

### 3. 更新Tweak.x代码

修改Hook的类名和方法名：
```objective-c
// 旧版本
%hook LKStatusManager

// 新版本可能变成
%hook LKUserStatusController
```

### 4. 测试验证

```bash
# 重新编译安装
make clean && make package && make install

# 查看日志
ssh root@设备IP
tail -f /var/log/syslog | grep FeishuAutoStatus
```

## 调试技巧

### 1. Console日志

在Tweak.x中添加NSLog：
```objective-c
NSLog(@"[FeishuAutoStatus] 当前状态: %@", status);
```

在Mac上查看日志：
```bash
# 通过Console.app过滤
# 或使用命令行
ssh root@设备IP "tail -f /var/log/syslog" | grep FeishuAutoStatus
```

### 2. 断点调试

使用Xcode附加到进程：
1. Xcode → Debug → Attach to Process
2. 选择"com.ss.iphone.lark"
3. 在代码中设置符号断点

### 3. 内存分析

使用Instruments分析内存泄漏：
```bash
instruments -t "Leaks" -D ~/leaks.trace -p 飞书PID
```

## 常见问题

### Q: 插件加载但不生效

A: 检查以下几点：
1. plist文件的Bundle ID是否正确
2. dylib是否成功注入（`ps aux | grep 飞书`）
3. Hook的类名是否正确
4. 方法签名是否匹配

### Q: 定时器不触发

A: 
1. 确认Timer添加到了正确的RunLoop
2. 检查应用是否进入后台被挂起
3. 验证Timer的target和selector

### Q: 状态切换无效

A: 
1. 逆向确认状态更新的真实方法
2. 检查参数类型和格式
3. 确认是否需要额外的权限验证

## 性能优化

### 1. 减少内存占用

- 及时释放不用的对象
- 使用弱引用避免循环引用
- 懒加载非必需资源

### 2. 降低CPU消耗

- 合理设置定时器间隔
- 避免频繁的状态查询
- 使用通知而非轮询

### 3. 电池优化

- 应用进入后台时考虑暂停定时器
- 减少不必要的网络请求
- 避免持续的高频操作

## 发布检查清单

- [ ] 代码中无硬编码的测试数据
- [ ] control文件版本号已更新
- [ ] README文档与功能一致
- [ ] 在多个iOS版本测试通过
- [ ] 在不同飞书版本验证兼容性
- [ ] 检查内存泄漏
- [ ] 验证卸载后无残留
- [ ] 偏好设置正常工作
- [ ] 日志输出合理（不过度）

## 参考资料

- [Theos Wiki](https://github.com/theos/theos/wiki)
- [Logos Syntax](http://iphonedevwiki.net/index.php/Logos)
- [iOS App Reverse Engineering](https://github.com/iosre/iOSAppReverseEngineering)
- [Frida Documentation](https://frida.re/docs/home/)
