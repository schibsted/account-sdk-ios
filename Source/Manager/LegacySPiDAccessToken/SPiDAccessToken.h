//
//  SPiDAccessToken.h
//  SPiDSDK
//
//  Copyright (c) 2012 Schibsted Payment. All rights reserved.
//

#import <Foundation/Foundation.h>
#define SPiDDebugLog NSLog

NS_ASSUME_NONNULL_BEGIN

/** Contains a access token that can be saved to the keychain */

@interface SPiDAccessToken : NSObject <NSCoding>

///---------------------------------------------------------------------------------------
/// @name Properties
///---------------------------------------------------------------------------------------

// Note: We have not included scope since it is not used, might have to be added later
/** User ID for the current client */
@property(nonatomic, copy) NSString * _Nullable userID;

/** The OAuth 2.0 access token */
@property(nonatomic, copy) NSString * _Nullable accessToken;

/** Expiry date for the access token */
@property(nonatomic, copy) NSDate * _Nullable expiresAt;

/** Refresh token used for refreshing the access token  */
@property(nonatomic, copy) NSString * _Nullable refreshToken;

///---------------------------------------------------------------------------------------
/// @name Public methods
///---------------------------------------------------------------------------------------

/** Initializes the AccessToken from the parameters

 @param userID Current user ID
 @param accessToken Access token
 @param expiresAt Access token expires at date
 @param refreshToken Refresh token
 @return SPiDAccessToken or nil if token is invalid
 */
- (instancetype)initWithUserID:(NSString * _Nullable)userID accessToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt refreshToken:(NSString *)refreshToken;

/** Initializes the AccessToken from a dictionary

 @param dictionary Received data from SPiD
 @return SPiDAccessToken or nil if token is invalid
 */
- (instancetype)initWithDictionary:(NSDictionary * _Nullable)dictionary;

/** Checks if the access token has expired

@Return Returns YES if access token has expired
*/
- (BOOL)hasExpired;

/** Checks if the access token is a client token

@Return Returns YES if the access token is a client token
*/
- (BOOL)isClientToken;

@end

NS_ASSUME_NONNULL_END
