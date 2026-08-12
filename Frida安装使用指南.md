# Frida安装和使用指南（巨魔设备）

## 当前状态
✅ 电脑已安装 Frida Tools
✅ 手机已通过USB连接
❌ 手机上需要安装 Frida Server

---

## 🔧 在手机上安装Frida Server

### 方法1：通过Sileo/Zebra安装（推荐）

1. **添加Frida源**
   - 打开 Sileo 或 Zebra
   - 添加源：`https://build.frida.re`
   
2. **安装Frida**
   - 搜索 "Frida"
   - 安装 `Frida` 包（注意不是Frida Tools）
   - 重启手机（可能需要）

3. **验证安装**
   ```bash
   # 在手机终端（NewTerm/iSH等）运行
   frida-server --version
   ```

### 方法2：手动安装（如果源无法访问）

1. **下载对应版本的Frida Server**
   - 访问：https://github.com/frida/frida/releases
   - 下载适合iOS的版本，例如：
     - `frida-server-16.7.19-ios-arm64.deb`（较新设备）
     - `frida-server-16.7.19-ios-arm64e.deb`（iPhone XS及以后）

2. **传输到手机**
   - 使用爱思助手/Filza/SSH等工具
   - 上传到 `/var/mobile/` 或 `/tmp/`

3. **安装deb**
   ```bash
   # 在手机终端运行
   su
   dpkg -i /var/mobile/frida-server-*.deb
   ```

4. **启动Frida Server**
   ```bash
   su
   frida-server &
   ```

---

## 🔌 重新连接测试

安装Frida Server后，在电脑上运行：

```powershell
# 在PowerShell中运行
$env:Path = "$env:LOCALAPPDATA\Packages\PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0\LocalCache\local-packages\Python313\Scripts;$env:Path"

# 测试连接
frida-ps -U
```

应该能看到手机上运行的进程列表，例如：
```
PID  Name
----  --------
1234  SpringBoard
5678  Preferences
9012  Lark (飞书)
```

---

## 🎯 开始分析飞书

### 步骤1：确保飞书正在运行
在手机上打开飞书app

### 步骤2：运行Frida脚本

```powershell
# 切换到项目目录
cd "D:\Users\2403050002\Desktop\py\优化\FeishuAutoStatus"

# 运行分析脚本（附加到已运行的飞书）
$env:Path = "$env:LOCALAPPDATA\Packages\PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0\LocalCache\local-packages\Python313\Scripts;$env:Path"
frida -U Lark -l frida_hook_status.js

# 或者使用Bundle ID
frida -U com.ss.iphone.lark -l frida_hook_status.js

# 如果飞书未运行，可以启动并注入
frida -U -f com.ss.iphone.lark -l frida_hook_status.js --no-pause
```

### 步骤3：在手机上操作飞书

脚本运行后，在手机上：
1. 点击飞书的个人头像
2. 点击"设置状态"或"我的状态"
3. 切换不同的状态（在线、忙碌、休息中等）
4. 多切换几次以获取更多日志

### 步骤4：查看输出

电脑控制台会显示：
```
[*] FeishuAutoStatus - 飞书状态管理逆向分析脚本
[*] 正在注入到飞书进程...

[+] 找到 15 个状态相关类:
    - LKStatusManager
    - LKUserStatusController
    - ...

[Hook] LKStatusManager.setUserStatus:
    self: <LKStatusManager: 0x123456>
    arg1: @"busy"
    返回值: 1

[通知] UserStatusDidChangeNotification
    object: <LKStatusManager: 0x123456>
```

**把完整的输出复制给我！**

---

## ⚠️ 常见问题

### 问题1：frida-ps一直显示"Waiting for USB device"

**原因：** 手机上没有安装或没有启动Frida Server

**解决：**
```bash
# 在手机终端运行
su
frida-server &
```

### 问题2：连接被拒绝

**解决：**
1. 确保手机已信任这台电脑
2. 重新插拔USB线
3. 重启Frida Server：
   ```bash
   killall frida-server
   frida-server &
   ```

### 问题3：找不到"Lark"进程

**可能的进程名：**
- `Lark`（飞书）
- `Feishu`（飞书）
- `com.ss.iphone.lark`（Bundle ID）

使用Bundle ID更可靠：
```powershell
frida -U com.ss.iphone.lark -l frida_hook_status.js
```

### 问题4：脚本注入后没有输出

**原因：** 类名可能不对或需要手动触发

**解决：**
1. 确保手机上打开了飞书
2. 在飞书中手动切换状态
3. 脚本会在状态变化时输出日志

---

## 🔄 完整流程总结

1. ✅ **电脑安装Frida Tools** - 已完成
2. ⬜ **手机安装Frida Server** - 你现在要做
3. ⬜ **测试连接** - `frida-ps -U`
4. ⬜ **运行脚本** - `frida -U Lark -l frida_hook_status.js`
5. ⬜ **操作飞书** - 切换状态
6. ⬜ **复制输出给我** - 我会更新代码

---

## 📞 需要帮助？

告诉我：
- 你在哪一步卡住了
- 看到什么错误信息
- 手机上看到什么（截图也可以）

我会立即帮你解决！
