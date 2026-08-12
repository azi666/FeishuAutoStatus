Java.perform(function() {
    console.log("[*] 开始Hook飞书状态切换...\n");
    
    // Hook 1: TextView.setText - 捕获UI文本变化
    try {
        let TextView = Java.use("android.widget.TextView");
        TextView.setText.overload("java.lang.CharSequence").implementation = function(text) {
            if (text && text.toString().length > 0 && text.toString().length < 100) {
                let textStr = text.toString();
                
                // 过滤可能的状态文本
                if (textStr.includes("状态") || textStr.includes("忙碌") || 
                    textStr.includes("摸鱼") || textStr.includes("会议") ||
                    /[\u{1F300}-\u{1F9FF}]/u.test(textStr)) { // emoji检测
                    
                    let stackTrace = Java.use("android.util.Log").getStackTraceString(
                        Java.use("java.lang.Throwable").$new()
                    );
                    
                    if (stackTrace.includes("lark") || stackTrace.includes("feishu")) {
                        console.log("\n[TextView.setText] 检测到可能的状态文本:");
                        console.log("  文本: " + textStr);
                        
                        // 提取关键调用栈（只显示飞书相关）
                        let lines = stackTrace.split('\n');
                        console.log("  关键调用栈:");
                        for (let i = 0; i < Math.min(lines.length, 15); i++) {
                            if (lines[i].includes("com.ss.android.lark")) {
                                console.log("    " + lines[i].trim());
                            }
                        }
                    }
                }
            }
            return this.setText(text);
        };
        console.log("[+] TextView.setText Hook 成功");
    } catch(e) {
        console.log("[-] TextView Hook 失败: " + e.message);
    }
    
    // Hook 2: SharedPreferences - 捕获本地存储
    try {
        let SharedPreferencesImpl = Java.use("android.app.SharedPreferencesImpl$EditorImpl");
        SharedPreferencesImpl.putString.implementation = function(key, value) {
            if (key && (key.includes("status") || key.includes("Status") || 
                       key.includes("custom") || key.includes("presence"))) {
                console.log("\n[SharedPreferences.putString] 状态相关数据:");
                console.log("  Key: " + key);
                console.log("  Value: " + value);
            }
            return this.putString(key, value);
        };
        console.log("[+] SharedPreferences Hook 成功");
    } catch(e) {
        console.log("[-] SharedPreferences Hook 失败: " + e.message);
    }
    
    // Hook 3: OkHttp - 捕获网络请求
    try {
        let RequestBuilder = Java.use("okhttp3.Request$Builder");
        RequestBuilder.build.implementation = function() {
            let request = this.build();
            let url = request.url().toString();
            
            if (url.includes("status") || url.includes("presence") || 
                url.includes("custom") || url.includes("profile")) {
                console.log("\n[HTTP Request] 状态相关API:");
                console.log("  URL: " + url);
                console.log("  Method: " + request.method());
                
                try {
                    let body = request.body();
                    if (body) {
                        let buffer = Java.use("okio.Buffer").$new();
                        body.writeTo(buffer);
                        console.log("  Body: " + buffer.readUtf8());
                    }
                } catch(e) {
                    console.log("  Body: (无法读取)");
                }
            }
            
            return request;
        };
        console.log("[+] OkHttp Hook 成功");
    } catch(e) {
        console.log("[-] OkHttp Hook 失败: " + e.message);
    }
    
    // Hook 4: 尝试Hook可能的状态管理类
    setTimeout(function() {
        console.log("\n[*] 尝试Hook常见的状态管理类...");
        
        let possibleClasses = [
            "com.ss.android.lark.profile.CustomStatusManager",
            "com.ss.android.lark.user.StatusManager",
            "com.ss.android.lark.status.StatusService",
            "com.ss.android.lark.presence.PresenceManager"
        ];
        
        possibleClasses.forEach(function(className) {
            try {
                let clazz = Java.use(className);
                console.log("[+] 找到类: " + className);
                
                let methods = clazz.class.getDeclaredMethods();
                methods.forEach(function(method) {
                    let methodName = method.getName();
                    if (methodName.includes("set") || methodName.includes("update")) {
                        console.log("    尝试Hook方法: " + methodName);
                        // 这里可以进一步Hook具体方法
                    }
                });
            } catch(e) {
                // 类不存在，跳过
            }
        });
    }, 2000);
    
    console.log("\n[*] Hook设置完成！");
    console.log("[*] 现在请在手机上操作：");
    console.log("  1. 打开飞书");
    console.log("  2. 点击头像或个人资料");
    console.log("  3. 设置/修改自定义状态");
    console.log("  4. 观察这里的输出\n");
});
