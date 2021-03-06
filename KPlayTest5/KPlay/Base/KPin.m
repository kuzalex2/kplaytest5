//
//  KPin.m
//  KPlayer
//
//  Created by test name on 15.04.2019.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KPin.h"
#import "KFilter.h"

#import "myDebug.h"


NSError *KResult2Error(KResult res)
{
    NSString *errorCode = nil;
    
    switch (res) {
        case KResult_OK:
            errorCode = [NSString stringWithFormat:@"No Error"];
            break;
        case KResult_InvalidState:
            errorCode = [NSString stringWithFormat:@"Invalid state"];
            break;
        case KResult_ERROR:
            errorCode = [NSString stringWithFormat:@"Error"];
         break;
        case KResult_ParseError:
            errorCode = [NSString stringWithFormat:@"Parse Error"];
            break;
        case KResult_UnsupportedFormat:
            errorCode = [NSString stringWithFormat:@"Unsupported format"];
            break;
        case KResult_RTMP_ConnectFailed:
            errorCode = [NSString stringWithFormat:@"RTMP Connection Failed"];
            break;
        case KResult_RTMP_ReadFailed:
            errorCode = [NSString stringWithFormat:@"RTMP Read Failed"];
            break;
        case KResult_RTMP_Disconnected:
            errorCode = [NSString stringWithFormat:@"RTMP Disconnected"];
            break;
//        case KResult_EOS:
//            errorCode = [NSString stringWithFormat:@"EOS"];
//            break;
        
    }
    return [NSError errorWithDomain:@"KPlay"
                        code:res
                        userInfo:@{
                            NSLocalizedDescriptionKey:errorCode
    }];
}

@interface KPin() {
@protected
    __weak KPin *_peer;
    __weak KFilter *_filter;
}
@end

@implementation KPin

-(instancetype)initWithFilter:(KFilter *)filter
{
    self = [super init];
    if (self) {
        _filter=filter;
    }
    return self;
}

-(BOOL)connectTo:(KPin *)sink
{
    _peer = sink;
    sink->_peer = self;
    
    return TRUE;
}

-(BOOL)disconnect
{
    if (_peer){
        _peer->_peer = nil;
        _peer = nil;
    }
    
    return TRUE;
}

-(BOOL)isMediaTypeSupported:(KMediaType *) type
{
    return FALSE;
}



-(KResult)pullSample:(KMediaSample **)sample probe:(BOOL)probe error:(NSError *__strong*)error
{
    return KResult_ERROR;
}


@end










@implementation KInputPin




-(KResult)pullSample:(KMediaSample **)sample probe:(BOOL)probe error:(NSError *__strong*)error
{
    if (_peer==nil)
        return KResult_ERROR;
    
    return [_peer pullSample:sample probe:probe error:error];
}


-(BOOL)isMediaTypeSupported:(KMediaType *) type
{
    if (_filter==nil)
        return FALSE;
    
    return [_filter isInputMediaTypeSupported:type];
}

@end








#import <pthread.h>


@implementation KOutputPin {
    pthread_mutex_t _pull_lock;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        pthread_mutex_init(&self->_pull_lock, NULL);
    }
    return self;
}

-(void)lockPull
{
    pthread_mutex_lock(&_pull_lock);
    
}
-(void)unlockPull
{
    pthread_mutex_unlock(&_pull_lock);
}

/*
-(instancetype)initWithFilter:(KFilter *)filter andType:(KMediaType *) type
{
    self = [super initWithFilter:filter];
    if (self) {
        _type = type;
    }
    return self;
}
 */

-(BOOL)connectTo:(KPin *)sink
{
    if (_filter==nil){
        DLog(@"connect failed: filter is null")
        return FALSE;
    }
    
    if (_peer!=nil){
        DLog(@"connect failed: already connected")
        return FALSE;
    }
    
    
    if (![sink isMediaTypeSupported:[_filter getOutputMediaTypeFromPin:self]])
        return FALSE;
    
    return [super connectTo:sink];
}




-(KResult)pullSample:(KMediaSample **)sample probe:(BOOL)probe error:(NSError *__strong*)error
{
    if (_filter==nil)
        return KResult_ERROR;
    
    return [_filter pullSampleInternal:sample probe:probe error:error fromPin:self];
}

@end
