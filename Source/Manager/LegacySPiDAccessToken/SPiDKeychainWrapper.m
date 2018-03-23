//
//  SPiDKeychainWrapper.h
//  SPiDSDK
//
//  Copyright (c) 2012 Schibsted Payment. All rights reserved.
//

#import "SPiDKeychainWrapper.h"

@interface SPiDKeychainWrapper ()

/** Generates a service name to use for the keychain

 The service will have the form 'bundleIdentifier-SPiD'

 @return Service name
 */
+ (NSString *)serviceNameForSPiD;

/** Creates the basic search query used for all keychain operations

 @param identifier Unique identifier for the keychain item
 @return Query as a `NSMutableDictionary`
  */
+ (NSMutableDictionary *)setupSearchQueryForIdentifier:(NSString *)identifier;

@end

@implementation SPiDKeychainWrapper

#pragma mark Public methods

///---------------------------------------------------------------------------------------
/// @name Public methods
///---------------------------------------------------------------------------------------

+ (SPiDAccessToken *)accessTokenFromKeychainForIdentifier:(NSString *)identifier; {
    NSMutableDictionary *query = [self setupSearchQueryForIdentifier:identifier];

    // search attributes
    [query setObject:(__bridge id) kCFBooleanTrue forKey:(__bridge id) kSecMatchLimitOne];
    [query setObject:(__bridge id) kCFBooleanTrue forKey:(__bridge id) kSecReturnData];

    CFTypeRef cfData = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) query, &cfData);
    if (status == noErr) {
        NSData *result = (__bridge_transfer NSData *) cfData;
        SPiDAccessToken *accessToken = [NSKeyedUnarchiver unarchiveObjectWithData:result];
        return accessToken;
    } else {
        //NSAssert(status == errSecItemNotFound, @"Error reading from keychain");
        return nil;
    }
}

+ (BOOL)storeInKeychainAccessTokenWithValue:(SPiDAccessToken *)accessToken forIdentifier:(NSString *)identifier {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:accessToken];
    NSMutableDictionary *query = [self setupSearchQueryForIdentifier:identifier];

    // add data
    [query setObject:data forKey:(__bridge id) kSecValueData];

    OSStatus status = SecItemAdd((__bridge CFDictionaryRef) query, NULL);
    if (status == errSecSuccess) {
        return YES;
    } else if (status == errSecDuplicateItem) {
        return [self updateAccessTokenInKeychainWithValue:accessToken forIdentifier:identifier];
    } else {
        // TODO: should we throw error instead?
        return NO;
    }
}

+ (BOOL)updateAccessTokenInKeychainWithValue:(SPiDAccessToken *)accessToken forIdentifier:(NSString *)identifier {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:accessToken];
    NSMutableDictionary *searchQuery = [self setupSearchQueryForIdentifier:identifier];
    NSMutableDictionary *updateQuery = [[NSMutableDictionary alloc] init];

    // add data
    [updateQuery setObject:data forKey:(__bridge id) kSecValueData];

    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef) searchQuery, (__bridge CFDictionaryRef) updateQuery);
    if (status == errSecSuccess) {
        return YES;
    } else {
        return NO;
    }
}

+ (void)removeAccessTokenFromKeychainForIdentifier:(NSString *)identifier {
    NSMutableDictionary *query = [self setupSearchQueryForIdentifier:identifier];

    OSStatus status = SecItemDelete((__bridge CFDictionaryRef) query);
    if (status != noErr) {
        SPiDDebugLog(@"Error deleting item to keychain - %d", (int)status);
    }
}

#pragma mark Private methods

///---------------------------------------------------------------------------------------
/// @name Private methods
///---------------------------------------------------------------------------------------

+ (NSString *)serviceNameForSPiD {
    NSString *appName = [[NSBundle mainBundle] bundleIdentifier];
    return [NSString stringWithFormat:@"%@-SPiD", appName];
}

+ (NSMutableDictionary *)setupSearchQueryForIdentifier:(NSString *)identifier {
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];

    [query setObject:(__bridge id) kSecClassGenericPassword forKey:(__bridge id) kSecClass];

    // set unique identification
    [query setObject:identifier forKey:(__bridge id) kSecAttrGeneric];
    [query setObject:identifier forKey:(__bridge id) kSecAttrAccount];
    [query setObject:[self serviceNameForSPiD] forKey:(__bridge id) kSecAttrService];

    return query;
}

@end
