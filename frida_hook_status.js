// Frida脚本 - 用于逆向分析飞书状态管理相关类和方法
// 使用方法: frida -U -f com.ss.iphone.lark -l frida_hook_status.js

console.log("[*] FeishuAutoStatus - 飞书状态管理逆向分析脚本");
console.log("[*] 正在注入到飞书进程...\n");

// 等待应用启动
setTimeout(function() {
    console.log("[*] 开始扫描状态相关类...\n");
    
    // 获取所有已加载的类
    var classes = ObjC.classes;
    var statusClasses = [];
    
    // 查找包含Status关键字的类
    for (var className in classes) {
        if (className.toLowerCase().indexOf('status') !== -1) {
            statusClasses.push(className);
        }
    }
    
    console.log("[+] 找到 " + statusClasses.length + " 个状态相关类:\n");
    statusClasses.forEach(function(cls) {
        console.log("    - " + cls);
    });
    
    console.log("\n[*] 尝试Hook常见状态管理方法...\n");
    
    // Hook候选类
    var candidateClasses = [
        "LKStatusManager",
        "LKUserStatusManager", 
        "StatusManager",
        "UserStatusController",
        "LKStatusViewController"
    ];
    
    candidateClasses.forEach(function(className) {
        try {
            var targetClass = ObjC.classes[className];
            if (targetClass) {
                console.log("[+] 找到类: " + className);
                
                // 获取所有实例方法
                var methods = targetClass.$ownMethods;
                console.log("    实例方法数量: " + methods.length);
                
                // 过滤状态相关方法
                var statusMethods = methods.filter(function(m) {
                    return m.toLowerCase().indexOf('status') !== -1 ||
                           m.toLowerCase().indexOf('update') !== -1 ||
                           m.toLowerCase().indexOf('change') !== -1 ||
                           m.toLowerCase().indexOf('set') !== -1;
                });
                
                console.log("    状态相关方法:");
                statusMethods.forEach(function(method) {
                    console.log("        - " + method);
                });
                
                // 尝试Hook setStatus类方法
                statusMethods.forEach(function(methodName) {
                    try {
                        var method = targetClass[methodName];
                        if (method) {
                            Interceptor.attach(method.implementation, {
                                onEnter: function(args) {
                                    console.log("\n[Hook] " + className + "." + methodName);
                                    console.log("    self: " + args[0]);
                                    if (args[2]) {
                                        console.log("    arg1: " + ObjC.Object(args[2]).toString());
                                    }
                                    if (args[3]) {
                                        console.log("    arg2: " + ObjC.Object(args[3]).toString());
                                    }
                                },
                                onLeave: function(retval) {
                                    if (retval) {
                                        console.log("    返回值: " + retval);
                                    }
                                }
                            });
                            console.log("    ✓ 已Hook: " + methodName);
                        }
                    } catch(e) {
                        // 忽略Hook失败的方法
                    }
                });
                
                console.log("");
            }
        } catch(e) {
            // 类不存在，继续下一个
        }
    });
    
    // Hook所有NSNotificationCenter通知，监听状态变化
    console.log("[*] Hook NSNotificationCenter 监听状态通知...\n");
    
    var NSNotificationCenter = ObjC.classes.NSNotificationCenter;
    var postNotification = NSNotificationCenter['- postNotificationName:object:userInfo:'];
    
    Interceptor.attach(postNotification.implementation, {
        onEnter: function(args) {
            var notificationName = ObjC.Object(args[2]).toString();
            if (notificationName.toLowerCase().indexOf('status') !== -1) {
                console.log("[通知] " + notificationName);
                if (args[3]) {
                    console.log("    object: " + ObjC.Object(args[3]).toString());
                }
                if (args[4]) {
                    console.log("    userInfo: " + ObjC.Object(args[4]).toString());
                }
            }
        }
    });
    
    console.log("\n[✓] Hook完成，等待状态变化事件...");
    console.log("[提示] 手动在飞书中修改状态以触发Hook\n");
    
}, 3000);
