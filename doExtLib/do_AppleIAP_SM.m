//
//  do_AppleIAP_SM.m
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_AppleIAP_SM.h"

#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doInvokeResult.h"
#import <StoreKit/StoreKit.h>

@interface do_AppleIAP_SM ()<SKProductsRequestDelegate,SKPaymentTransactionObserver>

@property (strong,nonatomic) NSMutableDictionary *products;//有效的产品
@property (strong,nonatomic) NSString *productID;//有效的产品ID
@property (strong,nonatomic) NSString *appStoreVerifyURL;//实际购买验证URL
@property (nonatomic,strong) id<doIScriptEngine> scritEngine;
@property (nonatomic,strong) NSString *callbackName;
@end

@implementation do_AppleIAP_SM
#pragma mark - 方法
#pragma mark - 同步异步方法的实现
//同步
- (void)restoreProduct:(NSArray *)parms
{
//    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
//    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    //自己的代码实现
    SKPaymentQueue *paymentQueue = [SKPaymentQueue defaultQueue];
    //恢复所有非消耗品
    [paymentQueue restoreCompletedTransactions];
//    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    //_invokeResult设置返回值
    
}
//异步
- (void)purchase:(NSArray *)parms
{
    //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    _scritEngine = [parms objectAtIndex:1];
//    自己的代码实现
    
    _callbackName = [parms objectAtIndex:2];
//    //回调函数名_callbackName
//    doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
    self.productID = _dictParas[@"productID"];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    if ([SKPaymentQueue canMakePayments]) {
        [self loadProducts:self.productID];
    }
}


#pragma mark - SKProductsRequestd代理方法
/**
 *  产品请求完成后的响应方法
 *
 *  @param request  请求对象
 *  @param response 响应对象，其中包含产品信息
 */
-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
//    doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
    NSArray *product = response.products;
//    if([product count] == 0){
//        [_invokeResult SetResultBoolean:NO];
//        [_scritEngine Callback:_callbackName :_invokeResult];
//        return;
//    }
    SKProduct *p = nil;
    for (SKProduct *pro in product) {
        if([pro.productIdentifier isEqualToString:self.productID]){
            p = pro;
        }
    }
    if (p !=nil) {
        [self purchaseProduct:p];
    }
//    SKPayment *payment = [SKPayment paymentWithProduct:p];
//    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

-(void)requestDidFinish:(SKRequest *)request
{
    
}

-(void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    if (error)
    {
        doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
        [_invokeResult SetResultBoolean:NO];
        [_scritEngine Callback:_callbackName :_invokeResult];
    }
}
#pragma mark - SKPaymentQueue监听方法
/**
 *  交易状态更新后执行
 *
 *  @param queue        支付队列
 *  @param transactions 交易数组，里面存储了本次请求的所有交易对象
 */
-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    [transactions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SKPaymentTransaction *paymentTransaction = obj;
        if (paymentTransaction.transactionState == SKPaymentTransactionStatePurchased)
        {//已购买成功
            NSLog(@"交易\"%@\"成功.",paymentTransaction.payment.productIdentifier);
            //购买成功后进行验证
//            [self verifyPurchaseWithPaymentTransaction];
            //结束支付交易
            [queue finishTransaction:paymentTransaction];
            doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
            [_invokeResult SetResultBoolean:YES];
            [_scritEngine Callback:_callbackName :_invokeResult];
        }
        else if(paymentTransaction.transactionState == SKPaymentTransactionStateRestored)
        {//恢复成功，对于非消耗品才能恢复,如果恢复成功则transaction中记录的恢复的产品交易
            NSLog(@"恢复交易\"%@\"成功.",paymentTransaction.payment.productIdentifier);
            [queue finishTransaction:paymentTransaction];//结束支付交易
            
            //恢复后重新写入偏好配置，重新加载UITableView
            [[NSUserDefaults standardUserDefaults]setBool:YES forKey:paymentTransaction.payment.productIdentifier];
        }
        else if(paymentTransaction.transactionState == SKPaymentTransactionStateFailed)
        {
            if (paymentTransaction.error.code == SKErrorPaymentCancelled)
            {//如果用户点击取消
                NSLog(@"取消购买.");
                doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
                [_invokeResult SetResultBoolean:NO];
                [_scritEngine Callback:_callbackName :_invokeResult];
            }
        }
        
    }];
}
//恢复购买完成
-(void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"恢复完成.");
}

#pragma mark - 私有方法
/**
 *  添加支付观察者监控，一旦支付后则会回调观察者的状态更新方法：
 */
-(void)addTransactionObjserver
{
    //设置支付观察者（类似于代理），通过观察者来监控购买情况
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}
/**
 *  加载所有产品，注意产品一定是从服务器端请求获得，因为有些产品可能开发人员知道其存在性，但是不经过审核是无效的；
 */
-(void)loadProducts:(NSString *)productID
{
    //定义要获取的产品标识集合
    
    NSSet *sets= [NSSet setWithObjects:productID, nil];
    //定义请求用于获取产品
    SKProductsRequest *productRequest = [[SKProductsRequest alloc]initWithProductIdentifiers:sets];
    //设置代理,用于获取产品加载状态
    productRequest.delegate = self;
    //开始请求
    [productRequest start];
}

/**
 *  购买产品
 *
 *  @param product 产品对象
 */
-(void)purchaseProduct:(SKProduct *)product
{
    //如果是非消耗品，购买过则提示用户
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([product.productIdentifier isEqualToString:self.productID])
    {
        NSLog(@"当前已经购买\"%@\" %li 个.",self.productID,(long)[defaults integerForKey:product.productIdentifier]);
    }else if([defaults boolForKey:product.productIdentifier])
    {
        NSLog(@"\"%@\"已经购买过，无需购买!",product.productIdentifier);
        return;
    }
    
    //创建产品支付对象
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    //支付队列，将支付对象加入支付队列就形成一次购买请求
    if (![SKPaymentQueue canMakePayments])
    {
        NSLog(@"设备不支持购买.");
        return;
    }
    SKPaymentQueue *paymentQueue = [SKPaymentQueue defaultQueue];
    //添加都支付队列，开始请求支付
    [paymentQueue addPayment:payment];
}

/**
 *  验证购买，避免越狱软件模拟苹果请求达到非法购买问题
 *
 */
-(void)verifyPurchaseWithPaymentTransaction
{
    //从沙盒中获取交易凭证并且拼接成请求体数据
    NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptUrl];
    
    NSString *receiptString = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];//转化为base64字符串
    
    NSString *bodyString = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\"}", receiptString];//拼接请求数据
    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    //创建请求到苹果官方进行购买验证
    NSURL *url=[NSURL URLWithString: self.appStoreVerifyURL];
    NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:url];
    requestM.HTTPBody = bodyData;
    requestM.HTTPMethod = @"POST";
    //创建连接并发送同步请求
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:requestM returningResponse:nil error:&error];
    if (error)
    {
        NSLog(@"验证购买过程中发生错误，错误信息：%@",error.localizedDescription);
        return;
    }
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
    NSLog(@"%@",dic);
    if([dic[@"status"] intValue] == 0)
    {
        NSLog(@"购买成功！");
        NSDictionary *dicReceipt = dic[@"receipt"];
        NSDictionary *dicInApp = [dicReceipt[@"in_app"] firstObject];
        NSString *productIdentifier = dicInApp[@"product_id"];//读取产品标识
        //如果是消耗品则记录购买数量，非消耗品则记录是否购买过
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([productIdentifier isEqualToString:self.productID])
        {
            NSInteger purchasedCount = [defaults integerForKey:productIdentifier];//已购买数量
            [[NSUserDefaults standardUserDefaults] setInteger:(purchasedCount+1) forKey:productIdentifier];
        }
        else
        {
            [defaults setBool:YES forKey:productIdentifier];
        }
        //在此处对购买记录进行存储，可以存储到开发商的服务器端
    }
    else
    {
        NSLog(@"购买失败，未通过验证！");
    }
}

@end