# FeishuAutoStatus - 飞书定时自动切换状态插件

## ✨ 功能特性

- 🔄 **自动切换状态** - 定时在预设的多个状态间自动切换
- ⏰ **工作时间识别** - 智能识别工作时间，非工作时间自动切换为休息状态
- 🎯 **自定义配置** - 支持自定义状态列表、切换间隔、工作时间
- 🧠 **智能适配** - 基于Android逆向分析，运行时动态查找iOS真实类名
- 📝 **详细日志** - 完整的调试日志，方便排查问题

## 📱 支持版本

- iOS 13.0+
- 越狱环境（需要安装Cydia Substrate）
- 飞书国际版（Bundle ID: com.ss.ios.lark.oversea）

## 🛠️ 技术原理

### 逆向分析路径

1. **Android分析** - 通过ADB和logcat分析Android版飞书
   ```
   发现关键类：com.ss.android.lark.mine.impl.custom_status.UserCustomStatusActivity
   ```

2. **iOS映射** - 推测iOS对应类名
   ```objective-c
   LKCustomStatusManager
   LKUserCustomStatusManager
   CustomStatusManager
   ```

3. **智能适配** - 运行时扫描所有类，动态查找真实类名

### 核心技术

- **运行时类扫描** - 使用 `objc_copyClassList` 扫描所有已加载的类
- **动态方法调用** - 使用 `NSInvocation` 动态调用未知签名的方法
- **多重Hook** - 同时Hook UIApplication和UIViewController捕获状态界面
- **通知机制** - 使用NSNotificationCenter进行模块间通信

## 📦 文件结构

```
FeishuAutoStatus/
├── Tweak.x                 # 主要代码（Theos语法）
├── Makefile                # 编译配置
├── control                 # deb包信息
├── FeishuAutoStatus.plist  # 注入配置（指定Bundle ID）
├── 编译安装指南.md         # 详细的编译和安装教程
└── 分析结果.md             # Android逆向分析记录
```

## 🚀 快速开始

### 1. 编译插件

需要macOS环境和Theos：

```bash
cd FeishuAutoStatus
make clean
make package
```

生成的deb文件在 `packages/` 目录。

**没有macOS？** 查看 `编译安装指南.md` 了解Docker方法。

### 2. 安装到iPhone

**方法A：Filza安装（推荐）**

1. 用爱思助手将.deb文件传到iPhone的Documents目录
2. 用Filza打开Documents，点击.deb文件
3. 点击"安装"
4. 重启SpringBoard：
   ```bash
   killall -9 SpringBoard
   ```

**方法B：SSH安装**

```bash
scp package.deb root@<iPhone-IP>:/tmp/
ssh root@<iPhone-IP>
dpkg -i /tmp/package.deb
killall -9 SpringBoard
```

### 3. 配置插件

配置文件位置：`/var/mobile/Library/Preferences/com.yourname.feishuautostatus.plist`

默认配置：
- 启用：是
- 切换间隔：3600秒（1小时）
- 工作时间：周一至周五 08:00-17:30
- 状态列表：在线✅ / 忙碌🔥 / 会议中📞 / 请勿打扰🚫

修改配置后重新加载：
```bash
killall -9 Lark
```

## 🐛 调试和日志

### 查看实时日志

**方法1：SSH + log命令**

```bash
ssh root@<iPhone-IP>
log stream --predicate 'processImagePath contains "Lark"' --level debug | grep FeishuAutoStatus
```

**方法2：使用Filza查看系统日志**

1. 打开Filza
2. 导航到 `/var/mobile/Library/Logs/`
3. 查找包含"Lark"的日志文件

### 关键日志标记

- 🚀 应用启动
- 📦 Bundle信息
- 🔍 类扫描
- ✅ 找到目标类
- 📺 界面出现
- ⏰ 定时器启动
- 📢 状态通知
- ❌ 错误信息

### 常见问题排查

**Q: 插件不生效？**

1. 确认已安装Cydia Substrate
2. 检查Bundle ID是否正确（查看日志中的"📦 Bundle ID"）
3. 重启SpringBoard
4. 查看日志是否有"🚀 飞书应用启动完成"

**Q: 找不到状态管理类？**

查看日志中的"🔍 发现可能的状态类"，将发现的类名更新到代码中。

**Q: 状态没有切换？**

1. 确认配置文件中 `enabled = true`
2. 查看是否在工作时间内
3. 检查日志中是否有"⏰ 启动定时器"

## 📝 自定义配置示例

### 修改状态列表

```xml
<key>statusList</key>
<array>
    <dict>
        <key>text</key>
        <string>摸鱼中</string>
        <key>emoji</key>
        <string>🐟</string>
    </dict>
    <dict>
        <key>text</key>
        <string>打游戏</string>
        <key>emoji</key>
        <string>🎮</string>
    </dict>
</array>
```

### 修改工作时间

```xml
<key>workStartHour</key>
<integer>9</integer>
<key>workStartMinute</key>
<integer>30</integer>
<key>workEndHour</key>
<integer>18</integer>
<key>workEndMinute</key>
<integer>0</integer>
```

### 禁用工作时间功能

```xml
<key>workTimeEnabled</key>
<false/>
```

这样会24小时循环切换状态。

## 🔧 开发和贡献

### 如果飞书更新导致插件失效

1. **重新分析Android版本**（如果可用）
   ```bash
   adb logcat | grep -i status
   ```

2. **查看iOS日志中扫描到的类名**
   ```bash
   log stream | grep "发现可能的状态类"
   ```

3. **更新代码中的类名列表**
   编辑 `Tweak.x` 中的 `possibleClasses` 数组

4. **重新编译安装**

### 技术要点

- 使用 `objc/runtime.h` 进行运行时类扫描
- 使用 `NSInvocation` 动态调用方法
- Hook `UIViewController` 捕获所有界面出现事件
- Hook `UIApplication` 监控应用生命周期

## 📄 许可证

MIT License - 自由使用和修改

## 🙏 致谢

- 基于Theos框架开发
- Android逆向分析提供类名线索
- 感谢越狱社区的工具支持

## 📞 反馈和支持

遇到问题请提供：
1. 飞书版本号
2. iOS系统版本
3. 完整的日志输出（包含🚀🔍📺等emoji标记）
4. 配置文件内容

---

**注意：此插件仅供学习研究使用，请遵守飞书服务条款。**
