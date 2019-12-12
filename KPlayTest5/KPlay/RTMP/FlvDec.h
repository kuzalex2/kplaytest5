//
//  FlvDec.h
//  KPlayTest5
//
//  Created by kuzalex on 12/3/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CoreMedia/CMFormatDescription.h>
#import "KPin.h"
#include "librtmp/rtmp_sys.h"


NS_ASSUME_NONNULL_BEGIN

@interface FlvStream : NSObject
    @property KMediaType *type;
    @property BOOL eos;
   

    -(KMediaSample *)popSamplewithProbe:(BOOL)probe;
    -(void)flush;

    -(KResult) parseRtmp:(RTMPPacket *)p;

@end


NS_ASSUME_NONNULL_END
