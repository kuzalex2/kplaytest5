//
//  VTDec.h
//  KPlayTest5
//
//  Created by kuzalex on 12/4/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTestFilters.h"
#include "KDecoder.h"
#import "AVDec.h"

NS_ASSUME_NONNULL_BEGIN

@interface KVideoDecoder : KDecoder
    -(id)createDecoder;
@end


@interface VTDec : NSObject<AVDec>
//    @property KMediaTypeImageBuffer *out_type;
//    -(KResult)decodeSample:(KMediaSample *)s andCallback:(OnMediaSampleCallback)onSuccess;
//    -(void) flush;
//    -(BOOL)isInputMediaTypeSupported:(KMediaType *)type;

@end

NS_ASSUME_NONNULL_END
