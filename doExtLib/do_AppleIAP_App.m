//
//  do_AppleIAP_App.m
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_AppleIAP_App.h"
static do_AppleIAP_App* instance;
@implementation do_AppleIAP_App
@synthesize OpenURLScheme;
+(id) Instance
{
    if(instance==nil)
        instance = [[do_AppleIAP_App alloc]init];
    return instance;
}
@end
