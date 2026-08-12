Java.perform(function() {
    console.log("[*] 开始扫描飞书状态管理类...");
    console.log("[*] 正在枚举已加载的类，这可能需要几秒钟...\n");
    
    const keywords = [
        "Status", "CustomStatus", "UserStatus", 
        "PresenceStatus", "StatusManager", "StatusService",
        "WorkStatus", "OnlineStatus", "AvailabilityStatus",
        "Presence", "Profile"
    ];
    
    let foundClasses = [];
    
    Java.enumerateLoadedClasses({
        onMatch: function(className) {
            if (className.includes("com.ss.android.lark") || 
                className.includes("com.larksuite") ||
                className.includes("bytedance")) {
                
                for (let keyword of keywords) {
                    if (className.toLowerCase().includes(keyword.toLowerCase())) {
                        foundClasses.push(className);
                        console.log("[+] 找到可能的状态类: " + className);
                        
                        try {
                            let clazz = Java.use(className);
                            let methods = clazz.class.getDeclaredMethods();
                            
                            console.log("    关键方法:");
                            let methodCount = 0;
                            methods.forEach(function(method) {
                                let methodStr = method.toString();
                                if (methodStr.includes("status") || 
                                    methodStr.includes("Status") ||
                                    methodStr.includes("setText") ||
                                    methodStr.includes("setEmoji") ||
                                    methodStr.includes("emoji") ||
                                    methodStr.includes("update") ||
                                    methodStr.includes("set") ||
                                    methodStr.includes("get")) {
                                    console.log("      - " + methodStr);
                                    methodCount++;
                                }
                            });
                            
                            if (methodCount === 0) {
                                console.log("      (无明显状态相关方法)");
                            }
                            console.log("");
                        } catch(e) {
                            console.log("    无法反射此类: " + e.message);
                            console.log("");
                        }
                        break;
                    }
                }
            }
        },
        onComplete: function() {
            console.log("[*] 扫描完成！");
            console.log("[*] 共找到 " + foundClasses.length + " 个可能的状态相关类");
            console.log("\n[*] 建议：");
            console.log("  1. 在飞书中手动切换状态");
            console.log("  2. 运行 hook_status_change.js 脚本监控动态行为");
        }
    });
});
