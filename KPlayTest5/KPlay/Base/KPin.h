//
//  KPin.h
//  KPlayer
//
//  Created by test name on 15.04.2019.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KMediaSample.h"

NS_ASSUME_NONNULL_BEGIN

//#define MKTAG(a,b,c,d) ((a) | ((b) << 8) | ((c) << 16) | ((unsigned)(d) << 24))
#define MKBETAG(a,b,c,d) ((d) | ((c) << 8) | ((b) << 16) | ((unsigned)(a) << 24))

typedef enum
{
    KResult_OK=0,
   // KResult_INTERRUPTED,
    KResult_InvalidState,
    KResult_ERROR,
    KResult_RTMP_ConnectFailed,
    KResult_RTMP_Disconnected,
    KResult_RTMP_ReadFailed,
  //  KResult_NOSAMPLE
    KResult_ParseError,
    KResult_UnsupportedFormat,
   // KResult_EOS
} KResult;

NSError *KResult2Error(KResult res);

@class KFilter;

@interface KPin : NSObject
    -(instancetype)initWithFilter:(KFilter *)filter;
    -(BOOL)connectTo:(KPin *)sink;
    -(BOOL)isMediaTypeSupported:(KMediaType *) type;

    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error;

@end

@interface KInputPin : KPin
    -(BOOL)isMediaTypeSupported:(KMediaType *) type;
    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong _Nonnull*_Nullable)error;
@end


@interface KOutputPin : KPin
    -(void)lockPull;
    -(void)unlockPull;
    -(BOOL)connectTo:(KPin *)sink;
    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error;
@end


NS_ASSUME_NONNULL_END
