//
//  WavReader.h
//  KPlayTest5
//
//  Created by kuzalex on 11/30/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <AudioToolbox/AudioToolbox.h>
#include "KPin.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum WavReaderState {
    WavReaderStateNone,
    WavReaderState1,
    WavReaderState2,
    WavReaderStateSample
} WavReaderState;

@interface WavReader : NSObject
    @property WavReaderState state;
    -(int64_t)getNextBytesToRead:(int64_t)position;
    //@property (nonatomic) int64_t nextBytesToRead;
    @property (nonatomic) int64_t dataSize;
    @property (nonatomic) CMTime duration;
    @property AudioStreamBasicDescription format;

    -(KResult)parseData:(NSData *)data;
    -(void)reset;
@end

NS_ASSUME_NONNULL_END
