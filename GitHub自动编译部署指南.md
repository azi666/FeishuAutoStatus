# 🚀 GitHub自动编译部署指南

## 📋 步骤总览

1. ✅ 创建GitHub仓库
2. ✅ 推送代码
3. ✅ 自动编译
4. ✅ 下载.deb安装

---

## 第一步：创建GitHub仓库

### 1.1 在GitHub网站创建新仓库

1. 访问 https://github.com/new
2. 填写信息：
   - **Repository name**: `FeishuAutoStatus`
   - **Description**: 飞书定时自动切换状态插件
   - **Public** 或 **Private**（建议Private避免被发现）
   - ❌ 不要勾选 "Add a README file"
3. 点击 "Create repository"

### 1.2 记录仓库地址

创建后会看到类似地址：
```
https://github.com/你的用户名/FeishuAutoStatus.git
```

---

## 第二步：初始化Git并推送代码

### 2.1 在PowerShell中执行

```powershell
# 进入项目目录
cd D:\Users\2403050002\Desktop\py\优化\FeishuAutoStatus

# 初始化Git仓库
git init

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit: 飞书自动状态切换插件"

# 添加远程仓库（替换成你的仓库地址）
git remote add origin https://github.com/你的用户名/FeishuAutoStatus.git

# 推送到GitHub
git branch -M main
git push -u origin main
```

### 2.2 如果提示需要认证

**方法A：使用Personal Access Token（推荐）**

1. 访问 https://github.com/settings/tokens
2. 点击 "Generate new token (classic)"
3. 勾选 `repo` 权限
4. 生成后复制token（只显示一次！）
5. 推送时用token代替密码：
   ```
   Username: 你的GitHub用户名
   Password: ghp_xxxxxxxxxxxx（刚才的token）
   ```

**方法B：使用GitHub Desktop（更简单）**

1. 下载安装 GitHub Desktop
2. 登录GitHub账号
3. File -> Add Local Repository -> 选择项目目录
4. Publish repository

---

## 第三步：自动编译

### 3.1 触发编译

推送代码后，GitHub Actions会自动开始编译。

**查看编译进度：**
1. 访问 `https://github.com/你的用户名/FeishuAutoStatus/actions`
2. 点击最新的workflow运行
3. 等待编译完成（约3-5分钟）

### 3.2 编译成功标志

✅ 看到绿色的 ✓ Build iOS Tweak

### 3.3 如果编译失败

点击失败的步骤查看日志，常见问题：
- Theos安装失败：网络问题，重新运行
- 代码语法错误：检查Tweak.x

---

## 第四步：下载.deb文件

### 4.1 下载Artifacts

1. 在Actions页面，点击编译成功的workflow
2. 向下滚动到 "Artifacts"
3. 点击 `FeishuAutoStatus-deb` 下载
4. 解压zip文件得到.deb

### 4.2 传输到iPhone

**方法A：爱思助手**
1. 连接iPhone
2. 文件管理 -> 用户系统 -> Documents
3. 导入.deb文件

**方法B：SSH/SCP**
```powershell
scp FeishuAutoStatus.deb root@iPhone-IP:/tmp/
```

---

## 第五步：安装插件

### 5.1 使用Filza安装

1. 打开Filza
2. 导航到Documents（或/tmp）
3. 点击.deb文件
4. 点击"安装"
5. 重启SpringBoard

### 5.2 使用SSH安装

```bash
ssh root@iPhone-IP
dpkg -i /tmp/FeishuAutoStatus.deb
killall -9 SpringBoard
```

---

## 🔄 创建Release版本（可选）

### 为什么创建Release？

- ✅ 固定版本号
- ✅ 直接下载.deb（不需要解压）
- ✅ 更新日志记录

### 如何创建Release

**方法A：通过tag自动创建**

```powershell
cd FeishuAutoStatus

# 创建tag
git tag v1.0.0

# 推送tag
git push origin v1.0.0
```

推送后会自动编译并创建Release，.deb文件直接附在Release页面。

**方法B：手动创建**

1. 访问仓库页面
2. 点击右侧 "Releases"
3. "Draft a new release"
4. 填写tag: `v1.0.0`
5. 上传.deb文件
6. "Publish release"

---

## 📝 版本管理建议

### 版本号规则

- `v1.0.0` - 初始版本
- `v1.0.1` - 修复bug
- `v1.1.0` - 新功能
- `v2.0.0` - 重大更新

### 更新流程

1. 修改代码
2. 提交：`git commit -m "修复状态切换bug"`
3. 推送：`git push`
4. 创建新tag：`git tag v1.0.1 && git push origin v1.0.1`
5. 自动编译新版本

---

## 🛡️ 隐私保护

### 如果不想公开代码

1. 创建仓库时选择 **Private**
2. 只邀请需要的人

### 如果已经是Public想改Private

1. 仓库Settings
2. 滚动到底部 "Danger Zone"
3. "Change repository visibility" -> Private

---

## 🐛 常见问题

### Q1: git命令找不到

**安装Git：**
```powershell
winget install Git.Git
```

重启PowerShell后再试。

### Q2: 推送失败："Authentication failed"

使用Personal Access Token代替密码（见第二步2.2）。

### Q3: Actions编译失败

查看具体错误日志：
1. Actions页面
2. 点击失败的workflow
3. 点击失败的步骤
4. 查看红色错误信息

### Q4: 下载的是zip不是deb

Artifacts会自动打包成zip，解压后就是.deb文件。

或者使用Release方式，直接下载.deb。

---

## 📞 技术支持

遇到问题请提供：
1. 截图（Actions编译页面/错误信息）
2. 仓库地址（如果是private可以邀请我）
3. 具体操作步骤

---

## ✅ 快速命令速查

```powershell
# 初始化
cd FeishuAutoStatus
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/用户名/FeishuAutoStatus.git
git push -u origin main

# 更新代码
git add .
git commit -m "更新说明"
git push

# 创建版本
git tag v1.0.0
git push origin v1.0.0

# 查看状态
git status
git log --oneline
```

---

**准备好了吗？现在就开始第一步：创建GitHub仓库！**
