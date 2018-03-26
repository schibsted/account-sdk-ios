//
//  SPiDAccessToken.m
//  SPiDSDK
//
//  Copyright (c) 2012 Schibsted Payment. All rights reserved.
//

#import "SPiDAccessToken.h"

static NSString *const SPiDAccessTokenUserIdKey = @"user_id";
static NSString *const SPiDAccessTokenKey = @"access_token";
static NSString *const SPiDAccessTokenExpiresInKey = @"expires_in";
static NSString *const SPiDAccessTokenExpiresAtKey = @"expires_at";
static NSString *const SPiDAccessTokenRefreshTokenKey = @"refresh_token";

@implementation SPiDAccessToken

+ (BOOL)isValidToken:(SPiDAccessToken *)accessToken {
    if (accessToken.accessToken == nil) {
        SPiDDebugLog(@"Could not create SPiDAccessToken, missing access_token parameter");
        return NO;
    }
    if (accessToken.expiresAt == nil) {
        SPiDDebugLog(@"Could not create SPiDAccessToken, missing expires_in parameter");
        return NO;
    }
    return YES;
}

- (instancetype)initWithUserID:(NSString *)userID accessToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt refreshToken:(NSString *)refreshToken {
    if (self = [super init]) {
        _userID = userID;
        _accessToken = accessToken;
        _expiresAt = expiresAt;
        _refreshToken = refreshToken;

        if (![SPiDAccessToken isValidToken:self]) {
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    NSString *userID = [dictionary objectForKey:SPiDAccessTokenUserIdKey];
    if(![userID isKindOfClass:[NSString class]]) {
        SPiDDebugLog(@"Failed to parse access token from dictionary");
        userID = nil; // API returns non-string values for client tokens. That stops here.
    }

    NSString *accessToken = [dictionary objectForKey:SPiDAccessTokenKey];
    if(![accessToken isKindOfClass:[NSString class]] || accessToken.length == 0) {
        SPiDDebugLog(@"Failed to parse access token from dictionary");
        return nil;
    }

    NSNumber *expiresIn = [dictionary objectForKey:SPiDAccessTokenExpiresInKey];
    if(![expiresIn isKindOfClass:[NSNumber class]]) {
        SPiDDebugLog(@"Failed to parse access token from dictionary");
        return nil;
    }
    NSDate *expiresAt = [NSDate dateWithTimeIntervalSinceNow:[expiresIn integerValue]];

    NSString *refreshToken = [dictionary objectForKey:SPiDAccessTokenRefreshTokenKey];
    if(![refreshToken isKindOfClass:[NSString class]]) {
        SPiDDebugLog(@"Failed to parse access token from dictionary");
        return nil;
    }

    return [self initWithUserID:userID accessToken:accessToken expiresAt:expiresAt refreshToken:refreshToken];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    NSString *userID = [decoder decodeObjectForKey:SPiDAccessTokenUserIdKey];
    NSString *accessToken = [decoder decodeObjectForKey:SPiDAccessTokenKey];
    NSDate *expiresAt = [decoder decodeObjectForKey:SPiDAccessTokenExpiresAtKey];
    NSString *refreshToken = [decoder decodeObjectForKey:SPiDAccessTokenRefreshTokenKey];
    return [self initWithUserID:userID accessToken:accessToken expiresAt:expiresAt refreshToken:refreshToken];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[self userID] forKey:SPiDAccessTokenUserIdKey];
    [coder encodeObject:[self accessToken] forKey:SPiDAccessTokenKey];
    [coder encodeObject:[self expiresAt] forKey:SPiDAccessTokenExpiresAtKey];
    [coder encodeObject:[self refreshToken] forKey:SPiDAccessTokenRefreshTokenKey];
}

- (BOOL)hasExpired {
    return ([[NSDate date] earlierDate:[self expiresAt]] == [self expiresAt]);
}

- (BOOL)isClientToken {
    return (_userID != nil ? [_userID isEqualToString:@"0"] : YES);
}

@end
