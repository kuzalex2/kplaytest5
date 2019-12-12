//
//  ADec.h
//  KPlayTest5
//
//  Created by kuzalex on 12/5/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTestFilters.h"
#import "AVDec.h"
#include "KDecoder.h"




NS_ASSUME_NONNULL_BEGIN

@interface KAudioDecoder : KDecoder
    -(id)createDecoder;
@end



@interface ADec : NSObject<AVDec>
//    @property KMediaType *out_type;
//    -(KResult)decodeSample:(KMediaSample *)s andCallback:(OnMediaSampleCallback)onSuccess;
//    -(void) flush;
//    -(BOOL)isInputMediaTypeSupported:(KMediaType *)type;

@end

NS_ASSUME_NONNULL_END

