//
//  PLTelnetClient.m
//  PLTelnetLite
//
//  Created by Patrick on 8/12/15.
//  Copyright (c) 2015 Patrick Lin. All rights reserved.
//

#import "PLTelnetClient.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>

static const NSTimeInterval     PLTelnetLite_Timeout        = 3;
static const NSInteger          PLTelnetLite_Retry_Count    = 6;
static const NSTimeInterval     PLTelnetLite_Retry_Delay    = 0.5;

@interface GCDAsyncSocket(PLTelnetClient)



@end

@implementation GCDAsyncSocket(PLTelnetClient)

- (void)test {
    self->socketFDBytesAvailable
}

@end

@interface PLTelnetClient() <GCDAsyncSocketDelegate>
{
    long                _readSequence;
    
    long                _writeSequence;
    
    dispatch_queue_t    _delegate_queue;
    
    GCDAsyncSocket*     _socket;
    
    NSMutableData*      _readData;
}

@property(strong, nonatomic)NSMutableData* readData;

@end

@implementation PLTelnetClient

@synthesize readData=_readData;

#pragma mark - Socket Delegate Methods

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        @autoreleasepool {
        
            if (_delegate != nil && [_delegate respondsToSelector:@selector(telnetClient:didConnectToHost:onPort:)]) {
                
                [_delegate telnetClient:self didConnectToHost:host onPort:port];
                
            }
            
            [sock readDataWithTimeout:PLTelnetLite_Timeout buffer:self.readData bufferOffset:self.readData.length tag:_readSequence++];
        
        }
        
    });
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        @autoreleasepool {
            
            if (_delegate != nil && [_delegate respondsToSelector:@selector(telnetClient:didDisconnectWithError:)]) {
                
                [_delegate telnetClient:self didDisconnectWithError:err];
                
            }
            
        }
        
    });
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSLog(@"didReadData data length: %ld, tag: %ld", data.length, tag);
        
        NSInteger counts = 0;
        
        __block BOOL hasBytesAvailable = NO;
        
        while (!hasBytesAvailable && counts <= PLTelnetLite_Retry_Count) {
            
            dispatch_semaphore_t read_task = dispatch_semaphore_create(0);
            
            [sock performBlock:^{
                
                if (CFReadStreamHasBytesAvailable(sock.readStream)) {
                    
                    hasBytesAvailable = YES;
                    
                    dispatch_semaphore_signal(read_task);
                    
                }
                
                NSLog(@"has data: %@", (hasBytesAvailable) ? @"YES" : @"NO");
                
            }];
            
            dispatch_semaphore_wait(read_task, dispatch_time(DISPATCH_TIME_NOW, PLTelnetLite_Retry_Delay * 1000 * NSEC_PER_MSEC));
            
            counts++;
        }
        
        if (hasBytesAvailable == YES) {
            
            [sock readDataWithTimeout:PLTelnetLite_Timeout buffer:self.readData bufferOffset:self.readData.length tag:tag];
            
            return;
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (_delegate != nil && [_delegate respondsToSelector:@selector(telnetClient:didReceiveData:)]) {
                
                @autoreleasepool {
                    
                    [_delegate telnetClient:self didReceiveData:self.readData];
                    
                }
                
            }
            
        });
        
    });
}

#pragma mark - Internal Methods

- (NSMutableData *)readData
{
    if (!_readData) {
        
        _readData = [NSMutableData data];
        
    }
    
    return _readData;
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
        
        _delegate_queue = dispatch_queue_create("com.patricksclin.PLTelnetLite.delegate", DISPATCH_QUEUE_SERIAL);
        
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_delegate_queue];
        
    }
    
    return self;
}

+ (id)clientWithDelegate:(id<PLTelnetClientDelegate>)delegate
{
    return [[PLTelnetClient alloc] initWithDelegate:delegate];
}

@end
