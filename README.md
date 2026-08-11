# FeishuAutoStatus - 飞书自动状态切换插件

![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

一个用于iOS越狱设备的Tweak插件，实现飞书应用的定时自动状态切换功能，保持在线状态活跃。

## ✨ 功能特性

- 🔄 **自动定时切换** - 按设定时间间隔自动切换飞书状态
- ⚙️ **灵活配置** - 支持5分钟到2小时多种切换间隔
- 📱 **系统集成** - 集成到iOS设置应用，方便管理
- 🎯 **多状态支持** - 预设多种状态（在线、忙碌、会议中、请勿打扰）
- 🔋 **后台运行** - 应用进入后台时保持定时器运行
- 🚀 **轻量级** - 占用资源少，不影响应用性能

## 📋 系统要求

- iOS 14.0 及以上
- 已越狱设备
- 已安装飞书应用（Bundle ID: `com.ss.iphone.lark`）
- Theos 开发环境（用于编译）

## 🛠️ 编译安装

### 前置要求

1. 安装 Theos 开发环境
```bash
# macOS/Linux
sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"

# 设置环境变量
export THEOS=~/theos
export PATH=$THEOS/bin:$PATH
```

2. 配置签名（如需）
```bash
export THEOS_DEVICE_IP=你的设备IP
export THEOS_DEVICE_PORT=22
```

### 编译步骤

```bash
# 1. 进入项目目录
cd FeishuAutoStatus

# 2. 编译Tweak
make clean
make package

# 3. 安装到设备
make install

# 4. 重启飞书应用
killall -9 com.ss.iphone.lark
```

生成的 `.deb` 文件位于 `packages/` 目录下。

## 📦 直接安装

如果你有编译好的 `.deb` 文件：

```bash
# 通过SSH传输到设备
scp com.yourname.feishuautostatus_1.0.0_iphoneos-arm.deb root@设备IP:/tmp/

# SSH登录设备并安装
ssh root@设备IP
dpkg -i /tmp/com.yourname.feishuautostatus_1.0.0_iphoneos-arm.deb

# 重启SpringBoard（可选）
killall SpringBoard
```

## ⚙️ 使用说明

### 1. 启用插件

安装后，打开 **设置 → 飞书自动状态**

<img src="https://via.placeholder.com/300x200?text=Settings+Screenshot" alt="设置截图" width="300"/>

### 2. 配置选项

| 选项 | 说明 | 默认值 |
|------|------|--------|
| 启用插件 | 开启/关闭自动状态切换 | 开启 |
| 切换间隔 | 状态切换的时间间隔 | 1小时 |

**可选间隔：**
- 5分钟 (300秒)
- 10分钟 (600秒)
- 30分钟 (1800秒)
- 1小时 (3600秒)
- 2小时 (7200秒)

### 3. 预设状态列表

插件默认循环切换以下状态：

1. ✅ 在线
2. 🔥 忙碌
3. 📞 会议中
4. 🚫 请勿打扰

### 4. 自定义状态（高级）

编辑配置文件（需要root权限）：

```bash
vim /var/mobile/Library/Preferences/com.yourname.feishuautostatus.plist
```

修改 `statusList` 数组：

```xml
<key>statusList</key>
<array>
    <dict>
        <key>text</key>
        <string>自定义状态</string>
        <key>emoji</key>
        <string>🎯</string>
    </dict>
    <!-- 添加更多状态 -->
</array>
```

修改后重新加载设置或重启飞书。

## 🔧 工作原理

1. **注入机制**：通过 MobileSubstrate 注入到飞书进程
2. **Hook技术**：Hook飞书的状态管理类 `LKStatusManager`
3. **定时器**：使用 `NSTimer` 在主线程定时触发状态切换
4. **通知机制**：通过 `NSNotificationCenter` 传递状态变化
5. **持久化**：配置保存在 `/var/mobile/Library/Preferences/` 目录

## 🐛 故障排除

### 插件未生效

```bash
# 1. 检查插件是否安装
dpkg -l | grep feishuautostatus

# 2. 检查过滤器配置
cat /Library/MobileSubstrate/DynamicLibraries/FeishuAutoStatus.plist

# 3. 查看系统日志
grep FeishuAutoStatus /var/log/syslog
```

### 状态未自动切换

1. 确认插件在设置中已启用
2. 检查飞书应用是否在运行
3. 查看Console日志，过滤 `FeishuAutoStatus` 关键词
4. 尝试手动重启飞书应用

### 卸载插件

```bash
# SSH登录设备
dpkg -r com.yourname.feishuautostatus

# 清理配置文件
rm /var/mobile/Library/Preferences/com.yourname.feishuautostatus.plist
```

## 📝 注意事项

⚠️ **重要提示**：

1. **类名适配**：本插件中的 `LKStatusManager` 等类名可能需要根据实际飞书版本调整
2. **方法适配**：状态更新方法 `updateStatus:` 需要逆向分析飞书获取真实方法名
3. **测试环境**：建议先在测试设备上验证功能
4. **版本兼容**：飞书更新可能导致插件失效，需要重新适配
5. **合规使用**：请遵守公司规定，合理使用自动化工具

## 🔍 逆向分析指南

如需适配新版本飞书，建议使用以下工具：

```bash
# 1. 导出飞书可执行文件的头文件
class-dump-z /var/containers/Bundle/Application/飞书.app/飞书 -H -o ~/headers/

# 2. 搜索状态相关类
cd ~/headers/
grep -r "Status" . | grep -i "manager\|controller"

# 3. 使用Frida hook验证
frida -U -f com.ss.iphone.lark -l hook_status.js
```

关键类和方法查找：
- 状态管理类：`*StatusManager`, `*StatusController`
- 状态更新方法：`setStatus:`, `updateStatus:`, `changeStatus:`
- 用户信息类：`*UserInfo`, `*Profile`

## 📄 项目结构

```
FeishuAutoStatus/
├── Makefile                    # 主编译配置
├── control                     # deb包元信息
├── FeishuAutoStatus.plist      # 过滤器配置
├── Tweak.x                     # 主代码逻辑
├── feishuautostatusprefs/      # 偏好设置Bundle
│   ├── Makefile
│   ├── FeishuAutoStatusPrefs.m
│   └── Resources/
│       ├── Root.plist          # 设置界面定义
│       └── Info.plist
└── README.md
```

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📜 许可证

MIT License - 详见 LICENSE 文件

## 👨‍💻 作者

YourName - your@email.com

## 🙏 致谢

- [Theos](https://github.com/theos/theos) - iOS越狱开发框架
- [CydiaSubstrate](http://www.cydiasubstrate.com/) - 代码注入框架

---

**免责声明**：本项目仅供学习交流使用，使用者需自行承担使用风险。请遵守相关法律法规和公司规定。
