//
//  KPin.h
//  KPlayer
//
//  Created by test name on 15.04.2019.
//  Copyright © 2019 Instreamatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KMediaSample.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum
{
    KResult_OK,
   // KResult_INTERRUPTED,
    KResult_InvalidState,
    KResult_ERROR,
  //  KResult_NOSAMPLE
} KResult;

NSError *KResult2Error(KResult res);

@class KFilter;

@interface KPin : NSObject
    -(instancetype)initWithFilter:(KFilter *)filter;
    -(BOOL)connectTo:(KPin *)sink;
    -(BOOL)isMediaTypeSupported:(KMediaType *) type;

    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError **)error;

@end

@interface KInputPin : KPin
    -(BOOL)isMediaTypeSupported:(KMediaType *) type;
    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *_Nonnull*_Nullable)error;
@end


@interface KOutputPin : KPin
    -(BOOL)connectTo:(KPin *)sink;
    -(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError **)error;
@end


NS_ASSUME_NONNULL_END