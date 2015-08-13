//
//  PLTelnetVT100Handler.h
//  PLTelnetLite
//
//  Created by Patrick Lin on 6/7/15.
//  Copyright (c) 2015 Patrick Lin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLTelnetCSIHandlerImpl.h"

@interface PLTelnetVT100Handler : NSObject <PLTelnetCSIHandlerImpl>

- (BOOL)isCSICode:(uint8_t)byte;

- (void)parse:(NSData *)data withBlock:(PLTelnetCSIParseBlock)block;

- (void)screen:(PLTelnetScreenObject *)screen process:(NSData *)data withParams:(NSArray *)params withMode:(NSString *)mode withValue:(NSData *)value;

@end
