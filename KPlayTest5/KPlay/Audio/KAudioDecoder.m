//
//  KAudioDecoder.m
//  KPlayTest5
//
//  Created by kuzalex on 12/5/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KAudioDecoder.h"

//#define MYDEBUG
//#define MYWARN
#include "myDebug.h"

//FIXME: autoreleease
//FIXME: seek!


//#import <VideoToolbox/VideoToolbox.h>
//#import <Foundation/Foundation.h>
//#import <CoreMedia/CoreMedia.h>
#import "ADec.h"

@implementation KAudioDecoder
{
    ADec *dec;
    KMediaSample * out_sample;//fixme - array of ones
}



-(KMediaType *)getOutputMediaTypeFromPin:(KOutputPin*)pin
{
    if (dec==nil)
        return nil;
    return dec.out_type;
}

- (void) flush
{
    out_sample = nil;
    if (dec){
        [dec flush];
       // dec=nil;
    }
}

- (void)onStateChanged:(KFilter *)filter state:(KFilterState)state
{
    switch (_state) {
        case KFilterState_STOPPED:
            [self flush];
            break;
        case KFilterState_STOPPING:
            break;
        case KFilterState_PAUSING:
            break;
        case KFilterState_STARTED:
            
            break;
        case KFilterState_PAUSED:
            break;
    }
}

-(KResult)seek:(float)sec
{
    [self flush];
    return KResult_OK;
}



-(BOOL)isInputMediaTypeSupported:(KMediaType *)type
{
    if (dec==nil)
        dec = [[ADec alloc] init];
    return [dec isInputMediaTypeSupported:type];
}



#define MAX_SEQUENCE_ERRORS 100


-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)outSample probe:(BOOL)probe error:(NSError *__strong*)outError fromPin:(nonnull KOutputPin *)pin
{
    KResult res;
    
    DLog(@"%@ pullSample", [self name]);
 
    if ([self.inputPins count] < 1 )
        return KResult_ERROR;
    
    
    // if out_samples -> return it
    

    for (int attempt=0;attempt<MAX_SEQUENCE_ERRORS;attempt++)
    {
        KMediaSample * __block newSample=nil;
        
        @autoreleasepool
        {
            KMediaSample *s;
            KResult res = [self.inputPins[0] pullSample:&s probe:probe error:outError];
            
            if (res != KResult_OK)
                return res;
            newSample = s;
        }
        
        if (dec==nil) {
            DErr(@"No decoder");
            return KResult_ERROR;
        }
        
        res = [dec decodeSample:newSample andCallback:^(KMediaSample * _Nonnull sample) {
            self->out_sample = sample;
        }];
        
        if (res!=KResult_OK){
            (*outError) = [NSError errorWithDomain:@"com.kuzalex" code:KResult_ERROR userInfo:@{@"Reason": @"Video decoding error"}];
            return res;
        }
        
        if (out_sample!=nil){
            *outSample = out_sample;
            if (!probe)
                out_sample=nil;
            return KResult_OK;
        }
        
        
        DErr(@"%@ error. attempt # %d",[self name], attempt);
    }
    
    DErr(@"%@ Couldn't decompress frames",[self name]);

    return KResult_ERROR;
}

@end
