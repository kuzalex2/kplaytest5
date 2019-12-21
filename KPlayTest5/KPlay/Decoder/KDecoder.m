//
//  KDecoder.m
//  KPlayTest5
//
//  Created by kuzalex on 12/12/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KDecoder.h"


//#define MYDEBUG
//#define MYWARN
#include "myDebug.h"

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "AVDec.h"
#import "KLinkedList.h"

@implementation KDecoder
{
    id<AVDec> dec;
    KLinkedList *out_samples;//fixme - array of ones
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self->out_samples = [[KLinkedList alloc] init];
    }
    return self;
}

-(KMediaType *)getOutputMediaTypeFromPin:(KOutputPin*)pin
{
    if (dec==nil)
        return nil;
    return dec.out_type;
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



-(KResult)flush
{
    [out_samples removeAllObjects];
    if (dec){
        [dec flush];
       // dec=nil;
    }
    return KResult_OK;
}

-(id)createDecoder
{
    return nil;
}


-(BOOL)isInputMediaTypeSupported:(KMediaType *)type
{
    if (dec==nil)
        dec = [self createDecoder];
    return [dec isInputMediaTypeSupported:type];
}



#define MAX_SEQUENCE_ERRORS 100
#define ORDER_WINDOW_NSAMPLES 10

-(void)pushSample:(KMediaSample *)sample
{
    [out_samples addObjectToTail:sample];
   
}

-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)outSample probe:(BOOL)probe error:(NSError *__strong*)outError fromPin:(nonnull KOutputPin *)pin
{
    KResult res;
    
    DLog(@"%@ pullSample", [self name]);
 
    if ([self.inputPins count] < 1 )
        return KResult_ERROR;
    
    ///FIXME: write this!
//    if (error || eos){
//        if (ordered_out_samples.size>0){
//            *outSample = ordered_out_samples.objectAtTail;
//            [ordered_out_samples removeObjectFromTail];
//            return KResult_OK;
//        }
//    }
    
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
        
        if (newSample.eos){
            newSample.type = dec.out_type;
            [self pushSample:newSample];
            
            if (![out_samples isEmpty]){
                *outSample = out_samples.objectAtTail;
                if (!probe)
                    [out_samples removeObjectFromHead];
                return KResult_OK;
            }
        }
        
        if (dec==nil) {
            DErr(@"No decoder");
            return KResult_ERROR;
        }
        
        res = [dec decodeSample:newSample andCallback:^(KMediaSample * _Nonnull sample) {
            [self pushSample:sample];
        }];
        
        if (res!=KResult_OK){
            (*outError) = [NSError errorWithDomain:@"com.kuzalex" code:KResult_ERROR userInfo:@{@"Reason": @"Video decoding error"}];
            return res;
        }
        
        if (![out_samples isEmpty]){
            *outSample = out_samples.objectAtTail;
            if (!probe)
                [out_samples removeObjectFromHead];
            return KResult_OK;
        }
        
        
        DErr(@"%@ error. attempt # %d",[self name], attempt);
    }
    
    DErr(@"%@ Couldn't decompress frames",[self name]);

    return KResult_ERROR;
}

@end

