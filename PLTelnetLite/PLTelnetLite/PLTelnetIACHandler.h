//
//  PLTelnetIACHandler.h
//  PLTelnetLite
//
//  Created by Patrick Lin on 6/7/15.
//  Copyright (c) 2015 Patrick Lin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLTelnetIACHandlerImpl.h"

@interface PLTelnetIACHandler : NSObject <PLTelnetIACHandlerImpl>

- (BOOL)isIACCode:(uint8_t)byte;

- (void)parse:(NSData *)data withBlock:(PLTelnetIACParseBlock)block;

@end
