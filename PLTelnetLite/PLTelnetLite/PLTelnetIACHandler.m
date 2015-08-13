//
//  PLTelnetIACHandler.m
//  PLTelnetLite
//
//  Created by Patrick Lin on 6/7/15.
//  Copyright (c) 2015 Patrick Lin. All rights reserved.
//

#import "PLTelnetIACHandler.h"

@implementation PLTelnetIACHandler

- (BOOL)isIACCode:(uint8_t)byte
{
    return (byte == PLTelnetCommand_IAC) ? YES : NO;
}

- (void)parse:(NSData *)data withBlock:(PLTelnetIACParseBlock)block
{
    __block NSData* IAC = nil;
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        
        if (byteRange.length == 1) {
            
            IAC = [NSData dataWithBytesNoCopy:(void *)data.bytes length:1 freeWhenDone:NO];
            
            *stop = YES;
            
            return;
            
        }
        
        NSUInteger endIndex = 1;
        
        for (size_t i = 1; i < byteRange.length; ++i) {
            
            endIndex = i;
            
            uint8_t endByte = ((uint8_t *)bytes)[i];
            
            if (endByte == 27 || endByte == 255) {
                
                break;
                
            }
            
        }
        
        IAC = [NSData dataWithBytesNoCopy:(void *)(bytes) length:(endIndex + 1) freeWhenDone:NO];
        
    }];
    
    block(IAC);
}

@end
