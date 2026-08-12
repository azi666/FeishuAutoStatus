# Frida Server 安装指南 - iPhone 14 Pro Max (iOS 16.4.1)

## 🎯 你的设备信息
- **设备**: iPhone 14 Pro Max
- **iOS版本**: 16.4.1
- **芯片**: A16 Bionic
- **需要版本**: frida-server arm64e

---

## ✅ 方法1：直接从Sileo安装（最推荐！）

这是最简单稳定的方法，不需要下载文件。

### 步骤：

1. **打开Sileo**（或Zebra/Installer）

2. **添加Frida官方源**
   - 点击"软件源"
   - 点击右上角"+"
   - 输入：`https://build.frida.re`
   - 点击"添加源"

3. **刷新源**
   - 等待刷新完成

4. **搜索并安装**
   - 搜索 "Frida"
   - 找到 "Frida" 包（不是Frida Tools）
   - 点击"安装"
   - 确认安装

5. **验证安装**
   - 打开NewTerm或SSH
   - 运行：`su` （密码默认是alpine）
   - 运行：`frida-server --version`
   - 应该显示版本号

6. **启动Frida Server**
   ```bash
   su
   frida-server &
   ```

完成！现在回到电脑继续。

---

## ✅ 方法2：手动下载安装（备用）

如果Sileo方法不行，使用这个：

### 下载地址：

由于GitHub连接问题，使用国内镜像：

**直接下载链接**（复制到浏览器）：
```
https://ghproxy.com/https://github.com/frida/frida/releases/download/17.17.0/frida-server-17.17.0-ios-arm64e.xz
```

或者使用这些镜像站：
- `https://mirror.ghproxy.com/`
- `https://gh.api.99988866.xyz/`

### 安装步骤：

1. **在电脑浏览器下载文件**
   - 下载后得到 `frida-server-17.17.0-ios-arm64e.xz`

2. **解压文件**
   - 使用7-Zip或WinRAR解压 `.xz` 文件
   - 得到 `frida-server-17.17.0-ios-arm64e`

3. **重命名**
   - 重命名为 `frida-server`

4. **传输到手机**
   
   **方式A：使用爱思助手**
   - 连接手机
   - 文件系统（越狱）→ `/var/root/`
   - 上传 `frida-server` 文件

   **方式B：使用SSH**
   ```powershell
   scp frida-server root@<手机IP>:/var/root/
   ```

   **方式C：使用Filza**
   - 通过iCloud/AirDrop传到手机
   - 用Filza移动到 `/var/root/`

5. **在手机上设置权限**
   
   打开NewTerm或SSH：
   ```bash
   su
   cd /var/root
   chmod +x frida-server
   chown root:wheel frida-server
   ```

6. **启动Frida Server**
   ```bash
   ./frida-server &
   ```

7. **验证**
   ```bash
   ps aux | grep frida
   # 应该能看到frida-server进程
   ```

---

## ✅ 方法3：从第三方源安装deb

### 添加这些源到Sileo：

1. **BigBoss源**（通常已有）
   ```
   http://apt.thebigboss.org/repofiles/cydia/
   ```

2. **Chariz源**
   ```
   https://repo.chariz.com/
   ```

然后搜索 "Frida" 安装。

---

## 🔧 验证安装成功

### 在手机上：
```bash
su
frida-server --version
# 或
./frida-server --version
```

### 在电脑上：
```powershell
$env:Path = "$env:LOCALAPPDATA\Packages\PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0\LocalCache\local-packages\Python313\Scripts;$env:Path"
frida-ps -U
```

看到进程列表就成功了！

---

## 🎯 下一步：分析飞书

安装成功后，立即运行：

```powershell
cd "D:\Users\2403050002\Desktop\py\优化\FeishuAutoStatus"
$env:Path = "$env:LOCALAPPDATA\Packages\PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0\LocalCache\local-packages\Python313\Scripts;$env:Path"
frida -U com.ss.iphone.lark -l frida_hook_status.js
```

然后在手机飞书中切换状态，**把输出发给我！**

---

## ⚠️ 常见问题

### Q: Sileo找不到Frida源？
A: 确认源地址正确：`https://build.frida.re`，刷新源后等待几分钟。

### Q: frida-server启动后立即退出？
A: 
```bash
# 查看错误信息
frida-server
# 可能需要安装依赖
apt install ldid
```

### Q: 电脑连接不上手机？
A: 
1. 确认USB连接正常
2. 确认手机已信任电脑
3. 重启frida-server
4. 重新插拔USB

---

## 📞 告诉我进度

完成后告诉我：
- ✅ 已安装（用的哪种方法）
- ✅ 能看到版本号
- ✅ 电脑能连上手机
- ✅ 准备分析飞书

或者告诉我卡在哪一步！
