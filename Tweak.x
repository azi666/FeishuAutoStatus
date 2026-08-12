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
#import <objc/message.h>
#import "SettingsViewController.h"

// 日志宏
#define FSLog(fmt, ...) do { \
    NSString *log = [NSString stringWithFormat:fmt, ##__VA_ARGS__]; \
    NSLog(@"[FeishuAutoStatus] %@", log); \
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FeishuAutoStatusLog" object:log]; \
} while(0)

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

// 发现的关键信息
static NSMutableDictionary *discoveredInfo = nil;
static Class discoveredStatusClass = nil;
static id discoveredStatusManager = nil;

// 函数前置声明
static void loadPreferences(void);
static void switchToNextStatus(void);
static void startTimer(void);
static void stopTimer(void);
static void updateStatusManually(void);

// 检查是否在工作时间
static BOOL isWorkTime() {
    BOOL workTimeEnabled = [preferences[kWorkTimeEnabledKey] boolValue];
    if (!workTimeEnabled) {
        return YES; // 未启用工作时间功能，视为始终在工作时间
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSTimeZone *chinaTimeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    [calendar setTimeZone:chinaTimeZone];
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
    
    FSLog(@"当前时间: %02ld:%02ld, 工作时间: %02ld:%02ld-%02ld:%02ld, %@",
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
        
        FSLog(@"非工作时间，设置为: %@", offWorkStatus);
        
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
    
    FSLog(@"切换状态到: %@ %@", emoji, statusText);
    
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
    if (discoveredStatusClass) {
        return discoveredStatusClass;
    }
    
    // 基于Android分析，iOS可能的类名
    NSArray *possibleClasses = @[
        @"LKCustomStatusManager",
        @"CustomStatusManager", 
        @"LKUserCustomStatusManager",
        @"UserCustomStatusManager",
        @"LKStatusManager",
        @"StatusManager",
        @"TTKCustomStatusManager",
        @"AWECustomStatusManager"
    ];
    
    for (NSString *className in possibleClasses) {
        Class cls = NSClassFromString(className);
        if (cls) {
            FSLog(@"✅ 找到状态管理类: %@", className);
            discoveredStatusClass = cls;
            
            if (!discoveredInfo) discoveredInfo = [NSMutableDictionary dictionary];
            discoveredInfo[@"statusManagerClass"] = className;
            
            return cls;
        }
    }
    
    FSLog(@"⚠️ 未找到已知的状态管理类，开始深度扫描...");
    
    // 扫描所有已加载的类
    unsigned int classCount = 0;
    Class *classes = objc_copyClassList(&classCount);
    
    NSMutableArray *candidates = [NSMutableArray array];
    
    for (unsigned int i = 0; i < classCount; i++) {
        const char *className = class_getName(classes[i]);
        NSString *classNameStr = [NSString stringWithUTF8String:className];
        
        // 查找包含Status的类
        if ([classNameStr containsString:@"Status"] && 
            ([classNameStr containsString:@"Manager"] || 
             [classNameStr containsString:@"Service"] ||
             [classNameStr containsString:@"Controller"])) {
            
            [candidates addObject:classNameStr];
            FSLog(@"🔍 发现候选类: %@", classNameStr);
            
            // 分析类的方法
            Class cls = classes[i];
            unsigned int methodCount = 0;
            Method *methods = class_copyMethodList(cls, &methodCount);
            
            for (unsigned int j = 0; j < methodCount; j++) {
                SEL selector = method_getName(methods[j]);
                NSString *methodName = NSStringFromSelector(selector);
                
                // 查找设置状态相关的方法
                if ([methodName containsString:@"setStatus"] || 
                    [methodName containsString:@"updateStatus"] ||
                    [methodName containsString:@"setCustom"] ||
                    [methodName containsString:@"updateCustom"]) {
                    FSLog(@"  📌 发现关键方法: %@", methodName);
                    
                    if (!discoveredInfo) discoveredInfo = [NSMutableDictionary dictionary];
                    if (!discoveredInfo[@"methods"]) discoveredInfo[@"methods"] = [NSMutableArray array];
                    [discoveredInfo[@"methods"] addObject:@{
                        @"class": classNameStr,
                        @"method": methodName
                    }];
                    
                    // 找到可能的类，记录下来
                    if (!discoveredStatusClass) {
                        discoveredStatusClass = cls;
                        discoveredInfo[@"statusManagerClass"] = classNameStr;
                        FSLog(@"✅ 自动选择类: %@", classNameStr);
                    }
                }
            }
            free(methods);
        }
    }
    
    free(classes);
    
    if (candidates.count > 0) {
        discoveredInfo[@"allCandidates"] = candidates;
        FSLog(@"📋 共发现 %lu 个候选类", (unsigned long)candidates.count);
    }
    
    return discoveredStatusClass;
}

// 动态调用设置状态方法
static void setCustomStatus(NSString *text, NSString *emoji) {
    Class statusClass = findStatusManagerClass();
    if (!statusClass) {
        FSLog(@"❌ 无法找到状态管理类");
        return;
    }
    
    // 尝试获取单例
    id manager = discoveredStatusManager;
    if (!manager) {
        NSArray *singletonSelectors = @[@"sharedInstance", @"shared", @"sharedManager", @"defaultManager"];
        
        for (NSString *selectorName in singletonSelectors) {
            SEL selector = NSSelectorFromString(selectorName);
            if ([statusClass respondsToSelector:selector]) {
                manager = ((id (*)(id, SEL))objc_msgSend)(statusClass, selector);
                if (manager) {
                    discoveredStatusManager = manager;
                    FSLog(@"✅ 获取单例成功: [%@ %@]", NSStringFromClass(statusClass), selectorName);
                    
                    if (!discoveredInfo) discoveredInfo = [NSMutableDictionary dictionary];
                    discoveredInfo[@"singletonMethod"] = selectorName;
                    break;
                }
            }
        }
    }
    
    if (!manager) {
        FSLog(@"⚠️ 无法获取状态管理器单例，尝试直接调用类方法");
        manager = statusClass;
    }
    
    // 尝试不同的方法签名
    NSArray *twoParamMethods = @[
        @"setCustomStatus:emoji:",
        @"setCustomStatusText:emoji:",
        @"updateCustomStatus:emoji:",
        @"setStatus:emoji:",
        @"updateStatus:emoji:",
        @"setCustomStatusWithText:emoji:",
        @"setStatusText:emoji:"
    ];
    
    for (NSString *methodName in twoParamMethods) {
        SEL selector = NSSelectorFromString(methodName);
        if ([manager respondsToSelector:selector]) {
            FSLog(@"✅ 调用方法: %@ text=%@ emoji=%@", methodName, text, emoji);
            
            if (!discoveredInfo) discoveredInfo = [NSMutableDictionary dictionary];
            discoveredInfo[@"workingMethod"] = methodName;
            discoveredInfo[@"lastStatus"] = @{@"text": text, @"emoji": emoji};
            
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
        @"updateStatus:",
        @"applyStatus:",
        @"setCustomStatusWithInfo:"
    ];
    
    NSArray *dictFormats = @[
        @{@"text": text ?: @"", @"emoji": emoji ?: @""},
        @{@"statusText": text ?: @"", @"statusEmoji": emoji ?: @""},
        @{@"content": text ?: @"", @"icon": emoji ?: @""},
        @{@"title": text ?: @"", @"emoji": emoji ?: @""}
    ];
    
    for (NSString *methodName in singleParamMethods) {
        SEL selector = NSSelectorFromString(methodName);
        if ([manager respondsToSelector:selector]) {
            for (NSDictionary *statusDict in dictFormats) {
                FSLog(@"✅ 尝试方法: %@ dict=%@", methodName, statusDict);
                
                if (!discoveredInfo) discoveredInfo = [NSMutableDictionary dictionary];
                discoveredInfo[@"workingMethod"] = methodName;
                discoveredInfo[@"dictFormat"] = statusDict;
                
                @try {
                    ((void (*)(id, SEL, id))objc_msgSend)(manager, selector, statusDict);
                    FSLog(@"✅ 调用成功！");
                    return;
                } @catch (NSException *e) {
                    FSLog(@"⚠️ 调用失败: %@", e.reason);
                }
            }
        }
    }
    
    FSLog(@"❌ 未找到可用的设置状态方法");
    FSLog(@"📊 已发现的信息: %@", discoveredInfo);
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
    
    FSLog(@"🚀 飞书应用启动完成");
    FSLog(@"📦 Bundle ID: %@", [[NSBundle mainBundle] bundleIdentifier]);
    
    // 延迟启动定时器和类扫描
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        FSLog(@"🔍 开始扫描状态管理类...");
        findStatusManagerClass();
        
        FSLog(@"⏰ 启动定时器...");
        startTimer();
    });
    
    return result;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    %orig;
    FSLog(@"📱 应用进入前台");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        startTimer();
    });
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    %orig;
    FSLog(@"🌙 应用进入后台，保持定时器运行");
}

%end

// Hook所有可能的ViewController来监控状态界面并注入设置入口
%hook UIViewController

- (void)viewDidLoad {
    %orig;
    
    NSString *className = NSStringFromClass([self class]);
    
    // 在飞书设置页面添加入口
    if ([className containsString:@"Setting"] || 
        [className containsString:@"Mine"] ||
        [className containsString:@"Profile"] ||
        [className containsString:@"Account"]) {
        
        FSLog(@"📺 发现设置相关页面: %@", className);
        
        // 延迟添加按钮，确保导航栏已准备好
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self addAutoStatusSettingsEntry];
        });
    }
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    
    NSString *className = NSStringFromClass([self class]);
    
    // 为所有页面添加摇一摇手势来打开设置
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FSLog(@"🎯 已启用摇一摇手势：在飞书任意界面摇动手机即可打开自动状态设置");
    });
    
    // 检测是否是状态相关的ViewController
    if ([className containsString:@"Status"] || 
        [className containsString:@"CustomStatus"] ||
        [className containsString:@"UserStatus"]) {
        FSLog(@"📺 状态相关界面出现: %@", className);
        FSLog(@"🔍 开始分析此界面的类结构...");
        
        if (!discoveredInfo) discoveredInfo = [NSMutableDictionary dictionary];
        if (!discoveredInfo[@"viewControllers"]) discoveredInfo[@"viewControllers"] = [NSMutableArray array];
        [discoveredInfo[@"viewControllers"] addObject:className];
        
        // 列出所有方法
        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList([self class], &methodCount);
        
        NSMutableArray *statusMethods = [NSMutableArray array];
        for (unsigned int i = 0; i < methodCount && i < 30; i++) {
            SEL selector = method_getName(methods[i]);
            NSString *methodName = NSStringFromSelector(selector);
            if ([methodName containsString:@"status"] || 
                [methodName containsString:@"Status"] ||
                [methodName containsString:@"set"] ||
                [methodName containsString:@"update"]) {
                [statusMethods addObject:methodName];
                FSLog(@"  - %@", methodName);
            }
        }
        free(methods);
        
        if (statusMethods.count > 0) {
            if (!discoveredInfo[@"vcMethods"]) discoveredInfo[@"vcMethods"] = [NSMutableDictionary dictionary];
            discoveredInfo[@"vcMethods"][className] = statusMethods;
        }
    }
}

// 添加摇一摇手势支持
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    %orig;
    
    if (motion == UIEventSubtypeMotionShake) {
        FSLog(@"📳 检测到摇一摇手势，打开自动状态设置");
        [self openAutoStatusSettings];
    }
}

%new
- (void)addAutoStatusSettingsEntry {
    // 尝试在导航栏添加设置按钮
    if (self.navigationItem) {
        UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] 
            initWithTitle:@"⚙️ 自动状态" 
            style:UIBarButtonItemStylePlain 
            target:self 
            action:@selector(openAutoStatusSettings)];
        
        if (self.navigationItem.rightBarButtonItems) {
            NSMutableArray *items = [self.navigationItem.rightBarButtonItems mutableCopy];
            [items addObject:settingsButton];
            self.navigationItem.rightBarButtonItems = items;
        } else {
            self.navigationItem.rightBarButtonItem = settingsButton;
        }
        
        FSLog(@"✅ 已添加设置入口按钮到: %@", NSStringFromClass([self class]));
    }
}

%new
- (void)openAutoStatusSettings {
    FSLog(@"🎯 打开自动状态设置界面");
    
    FSAutoStatusSettingsViewController *settingsVC = [[FSAutoStatusSettingsViewController alloc] init];
    
    // 传递已发现的信息
    if (discoveredInfo) {
        [settingsVC appendLog:[NSString stringWithFormat:@"[发现] 已找到的信息: %@", discoveredInfo]];
    }
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:nav animated:YES completion:^{
        FSLog(@"✅ 设置界面已打开");
    }];
}

%end

// 构造函数
%ctor {
    @autoreleasepool {
        FSLog(@"🎯 插件已加载");
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
        
        // 监听手动触发通知
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,
            (CFNotificationCallback)updateStatusManually,
            CFSTR("com.yourname.feishuautostatus.trigger"),
            NULL,
            CFNotificationSuspensionBehaviorCoalesce
        );
    }
}

// 手动触发状态更新（用于调试）
static void updateStatusManually() {
    FSLog(@"🔧 [调试] 手动触发状态更新");
    
    loadPreferences();
    BOOL enabled = [preferences[kEnabledKey] boolValue];
    
    if (enabled) {
        switchToNextStatus();
    } else {
        FSLog(@"⚠️ 自动状态未启用");
    }
}

// 析构函数
%dtor {
    stopTimer();
}
