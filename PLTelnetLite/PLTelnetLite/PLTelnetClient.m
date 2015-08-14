//
//  PLTelnetClient.m
//  PLTelnetLite
//
//  Created by Patrick on 8/12/15.
//  Copyright (c) 2015 Patrick Lin. All rights reserved.
//

#import "PLTelnetClient.h"
#import <CocoaAsyncSocket/AsyncSocket.h>
#import "PLTelnetScreenObject.h"
#import "PLTelnetIACHandler.h"
#import "PLTelnetVT100Handler.h"

static const NSTimeInterval     PLTelnetLite_Timeout        = 5;
static const NSTimeInterval     PLTelnetLite_Retry_Delay    = 0.2;
static const NSInteger          PLTelnetLite_Retry_Count    = 3;

@interface AsyncSocket(PLTelnetClient)

@end

@implementation AsyncSocket(PLTelnetClient)

@end

@interface PLTelnetClient() <AsyncSocketDelegate>
{
    long                _readSequence;
    
    long                _writeSequence;
    
    AsyncSocket*        _socket;
    
    NSMutableData*      _readData;
}

@property(strong, nonatomic)NSMutableData* readData;

@end

@implementation PLTelnetClient

@synthesize readData=_readData;

#pragma mark - Socket Delegate Methods

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        @autoreleasepool {
        
            if (_delegate != nil && [_delegate respondsToSelector:@selector(telnetClient:didConnectToHost:onPort:)]) {
                
                [_delegate telnetClient:self didConnectToHost:host onPort:port];
                
            }
            
            [sock readDataWithTimeout:self.timeout buffer:self.readData bufferOffset:self.readData.length tag:_readSequence++];
        
        }
        
    });
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        @autoreleasepool {
            
            if (_delegate != nil && [_delegate respondsToSelector:@selector(telnetClient:didDisconnectWithError:)]) {
                
                [_delegate telnetClient:self didDisconnectWithError:err];
                
            }
            
        }
        
    });
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    @autoreleasepool {
        
        [self parse:data];
        
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PLTelnetLite_Retry_Delay * 1000 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        
        NSInteger counts = 0;
        
        __block BOOL hasBytesAvailable = NO;
        
        while (!hasBytesAvailable && counts <= PLTelnetLite_Retry_Count) {
            
            dispatch_semaphore_t read_task = dispatch_semaphore_create(0);
            
            if (CFReadStreamHasBytesAvailable(sock.getCFReadStream)) {
                
                hasBytesAvailable = YES;
                
                dispatch_semaphore_signal(read_task);
                
            }
            
            dispatch_semaphore_wait(read_task, dispatch_time(DISPATCH_TIME_NOW, PLTelnetLite_Retry_Delay * 1000 * NSEC_PER_MSEC));
            
            counts++;
        }
        
        if (hasBytesAvailable == YES) {
            
            [sock readDataWithTimeout:self.timeout buffer:self.readData bufferOffset:self.readData.length tag:tag];
            
            return;
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (_delegate != nil && [_delegate respondsToSelector:@selector(telnetClient:didReceiveData:)]) {
                
                @autoreleasepool {
                    
                    [_delegate telnetClient:self didReceiveData:self.readData];
                    
                    [self.readData setLength:0];
                    
                }
                
            }
            
        });
        
    });
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    [_socket readDataWithTimeout:self.timeout buffer:self.readData bufferOffset:self.readData.length tag:_readSequence++];
}

#pragma mark - Internal Methods

- (NSMutableData *)readData
{
    if (!_readData) {
        
        _readData = [NSMutableData data];
        
    }
    
    return _readData;
}

- (void)parse:(NSData *)parseData
{
    NSMutableData* temp_readData = [NSMutableData dataWithBytes:parseData.bytes length:parseData.length];
    
    NSData* buffer = [NSData dataWithBytes:parseData.bytes length:parseData.length];
    
    [buffer enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        
        __block size_t start = 0;
        
        for (__block size_t i = 0; i < byteRange.length; i++) {
            
            @autoreleasepool {
            
                uint8_t byte = ((uint8_t *)bytes)[i];
                
                // IAC Handler
                if (_IACHandler != nil && [_IACHandler isIACCode:byte]) {
                    
                    void* offsetBytes = (void *)bytes + i;
                    
                    NSUInteger offsetLength = byteRange.length - i;
                    
                    NSData* data = [NSData dataWithBytesNoCopy:offsetBytes length:offsetLength freeWhenDone:NO];
                    
                    [_IACHandler parse:data withBlock:^(NSData* IAC) {
                        
                        if (IAC != nil && IAC.length > 0) {
                            
                            [temp_readData replaceBytesInRange:NSMakeRange(0, (i - start) + IAC.length) withBytes:NULL length:0];
                            
                            if (_delegate != nil && [_delegate respondsToSelector:@selector(telnetClient:didReceiveIAC:)]) {
                                
                                [_delegate telnetClient:self didReceiveIAC:IAC];
                                
                            }
                            
                            i += (IAC.length - 1);
                            
                            start = i + 1;
                            
                        }
                        
                    }];
                    
                    data = nil;
                    
                }
                
                // CSI Handler
                else if (_CSIHandler != nil && [_CSIHandler isCSICode:byte]) {
                    
                    void* offsetBytes = (void *)bytes + i;
                    
                    NSUInteger offsetLength = byteRange.length - i;
                    
                    NSData* data = [NSData dataWithBytesNoCopy:offsetBytes length:offsetLength freeWhenDone:NO];
                    
                    [_CSIHandler parse:data withBlock:^(NSData *CSI, NSArray *params, NSString *mode, NSData *value) {
                        
                        if (CSI != nil && mode != nil) {
                            
                            [temp_readData replaceBytesInRange:NSMakeRange(0, (i - start) + CSI.length) withBytes:NULL length:0];
                            
                            [_CSIHandler screen:_screen process:CSI withParams:params withMode:mode withValue:value];
                            
                            if (_delegate != nil && [_delegate respondsToSelector:@selector(telnetClient:didReceiveCSI:withParams:withMode:withValue:)]) {
                                
                                [_delegate telnetClient:self didReceiveCSI:CSI withParams:params withMode:mode withValue:value];
                                
                            }
                            
                            i += (CSI.length - 1);
                            
                            start = i + 1;
                            
                        }
                        
                    }];
                    
                    data = nil;
                    
                }
                
            }
            
        }
        
    }];
    
    [temp_readData setLength:0];
    
    temp_readData = nil;
    
    buffer = nil;
}

- (void)setExpectedStringEncodings:(NSArray *)expectedStringEncodings
{
    _screen.expectedStringEncodings = expectedStringEncodings;
}

- (NSArray *)expectedStringEncodings
{
    return _screen.expectedStringEncodings;
}

#pragma mark - Public Methods

- (BOOL)connectToHost:(NSString *)host onPort:(NSUInteger)port
{
    return [_socket connectToHost:host onPort:port error:nil];
}

- (void)disconnect
{
    [_socket disconnect];
}

- (void)sendData:(NSData *)data
{
    [_socket writeData:data withTimeout:self.timeout tag:_writeSequence++];
}

#pragma mark - Init Methods

- (id)init
{
    return [self initWithDelegate:nil];
}

- (id)initWithDelegate:(id<PLTelnetClientDelegate>)delegate
{
    if (self = [super init]) {
        
        _delegate = delegate;
        
        _timeout = PLTelnetLite_Timeout;
        
        _IACHandler = [[PLTelnetIACHandler alloc] init];
        
        _CSIHandler = [[PLTelnetVT100Handler alloc] init];
        
        _socket = [[AsyncSocket alloc] initWithDelegate:self];
        
        _screen = [[PLTelnetScreenObject alloc] init];
        
    }
    
    return self;
}

+ (id)clientWithDelegate:(id<PLTelnetClientDelegate>)delegate
{
    return [[PLTelnetClient alloc] initWithDelegate:delegate];
}

@end
