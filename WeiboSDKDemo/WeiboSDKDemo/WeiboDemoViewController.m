//
//  WeiboDemoViewController.m
//  WeiboSDKLibDemo
//
//  Created by 阿More on 14-2-10.
//  Copyright (c) 2014年 SINA iOS Team. All rights reserved.
//

#import "WeiboDemoViewController.h"

#import "ASWeiboSDK.h"

@interface WeiboDemoViewController ()
{
    ASWeiboSDK  *weiboSDK;
}

@property (nonatomic, retain) UISwitch *textSwitch;
@property (nonatomic, retain) UISwitch *imageSwitch;
@property (nonatomic, retain) UISwitch *mediaSwitch;

@end

@implementation WeiboDemoViewController

@synthesize textSwitch;
@synthesize imageSwitch;
@synthesize mediaSwitch;

@synthesize titleLabel;
@synthesize shareButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    
    weiboSDK = [ASWeiboSDK sharedInstance];
    
    [self shareMessage];
    
    UIButton *ssoButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [ssoButton setTitle:@"请求微博认证（SSO授权）" forState:UIControlStateNormal];
    [ssoButton addTarget:self action:@selector(ssoButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    ssoButton.frame = CGRectMake(20, 250, 280, 50);
    [self.view addSubview:ssoButton];
    
    UIButton *inviteFriendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [inviteFriendButton setTitle:@"用户信息" forState:UIControlStateNormal];
    [inviteFriendButton addTarget:self action:@selector(inviteFriendButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    inviteFriendButton.frame = CGRectMake(20, 370, 280, 50);
    [self.view addSubview:inviteFriendButton];
    
    UIButton *ssoOutButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [ssoOutButton setTitle:@"登出" forState:UIControlStateNormal];
    [ssoOutButton addTarget:self action:@selector(ssoOutButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    ssoOutButton.frame = CGRectMake(20, 300, 280, 50);
    [self.view addSubview:ssoOutButton];
    
    
    [self.shareButton setTitle:@"分享消息到微博" forState:UIControlStateNormal];
    self.titleLabel.text = @"第三方应用主动发送消息给微博";
    
}

-(void)shareMessage
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 100)] autorelease];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.numberOfLines = 3;
    [self.view addSubview:self.titleLabel];
    [self.titleLabel setText:@"微博给第三方应用发送提供消息的请求后，第三方应用返回消息给微博"];
    
    UILabel *textLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 110, 80, 30)] autorelease];
    textLabel.text = @"文字";
    textLabel.backgroundColor = [UIColor clearColor];
    textLabel.textAlignment = NSTextAlignmentLeft;
    self.textSwitch = [[[UISwitch alloc] initWithFrame:CGRectMake(100, 110, 120, 30)] autorelease];
    [self.view addSubview:textLabel];
    [self.view addSubview:self.textSwitch];
    
    UILabel *imageLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 150, 80, 30)] autorelease];
    imageLabel.text = @"图片";
    imageLabel.backgroundColor = [UIColor clearColor];
    imageLabel.textAlignment = NSTextAlignmentCenter;
    self.imageSwitch = [[[UISwitch alloc] initWithFrame:CGRectMake(100, 150, 120, 30)] autorelease];
    [self.view addSubview:imageLabel];
    [self.view addSubview:self.imageSwitch];
    
    UILabel *mediaLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 190, 80, 30)] autorelease];
    mediaLabel.text = @"多媒体";
    mediaLabel.backgroundColor = [UIColor clearColor];
    mediaLabel.textAlignment = NSTextAlignmentCenter;
    self.mediaSwitch = [[[UISwitch alloc] initWithFrame:CGRectMake(100, 190, 120, 30)] autorelease];
    [self.view addSubview:mediaLabel];
    [self.view addSubview:self.mediaSwitch];
    
    
    self.shareButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.shareButton.titleLabel.numberOfLines = 2;
    self.shareButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.shareButton setTitle:@"返回消息给微博" forState:UIControlStateNormal];
    [self.shareButton addTarget:self action:@selector(shareButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.shareButton.frame = CGRectMake(210, 110, 90, 110);
    [self.view addSubview:self.shareButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (WBMessageObject *)messageToShare
{
    WBMessageObject *message = [WBMessageObject message];
    
    if (self.textSwitch.on)
    {
        message.text = @"测试通过WeiboSDK发送文字到微博!";
    }
    
    if (self.imageSwitch.on)
    {
        WBImageObject *image = [WBImageObject object];
        image.imageData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"image_1" ofType:@"jpg"]];
        message.imageObject = image;
    }
    
    if (self.mediaSwitch.on)
    {
        WBWebpageObject *webpage = [WBWebpageObject object];
        webpage.objectID = @"identifier1";
        webpage.title = @"分享网页标题";
        webpage.description = [NSString stringWithFormat:@"分享网页内容简介-%.0f", [[NSDate date] timeIntervalSince1970]];
        webpage.thumbnailData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"image_2" ofType:@"jpg"]];
        webpage.webpageUrl = @"http://sina.cn?a=1";
        message.mediaObject = webpage;
    }
    
    return message;
}

- (void)shareButtonPressed
{
//    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:[self messageToShare]];
//    request.userInfo = @{@"ShareMessageFrom": @"SendMessageToWeiboViewController",
//                         @"Other_Info_1": [NSNumber numberWithInt:123],
//                         @"Other_Info_2": @[@"obj1", @"obj2"],
//                         @"Other_Info_3": @{@"key1": @"obj1", @"key2": @"obj2"}};
//    //    request.shouldOpenWeiboAppInstallPageIfNotInstalled = NO;
//    
//    [WeiboSDK sendRequest:request];
    
    NSDictionary *userinfo = @{@"ShareMessageFrom": @"SendMessageToWeiboViewController",
                                                        @"Other_Info_1": [NSNumber numberWithInt:123],
                                                        @"Other_Info_2": @[@"obj1", @"obj2"],
                                                        @"Other_Info_3": @{@"key1": @"obj1", @"key2": @"obj2"}};
    
    [weiboSDK sendWeiBoWithText:@"测试通过WeiboSDK发送文字到微博!"
                          image:[UIImage imageNamed:@"icon.png"]
                       userInfo:userinfo];
    
}

- (void)ssoButtonPressed
{
    [weiboSDK logIn];
}

- (void)ssoOutButtonPressed
{
    [weiboSDK logOut];
}

- (void)inviteFriendButtonPressed
{

    [weiboSDK getWeiboUserInfo];
    
}
@end
