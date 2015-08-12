//
//  PLTelnetClient.h
//  PLTelnetLite
//
//  Created by Patrick on 8/12/15.
//  Copyright (c) 2015 Patrick Lin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PLTelnetClient;

@protocol PLTelnetClientDelegate <NSObject>

@optional

- (void)telnetClient:(PLTelnetClient *)client didConnectToHost:(NSString *)host onPort:(NSUInteger)port;

- (void)telnetClient:(PLTelnetClient *)client didDisconnectWithError:(NSError *)error;

- (void)telnetClient:(PLTelnetClient *)client didReceiveData:(NSData *)data;

- (void)telnetClient:(PLTelnetClient *)client didReceiveIAC:(NSData *)iac;

- (void)telnetClient:(PLTelnetClient *)client didReceiveCSI:(NSData *)csi withParams:(NSArray *)params withMode:(NSString *)mode withValue:(NSData *)value;

@end

@interface PLTelnetClient : NSObject

@property(atomic, weak, readwrite)id<PLTelnetClientDelegate> delegate;

- (BOOL)connectToHost:(NSString *)host onPort:(NSUInteger)port;

- (void)disconnect;

- (void)sendData:(NSData *)data;

- (id)initWithDelegate:(id<PLTelnetClientDelegate>)delegate;

+ (id)clientWithDelegate:(id<PLTelnetClientDelegate>)delegate;

@end
