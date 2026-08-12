# Frida Server 下载和安装（更新版）

## 🎯 方法1：直接从Cydia/Sileo源安装（最简单）

### 步骤：
1. 打开 **Sileo** 或 **Zebra**
2. 添加源：`https://build.frida.re`
3. 刷新源
4. 搜索 "**Frida**"
5. 安装 Frida 包
6. 完成！

---

## 🎯 方法2：下载预编译的deb包

Frida官方不再提供deb格式，但社区有打包好的版本：

### 下载地址（选一个）：

**选项A：从第三方源**
```
https://apt.bingner.com/ (Elucubratus源)
https://repo.chariz.com/ (Chariz源)
```

**选项B：手动下载tar.xz并转换**
最新版下载链接（根据你的设备）：

- **iPhone XS及以后（A12+）**：
  https://github.com/frida/frida/releases/download/17.17.0/frida-server-17.17.0-ios-arm64e.xz

- **iPhone X及之前（A11-）**：
  https://github.com/frida/frida/releases/download/17.17.0/frida-server-17.17.0-ios-arm64.xz

---

## 🎯 方法3：直接使用二进制文件（推荐！）

不需要deb包，直接运行：

### 步骤：

#### 1. 下载frida-server

在电脑上下载：
```powershell
# 下载最新版（根据你的设备选择）
# A12及以后（iPhone XS/XR/11/12/13/14/15）
Invoke-WebRequest -Uri "https://github.com/frida/frida/releases/download/17.17.0/frida-server-17.17.0-ios-arm64e.xz" -OutFile "frida-server.xz"

# 解压
# 需要7-Zip或其他解压工具
```

#### 2. 传输到手机

使用任意方法传到手机：
- **爱思助手**：文件系统 → /var/root/
- **SSH**: `scp frida-server root@<手机IP>:/var/root/`
- **Filza**：直接导入

#### 3. 在手机上设置权限并运行

打开手机终端（NewTerm/iSH/SSH），运行：

```bash
su
cd /var/root
chmod +x frida-server
./frida-server &
```

完成！

---

## 🎯 方法4：最快速方案（我帮你准备好）

我已经为你准备了一个自动化脚本：

### 在电脑上运行：

```powershell
cd "D:\Users\2403050002\Desktop\py\优化\FeishuAutoStatus"

# 下载frida-server（选择你的设备类型）
# A12+设备（iPhone XS及以后）
Invoke-WebRequest -Uri "https://github.com/frida/frida/releases/download/17.17.0/frida-server-17.17.0-ios-arm64e.xz" -OutFile "frida-server-ios-arm64e.xz"

# 解压（使用PowerShell）
# 如果有7-Zip
& "C:\Program Files\7-Zip\7z.exe" x frida-server-ios-arm64e.xz
```

然后用爱思助手或SSH传到手机的 `/var/root/` 目录。

---

## ✅ 验证安装

### 在手机上：
```bash
su
frida-server --version
# 或者
./frida-server --version
```

### 在电脑上：
```powershell
$env:Path = "$env:LOCALAPPDATA\Packages\PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0\LocalCache\local-packages\Python313\Scripts;$env:Path"
frida-ps -U
```

应该能看到进程列表！

---

## 🔧 启动frida-server

每次重启手机后需要运行：

```bash
su
cd /var/root
./frida-server &
```

或者添加到开机启动（可选）：
```bash
# 使用LaunchDaemon
nano /Library/LaunchDaemons/re.frida.server.plist
```

---

## 💡 推荐方案

**最简单**：方法1 - 从Sileo源安装（5分钟）

**最快速**：方法3 - 下载二进制直接运行（10分钟）

**最稳定**：方法1 - 从官方源安装

---

## 📞 需要帮助？

告诉我：
1. 你的iPhone型号（例如：iPhone 13 Pro）
2. iOS版本（例如：iOS 15.6）
3. 你更倾向哪种方法

我会给你提供具体的命令和文件！
