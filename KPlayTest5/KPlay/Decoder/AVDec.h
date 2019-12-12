//
//  AVDec.h
//  KPlayTest5
//
//  Created by kuzalex on 12/12/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#ifndef AVDec_h
#define AVDec_h

typedef void(^OnMediaSampleCallback)(KMediaSample *sample);

@protocol AVDec <NSObject>

    @property KMediaType *out_type;
    -(KResult)decodeSample:(KMediaSample *)s andCallback:(OnMediaSampleCallback)onSuccess;
    -(void) flush;
    -(BOOL)isInputMediaTypeSupported:(KMediaType *)type;

@end

#endif /* AVDec_h */
