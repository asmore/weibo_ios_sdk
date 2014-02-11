//
//  ASWeiboSDK.m
//  youyu1.0
//
//  Created by 阿More on 14-2-8.
//  Copyright (c) 2014年 popalm.com. All rights reserved.
//

#import "ASWeiboSDK.h"

#import "SFHFKeychainUtils.h"
#import "JSONKit.h"

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

@synthesize weiboUserInfo;

@synthesize redirectURI;
//@synthesize isUserExclusive;
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
        
#ifdef DEBUG
        NSString *title = @"认证结果";
        NSString *message = [NSString stringWithFormat:@"响应状态: %d\nresponse.userId: %@\nresponse.accessToken: %@\n响应UserInfo数据: %@\n原请求UserInfo数据: %@",(int)response.statusCode,[(WBAuthorizeResponse *)response userID], [(WBAuthorizeResponse *)response accessToken], response.userInfo, response.requestUserInfo];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
        
        [alert show];
        [alert release];
#endif
        
        
        self.accessToken = [(WBAuthorizeResponse *)response accessToken];
        self.userID = [(WBAuthorizeResponse *)response userID];
        self.expirationDate = [(WBAuthorizeResponse *)response expirationDate];
        self.expireTime = [self.expirationDate timeIntervalSince1970];
        
        [self saveAuthorizeDataToKeychain];
        
        
        if ([delegate respondsToSelector:@selector(sinaweiboDidLogIn:)])
        {
            [delegate sinaweiboDidLogIn:self];
        }
    }
}


#pragma mark - WBHttpRequestDelegate

- (id)parseJSONData:(NSData *)data error:(NSError **)error
{
    NSError *parseError = nil;
	id result =[data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&parseError];
	
	if (parseError && (error != nil))
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  parseError, @"error",
                                  @"Data parse error", NSLocalizedDescriptionKey, nil];
        *error = [self errorWithCode:kWBSDKErrorCodeParseError
                            userInfo:userInfo];
	}
	
	return result;
}

- (id)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo
{
    return [NSError errorWithDomain:kWBSDKErrorDomain code:code userInfo:userInfo];
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
    
    if ([delegate respondsToSelector:@selector(sinaweibo:requestDidFailWithError:)])
    {
        [delegate sinaweibo:self requestDidFailWithError:error];
    }
}


- (void)request:(WBHttpRequest *)_request didFinishLoadingWithResult:(NSString *)result
{
	NSError *error = nil;
	id resultDic = [self parseJSONData:[result dataUsingEncoding:NSUTF8StringEncoding] error:&error];

	if (error)
	{
		[self request:_request didFailWithError:error];
        return;
	}
    
#ifdef DEBUG
    NSLog(@"resultDic :%@",resultDic);
#endif
    
    if ([_request.url hasSuffix:@"statuses/update.json"])
    {
        [self sendWeiboSucceed:resultDic];
    }
    else if ([_request.url hasSuffix:@"statuses/upload.json"])
    {
        [self sendWeiboSucceed:resultDic];

    }
    if ([_request.url hasSuffix:@"users/show.json"])
    {
        self.weiboUserInfo = resultDic;
        
        [self getUserInfoSucceed:resultDic];
    }
    if ([_request.url hasSuffix:@"/revokeoauth2"])
    {
        
        if ([delegate respondsToSelector:@selector(sinaweiboDidLogOut:)])
        {
            [delegate sinaweiboDidLogOut:self];
        }

    }
    
    else
    {
    
#ifdef DEBUG
        NSString *title = nil;
        UIAlertView *alert = nil;
        
        title = @"收到网络回调";
        alert = [[UIAlertView alloc] initWithTitle:title
                                           message:[NSString stringWithFormat:@"%@",result]
                                          delegate:nil
                                 cancelButtonTitle:@"确定"
                                 otherButtonTitles:nil];
        [alert show];
        [alert release];
#endif
        
        if ([delegate respondsToSelector:@selector(sinaweibo:requestDidSucceedWithResult:)])
        {
            [delegate sinaweibo:self requestDidSucceedWithResult:result];
        }
    }

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

#pragma mark - Validation

/**
 * @description 判断是否登录
 * @return YES为已登录；NO为未登录
 */
- (BOOL)isLoggedIn
{
    //    return userID && accessToken && refreshToken;
    //return userID && accessToken && (expireTime > 0);
    return userID && accessToken;
}
/**
 * @description 判断登录是否过期
 * @return YES为已过期；NO为未为期
 */
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

/**
 * @description 判断登录是否有效，当已登录并且登录未过期时为有效状态
 * @return YES为有效；NO为无效
 */
- (BOOL)isAuthValid
{
    return ([self isLoggedIn] && ![self isAuthorizeExpired]);
}


- (void)notifyTokenExpired:(id<WBHttpRequestDelegate>)requestDelegate
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"Token expired", NSLocalizedDescriptionKey, nil];
    
    NSError *error = [NSError errorWithDomain:kSinaWeiboSDKErrorDomain
                                         code:21315
                                     userInfo:userInfo];
    
    if ([delegate respondsToSelector:@selector(sinaweibo:accessTokenInvalidOrExpired:)])
    {
        [delegate sinaweibo:self accessTokenInvalidOrExpired:error];
    }
    
    if ([requestDelegate respondsToSelector:@selector(request:didFailWithError:)])
	{
		[requestDelegate request:nil didFailWithError:error];
	}
}

- (void)requestDidFailWithInvalidToken:(NSError *)error
{
    if ([delegate respondsToSelector:@selector(sinaweibo:accessTokenInvalidOrExpired:)])
    {
        [delegate sinaweibo:self accessTokenInvalidOrExpired:error];
    }
}

#pragma mark - Private Methods

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
    if ([self isAuthValid])
    {
        if ([delegate respondsToSelector:@selector(sinaweiboDidLogIn:)])
        {
            [delegate sinaweiboDidLogIn:self];
        }
    }
    
    WBAuthorizeRequest *_request = [WBAuthorizeRequest request];
    _request.redirectURI = kRedirectURI;
    _request.scope = @"all";
    [WeiboSDK sendRequest:_request];
}

- (void)logOut
{
    [WeiboSDK logOutWithToken:accessToken delegate:self withTag:@"user1"];
    [self deleteAuthorizeDataInKeychain];
}

#pragma mark Request
- (void)requestWithURL:(NSString *)url
                 params:(NSMutableDictionary *)params
             httpMethod:(NSString *)httpMethod
               delegate:(id<WBHttpRequestDelegate>)_delegate
{
    if (params == nil)
    {
        params = [NSMutableDictionary dictionary];
    }
    
    if ([self isAuthValid])
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
    else
    {
        //notify token expired in next runloop
        [self performSelectorOnMainThread:@selector(notifyTokenExpired:)
                               withObject:_delegate
                            waitUntilDone:NO];
        
        return;
    }
    
}


- (void)loadRequestWithMethodName:(NSString *)methodName
                       httpMethod:(NSString *)httpMethod
                           params:(NSDictionary *)params
{
	if (![self isAuthValid])
	{
        //notify token expired in next runloop
        [self performSelectorOnMainThread:@selector(notifyTokenExpired:)
                               withObject:nil
                            waitUntilDone:NO];
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


#pragma mark - weibo open API 接口

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


- (void)getWeiboUserInfo
{    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    
    if (self.userID) {
        [params setObject:self.userID forKey:@"uid"];
    }
    
    [self loadRequestWithMethodName:@"users/show.json"
                         httpMethod:@"GET"
                             params:params];
}




- (void)sendWeiboSucceed:(id)result
{
#ifdef DEBUG
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                        message:[NSString stringWithFormat:@"Post status \"%@\" succeed!", result]
                                                       delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertView show];
    [alertView release];
#endif
    
    if ([delegate respondsToSelector:@selector(sinaweibo:sendWeiboSucceedWithResult:)])
    {
        [delegate sinaweibo:self sendWeiboSucceedWithResult:result];
    }
    
}

- (void)getUserInfoSucceed:(id)result
{
    if ([delegate respondsToSelector:@selector(sinaweibo:getUserInfoSucceedWithResult:)])
    {
        [delegate sinaweibo:self getUserInfoSucceedWithResult:result];
    }
}



@end
