//
//  ViewController.m
//  OC_JS
//
//  Created by wkx on 2018/11/6.
//  Copyright © 2018年 wkx. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>

@interface ViewController ()<WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>

@property(nonatomic, strong) WKWebView *wkWebView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view addSubview:self.wkWebView];
    self.view.backgroundColor = [UIColor whiteColor];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [_wkWebView.configuration.userContentController removeScriptMessageHandlerForName:@"Call"];
    _wkWebView.navigationDelegate = nil;
    _wkWebView.UIDelegate = nil;
    _wkWebView = nil;
}


#pragma mark - GETTER/SETTER

- (WKWebView *)wkWebView
{
    if (_wkWebView == nil)
    {
        float kWidth = [UIScreen mainScreen].bounds.size.width;
        float kHeight = [UIScreen mainScreen].bounds.size.height;
        
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        WKUserContentController *userController = [[WKUserContentController alloc] init];
        configuration.userContentController = userController;
        _wkWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, kWidth, kHeight) configuration:configuration];
        NSString *path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"index.html"];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]];
        [_wkWebView loadRequest:request];
        _wkWebView.navigationDelegate = self;
        _wkWebView.UIDelegate = self;
        [userController addScriptMessageHandler:self name:@"Call"];
    }
    return _wkWebView;
}

#pragma mark - WKScriptMessageHandler
//JS调用的OC回调方法
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message

{
    if ([message.name isEqualToString:@"Call"])
    {
        NSString *functionName = [message.body valueForKey:@"functionName"];
        NSDictionary *arguments = [message.body valueForKey:@"arguments"];
        
        if ([functionName isEqualToString:@"OC_Fun_01"])
        {
            [self OC_Fun_01:arguments];
        }
        else if ([functionName isEqualToString:@"OC_Fun_02"])
        {
            [self OC_Fun_02:arguments];
        }
    }
}

#pragma mark - WKUIDelegate

//接收到输入框 这里作用JS调OC
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler
{
    NSError *err = nil;
    NSData *dataFromString = [prompt dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:dataFromString options:NSJSONReadingMutableContainers error:&err];
    if (!err)
    {
        NSString *type = [payload objectForKey:@"type"];
        if (type && [type isEqualToString:@"JSbridge"])
        {
            NSString *returnValue = @"";
            NSString *functionName = [payload objectForKey:@"functionName"];
            NSDictionary *args = [payload objectForKey:@"arguments"];
            if ([functionName isEqualToString:@"OC_Fun_05"])
            {
                returnValue = [self OC_Fun_05:args];
            }
            else if ([functionName isEqualToString:@"OC_Fun_06"])
            {
                returnValue = [self OC_Fun_06:args];
            }
            
            completionHandler(returnValue);
        }
    }
}


//接收到警告面板
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();//此处的completionHandler()就是调用JS方法时，`evaluateJavaScript`方法中的completionHandler
    }];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Private

- (void)OC_Fun_01:(id)arguments
{
    NSLog(@"Fun:OC_Fun_01,arguments:%@",arguments);
}

- (void)OC_Fun_02:(id)arguments
{
    NSLog(@"Fun:OC_Fun_02,arguments:%@",arguments);
}

- (NSString *)OC_Fun_05:(id)arguments
{
    return @"Fun:OC_Fun_05";
}

- (NSString *)OC_Fun_06:(id)arguments
{
    return @"Fun:OC_Fun_06";
}

@end
