//
//  KMediaSample.m
//  KPlayer
//
//  Created by test name on 15.04.2019.
//  Copyright © 2019 kuzalex. All rights reserved.
//

//#define MYDEBUG
#include "myDebug.h"

#import "KMediaSample.h"


@implementation KMediaType {
    CMFormatDescriptionRef _format;
}

    -(CMFormatDescriptionRef)format
    {
        return _format;
    }

    -(void) setFormat: (CMFormatDescriptionRef)someFormat
    {
        if (_format!=nil){
            CFRelease(_format);
        }
        _format = someFormat;
    }
    -(void)dealloc
    {
        if (_format!=nil)
            CFRelease(_format);
        DLog(@"dealloc format");
    }

    - (instancetype)initWithName:(NSString *)name
    {
        self = [super init];
        if (self) {
            if (name!=nil){
                _name = [NSString stringWithString:name];
            }
        
        }
        return self;
    }
@end


@implementation KMediaTypeImageBuffer
@end




@implementation KMediaSample
- (instancetype)init
{
    self = [super init];
    if (self) {
        self->_key = TRUE;
        DLog(@"init sample %@", self);
    }
    return self;
}
-(void)dealloc
{
    DLog(@"dealloc sample %@", self);
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<KMediaSample: %p, key=%d, ts=%lld/%d, data={sz=%d}>",
            (void*)self, (int)self.key, self.ts.value, self.ts.timescale, self.data!=nil?(int)self.data.length:-1];
}

@end

@implementation KMediaSampleImageBuffer
{
    CVImageBufferRef _image;
}

    -(CVImageBufferRef)image
    {
        return _image;
    }

    -(void) setImage: (CVImageBufferRef)someImage
    {
        _image = someImage;
        if (someImage!=nil)
            CFRetain(someImage);
    }
    -(void)dealloc
    {
        if (_image!=nil)
            CFRelease(_image);
        DLog(@"dealloc sample");
        
    }
    -(NSString *)description
    {
        return [NSString stringWithFormat:@"<KMediaSampleImageBuffer: %p, ts=%lld/%d>",
                     (void*)self, self.ts.value, self.ts.timescale];
    }
@end

@implementation KMediaSampleText
@end

@implementation KMediaSampleSegmentDescriptor
@end


