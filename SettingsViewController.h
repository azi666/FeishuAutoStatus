// SettingsViewController.h
// 飞书自动状态切换 - 设置界面

#import <UIKit/UIKit.h>

@interface FSAutoStatusSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextView *logView;
@property (nonatomic, strong) NSMutableArray *logs;

- (void)appendLog:(NSString *)log;

@end
