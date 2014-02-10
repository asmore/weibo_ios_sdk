//
//  ASWeiboSDK.h
//  youyu1.0
//
//  Created by 阿More on 14-2-8.
//  Copyright (c) 2014年 popalm.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WeiboSDK.h"
#import "Bee_Singleton.h"

typedef void (^requestBlock)();
typedef enum
{
    kWBRequestPostDataTypeNone,
	kWBRequestPostDataTypeNormal,			// for normal data post, such as "user=name&password=psd"
	kWBRequestPostDataTypeMultipart,        // for uploading images and files.
}WBRequestPostDataType;


#define kWBSDKErrorDomain           @"WeiBoSDKErrorDomain"
#define kWBSDKErrorCodeKey          @"WeiBoSDKErrorCodeKey"

#define kWBSDKAPIDomain             @"https://api.weibo.com/2/"

typedef enum
{
	kWBErrorCodeInterface	= 100,
	kWBErrorCodeSDK         = 101,
}WBErrorCode;

typedef enum
{
	kWBSDKErrorCodeParseError       = 200,
	kWBSDKErrorCodeRequestError     = 201,
	kWBSDKErrorCodeAccessError      = 202,
	kWBSDKErrorCodeAuthorizeError	= 203,
}WBSDKErrorCode;





@class ASWeiboSDK;
@protocol SinaWeiboDelegate;

@protocol ASWeiboSDKDelegate <NSObject>

@optional

// If you try to log in with logIn or logInUsingUserID method, and
// there is already some authorization info in the Keychain,
// this method will be invoked.
// You may or may not be allowed to continue your authorization,
// which depends on the value of isUserExclusive.
- (void)engineAlreadyLoggedIn:(ASWeiboSDK *)engine;

// Log in successfully.
- (void)engineDidLogIn:(ASWeiboSDK *)engine;

// Failed to log in.
// Possible reasons are:
// 1) Either username or password is wrong;
// 2) Your app has not been authorized by Sina yet.
- (void)engine:(ASWeiboSDK *)engine didFailToLogInWithError:(NSError *)error;

// Log out successfully.
- (void)engineDidLogOut:(ASWeiboSDK *)engine;

// When you use the WBEngine's request methods,
// you may receive the following four callbacks.
- (void)engineNotAuthorized:(ASWeiboSDK *)engine;
- (void)engineAuthorizeExpired:(ASWeiboSDK *)engine;

- (void)engine:(ASWeiboSDK *)engine requestDidFailWithError:(NSError *)error;
- (void)engine:(ASWeiboSDK *)engine requestDidSucceedWithResult:(id)result;

@end


@interface ASWeiboSDK : NSObject
{
    NSString        *appKey;
    NSString        *appSecret;
    
    NSString        *userID;
    NSString        *accessToken;
    NSTimeInterval  expireTime;
    NSDate          *expirationDate;
    
    NSString        *redirectURI;
    
    // Determine whether user must log out before another logging in.
    BOOL            isUserExclusive;
    
    id<ASWeiboSDKDelegate> delegate;
    
    
    WBHttpRequest       *request;
    WBAuthorizeRequest  *authorize;
}

@property (nonatomic, retain) NSString *appKey;
@property (nonatomic, retain) NSString *appSecret;
@property (nonatomic, retain) NSString *userID;
@property (nonatomic, retain) NSString *accessToken;
@property (nonatomic, assign) NSTimeInterval expireTime;
@property (nonatomic, retain) NSDate *expirationDate;

@property (nonatomic, retain) NSString *redirectURI;
@property (nonatomic, assign) BOOL isUserExclusive;

@property (nonatomic, assign) id<ASWeiboSDKDelegate> delegate;

@property (nonatomic, retain) WBHttpRequest *request;
@property (nonatomic, retain) WBAuthorizeRequest *authorize;

AS_SINGLETON(ASWeiboSDK)

+ (BOOL)registerApp:(NSString *)appKey;
+ (void)enableDebugMode:(BOOL)enabled;
+ (BOOL)handleOpenURL:(NSURL *)url;


// Initialize an instance with the AppKey and the AppSecret you have for your client.
- (id)initWithAppKey:(NSString *)theAppKey appSecret:(NSString *)theAppSecret;

// Log in using OAuth Web authorization.
// If succeed, engineDidLogIn will be called.
- (void)logIn;


// Log out.
// If succeed, engineDidLogOut will be called.
- (void)logOut;

// Check if user has logged in, or the authorization is expired.
- (BOOL)isLoggedIn;
- (BOOL)isAuthorizeExpired;

// @methodName: The interface you are trying to visit, exp, "statuses/public_timeline.json" for the newest timeline.
// See
// http://open.weibo.com/wiki/API%E6%96%87%E6%A1%A3_V2
// for more details.
// @httpMethod: "GET" or "POST".
// @params: A dictionary that contains your request parameters.
// @postDataType: "GET" for kWBRequestPostDataTypeNone, "POST" for kWBRequestPostDataTypeNormal or kWBRequestPostDataTypeMultipart.
// @httpHeaderFields: A dictionary that contains HTTP header information.
//- (void)loadRequestWithMethodName:(NSString *)methodName
//                       httpMethod:(NSString *)httpMethod
//                           params:(NSDictionary *)params
//                     postDataType:(WBRequestPostDataType)postDataType
//                 httpHeaderFields:(NSDictionary *)httpHeaderFields
//                    completeBlock:(requestBlock) completeBlock
//                      failedBlock:(requestBlock) faildBlock;

- (void)requestWithURL:(NSString *)url
                             params:(NSMutableDictionary *)params
                         httpMethod:(NSString *)httpMethod
                           delegate:(id<WBHttpRequestDelegate>)delegate;

//发微博
- (void)sendWeiBoWithText:(NSString *)text
                    image:(UIImage *)image
                 userInfo:(NSDictionary*)userInfo;

@end

/**
 * @description 第三方应用需实现此协议，登录时传入此类对象，用于完成登录结果的回调
 */
@protocol SinaWeiboDelegate <NSObject>

@optional

- (void)sinaweiboDidLogIn:(ASWeiboSDK *)sinaweibo;
- (void)sinaweiboDidLogOut:(ASWeiboSDK *)sinaweibo;
- (void)sinaweiboLogInDidCancel:(ASWeiboSDK *)sinaweibo;
- (void)sinaweibo:(ASWeiboSDK *)sinaweibo logInDidFailWithError:(NSError *)error;
- (void)sinaweibo:(ASWeiboSDK *)sinaweibo accessTokenInvalidOrExpired:(NSError *)error;

@end

