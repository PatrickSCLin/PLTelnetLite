//
//  PLTelnetScreenHandler.m
//  PLTelnetLite
//
//  Created by Patrick on 6/9/15.
//  Copyright (c) 2015 Patrick Lin. All rights reserved.
//

#import "PLTelnetScreenObject.h"
#import <unicode/uchar.h>

const NSUInteger PLTelnetColumnWidth    = 80;
const NSUInteger PLTelnetRowHeight      = 24;

@interface PLTelnetScreenObject()
{
    unichar screen[PLTelnetRowHeight][PLTelnetColumnWidth];
}

@end

@implementation PLTelnetScreenObject

- (void)textProcess:(NSData *)data
{
    if (data == nil) { return; }

    __block NSString* text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (text == nil && _expectedStringEncodings != nil) {
        
        [_expectedStringEncodings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            NSStringEncoding stringEncoding = CFStringConvertEncodingToNSStringEncoding([(NSNumber *)obj unsignedIntValue]);
            
            text = [[NSString alloc] initWithData:data encoding:stringEncoding];
            
            if (text) {

                *stop = YES;
                
                return;
            
            }
            
        }];
        
    }
    
    if (text == nil ) { return; }
    
    size_t length = [text length];
    
    for (int i = 0; i < length; i++) {
        
        unichar word = [text characterAtIndex:i];
        
        // 0: null
        if (word == 0) {
            
            continue;
            
        }
        
        // 8: backspace
        if (word == 8) {
            
            self.currentColumn--;
            
            continue;
            
        }
        
        // 10: newline
        if (word == 10) {
            
            self.currentRow++;
            
            continue;
            
        }
        
        // 13: CR
        if (word == 13) {
            
            self.currentColumn = 1;
            
            continue;
            
        }
        
        if ([self isFullWidth:word]) {
            
            screen[self.currentRow - 1][self.currentColumn - 1] = word;
            
            screen[self.currentRow - 1][self.currentColumn] = 0;
            
            self.currentColumn = self.currentColumn + 2;
             
        }
        
        else {
            
            BOOL isValidRow = (self.currentRow >= 1 && self.currentRow <= PLTelnetRowHeight) ? YES : NO;
            
            BOOL isValidColumn = (self.currentColumn >= 1 && self.currentColumn <= PLTelnetColumnWidth) ? YES : NO;
            
            if (isValidRow && isValidColumn) {
                
                screen[self.currentRow - 1][self.currentColumn - 1] = word;
                
            }
            
            self.currentColumn++;
            
        }
        
    }
}

#pragma mark - Private Methods

- (BOOL)isFullWidth:(unichar)character
{
    int width = u_getIntPropertyValue(character, UCHAR_EAST_ASIAN_WIDTH);
    
    return width == U_EA_FULLWIDTH || width == U_EA_WIDE;
}

#pragma mark - Public Methods

- (void)setCharacter:(unichar)character InRow:(NSUInteger)row column:(NSUInteger)column
{
    screen[row - 1][column - 1] = character;
}

- (void)resetScreen
{
    for (size_t row = 0; row < PLTelnetRowHeight; row++) {
        
        for (size_t column = 0; column < PLTelnetColumnWidth; column++) {
            
            screen[row][column] = 32;
            
        }
        
    }
}

- (void)printScreen
{
    printf("\n====================================================================================================\n");
    
    for (NSUInteger row = 0; row < PLTelnetRowHeight; row++) {
        
        NSMutableString* line = [NSMutableString string];
        
        for (NSUInteger column = 0; column < PLTelnetColumnWidth; column++) {
            
            if (screen[row][column] == 0) {
                
                continue;
                
            }
            
            NSString* word = [NSString stringWithCharacters:&(screen[row][column]) length:1];
            
            [line appendString:word];
            
        }
        
        printf("#%-10u %-100s\n", (uint)(row + 1), [line UTF8String]);
        
    }
    
    printf("====================================================================================================\n\n\n\n");
}

- (NSString *)screenContentInRow:(NSUInteger)row
{
    NSMutableString* content = [NSMutableString string];
    
    for (NSUInteger column = 1; column <= PLTelnetColumnWidth; column++) {
        
        if (screen[row - 1][column - 1] == 0) {
            
            continue;
            
        }
        
        NSString* word = [NSString stringWithCharacters:&(screen[row - 1][column - 1]) length:1];
        
        [content appendString:word];
        
    }
    
    return content;
}

- (NSString *)screenContent
{
    NSMutableString* content = [NSMutableString string];
    
    for (NSUInteger row = 1; row <= PLTelnetRowHeight; row++) {
        
        NSString* line = [self screenContentInRow:row];
        
        [content appendFormat:@"%@\n", line];
        
    }
    
    return content;
}

#pragma mark - Init Mehtods

- (id)init
{
    if (self = [super init]) {
        
        _currentRow = 1;
        
        _currentColumn = 1;
        
        [self resetScreen];
        
    }
    
    return self;
}

@end

