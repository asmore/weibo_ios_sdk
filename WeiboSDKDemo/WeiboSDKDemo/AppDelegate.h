//
//  AppDelegate.h
//  WeiboSDKDemo
//
//  Created by Wade Cheng on 3/29/13.
//  Copyright (c) 2013 SINA iOS Team. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SendMessageToWeiboViewController;
@class WeiboDemoViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    NSString* wbtoken;
}

@property (strong, nonatomic) UIWindow *window;

//@property (strong, nonatomic) SendMessageToWeiboViewController *viewController;
@property (strong, nonatomic) WeiboDemoViewController *viewController;

@property (strong, nonatomic) NSString *wbtoken;

@end
