//
//  PLTelnetEncodingUtils.h
//  PLTelnetLite
//
//  Created by Patrick on 8/14/15.
//  Copyright (c) 2015 Patrick Lin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PLTelnetEncodingUtils : NSObject

+ (BOOL)isBig5inHigh:(unsigned char)high inLow:(unsigned char)low;

+ (unichar)Big5ToUTF8:(unichar)big5Char;

@end
