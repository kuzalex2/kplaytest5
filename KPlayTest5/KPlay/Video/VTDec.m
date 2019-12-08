//
//  VTDec.m
//  KPlayTest5
//
//  Created by kuzalex on 12/4/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "VTDec.h"
#import "KTestFilters.h"

//#define MYDEBUG
//#define MYWARN
#include "myDebug.h"



#import <VideoToolbox/VideoToolbox.h>
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

typedef void(^OnMediaSampleCallback)(KMediaSample *sample);

@implementation VTDec
{
    
    KMediaType *last_type;
    
    VTDecompressionSessionRef session;
    OnMediaSampleCallback onMediaSample;
}



- (void) flush
{
    if( session ) {
        VTDecompressionSessionInvalidate(session);
        CFRelease(session);
    }
    last_type=nil;
    session=nil;
}

- (void)dealloc
{
    if( session ) {
        VTDecompressionSessionInvalidate(session);
        CFRelease(session);
    }
}



-(BOOL)isInputMediaTypeSupported:(KMediaType *)type
{
    if (type.name!=nil && [type.name compare:@"video"]>=0)
    {
        CMFormatDescriptionRef format = [type format];
        if (format==nil){
            DErr(@"VTDec format is video/h264, but no CMFormatDescriptionRef");
            return FALSE;
        }
        UInt32 fourcc = CMVideoFormatDescriptionGetCodecType(format);
        
        DLog(@"Found %d ", fourcc);
        
        if (MKBETAG('a','v','c','1')==fourcc) {
            _out_type = [[KMediaTypeImageBuffer alloc]initWithName:@"image/CVImageBufferRef"];
            _out_type.dimension = CMVideoFormatDescriptionGetDimensions(format);
            return TRUE;
        }
        
        DLog(@"Not supported fourcc %d", fourcc);
    }
    
    return FALSE;
    
}

void didDecompress( void *decompressionOutputRefCon,
                   void *sourceFrameRefCon,
                   OSStatus status,
                   VTDecodeInfoFlags infoFlags,
                   CVImageBufferRef imageBuffer,
                   CMTime presentationTimeStamp,
                   CMTime presentationDuration )
{
    if (status != noErr || !imageBuffer) {
        
        //AIRMediaBuffer *weakSelf = (__bridge AIRMediaBuffer *)decompressionOutputRefCon;
        
        // error -8969 codecBadDataErr
        // -12909 The operation couldn’t be completed. (OSStatus error -12909.) kVTVideoDecoderBadDataErr
        DErr(@"Error decompresssing frame at time: %.3f error: %d infoFlags: %u ",
              (float)presentationTimeStamp.value/presentationTimeStamp.timescale,
              (int)status,
              (unsigned int)infoFlags
              );
        return;
    }
    
    
    VTDec *weakSelf = (__bridge VTDec *)decompressionOutputRefCon;
    if( [weakSelf respondsToSelector:@selector(onImageData:withPTS:andDuration:)] ) {
        [weakSelf onImageData:imageBuffer withPTS:presentationTimeStamp andDuration:presentationDuration];
    }
}

- (void) onImageData:(CVImageBufferRef)imageBuffer withPTS:(CMTime) presentationTimeStamp andDuration:(CMTime) presentationDuration
{
    KMediaSampleImageBuffer *out_sample = [[KMediaSampleImageBuffer alloc]init];
    out_sample.type = _out_type;

    out_sample.image = imageBuffer;

    out_sample.ts = presentationTimeStamp.value;
    out_sample.timescale = presentationTimeStamp.timescale;
    
    if (self->onMediaSample!=nil)
        self->onMediaSample(out_sample);
}


-(KResult)decodeSample:(KMediaSample *)sample andCallback:(OnMediaSampleCallback)onSuccess
{
    OSStatus status;
    
    DLog(@"<VTDec> decodeSample ts=%lld sz=%lu", sample.ts, (unsigned long)sample.data.length);
    
    self->onMediaSample = onSuccess;

  
        
    const unsigned char *memory = (const unsigned char *)sample.data.bytes;
            
    CMBlockBufferRef videoBlock = NULL;
    status = CMBlockBufferCreateWithMemoryBlock(NULL,
                                                (void*)(memory + 0),
                                                sample.data.length,
                                                kCFAllocatorNull,
                                                NULL,
                                                0,
                                                sample.data.length,
                                                0,
                                                &videoBlock);
    
    // 6. create a CMSampleBuffer.
    CMSampleBufferRef sbRef = NULL;
    CMSampleTimingInfo timingInfo;
    timingInfo.presentationTimeStamp = CMTimeMake(sample.ts, sample.timescale);
    timingInfo.duration = kCMTimeInvalid;
    
            
            
    timingInfo.decodeTimeStamp = kCMTimeInvalid;
    const size_t sampleSizeArray[] = {sample.data.length};
    
    
    
    status = CMSampleBufferCreate(kCFAllocatorDefault, videoBlock, true, NULL, NULL,sample.type.format , 1, 1, &timingInfo, 1, sampleSizeArray, &sbRef);
    
    
    if (last_type==nil || ![last_type isEqual:sample.type] || session==nil)
        // if (last_type!=(*sample).type)
    {
        [self flush];
               
        
        VTDecompressionOutputCallbackRecord callback;
        callback.decompressionOutputCallback = didDecompress;
        callback.decompressionOutputRefCon = (__bridge void *)self;
        
        NSDictionary *destinationImageBufferAttributes = @{(id)kCVPixelBufferOpenGLESCompatibilityKey:@(YES)};
        
        
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              sample.type.format,
                                              NULL, //decoder_config,//
                                              (__bridge CFDictionaryRef)destinationImageBufferAttributes,
                                              &callback,
                                              &session);
        
        if( status != noErr )
            session=nil;
        
        
        if (session==nil){
            DErr(@"VTDec Couldn't create decompressionSessionCreateWithFormat");
            
            return KResult_ERROR;
        }
        
        last_type = sample.type;
        DLog(@"VTDec New session");
    }
    
    
    // 7. use VTDecompressionSessionDecodeFrame
    VTDecodeFrameFlags flags = 0;
    VTDecodeInfoFlags flagOut;
    
    status = VTDecompressionSessionDecodeFrame(session, sbRef, flags, &sbRef, &flagOut);
    
    if (status != noErr) {
        
        
        if (status == kVTInvalidSessionErr || status == kVTFormatDescriptionChangeNotSupportedErr ) {
            DLog(@"_____ kVTInvalidSessionErr %d", (int)status);
            
        } else {
            DLog(@"VTDec _____ %d", (int)status);
        }
        return KResult_ERROR;
    }
    
    //DLog(@"VTDecompressionSessionDecodeFrame: %@", (status == noErr) ? @"successfully." : @"failed.");
    CFRelease(videoBlock);
    
    CFRelease(sbRef);
    
    return KResult_OK;
}


@end

