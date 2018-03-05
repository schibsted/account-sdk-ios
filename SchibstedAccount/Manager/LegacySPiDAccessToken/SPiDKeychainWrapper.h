//
//  SPiDKeychainWrapper.h
//  SPiDSDK
//
//  Copyright (c) 2012 Schibsted Payment. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPiDAccessToken.h"

NS_ASSUME_NONNULL_BEGIN

/** `SPiDKeychainWrapper` is a wrapper used to simplfy keychain access.
 It is used by the `SPiDClient` for all keychain operations.
 Note that all keychain items are available in the iPhone simulator to all apps since the application is not signed!
*/

@interface SPiDKeychainWrapper : NSObject

///---------------------------------------------------------------------------------------
/// @name Public methods
///---------------------------------------------------------------------------------------

/** Get access token from keychain
 Tries to load the access token from the keychain

 @param identifier Unique identification for this keychain item
 @return Access token if available otherwise nil
 */
+ (SPiDAccessToken * _Nullable)accessTokenFromKeychainForIdentifier:(NSString *)identifier;

/** Saves access token to keychain
 Tries to save the access token to the keychain

 @param accessToken Access token to save
 @param identifier Unique identification for this keychain item
 @return Access token if available otherwise nil
 */
+ (BOOL)storeInKeychainAccessTokenWithValue:(SPiDAccessToken *)accessToken forIdentifier:(NSString *)identifier;

/** Update access token in keychain
 Tries to update the access token in the keychain

 @param accessToken Access token to save
 @param identifier Unique identification for this keychain item
 @return YES if successful otherwise NO
 */
+ (BOOL)updateAccessTokenInKeychainWithValue:(SPiDAccessToken *)accessToken forIdentifier:(NSString *)identifier;

/** Remove access token from keychain
 Tries to remove the access token from the keychain

 @param identifier Unique identification for this keychain item
 */
+ (void)removeAccessTokenFromKeychainForIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
