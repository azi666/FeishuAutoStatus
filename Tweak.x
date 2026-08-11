/*
 * FeishuAutoStatus - 飞书定时自动切换状态插件
 * 
 * 功能：
 * 1. 自动定时切换飞书在线状态
 * 2. 支持自定义状态列表
 * 3. 支持自定义切换时间间隔
 * 4. 后台持续运行
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

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

// Hook飞书状态管理类（需要根据实际类名调整）
%hook LKStatusManager

- (id)init {
    id result = %orig;
    NSLog(@"[FeishuAutoStatus] LKStatusManager初始化");
    
    // 监听状态变化通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(autoStatusChanged:)
                                                 name:@"FeishuAutoStatusChanged"
                                               object:nil];
    
    return result;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    %orig;
}

%new
- (void)autoStatusChanged:(NSNotification *)notification {
    NSDictionary *status = notification.userInfo;
    NSString *statusText = status[@"text"];
    NSString *emoji = status[@"emoji"];
    
    NSLog(@"[FeishuAutoStatus] 收到状态变化通知: %@ %@", emoji, statusText);
    
    // 调用飞书原生方法更新状态（需要根据实际方法名调整）
    if ([self respondsToSelector:@selector(updateStatus:)]) {
        [self performSelector:@selector(updateStatus:) withObject:statusText];
    }
}

%end

// Hook应用委托以启动定时器
%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    
    NSLog(@"[FeishuAutoStatus] 飞书应用启动，准备启动定时器");
    
    // 延迟启动定时器，确保应用完全加载
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        startTimer();
    });
    
    return result;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    %orig;
    NSLog(@"[FeishuAutoStatus] 应用进入前台");
    startTimer();
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    %orig;
    NSLog(@"[FeishuAutoStatus] 应用进入后台");
    // 保持定时器运行（iOS可能会暂停）
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
