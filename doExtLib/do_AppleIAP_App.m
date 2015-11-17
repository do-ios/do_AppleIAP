//
//  do_AppleIAP_App.m
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//
#import <StoreKit/StoreKit.h>
#import "doScriptEngineHelper.h"
#import "do_AppleIAP_App.h"
#import "do_AppleIAP_SM.h"

static do_AppleIAP_App* instance;
@implementation do_AppleIAP_App
@synthesize OpenURLScheme;
+(id) Instance
{
    if(instance==nil)
        instance = [[do_AppleIAP_App alloc]init];
    return instance;
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    do_AppleIAP_SM *apple = (do_AppleIAP_SM *)[doScriptEngineHelper ParseSingletonModule:nil :@"do_AppleIAP_SM"];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:apple];
    return YES;
}
@end
