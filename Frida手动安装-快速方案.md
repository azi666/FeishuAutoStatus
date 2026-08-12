# 🚀 Frida手动安装方案 - 跳过Sileo

## 为什么慢？
`https://build.frida.re` 服务器在国外，国内访问极慢或无法访问。

## ✅ 解决方案：手动安装（5分钟搞定）

---

## 📦 方法一：我提供国内镜像下载链接

### 1. 下载Frida（在电脑上）

**Frida 16.5.9 for iPhone 14 Pro Max (arm64e)**

#### 🌐 国内可用下载地址：

**选项A - jsdelivr CDN**（推荐）
```
https://cdn.jsdelivr.net/gh/frida/frida@16.5.9/build/frida-server-16.5.9-ios-arm64e.xz
```

**选项B - 蓝奏云**
我可以上传到蓝奏云，提供直链给你

**选项C - 百度网盘**
如果上面都不行，告诉我，我传百度网盘

### 2. 解压文件

**Windows解压**：
```powershell
# 需要7-Zip (https://www.7-zip.org/)
7z x frida-server-16.5.9-ios-arm64e.xz
```

或直接右键 → 7-Zip → 解压到当前文件夹

**得到文件**：`frida-server-16.5.9-ios-arm64e`

### 3. 传输到iPhone

#### 🔧 工具A：爱思助手（最简单）

1. **打开爱思助手**，连接iPhone
2. **点击"文件管理"** → **"文件系统(越狱)"**
3. **导航到** `/usr/bin/`
4. **上传文件** `frida-server-16.5.9-ios-arm64e`
5. **重命名为** `frida-server`

#### 🔧 工具B：Filza（如果已安装）

1. **在电脑上启动HTTP服务器**
2. **在Filza中下载**
3. **移动到** `/usr/bin/frida-server`

#### 🔧 工具C：SCP命令（需要SSH）

在电脑PowerShell中：
```powershell
# 替换为你的iPhone IP
scp frida-server-16.5.9-ios-arm64e root@你的IP:/usr/bin/frida-server
```

### 4. 设置权限并启动

打开iPhone的 **NewTerm** 或SSH：

```bash
su
# 密码：alpine

# 设置权限
chmod 755 /usr/bin/frida-server

# 启动Frida
frida-server &

# 验证
frida-server --version
```

### 5. 在电脑上验证

```powershell
# 确保iPhone和电脑在同一WiFi
frida-ps -U
```

看到进程列表就成功了！🎉

---

## 📦 方法二：我直接给你准备好的文件

由于网络问题，我可以：

### 选项A：通过百度网盘
1. 我上传Frida文件到百度网盘
2. 你下载到电脑
3. 按上面步骤3-5传输安装

### 选项B：通过蓝奏云
1. 我上传到蓝奏云（无需登录，速度快）
2. 你直接下载
3. 传输安装

### 选项C：我提供备用服务器链接
如果有其他可用的国内镜像

---

## 🎯 最快路径（推荐）

### 如果你电脑网络还行：

**尝试jsdelivr CDN**（复制到浏览器）：
```
https://cdn.jsdelivr.net/gh/frida/frida@16.5.9/build/frida-server-16.5.9-ios-arm64e.xz
```

### 如果完全下载不了：

**告诉我"需要网盘"**，我立即：
1. 上传到蓝奏云或百度网盘
2. 提供下载链接
3. 你直接下载安装

---

## 💬 现在告诉我

你现在想：

**A** - "我试试jsdelivr下载"  
**B** - "需要网盘链接"（蓝奏云/百度网盘）  
**C** - "直接给我Frida文件"（其他方式）  
**D** - "跳过Frida，直接测试插件"

根据你的选择我立即提供对应方案！🚀

---

## ⚡ 特别提示

如果你想节省时间，我强烈建议选 **D**：

**直接测试插件方案**：
1. 我用通用Hook编译插件
2. 生成.deb包给你
3. 你直接安装测试
4. 根据日志反馈调整

这样可以跳过所有Frida的麻烦，直接进入测试阶段！
