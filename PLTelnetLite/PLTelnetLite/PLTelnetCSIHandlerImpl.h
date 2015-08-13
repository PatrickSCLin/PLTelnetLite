//
//  PLTelnetCSIImpl.h
//  PLTelnetLite
//
//  Created by Patrick Lin on 6/7/15.
//  Copyright (c) 2015 Patrick Lin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLTelnetScreenObject.h"

typedef NS_ENUM(unsigned char, PLTelnetControlCode) {
    
    // Required
    PLTelnetControlCode_NUL = 0, // NULL - No operation
    PLTelnetControlCode_LF = 10,  // Line Feed - Moves the printer to the next print line, keeping the same horizontal position.
    PLTelnetControlCode_CR = 13,  // Carriage Return - Moves the printer to the left margin of the current line.
    
    // Optional
    PLTelnetControlCode_BEL = 7,  // BELL - Produces an audible or visible signal (which does NOT move the print head).
    PLTelnetControlCode_BS = 8,  // Back Space - Moves the print head one character position towards the left margin. (On a printing device, this mechanism was commonly used to form composite characters by printing two basic characters on top of each other.)
    PLTelnetControlCode_HT = 9,  // Horizontal Tab - Moves the printer to the next horizontal tab stop. It remains unspecified how either party determines or establishes where such tab stops are located.
    PLTelnetControlCode_VT = 11,  // Vertical Tab - Moves the printer to the next vertical tab stop. It remains unspecified how either party determines or establishes where such tab stops are located.
    PLTelnetControlCode_FF = 12,  // Form Feed - Moves the printer to the top of the next page, keeping the same horizontal position. (On visual displays, this commonly clears the screen and moves the cursor to the top left corner.)
    PLTelnetControlCode_ESC = 27, // ESC
    
};

typedef void (^PLTelnetCSIParseBlock)(NSData* CSI, NSArray* params, NSString* mode, NSData* value);

@protocol PLTelnetCSIHandlerImpl <NSObject>

@required

- (BOOL)isCSICode:(uint8_t)byte;

- (void)parse:(NSData *)data withBlock:(PLTelnetCSIParseBlock)block;

- (void)screen:(PLTelnetScreenObject *)screen process:(NSData *)data withParams:(NSArray *)params withMode:(NSString *)mode withValue:(NSData *)value;

@end
