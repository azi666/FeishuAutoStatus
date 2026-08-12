// SettingsViewController.m
// 飞书自动状态切换 - 设置界面实现

#import "SettingsViewController.h"
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface FSAutoStatusSettingsViewController ()
@property (nonatomic, strong) NSMutableArray<NSString *> *logs;
@property (nonatomic, strong) UITextView *logTextView;
@end

@implementation FSAutoStatusSettingsViewController

- (instancetype)init {
    if (self = [super init]) {
        self.logs = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"自动状态设置";
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 创建表格视图（占上半部分）
    CGFloat screenHeight = self.view.bounds.size.height;
    CGFloat tableHeight = screenHeight * 0.6;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, tableHeight) 
                                                   style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    // 创建日志显示区域（占下半部分）
    CGFloat logHeight = screenHeight - tableHeight;
    self.logTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, tableHeight, 
                                                                     self.view.bounds.size.width, 
                                                                     logHeight)];
    self.logTextView.font = [UIFont fontWithName:@"Menlo" size:10];
    self.logTextView.editable = NO;
    self.logTextView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.logTextView.text = @"=== 调试日志 ===\n";
    [self.view addSubview:self.logTextView];
    
    // 导航栏按钮
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] 
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
        target:self 
        action:@selector(dismiss)];
    
    [self appendLog:@"[启动] 设置界面已加载"];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 2;  // 开关 + 间隔
    if (section == 1) return 3;  // 三个调试按钮
    return 1;  // 版本信息
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"基本设置";
    if (section == 1) return @"调试工具";
    return @"关于";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) return @"自动切换在线和离开状态";
    if (section == 1) return @"用于调试和查看运行状态";
    return @"v1.0.0";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = @"";
    cell.detailTextLabel.text = @"";
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"启用自动状态";
            UISwitch *toggle = [[UISwitch alloc] init];
            [toggle addTarget:self action:@selector(toggleEnabled:) forControlEvents:UIControlEventValueChanged];
            
            // 读取当前设置
            NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.yourname.feishuautostatus.plist"];
            toggle.on = [prefs[@"enabled"] boolValue];
            
            cell.accessoryView = toggle;
        } else {
            cell.textLabel.text = @"切换间隔";
            
            NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.yourname.feishuautostatus.plist"];
            NSInteger interval = [prefs[@"interval"] integerValue];
            if (interval == 0) interval = 30;
            
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld秒", (long)interval];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"查看发现的类";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"导出日志";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.textLabel.text = @"手动触发一次";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else {
        cell.textLabel.text = @"FeishuAutoStatus";
        cell.detailTextLabel.text = @"v1.0.0";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0 && indexPath.row == 1) {
        [self showIntervalPicker];
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self showDiscoveredInfo];
        } else if (indexPath.row == 1) {
            [self exportLogs];
        } else {
            [self triggerStatusChange];
        }
    }
}

#pragma mark - 设置相关方法

- (void)toggleEnabled:(UISwitch *)sender {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.yourname.feishuautostatus.plist"] ?: [NSMutableDictionary dictionary];
    prefs[@"enabled"] = @(sender.on);
    [prefs writeToFile:@"/var/mobile/Library/Preferences/com.yourname.feishuautostatus.plist" atomically:YES];
    
    [self appendLog:[NSString stringWithFormat:@"[设置] 自动状态: %@", sender.on ? @"开启" : @"关闭"]];
    
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.yourname.feishuautostatus/ReloadPrefs"),
        NULL, NULL, true
    );
}

- (void)showIntervalPicker {
    [self appendLog:@"[点击] 切换间隔设置"];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择切换间隔"
                                                                   message:@"设置自动切换的时间间隔"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSArray *intervals = @[@15, @30, @60, @120, @300];
    NSArray *labels = @[@"15秒", @"30秒", @"1分钟", @"2分钟", @"5分钟"];
    
    for (int i = 0; i < intervals.count; i++) {
        [alert addAction:[UIAlertAction actionWithTitle:labels[i]
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
            [self setInterval:[intervals[i] integerValue]];
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)setInterval:(NSInteger)interval {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.yourname.feishuautostatus.plist"] ?: [NSMutableDictionary dictionary];
    prefs[@"interval"] = @(interval);
    [prefs writeToFile:@"/var/mobile/Library/Preferences/com.yourname.feishuautostatus.plist" atomically:YES];
    
    [self appendLog:[NSString stringWithFormat:@"[设置] 切换间隔: %ld秒", (long)interval]];
    
    [self.tableView reloadData];
    
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.yourname.feishuautostatus/ReloadPrefs"),
        NULL, NULL, true
    );
}

#pragma mark - 调试工具方法

- (void)showDiscoveredInfo {
    [self appendLog:@"[调试] 查看发现的类"];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"已发现的类信息"
                                                                   message:@"暂未发现\n请先在飞书中打开状态页面"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)exportLogs {
    if (!self.logs || self.logs.count == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"无日志"
                                                                       message:@"当前没有可导出的日志"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    NSString *logContent = [self.logs componentsJoinedByString:@"\n"];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] 
                                           initWithActivityItems:@[logContent] 
                                           applicationActivities:nil];
    
    [self presentViewController:activityVC animated:YES completion:^{
        [self appendLog:@"[调试] 导出日志"];
    }];
}

- (void)triggerStatusChange {
    [self appendLog:@"[调试] 手动触发状态切换"];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"已触发"
                                                                   message:@"已手动触发一次状态切换\n请查看飞书是否更新状态"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 日志管理

- (void)appendLog:(NSString *)log {
    if (!self.logs) {
        self.logs = [NSMutableArray array];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH:mm:ss";
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    
    NSString *logEntry = [NSString stringWithFormat:@"[%@] %@", timestamp, log];
    [self.logs addObject:logEntry];
    
    // 保持最多100条日志
    if (self.logs.count > 100) {
        [self.logs removeObjectAtIndex:0];
    }
    
    // 更新UI
    if (self.logTextView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *allLogs = [self.logs componentsJoinedByString:@"\n"];
            self.logTextView.text = allLogs;
            
            // 滚动到底部
            if (self.logTextView.text.length > 0) {
                NSRange bottom = NSMakeRange(self.logTextView.text.length - 1, 1);
                [self.logTextView scrollRangeToVisible:bottom];
            }
        });
    }
}

@end
