## WKWebView OC与JS交互 同步返回值


<font size=5 color='#333333'>`以下主要讲WKWebView中OC与JS交互,UIWebView这里稍微简单介绍`</font>
> <font size=3>这里重点关于wkwebview中JS调用OC<font color='#20B2AA'>返回值的问题</font>，普通的OC与JS交互网上资料一大堆</font>

### 一、OC与JS交互
<font size=4 color='#666666'>稍微简单介绍下:</font>
#### 1.1.JavaScript —> Objective-C

#### 1.1.1.第一种JS调用OC window.webkit.messageHandlers.<方法名>.postMessage(<数据>)
* 向WKWebViewConfiguration实例中注入OC对象

```
// 这里只注册一个方法足矣，通过参数functionName区分调用OC相应方法
WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
...
[config.userContentController addScriptMessageHandler:self name:@"Call" ];
```

* JS方法  
 
```
// 这里使用window.webkit.messageHandlers.<方法名>.postMessage(<数据>) 没有直接返回值功能

var JS_Fun_01 = function (){
    var args = arguments;
    var args_num = arguments.length;
    window.webkit.messageHandlers.Call.postMessage({
                                                   'functionName':'OC_Fun_01',
                                                   'arguments': args_num == 0 ? {} : JSON.stringify(args),
                                                   });
};

var JS_Fun_02 = function (){
    var args = arguments;
    var args_num = arguments.length;
    window.webkit.messageHandlers.Call.postMessage({
                                                   'functionName':'OC_Fun_02',
                                                   'arguments': args_num == 0 ? {} : JSON.stringify(args),
                                                   });
};

var JS_Fun_03 = function (){
	var args = arguments;
	return JSON.stringify(args);
};

```

<font size=3 color='#666666'>下面是<font color=red>错误</font>调用：</font>

```
// 假如有个需求通过调用OC方法给个返回值
// 下面这个方法是错误的 window.webkit.messageHandlers.Call.postMessage没有返回值功能
var JS_Fun_Error = function (){
   var result = window.webkit.messageHandlers.Call.postMessage({
		'functionName':'OC_Fun_01',
 		'arguments':{},
	});
	return result;
};

```
 
* OC方法  

```
// JS -> OC
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

- (void)OC_Fun_01:(id)arguments
{

}

- (void)OC_Fun_02:(id)arguments
{

}

...

```
#### 1.1.2.第二种JS调用OC URL请求截获
<font size=3 color='#999999'>JavaScript 在浏览器环境中发出URL请求, Objective-C 截获请求以获取相关请求的思路. 在Objective-C 中在实现UIWebViewDelegate 时截获请求:</font>

```
// UIWebView
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *URL =  request.URL;
    // if (url是自定义的JavaScript通信协议) {
        //
        // do something
        //
        // 返回 NO 以阻止 `URL` 的加载或者跳转
        // return NO;
    // }
}

// WKWebView
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL *URL = navigationAction.request.URL;
    // if (url是自定义的JavaScript通信协议) {
        //
        // do something
        //
        // decisionHandler(WKNavigationActionPolicyCancel); 以阻止 `URL` 的加载或者跳转
        // decisionHandler(WKNavigationActionPolicyCancel);
        // return;
    // }
    decisionHandler(WKNavigationActionPolicyAllow);
}

JavaScript有各种不同的方式发出URL 请求:
第一种：location.href : 修改window.location.href 替换成一个合成的URL, 比如 async://method:args
第二种：location.hash : 修改 window.location.hash
第三种：iframe
```

#### 1.1.3.第三种JS调用OC 监听Cookie

```
// Objective-C 可以通过NSHTTPCookieManagerCookiesChangedNotification 事件以监听cookie的变化.
// 当JavaScript 修改 document.cookie 后, Objective-C 可以通过分析cookie以得到信息.

NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
[defaultCenter addObserverForName:NSHTTPCookieManagerCookiesChangedNotification
                           object:nil
                            queue:nil
                       usingBlock:^(NSNotification *notification) {
                           NSHTTPCookieStorage *cookieStorage = notification.object;
                           // do something with cookieStorage
                       }];
```

#### 1.1.4.第四种JS调用OC \<JavaScriptCore/JavaScriptCore>,<font size=4 color=red>可同步返回值</font> 
```
// 此处无返回值写法
JSContext *context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
context[@"JS_Fun_04"] = ^() {
    //用数组接收传过来的多个参数
    NSArray *paramArray = [JSContext currentArguments];
};

// 此处有回值写法
JSContext *context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
__weak JSContext *theContext = context;
context[@"JS_Fun_04"] = ^JSValue *() {
    //用数组接收传过来的多个参数
    NSArray *paramArray = [JSContext currentArguments];
    
    return [JSValue valueWithObject:@"这里是返回值" inContext:theContext];
};

```

<font size=3>以上前三种方式<font size=5 color=red>缺点</font></font>  
window.webkit.messageHandlers.<方法名>.postMessage(<数据>)、URL请求截获、监听Cookie的三种方式,整个过程是异步，不能同步  
在JavaScript中不能直接获取Objective-C处理的返回值,需要Objective-C 调用JavaScript层自己实现的api才能得到返回值  
使用callback 比较麻烦,需要在JavaScript 上自己实现


#### 1.2.Objective-C —> JavaScript
```
// WKWebView
[wkWebView evaluateJavaScript:@"JS_Fun_03('参数一','参数二')" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
	NSLog(@"%@", result);
}];

// UIWebView的第一种
NSString *result = [webView stringByEvaluatingJavaScriptFromString:@"JS_Fun_03('参数一','参数二')"];

// UIWebView的第二种
JSContext *context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
id result = [context evaluateScript:@"JS_Fun_03('参数一','参数二')"];
```
```
JavaScriptCore 各种类型数据:
   Objective-C type  |   JavaScript type
 --------------------+---------------------
         nil         |     undefined
        NSNull       |        null
       NSString      |       string
       NSNumber      |   number, boolean
     NSDictionary    |   Object object
       NSArray       |    Array object
        NSDate       |     Date object
       NSBlock (1)   |   Function object (1)
          id (2)     |   Wrapper object (2)
        Class (3)    | Constructor object (3)

```

### 二、WKWebView实现JS调用OC 同步返回值 <font color=red>重点❗️ 重点❗️❗️ 重点❗️❗️❗️ </font>
```
js:
var JS_Fun_05 = function (){
	var args = arguments;
	var type = "JSbridge";
	var functionName = "OC_Fun_05";
	var payload = {"type": type, "functionName": name, "arguments": args};
	var res = prompt(JSON.stringify(payload));
};

oc:
self.webView.UIDelegate = self;

// JS端调用prompt函数时，会触发此代理方法。
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler {
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

- (NSString *)OC_Fun_05:(NSDictionary *)args
{
	return @"Fun:OC_Fun_05";
}
- (NSString *)OC_Fun_06:(NSDictionary *)args
{
	return @"Fun:OC_Fun_06";
}

```
