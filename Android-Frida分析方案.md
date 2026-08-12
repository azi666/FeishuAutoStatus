# 🤖 用Android Frida分析飞书状态管理类

## 为什么这个方案好？

安卓飞书和iOS飞书通常使用**相同的核心SDK**（跨平台）：
- Java/Kotlin类名大概率一致
- 方法签名基本相同
- 业务逻辑通用

分析出Android的类名后，可以直接映射到iOS！

---

## 📋 准备工作检查

### 1. 确认ADB连接
```powershell
adb devices
```
应该看到你的设备。

### 2. 安装Frida Server（Android端）

#### 下载Frida Server
根据你的手机架构（通常是arm64）：

```powershell
# 查看手机架构
adb shell getprop ro.product.cpu.abi
# 输出通常是：arm64-v8a
```

**下载地址**（选一个）：
```
https://github.com/frida/frida/releases/download/17.17.0/frida-server-17.17.0-android-arm64.xz
```

或CDN镜像：
```
https://cdn.jsdelivr.net/gh/frida/frida/releases/download/17.17.0/frida-server-17.17.0-android-arm64.xz
```

#### 安装到手机
```powershell
# 解压文件（Windows用7-Zip）
7z x frida-server-17.17.0-android-arm64.xz

# 推送到手机
adb push frida-server-17.17.0-android-arm64 /data/local/tmp/frida-server

# 设置权限
adb shell "chmod 755 /data/local/tmp/frida-server"

# 启动Frida
adb shell "/data/local/tmp/frida-server &"
```

### 3. 验证连接
```powershell
frida-ps -U
```

应该看到手机上运行的所有进程，包括飞书。

---

## 🔍 分析脚本

### 脚本1：查找状态管理相关类

创建文件：`find_status_classes.js`

```javascript
Java.perform(function() {
    console.log("[*] 开始扫描飞书状态管理类...");
    
    // 搜索关键词
    const keywords = [
        "Status", "CustomStatus", "UserStatus", 
        "PresenceStatus", "StatusManager", "StatusService",
        "WorkStatus", "OnlineStatus", "AvailabilityStatus"
    ];
    
    // 获取所有已加载的类
    Java.enumerateLoadedClasses({
        onMatch: function(className) {
            // 过滤飞书相关的类
            if (className.includes("com.ss.android.lark") || 
                className.includes("com.larksuite") ||
                className.includes("feishu")) {
                
                // 检查是否包含状态相关关键词
                for (let keyword of keywords) {
                    if (className.toLowerCase().includes(keyword.toLowerCase())) {
                        console.log("[+] 找到可能的状态类: " + className);
                        
                        try {
                            // 尝试获取类的方法
                            let clazz = Java.use(className);
                            let methods = clazz.class.getDeclaredMethods();
                            
                            console.log("    方法列表:");
                            methods.forEach(function(method) {
                                let methodName = method.toString();
                                if (methodName.includes("status") || 
                                    methodName.includes("Status") ||
                                    methodName.includes("setText") ||
                                    methodName.includes("setEmoji") ||
                                    methodName.includes("update")) {
                                    console.log("      - " + methodName);
                                }
                            });
                            console.log("");
                        } catch(e) {
                            console.log("    无法反射此类: " + e);
                        }
                    }
                }
            }
        },
        onComplete: function() {
            console.log("[*] 扫描完成！");
        }
    });
});
```

### 运行脚本
```powershell
# 获取飞书包名
adb shell pm list packages | findstr lark

# 通常是：com.ss.android.lark

# 启动飞书（如果没运行）
adb shell am start -n com.ss.android.lark/.main.app.MainActivity

# 运行Frida脚本
frida -U -n Lark -l find_status_classes.js
```

---

### 脚本2：Hook状态切换动作

创建文件：`hook_status_change.js`

```javascript
Java.perform(function() {
    console.log("[*] 开始Hook飞书状态切换...");
    
    // 方法1：Hook TextView.setText（通用）
    let TextView = Java.use("android.widget.TextView");
    TextView.setText.overload("java.lang.CharSequence").implementation = function(text) {
        if (text && text.toString().length > 0) {
            let stackTrace = Java.use("android.util.Log").getStackTraceString(
                Java.use("java.lang.Throwable").$new()
            );
            
            // 过滤状态相关的setText调用
            if (stackTrace.includes("status") || stackTrace.includes("Status")) {
                console.log("\n[TextView.setText] 检测到状态相关文本:");
                console.log("  文本: " + text);
                console.log("  调用栈:\n" + stackTrace);
            }
        }
        return this.setText(text);
    };
    
    // 方法2：Hook SharedPreferences（状态可能存储在这里）
    let SharedPreferencesImpl = Java.use("android.app.SharedPreferencesImpl$EditorImpl");
    SharedPreferencesImpl.putString.implementation = function(key, value) {
        if (key && (key.includes("status") || key.includes("Status"))) {
            console.log("\n[SharedPreferences.putString]");
            console.log("  Key: " + key);
            console.log("  Value: " + value);
            
            let stackTrace = Java.use("android.util.Log").getStackTraceString(
                Java.use("java.lang.Throwable").$new()
            );
            console.log("  调用栈:\n" + stackTrace);
        }
        return this.putString(key, value);
    };
    
    // 方法3：Hook网络请求（状态可能通过API更新）
    try {
        let OkHttpClient = Java.use("okhttp3.OkHttpClient");
        console.log("[*] 找到OkHttp，准备Hook网络请求...");
        
        let Request = Java.use("okhttp3.Request");
        let RequestBuilder = Java.use("okhttp3.Request$Builder");
        
        RequestBuilder.build.implementation = function() {
            let request = this.build();
            let url = request.url().toString();
            
            // 过滤状态相关API
            if (url.includes("status") || url.includes("presence") || url.includes("custom")) {
                console.log("\n[HTTP Request] 检测到状态相关请求:");
                console.log("  URL: " + url);
                console.log("  Method: " + request.method());
                
                try {
                    let body = request.body();
                    if (body) {
                        console.log("  Body: " + body.toString());
                    }
                } catch(e) {}
            }
            
            return request;
        };
    } catch(e) {
        console.log("[-] OkHttp Hook失败: " + e);
    }
    
    console.log("[*] Hook设置完成，现在手动切换飞书状态...");
});
```

### 运行脚本
```powershell
frida -U -n Lark -l hook_status_change.js
```

**运行后**：
1. 在手机上打开飞书
2. 点击头像 → 设置状态
3. 修改状态文本和emoji
4. 查看Frida输出的日志

---

### 脚本3：搜索状态相关字符串

创建文件：`search_status_strings.js`

```javascript
Java.perform(function() {
    console.log("[*] 搜索状态相关字符串常量...");
    
    Java.enumerateLoadedClasses({
        onMatch: function(className) {
            if (className.includes("com.ss.android.lark")) {
                try {
                    let clazz = Java.use(className);
                    let fields = clazz.class.getDeclaredFields();
                    
                    fields.forEach(function(field) {
                        let fieldName = field.getName();
                        
                        // 查找字符串常量
                        if (field.getType().getName() === "java.lang.String") {
                            try {
                                field.setAccessible(true);
                                let value = field.get(null); // 静态字段
                                
                                if (value && typeof value === 'string') {
                                    if (value.includes("status") || 
                                        value.includes("custom_status") ||
                                        value.includes("presence")) {
                                        console.log("[+] 找到字符串常量:");
                                        console.log("  类: " + className);
                                        console.log("  字段: " + fieldName);
                                        console.log("  值: " + value);
                                        console.log("");
                                    }
                                }
                            } catch(e) {}
                        }
                    });
                } catch(e) {}
            }
        },
        onComplete: function() {
            console.log("[*] 搜索完成！");
        }
    });
});
```

---

## 📊 预期结果

运行上述脚本后，你会得到：

### 1. 状态管理类名
例如：
```
com.ss.android.lark.profile.CustomStatusManager
com.ss.android.lark.user.StatusService
```

### 2. 关键方法
例如：
```java
setCustomStatus(String text, String emoji, long duration)
updateUserStatus(StatusModel status)
clearCustomStatus()
```

### 3. API端点
例如：
```
https://open.feishu.cn/open-apis/user/v1/custom_status
```

### 4. 数据模型
例如：
```javascript
{
    "status_text": "摸鱼中",
    "status_emoji": "🐟",
    "expire_time": 1234567890
}
```

---

## 🔄 映射到iOS

找到Android的类名后，iOS通常对应：

| Android | iOS |
|---------|-----|
| `com.ss.android.lark.CustomStatusManager` | `LKCustomStatusManager` 或 `CustomStatusManager` |
| `setCustomStatus(String, String, long)` | `setCustomStatus:emoji:duration:` |
| `updateUserStatus(StatusModel)` | `updateUserStatus:` |

---

## 💬 现在开始

### 第1步：确认环境
```powershell
# 检查ADB
adb devices

# 检查Frida
frida --version
```

### 第2步：安装Frida Server到手机
我会引导你完成

### 第3步：运行分析脚本
获取真实的类名和方法

### 第4步：更新iOS代码
根据分析结果修改Tweak.x

---

## 🆘 需要帮助

告诉我：

**A** - "开始装Frida Server"（我提供详细步骤）  
**B** - "Frida已经装好了"（直接运行脚本）  
**C** - "ADB有问题"（我帮你排查）  
**D** - "手机架构不确定"（我帮你查）

准备好了就告诉我，我们立即开始分析！🚀
