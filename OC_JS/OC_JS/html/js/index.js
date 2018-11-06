
// WKWebView JS调OC window.webkit.messageHandlers.<方法名>.postMessage(<数据>)

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

var JS_Fun_04 = function (){
};



// WKWebView JS调OC 同步返回值

var JS_Fun_05 = function (){
    var args = arguments;
    var type = "JSbridge";
    var functionName = "OC_Fun_05";
    var payload = {"type": type, "functionName": functionName, "arguments": args};
    var res = prompt(JSON.stringify(payload));
    alert(res);
};

var JS_Fun_06 = function (){
    var args = arguments;
    var type = "JSbridge";
    var functionName = "OC_Fun_06";
    var payload = {"type": type, "functionName": functionName, "arguments": args};
    var res = prompt(JSON.stringify(payload));
    alert(res);
};
