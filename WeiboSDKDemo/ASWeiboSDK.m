//
//  ASWeiboSDK.m
//  youyu1.0
//
//  Created by 阿More on 14-2-8.
//  Copyright (c) 2014年 popalm.com. All rights reserved.
//

#import "ASWeiboSDK.h"
#import "SFHFKeychainUtils.h"

#define kWBURLSchemePrefix              @"WB_"

#define kWBKeychainServiceNameSuffix    @"_WeiBoServiceName"
#define kWBKeychainUserID               @"WeiBoUserID"
#define kWBKeychainAccessToken          @"WeiBoAccessToken"
#define kWBKeychainExpireTime           @"WeiBoExpireTime"

@interface ASWeiboSDK (Private) <WBHttpRequestDelegate,WeiboSDKDelegate>

- (NSString *)urlSchemeString;

- (void)saveAuthorizeDataToKeychain;
- (void)readAuthorizeDataFromKeychain;
- (void)deleteAuthorizeDataInKeychain;

@end

@implementation ASWeiboSDK
@synthesize appKey;
@synthesize appSecret;
@synthesize userID;
@synthesize accessToken;
@synthesize expireTime;
@synthesize expirationDate;

@synthesize redirectURI;
@synthesize isUserExclusive;
@synthesize request;
@synthesize authorize;
@synthesize delegate;
//@synthesize rootViewController;


DEF_SINGLETON(ASWeiboSDK)


#pragma mark - WeiboSDK

+ (BOOL)registerApp:(NSString *)appKey
{
    return [WeiboSDK registerApp:kAppKey];
}

+ (void)enableDebugMode:(BOOL)enabled
{
    [WeiboSDK enableDebugMode:enabled];

}

+ (BOOL)handleOpenURL:(NSURL *)url
{
    return [WeiboSDK handleOpenURL:url delegate:[ASWeiboSDK sharedInstance]];
}

#pragma mark - WeiboSDKDelegate 
- (void)didReceiveWeiboRequest:(WBBaseRequest *)request
{
//    if ([request isKindOfClass:WBProvideMessageForWeiboRequest.class])
//    {
//        ProvideMessageForWeiboViewController *controller = [[[ProvideMessageForWeiboViewController alloc] init] autorelease];
//        [self.viewController presentModalViewController:controller animated:YES];
//    }
}

- (void)didReceiveWeiboResponse:(WBBaseResponse *)response
{
    if ([response isKindOfClass:WBSendMessageToWeiboResponse.class])
    {
        NSString *title = @"发送结果";
        NSString *message = [NSString stringWithFormat:@"响应状态: %d\n响应UserInfo数据: %@\n原请求UserInfo数据: %@",(int)response.statusCode, response.userInfo, response.requestUserInfo];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    else if ([response isKindOfClass:WBAuthorizeResponse.class])
    {
        NSString *title = @"认证结果";
        NSString *message = [NSString stringWithFormat:@"响应状态: %d\nresponse.userId: %@\nresponse.accessToken: %@\n响应UserInfo数据: %@\n原请求UserInfo数据: %@",(int)response.statusCode,[(WBAuthorizeResponse *)response userID], [(WBAuthorizeResponse *)response accessToken], response.userInfo, response.requestUserInfo];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
        
        self.accessToken = [(WBAuthorizeResponse *)response accessToken];
        self.userID = [(WBAuthorizeResponse *)response userID];
        self.expirationDate = [(WBAuthorizeResponse *)response expirationDate];
        self.expireTime = [self.expirationDate timeIntervalSince1970];
        
        [self saveAuthorizeDataToKeychain];
        
        [alert show];
        [alert release];
    }
}


#pragma mark - WBHttpRequestDelegate

- (void)request:(WBHttpRequest *)_request didFinishLoadingWithResult:(NSString *)result
{
    NSString *title = nil;
    UIAlertView *alert = nil;
    
    if ([_request.url hasSuffix:@"statuses/update.json"])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                            message:[NSString stringWithFormat:@"Post status \"%@\" succeed!", result]
                                                           delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
    }
    else if ([_request.url hasSuffix:@"statuses/upload.json"])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                            message:[NSString stringWithFormat:@"Post image status \"%@\" succeed!", result]
                                                           delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];

    }
    else
    {
    
        title = @"收到网络回调";
        alert = [[UIAlertView alloc] initWithTitle:title
                                           message:[NSString stringWithFormat:@"%@",result]
                                          delegate:nil
                                 cancelButtonTitle:@"确定"
                                 otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

- (void)request:(WBHttpRequest *)request didFailWithError:(NSError *)error;
{
    NSString *title = nil;
    UIAlertView *alert = nil;
    
    title = @"请求异常";
    alert = [[UIAlertView alloc] initWithTitle:title
                                       message:[NSString stringWithFormat:@"%@",error]
                                      delegate:nil
                             cancelButtonTitle:@"确定"
                             otherButtonTitles:nil];
    [alert show];
    [alert release];
}



#pragma mark - ASWeiboSDK Life Circle

- (id)init
{
    if (self = [super init]) {
        
        [self readAuthorizeDataFromKeychain];
    }
    
    return self;
}

- (id)initWithAppKey:(NSString *)theAppKey appSecret:(NSString *)theAppSecret
{
    if (self = [self init])
    {
        self.appKey = theAppKey;
        self.appSecret = theAppSecret;
        
        //isUserExclusive = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readAuthorizeDataFromKeychain) name:@"WBAuthStatusChange" object:nil];
        [self readAuthorizeDataFromKeychain];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [appKey release], appKey = nil;
    [appSecret release], appSecret = nil;
    
    [userID release], userID = nil;
    [accessToken release], accessToken = nil;
    
    [redirectURI release], redirectURI = nil;
    
//    [request setDelegate:nil];
//    [request disconnect];
//    [request release], request = nil;
//    
//    [authorize setDelegate:nil];
//    [authorize release], authorize = nil;
//    
//    delegate = nil;
//    rootViewController = nil;
    
    [super dealloc];
}


#pragma mark - WBEngine Private Methods

- (NSString *)urlSchemeString
{
    return [NSString stringWithFormat:@"%@%@", kWBURLSchemePrefix, appKey];
}

- (void)saveAuthorizeDataToKeychain
{
    NSString *serviceName = [[self urlSchemeString] stringByAppendingString:kWBKeychainServiceNameSuffix];
    [SFHFKeychainUtils storeUsername:kWBKeychainUserID andPassword:userID forServiceName:serviceName updateExisting:YES error:nil];
	[SFHFKeychainUtils storeUsername:kWBKeychainAccessToken andPassword:accessToken forServiceName:serviceName updateExisting:YES error:nil];
	[SFHFKeychainUtils storeUsername:kWBKeychainExpireTime andPassword:[NSString stringWithFormat:@"%lf", expireTime] forServiceName:serviceName updateExisting:YES error:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WBAuthStatusChange" object:nil];
}

- (void)readAuthorizeDataFromKeychain
{
    NSString *serviceName = [[self urlSchemeString] stringByAppendingString:kWBKeychainServiceNameSuffix];
    self.userID = [SFHFKeychainUtils getPasswordForUsername:kWBKeychainUserID andServiceName:serviceName error:nil];
    self.accessToken = [SFHFKeychainUtils getPasswordForUsername:kWBKeychainAccessToken andServiceName:serviceName error:nil];
    self.expireTime = [[SFHFKeychainUtils getPasswordForUsername:kWBKeychainExpireTime andServiceName:serviceName error:nil] doubleValue];
}

- (void)deleteAuthorizeDataInKeychain
{
    self.userID = nil;
    self.accessToken = nil;
    self.expireTime = 0;
    
    NSString *serviceName = [[self urlSchemeString] stringByAppendingString:kWBKeychainServiceNameSuffix];
    [SFHFKeychainUtils deleteItemForUsername:kWBKeychainUserID andServiceName:serviceName error:nil];
	[SFHFKeychainUtils deleteItemForUsername:kWBKeychainAccessToken andServiceName:serviceName error:nil];
	[SFHFKeychainUtils deleteItemForUsername:kWBKeychainExpireTime andServiceName:serviceName error:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WBAuthStatusChange" object:nil];
}

#pragma mark Authorization

- (void)logIn
{
    if ([self isLoggedIn])
    {
        if ([delegate respondsToSelector:@selector(engineAlreadyLoggedIn:)])
        {
            [delegate engineAlreadyLoggedIn:self];
        }
        if (isUserExclusive)
        {
            return;
        }
    }
    
    WBAuthorizeRequest *_request = [WBAuthorizeRequest request];
    _request.redirectURI = kRedirectURI;
    _request.scope = @"all";
    [WeiboSDK sendRequest:_request];
    
//    WBAuthorize *auth = [[WBAuthorize alloc] initWithAppKey:appKey appSecret:appSecret];
//    [auth setRootViewController:rootViewController];
//    [auth setDelegate:self];
//    self.authorize = auth;
//    [auth release];
//    
//    if ([redirectURI length] > 0)
//    {
//        [authorize setRedirectURI:redirectURI];
//    }
//    else
//    {
//        [authorize setRedirectURI:@"http://"];
//    }
//    
//    [authorize startAuthorize];
}

- (void)logOut
{
    //AppDelegate *myDelegate =(AppDelegate*)[[UIApplication sharedApplication] delegate];
    [WeiboSDK logOutWithToken:accessToken delegate:self withTag:@"user1"];
}


- (BOOL)isLoggedIn
{
    //    return userID && accessToken && refreshToken;
    //return userID && accessToken && (expireTime > 0);
    return userID && accessToken && ![self isAuthorizeExpired];
}

- (BOOL)isAuthorizeExpired
{
    if (expireTime == 0) {
        return YES;
    }
    if ([[NSDate date] timeIntervalSince1970] > expireTime)
    {
        // force to log out
        [self deleteAuthorizeDataInKeychain];
        return YES;
    }
    return NO;
}



#pragma mark Request
- (void)requestWithURL:(NSString *)url
                 params:(NSMutableDictionary *)params
             httpMethod:(NSString *)httpMethod
               delegate:(id<WBHttpRequestDelegate>)delegate
{
    [request disconnect];
    //NSString *url = [NSString stringWithFormat:@"%@%@", kWBSDKAPIDomain, methodName];
    
    self.request = [WBHttpRequest requestWithAccessToken:accessToken
                                                     url:url
                                              httpMethod:httpMethod
                                                  params:params
                                                delegate:self
                                                 withTag:@"user1"];
    
}


- (void)loadRequestWithMethodName:(NSString *)methodName
                       httpMethod:(NSString *)httpMethod
                           params:(NSDictionary *)params
{
    // Step 1.
    // Check if the user has been logged in.
	if (![self isLoggedIn])
	{
        if ([delegate respondsToSelector:@selector(engineNotAuthorized:)])
        {
            [delegate engineNotAuthorized:self];
        }
        return;
	}
    
	// Step 2.
    // Check if the access token is expired.
    if ([self isAuthorizeExpired])
    {
        if ([delegate respondsToSelector:@selector(engineAuthorizeExpired:)])
        {
            [delegate engineAuthorizeExpired:self];
        }
        return;
    }
    
    [request disconnect];
    NSString *url = [NSString stringWithFormat:@"%@%@", kWBSDKAPIDomain, methodName];
    
    self.request = [WBHttpRequest requestWithAccessToken:accessToken
                                                      url:url
                                               httpMethod:httpMethod
                                                   params:params
                                                 delegate:self
                                                  withTag:@"user1"];
    
}

- (void)sendWeiBoWithText:(NSString *)text
                    image:(UIImage *)image
                 userInfo:(NSDictionary*)userInfo
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    
    [params setObject:(text ? text : @"") forKey:@"status"];
    
    if (image)
    {
        [params setObject:image forKey:@"pic"];
        
        [self loadRequestWithMethodName:@"statuses/upload.json"
                             httpMethod:@"POST"
                                 params:params];
    }
    else
    {
        [self loadRequestWithMethodName:@"statuses/update.json"
                             httpMethod:@"POST"
                                 params:params];
    }
}
@end
