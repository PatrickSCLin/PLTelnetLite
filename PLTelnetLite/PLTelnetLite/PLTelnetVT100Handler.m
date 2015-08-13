//
//  PLTelnetVT100Handler.m
//  PLTelnetLite
//
//  Created by Patrick Lin on 6/7/15.
//  Copyright (c) 2015 Patrick Lin. All rights reserved.
//

#import "PLTelnetVT100Handler.h"

@implementation PLTelnetVT100Handler

- (BOOL)isCSICode:(uint8_t)byte
{
    return (byte == PLTelnetControlCode_ESC) ? YES : NO;
}

- (void)parse:(NSData *)data withBlock:(PLTelnetCSIParseBlock)block
{
    __block NSData* CSI = nil;
    
    __block NSArray* params = nil;
    
    __block NSString* mode = nil;
    
    __block NSData* value = nil;
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        
        if (byteRange.length == 1) {
        
            CSI = [NSData dataWithBytesNoCopy:(void *)data.bytes length:1 freeWhenDone:NO];
            
            *stop = YES;
            
            return;
        
        }
        
        uint8_t firstByte = ((uint8_t *)bytes)[1];
        
        switch (firstByte) {
            
            // [
            case 91:
            {
                NSInteger modeIndex = -1;
                
                for (size_t i = 2; i < byteRange.length; i++) {
                    
                    uint8_t modeByte = ((uint8_t *)bytes)[i];
                    
                    if (modeByte > 59) {
                        
                        modeIndex = i;
                        
                        break;
                        
                    }
                    
                }
                
                if (modeIndex == -1) {
                    
                    CSI = [NSData dataWithBytesNoCopy:(void *)data.bytes length:data.length freeWhenDone:NO];
                    
                    *stop = YES;
                    
                    return;
                    
                }
                
                NSInteger endIndex = (modeIndex + 1 < byteRange.length) ? -1 : modeIndex + 1;
                
                for (size_t i = modeIndex + 1; i < byteRange.length; i++) {
                    
                    uint8_t endByte = ((uint8_t *)bytes)[i];
                    
                    if (endByte == 27 || endByte == 255) {
                        
                        endIndex = i;
                        
                        break;
                        
                    }
                    
                }
                
                if (endIndex == -1) {
                    
                    CSI = [NSData dataWithBytesNoCopy:(void *)data.bytes length:data.length freeWhenDone:NO];
                    
                    params = [NSArray arrayWithArray:[[[NSString alloc] initWithBytes:(bytes + 2) length:(modeIndex - 2) encoding:NSASCIIStringEncoding] componentsSeparatedByString:@";"]];
                    
                    mode = [[NSString alloc] initWithBytes:(bytes + modeIndex) length:1 encoding:NSASCIIStringEncoding];
                    
                    value = [NSData dataWithBytesNoCopy:(void *)(bytes + modeIndex + 1) length:(byteRange.length - modeIndex - 1) freeWhenDone:NO];
                    
                    *stop = YES;
                    
                    return;
                    
                }
                
                CSI = [NSData dataWithBytesNoCopy:(void *)(bytes) length:(endIndex) freeWhenDone:NO];
                
                params = [NSArray arrayWithArray:[[[NSString alloc] initWithBytes:(bytes + 2) length:(modeIndex - 2) encoding:NSASCIIStringEncoding] componentsSeparatedByString:@";"]];
                
                mode = [[NSString alloc] initWithBytes:(bytes + modeIndex) length:1 encoding:NSASCIIStringEncoding];
                
                if (modeIndex < endIndex) {
                    
                    value = [NSData dataWithBytesNoCopy:(void *)(bytes + modeIndex + 1) length:(endIndex - modeIndex - 1) freeWhenDone:NO];
                    
                }
                
            }
                break;
                
            default:
                
                NSLog(@"data: %@", data);
                
                NSAssert(false, @"Need to Implmenet");
                
                break;
        }
        
    }];
    
    block(CSI, params, mode, value);
}

- (void)screen:(PLTelnetScreenObject *)screen process:(NSData *)data withParams:(NSArray *)params withMode:(NSString *)mode withValue:(NSData *)value
{
    //NSLog(@"found value: %@, %@, mode: %@", [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding], value, mode);
    
    if (data.length == 1 && ((uint8_t *)data.bytes)[0] == 27) {
        
        NSAssert(false, @"Need to implmenet");
        
    }
    
    // attribute
    if ([mode isEqualToString:@"m"]) {
        
        
        
    }
    
    // cursor position
    else if ([mode isEqualToString:@"H"]) {
        
        // [ 0 H => move the cursor to (1, 1)
        if (params == nil || params.count == 0 || (params.count == 1 && [(NSString *)params[0] isEqualToString:@""])) {
            
            screen.currentColumn = 1;
            
            screen.currentRow = 1;
            
        }
        
        // [ R ; C H => move the cursor to (C, R)
        else if (params != nil && params.count == 2) {
            
            screen.currentRow = [(NSString *)params[0] integerValue];
            
            screen.currentColumn = [(NSString *)params[1] integerValue];
            
        }
        
    }
    
    // Erasing Screen
    else if ([mode isEqualToString:@"J"]) {
        
        // [ 0 J => clean screen from current position to end of screen
        if (params == nil || params.count == 0 || (params.count == 1 && [(NSString *)params[0] isEqualToString:@""])) {
            
            NSUInteger row = screen.currentRow;
            
            NSUInteger column = screen.currentColumn;
            
            while (row <= PLTelnetRowHeight) {
                
                [screen setCharacter:32 InRow:row column:column];
                
                column++;
                
                if (column > PLTelnetColumnWidth) {
                    
                    column = 1;
                    
                    row++;
                    
                }
                
            }
            
        }
        
        // [ 1 J => clean screen from beginning of scrren to current position
        else if (params == nil || params.count == 0 || (params.count == 1 && [(NSString *)params[0] isEqualToString:@"1"])) {
            
            NSUInteger row = 1;
            
            NSUInteger column = 1;
            
            while (row <= screen.currentRow && column <= screen.currentColumn) {
                
                [screen setCharacter:32 InRow:row column:column];
                
                column++;
                
                if (column > PLTelnetColumnWidth) {
                    
                    column = 1;
                    
                    row++;
                    
                }
                
            }
            
        }
        
        // [ 2 J => clean whole screen
        else if (params == nil || params.count == 0 || (params.count == 1 && [(NSString *)params[0] isEqualToString:@"2"])) {
            
            NSUInteger row = 1;
            
            NSUInteger column = 1;
            
            while (row <= PLTelnetRowHeight && column <= PLTelnetColumnWidth) {
                
                [screen setCharacter:32 InRow:row column:column];
                
                column++;
                
                if (column > PLTelnetColumnWidth) {
                    
                    column = 1;
                    
                    row++;
                    
                }
                
            }
            
        }
        
    }
    
    // Erasing Screen
    else if ([mode isEqualToString:@"K"]) {
        
        // [ 0 K => clear line from current position to end of line
        if (params == nil || params.count == 0 || (params.count == 1 && [(NSString *)params[0] isEqualToString:@""])) {
            
            for (NSUInteger column = screen.currentColumn; column <= PLTelnetColumnWidth; column++) {
                
                [screen setCharacter:32 InRow:screen.currentRow column:column];
                
            }
            
        }
        
        // [ 1 K => clear line from beginning of line to current position
        else if (params != nil && params.count == 1 && [(NSString *)params[0] isEqualToString:@"1"]) {
            
            for (NSUInteger column = 1; column <= screen.currentColumn; column++) {
                
                [screen setCharacter:32 InRow:screen.currentRow column:column];
                
            }
            
        }
        
        // [ 2 K => clean whole line of current position
        else if (params != nil && params.count == 1 && [(NSString *)params[0] isEqualToString:@"2"]) {
            
            for (NSUInteger column = 1; column <= PLTelnetColumnWidth; column++) {
                
                [screen setCharacter:32 InRow:screen.currentRow column:column];
                
            }
            
        }
        
    }
    
    else {
        
        NSLog(@"unknown mode: %@", mode);
        
        NSAssert(false, @"Need to implmenet");
        
    }
    
    [screen textProcess:value];
}

@end
