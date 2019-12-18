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

//    - (instancetype)initEOS
//    {
//        self = [super init];
//        if (self) {
//            CMTime
//        }
//        return self;
//    }

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
//        if (someFormat!=nil)
//            CFRetain(someFormat);
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

//    - (BOOL) isEqual:(KMediaType *) type
//    {
//        if (type==nil)
//            return false;
//        if (_name==nil || type.name==nil)
//            return false;
//        if (! [_name isEqualToString:type.name] )
//            return false;
//    
//        if (_format == NULL && type->_format == NULL)
//            return TRUE;
//        return CMFormatDescriptionEqual(_format,type->_format);
//    }
@end


@implementation KMediaTypeImageBuffer
@end




@implementation KMediaSample
- (instancetype)init
{
    self = [super init];
    if (self) {
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
    return [NSString stringWithFormat:@"<KMediaSample: %p, ts=%lld/%d, data={sz=%d}>",
            (void*)self, self.ts.value, self.ts.timescale, self.data!=nil?(int)self.data.length:-1];
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


