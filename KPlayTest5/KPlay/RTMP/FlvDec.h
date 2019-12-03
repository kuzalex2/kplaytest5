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
    @property KMediaSample *sample;

    -(int64_t)duration;

    -(KResult) parseRtmp:(RTMPPacket *)p;

    

@end

//typedef struct FlvStream {
//    
//    CMFormatDescriptionRef format;
//    uint8_t *data;
//    uint32_t data_size;
//    
//} FlvPacket;
//
//KResult parsePacket(RTMPPacket *p, FlvPacket *f);

NS_ASSUME_NONNULL_END
