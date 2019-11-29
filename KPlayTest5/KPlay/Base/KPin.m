//
//  KPin.m
//  KPlayer
//
//  Created by test name on 15.04.2019.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KPin.h"
#import "KFilter.h"


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











@implementation KOutputPin

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
    if (_filter==nil)
        return KResult_ERROR;
    
    if (![sink isMediaTypeSupported:[_filter getOutputMediaType]])
        return FALSE;
    
    return [super connectTo:sink];
}




-(KResult)pullSample:(KMediaSample **)sample probe:(BOOL)probe error:(NSError *__strong*)error
{
    if (_filter==nil)
        return KResult_ERROR;
    
    return [_filter pullSample:sample probe:probe error:error];
}

@end
