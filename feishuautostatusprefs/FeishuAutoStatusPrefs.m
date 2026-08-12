#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface FeishuAutoStatusPrefsListController : PSListController
@end

@implementation FeishuAutoStatusPrefsListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)reloadPreferences:(id)sender {
    // 重新加载偏好设置
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.yourname.feishuautostatus/ReloadPrefs"),
        NULL,
        NULL,
        YES
    );
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"成功"
                                                                   message:@"设置已更新，将在下次切换时生效"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
