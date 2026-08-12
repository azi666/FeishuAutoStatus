# Dopamine越狱设备 - Frida安装完整教程

## 🎯 目标
在你已越狱的iPhone 14 Pro Max上安装Frida Server

---

## 📱 方法一：Sileo安装（最简单，推荐⭐⭐⭐⭐⭐）

### 1. 打开Sileo（越狱后自动安装的）

### 2. 添加Frida源
- 点击底部 **"Sources"（源）**
- 点击右上角 **"Edit"（编辑）**
- 点击左上角 **"+"**
- 输入源地址：`https://build.frida.re`
- 点击 **"Add Source"（添加源）**
- 等待刷新完成

### 3. 搜索并安装Frida
- 点击底部 **"Search"（搜索）**
- 搜索：`Frida`
- 找到 **"Frida"** 包（作者：Frida Project）
- 点击进入
- 点击 **"Get"（获取）** 或 **"Install"（安装）**
- 点击 **"Confirm"（确认）**
- 等待安装完成

### 4. 验证安装
打开 **NewTerm**（或SSH连接）：
```bash
su
# 输入密码（默认：alpine）

frida-server --version
```

如果显示版本号（如：`16.5.9`），说明安装成功！

---

## 📱 方法二：手动安装（如果方法一失败）

### 1. 在电脑上下载Frida
我已经帮你准备好了脚本：
```powershell
# 运行项目里的下载脚本
.\下载Frida.bat
```

会下载：`frida-server-17.17.0-ios-arm64e.xz`

### 2. 解压文件
```powershell
# 需要7-Zip
7z x frida-server-17.17.0-ios-arm64e.xz
# 得到：frida-server-17.17.0-ios-arm64e
```

### 3. 传输到iPhone
使用爱思助手或iFunBox：
- 连接iPhone
- 进入文件系统
- 上传到：`/usr/bin/frida-server`

或使用SCP（需要开启SSH）：
```powershell
scp frida-server-17.17.0-ios-arm64e root@你的iPhone的IP:/usr/bin/frida-server
```

### 4. 设置权限
在iPhone上（NewTerm或SSH）：
```bash
su
chmod +x /usr/bin/frida-server
```

### 5. 启动Frida
```bash
frida-server &
```

---

## ✅ 验证Frida是否工作

### 在iPhone上：
```bash
su
frida-server &
# 看到类似：[*] Listening on 0.0.0.0:27042
```

按 `Ctrl+C` 退出日志，Frida会继续后台运行。

### 在电脑上：
```powershell
# 确保iPhone和电脑在同一WiFi
# 列出iPhone上的进程
frida-ps -U
```

**如果看到一堆进程列表（包括"Lark"或"飞书"），说明成功了！** 🎉

---

## 🚀 下一步：运行分析脚本

完成上述步骤后，告诉我"Frida安装好了"，我会立即给你运行分析脚本！

---

## 🆘 可能的问题

### 问题1：Sileo找不到Frida包
**解决**：
- 确认源地址正确：`https://build.frida.re`
- 刷新源：下拉刷新
- 使用方法二手动安装

### 问题2：frida-ps -U 报错
**解决**：
```powershell
# 重新安装frida-tools
pip uninstall frida frida-tools
pip install frida-tools
```

### 问题3：SSH连接不上
**解决**：
- 确保安装了OpenSSH（Sileo搜索安装）
- 默认密码：`alpine`（建议修改）
- 使用命令：`passwd`

### 问题4：frida-server启动后立即退出
**解决**：
```bash
# 查看详细错误
frida-server -l 0.0.0.0:27042
```

---

## 💡 小贴士

1. **Frida Server需要手动启动**
   - 每次重启手机后需要重新运行 `frida-server &`
   - 或安装LaunchDaemon让它自动启动

2. **保持Frida后台运行**
   - 不要关闭NewTerm窗口
   - 或使用 `nohup frida-server &` 让它真正后台运行

3. **版本匹配**
   - 电脑端frida-tools版本需要 ≤ 手机端frida-server版本
   - 如果报错，检查版本：`frida --version` vs `frida-server --version`

---

## 准备好了？

安装完成后回复：**"Frida装好了"** 或 **"frida-ps -U 能看到进程"**

我会立即提供飞书分析脚本！ 🚀
