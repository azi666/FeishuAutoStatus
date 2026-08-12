/*
 * FeishuAutoStatus - 飞书定时自动切换状态插件
 * 
 * 功能：
 * 1. 自动定时切换飞书在线状态
 * 2. 支持自定义状态列表
 * 3. 支持自定义切换时间间隔
 * 4. 后台持续运行
 * 
 * 技术：
 * - 基于Android逆向分析的结果
 * - Android包路径：com.ss.android.lark.mine.impl.custom_status
 * - Android Activity：UserCustomStatusActivity
 * - iOS映射类名：LKCustomStatusManager / CustomStatusManager
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// 偏好设置键
#define kPreferencesPath @"/var/mobile/Library/Preferences/com.yourname.feishuautostatus.plist"
#define kEnabledKey @"enabled"
#define kIntervalKey @"interval"
#define kStatusListKey @"statusList"
#define kWorkTimeEnabledKey @"workTimeEnabled"
#define kWorkStartHourKey @"workStartHour"
#define kWorkStartMinuteKey @"workStartMinute"
#define kWorkEndHourKey @"workEndHour"
#define kWorkEndMinuteKey @"workEndMinute"
#define kOffWorkStatusKey @"offWorkStatus"

// 默认配置
#define kDefaultInterval 3600 // 默认1小时切换一次
#define kDefaultEnabled YES
#define kDefaultWorkTimeEnabled YES
#define kDefaultWorkStartHour 8
#define kDefaultWorkStartMinute 0
#define kDefaultWorkEndHour 17
#define kDefaultWorkEndMinute 30

static NSTimer *statusTimer = nil;
static NSMutableDictionary *preferences = nil;
static NSArray *statusList = nil;
static NSInteger currentStatusIndex = 0;

// 检查是否在工作时间
static BOOL isWorkTime() {
    BOOL workTimeEnabled = [preferences[kWorkTimeEnabledKey] boolValue];
    if (!workTimeEnabled) {
        return YES; // 未启用工作时间功能，视为始终在工作时间
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitWeekday) fromDate:now];
    
    NSInteger weekday = components.weekday;
    // 周六=7, 周日=1
    if (weekday == 1 || weekday == 7) {
        NSLog(@"[FeishuAutoStatus] 当前是周末，非工作时间");
        return NO;
    }
    
    NSInteger currentHour = components.hour;
    NSInteger currentMinute = components.minute;
    NSInteger currentTotalMinutes = currentHour * 60 + currentMinute;
    
    NSInteger workStartHour = [preferences[kWorkStartHourKey] integerValue];
    NSInteger workStartMinute = [preferences[kWorkStartMinuteKey] integerValue];
    NSInteger workStartTotalMinutes = workStartHour * 60 + workStartMinute;
    
    NSInteger workEndHour = [preferences[kWorkEndHourKey] integerValue];
    NSInteger workEndMinute = [preferences[kWorkEndMinuteKey] integerValue];
    NSInteger workEndTotalMinutes = workEndHour * 60 + workEndMinute;
    
    BOOL inWorkTime = (currentTotalMinutes >= workStartTotalMinutes && currentTotalMinutes < workEndTotalMinutes);
    
    NSLog(@"[FeishuAutoStatus] 当前时间: %02ld:%02ld, 工作时间: %02ld:%02ld-%02ld:%02ld, %@",
          (long)currentHour, (long)currentMinute,
          (long)workStartHour, (long)workStartMinute,
          (long)workEndHour, (long)workEndMinute,
          inWorkTime ? @"工作时间" : @"休息时间");
    
    return inWorkTime;
}

// 加载偏好设置
static void loadPreferences() {
    preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:kPreferencesPath];
    if (!preferences) {
        preferences = [@{
            kEnabledKey: @(kDefaultEnabled),
            kIntervalKey: @(kDefaultInterval),
            kWorkTimeEnabledKey: @(kDefaultWorkTimeEnabled),
            kWorkStartHourKey: @(kDefaultWorkStartHour),
            kWorkStartMinuteKey: @(kDefaultWorkStartMinute),
            kWorkEndHourKey: @(kDefaultWorkEndHour),
            kWorkEndMinuteKey: @(kDefaultWorkEndMinute),
            kOffWorkStatusKey: @"休息中 🌙",
            kStatusListKey: @[
                @{@"text": @"在线", @"emoji": @"✅"},
                @{@"text": @"忙碌", @"emoji": @"🔥"},
                @{@"text": @"会议中", @"emoji": @"📞"},
                @{@"text": @"请勿打扰", @"emoji": @"🚫"}
            ]
        } mutableCopy];
    }
    
    statusList = preferences[kStatusListKey];
    if (!statusList || statusList.count == 0) {
        statusList = @[
            @{@"text": @"在线", @"emoji": @"✅"},
            @{@"text": @"忙碌", @"emoji": @"🔥"}
        ];
    }
}

// 保存偏好设置
static void savePreferences() {
    if (preferences) {
        [preferences writeToFile:kPreferencesPath atomically:YES];
    }
}

// 切换到下一个状态
static void switchToNextStatus() {
    // 检查是否在工作时间
    if (!isWorkTime()) {
        // 非工作时间，设置为休息状态
        NSString *offWorkStatus = preferences[kOffWorkStatusKey];
        if (!offWorkStatus || offWorkStatus.length == 0) {
            offWorkStatus = @"休息中 🌙";
        }
        
        NSDictionary *status = @{
            @"text": offWorkStatus,
            @"emoji": @"🌙"
        };
        
        NSLog(@"[FeishuAutoStatus] 非工作时间，设置为: %@", offWorkStatus);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FeishuAutoStatusChanged"
                                                            object:nil
                                                          userInfo:status];
        return;
    }
    
    // 工作时间，正常切换状态
    if (!statusList || statusList.count == 0) return;
    
    currentStatusIndex = (currentStatusIndex + 1) % statusList.count;
    NSDictionary *status = statusList[currentStatusIndex];
    
    NSString *statusText = status[@"text"];
    NSString *emoji = status[@"emoji"];
    
    NSLog(@"[FeishuAutoStatus] 切换状态到: %@ %@", emoji, statusText);
    
    // 发送状态更新通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FeishuAutoStatusChanged"
                                                        object:nil
                                                      userInfo:status];
}

// 启动定时器
static void startTimer() {
    if (statusTimer) {
        [statusTimer invalidate];
        statusTimer = nil;
    }
    
    loadPreferences();
    
    BOOL enabled = [preferences[kEnabledKey] boolValue];
    if (!enabled) {
        NSLog(@"[FeishuAutoStatus] 插件未启用");
        return;
    }
    
    NSTimeInterval interval = [preferences[kIntervalKey] doubleValue];
    if (interval < 60) interval = kDefaultInterval;
    
    NSLog(@"[FeishuAutoStatus] 启动定时器，间隔: %.0f秒", interval);
    
    statusTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                   target:[NSObject class]
                                                 selector:@selector(timerFired:)
                                                 userInfo:nil
                                                  repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:statusTimer forMode:NSRunLoopCommonModes];
}

// 停止定时器
static void stopTimer() {
    if (statusTimer) {
        [statusTimer invalidate];
        statusTimer = nil;
        NSLog(@"[FeishuAutoStatus] 定时器已停止");
    }
}

// NSTimer回调方法
@interface NSObject (FeishuAutoStatus)
+ (void)timerFired:(NSTimer *)timer;
@end

@implementation NSObject (FeishuAutoStatus)
+ (void)timerFired:(NSTimer *)timer {
    switchToNextStatus();
}
@end

// 运行时查找真实的类名
static Class findStatusManagerClass() {
    // 基于Android分析，iOS可能的类名
    NSArray *possibleClasses = @[
        @"LKCustomStatusManager",
        @"CustomStatusManager", 
        @"LKUserCustomStatusManager",
        @"UserCustomStatusManager",
        @"LKStatusManager",
        @"StatusManager"
    ];
    
    for (NSString *className in possibleClasses) {
        Class cls = NSClassFromString(className);
        if (cls) {
            NSLog(@"[FeishuAutoStatus] ✅ 找到状态管理类: %@", className);
            return cls;
        }
    }
    
    NSLog(@"[FeishuAutoStatus] ⚠️ 未找到已知的状态管理类，尝试运行时扫描...");
    
    // 扫描所有已加载的类
    unsigned int classCount = 0;
    Class *classes = objc_copyClassList(&classCount);
    
    for (unsigned int i = 0; i < classCount; i++) {
        const char *className = class_getName(classes[i]);
        NSString *classNameStr = [NSString stringWithUTF8String:className];
        
        // 查找包含Status的类
        if ([classNameStr containsString:@"Status"] && 
            ([classNameStr containsString:@"Manager"] || [classNameStr containsString:@"Service"])) {
            NSLog(@"[FeishuAutoStatus] 🔍 发现可能的状态类: %@", classNameStr);
        }
    }
    
    free(classes);
    return nil;
}

// 动态调用设置状态方法
static void setCustomStatus(NSString *text, NSString *emoji) {
    Class statusClass = findStatusManagerClass();
    if (!statusClass) {
        NSLog(@"[FeishuAutoStatus] ❌ 无法找到状态管理类");
        return;
    }
    
    // 尝试获取单例
    id manager = nil;
    SEL sharedSelector = NSSelectorFromString(@"sharedInstance");
    if ([statusClass respondsToSelector:sharedSelector]) {
        manager = [statusClass performSelector:sharedSelector];
    } else {
        sharedSelector = NSSelectorFromString(@"shared");
        if ([statusClass respondsToSelector:sharedSelector]) {
            manager = [statusClass performSelector:sharedSelector];
        }
    }
    
    if (!manager) {
        NSLog(@"[FeishuAutoStatus] ⚠️ 无法获取状态管理器单例");
        return;
    }
    
    // 尝试不同的方法签名
    NSArray *methodNames = @[
        @"setCustomStatus:emoji:",
        @"setCustomStatusText:emoji:",
        @"updateCustomStatus:emoji:",
        @"setStatus:emoji:",
        @"updateStatus:emoji:"
    ];
    
    for (NSString *methodName in methodNames) {
        SEL selector = NSSelectorFromString(methodName);
        if ([manager respondsToSelector:selector]) {
            NSLog(@"[FeishuAutoStatus] ✅ 调用方法: %@ text=%@ emoji=%@", methodName, text, emoji);
            
            NSMethodSignature *signature = [manager methodSignatureForSelector:selector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:manager];
            [invocation setSelector:selector];
            [invocation setArgument:&text atIndex:2];
            [invocation setArgument:&emoji atIndex:3];
            [invocation invoke];
            return;
        }
    }
    
    // 尝试单参数方法（传入字典或对象）
    NSArray *singleParamMethods = @[
        @"setCustomStatus:",
        @"updateCustomStatus:",
        @"setStatus:",
        @"updateStatus:"
    ];
    
    NSDictionary *statusDict = @{
        @"text": text ?: @"",
        @"emoji": emoji ?: @"",
        @"statusText": text ?: @"",
        @"statusEmoji": emoji ?: @""
    };
    
    for (NSString *methodName in singleParamMethods) {
        SEL selector = NSSelectorFromString(methodName);
        if ([manager respondsToSelector:selector]) {
            NSLog(@"[FeishuAutoStatus] ✅ 调用方法: %@ dict=%@", methodName, statusDict);
            [manager performSelector:selector withObject:statusDict];
            return;
        }
    }
    
    NSLog(@"[FeishuAutoStatus] ❌ 未找到可用的设置状态方法");
}

// 通用Hook：捕获所有可能的状态管理类
%hook NSObject

%new
- (void)autoStatusChanged:(NSNotification *)notification {
    NSDictionary *status = notification.userInfo;
    NSString *statusText = status[@"text"];
    NSString *emoji = status[@"emoji"];
    
    NSLog(@"[FeishuAutoStatus] 📢 收到状态变化通知: %@ %@", emoji, statusText);
    
    setCustomStatus(statusText, emoji);
}

%end

// Hook UIApplication以检测飞书启动
%hook UIApplication

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    
    NSLog(@"[FeishuAutoStatus] 🚀 飞书应用启动完成");
    NSLog(@"[FeishuAutoStatus] 📦 Bundle ID: %@", [[NSBundle mainBundle] bundleIdentifier]);
    
    // 延迟启动定时器和类扫描
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"[FeishuAutoStatus] 🔍 开始扫描状态管理类...");
        findStatusManagerClass();
        
        NSLog(@"[FeishuAutoStatus] ⏰ 启动定时器...");
        startTimer();
    });
    
    return result;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    %orig;
    NSLog(@"[FeishuAutoStatus] 📱 应用进入前台");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        startTimer();
    });
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    %orig;
    NSLog(@"[FeishuAutoStatus] 🌙 应用进入后台，保持定时器运行");
}

%end

// Hook所有可能的ViewController来监控状态界面
%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    
    NSString *className = NSStringFromClass([self class]);
    
    // 检测是否是状态相关的ViewController
    if ([className containsString:@"Status"] || 
        [className containsString:@"CustomStatus"] ||
        [className containsString:@"UserStatus"]) {
        NSLog(@"[FeishuAutoStatus] 📺 状态相关界面出现: %@", className);
        NSLog(@"[FeishuAutoStatus] 🔍 开始分析此界面的类结构...");
        
        // 列出所有方法
        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList([self class], &methodCount);
        
        NSLog(@"[FeishuAutoStatus] 📋 %@ 的方法列表:", className);
        for (unsigned int i = 0; i < methodCount && i < 20; i++) {
            SEL selector = method_getName(methods[i]);
            NSString *methodName = NSStringFromSelector(selector);
            if ([methodName containsString:@"status"] || 
                [methodName containsString:@"Status"] ||
                [methodName containsString:@"set"] ||
                [methodName containsString:@"update"]) {
                NSLog(@"[FeishuAutoStatus]   - %@", methodName);
            }
        }
        free(methods);
    }
}

%end

// 构造函数
%ctor {
    @autoreleasepool {
        NSLog(@"[FeishuAutoStatus] 插件已加载");
        loadPreferences();
        
        // 监听偏好设置变化
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,
            (CFNotificationCallback)startTimer,
            CFSTR("com.yourname.feishuautostatus/ReloadPrefs"),
            NULL,
            CFNotificationSuspensionBehaviorCoalesce
        );
    }
}

// 析构函数
%dtor {
    stopTimer();
}
