//
//  PLTelnetScreenHandler.h
//  PLTelnetLite
//
//  Created by Patrick on 6/9/15.
//  Copyright (c) 2015 Patrick Lin. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSUInteger PLTelnetColumnWidth;
extern const NSUInteger PLTelnetRowHeight;

@interface PLTelnetScreenObject : NSObject

@property(assign, nonatomic)NSUInteger currentRow;

@property(assign, nonatomic)NSUInteger currentColumn;

@property(strong, nonatomic)NSArray* expectedStringEncodings;

- (void)textProcess:(NSData *)data;

- (void)setCharacter:(unichar)character InRow:(NSUInteger)row column:(NSUInteger)column;

- (void)resetScreen;

- (void)printScreen;

- (NSString *)screenContentInRow:(NSUInteger)row;

- (NSString *)screenContent;

@end
