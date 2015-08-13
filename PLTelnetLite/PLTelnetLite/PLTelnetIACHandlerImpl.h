//
//  PLTelnetIACHandlerImpl.h
//  PLTelnetLite
//
//  Created by Patrick Lin on 6/7/15.
//  Copyright (c) 2015 Patrick Lin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(unsigned char, PLTelnetCommand) {
    
    PLTelnetCommand_SE = 240, // End of subnegotiation parameters
    PLTelnetCommand_NOP = 241, // No operation
    PLTelnetCommand_DM = 242, // Data mark - Indicates the position of a Synch event within the data stream. This should always be accompanied by a TCP urgent notification.
    PLTelnetCommand_BRK = 243, // Break - Indicates that the "break" or "attention" key was hi.
    PLTelnetCommand_IP = 244, // Suspend - Interrupt or abort the process to which the NVT is connected.
    PLTelnetCommand_AO = 245, // Abort output - Allows the current process to run to completion but does not send its output to the user.
    PLTelnetCommand_AYT = 246, // Are you there - Send back to the NVT some visible evidence that the AYT was received.
    PLTelnetCommand_EC = 247, // Erase character - The receiver should delete the last preceding undeleted character from the data stream.
    PLTelnetCommand_EL = 248, // Erase line - Delete characters from the data stream back to but not including the previous CRLF.
    PLTelnetCommand_GA = 249, // Go ahead - Under certain circumstances used to tell the other end that it can transmit.
    PLTelnetCommand_SB = 250, // Subnegotiation - Subnegotiation of the indicated option follows.
    PLTelnetCommand_WILL = 251, // will - Indicates the desire to begin performing, or confirmation that you are now performing, the indicated option.
    PLTelnetCommand_WONT = 252, // wont - Indicates the refusal to perform, or continue performing, the indicated option.
    PLTelnetCommand_DO = 253, // do - Indicates the request that the other party perform, or confirmation that you are expecting the other party to perform, the indicated option.
    PLTelnetCommand_DONT = 254, // dont - Indicates the demand that the other party stop performing, or confirmation that you are no longer expecting the other party to perform, the indicated option.
    PLTelnetCommand_IAC = 255 // Interpret as command - Interpret as a command
    
};

typedef void (^PLTelnetIACParseBlock)(NSData* IAC);

@protocol PLTelnetIACHandlerImpl <NSObject>

@required

- (BOOL)isIACCode:(uint8_t)byte;

- (void)parse:(NSData *)data withBlock:(PLTelnetIACParseBlock)block;

@end
