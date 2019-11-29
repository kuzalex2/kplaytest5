//
//  KMediaSample.h
//  KPlayer
//
//  Created by test name on 15.04.2019.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CoreMedia/CMFormatDescription.h>

NS_ASSUME_NONNULL_BEGIN

@interface KMediaType : NSObject
    - (instancetype)initWithName:(NSString *)name;

    @property (readonly, nonatomic, retain) NSString *name;
    @property (nonatomic)  CMFormatDescriptionRef format;
   // - (BOOL) isEqual:(KMediaType *) type;
@end

@interface KMediaTypeImageBuffer : KMediaType
    @property CMVideoDimensions dimension;
@end

@interface KMediaSample : NSObject
    @property (nonatomic, retain) KMediaType *type;
    @property (nonatomic, retain) NSData *data;
    @property (nonatomic)        int64_t ts;
    @property (nonatomic)        int32_t timescale;
    @property (nonatomic)  BOOL discontinuity;
@end

@interface KMediaSampleImageBuffer : KMediaSample
    @property (nonatomic)  CVImageBufferRef image;
@end

@interface KMediaSampleText : KMediaSample
    @property (nonatomic)  NSString *text;
@end

@interface KMediaSampleSegmentDescriptor : KMediaSample
    @property (nonatomic)  NSString *url;

// range
// duration
// ...
@end


NS_ASSUME_NONNULL_END
