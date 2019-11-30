//
//  KAudioSourceWavReaderFilter.m
//  KPlayTest5
//
//  Created by kuzalex on 12/1/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KAudioSourceWavReaderFilter.h"

#define MYDEBUG
//#define MYWARN
#import "myDebug.h"
#import "Wav/WavReader.h"

#include <AudioToolbox/AudioToolbox.h>

@implementation KAudioSourceWavReaderFilter{
    NSURL *_url;
    KMediaType *_type;
    NSURLSessionDownloadTask *_download_task;
    WavReader *reader;
    dispatch_semaphore_t _sem1;
    KMediaSample *_outSample;
    NSError *_error;
    
    NSUInteger _position;
    NSUInteger _start_data_position;
}




-(instancetype)initWithUrl:(NSString *)url
{
    self = [super init];
    if (self) {
        self->_type = nil;
        self->_download_task=nil;
        self->_url = [[NSURL alloc] initWithString:url];
        self->_position=0;
        self->_start_data_position=0;
        self->reader = [[WavReader alloc]init];
        
        if (!self->_url)
            return nil;
        
        KOutputPin *output = [[KOutputPin alloc] initWithFilter:self ];
        [self.outputPins addObject:output];
        [self onStateChanged:self state:_state];
    }
    return self;
}

-(KMediaType *)getOutputMediaType
{
    return _type;
}

- (void)onStateChanged:(KFilter *)filter state:(KFilterState)state
{
    switch (_state) {
        case KFilterState_STOPPED:
        case KFilterState_STOPPING:
            if (_download_task) {
                [_download_task cancel];
            }
            self->_position=self->_start_data_position;
            //self->_start_data_position=0;
            //self->_format_is_valid = FALSE;
            break;
        case KFilterState_PAUSING:
        case KFilterState_STARTED:
        case KFilterState_PAUSED:
            
            break;
    }
}

- (NSURLSessionDownloadTask *)downloadUrl:(NSURL *)url withRange:(NSRange)range completionHandler:(void (^)(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
   
    NSString *rangeString = [NSString stringWithFormat:@"bytes=%lu-%lu", (unsigned long)range.location, range.location+range.length-1];
    [request setValue:rangeString forHTTPHeaderField:@"Range"];
    
                                      
    DLog(@"<%@> Downloading %@ %@", [self name], url.host, rangeString);
    return [[NSURLSession sharedSession] downloadTaskWithRequest:request
                                               completionHandler:completionHandler];
                      
}




-(void)downloadNext:(NSUInteger)sz withSuccess:(void (^)(NSData *data))successCallback andError:(void (^)(NSError *err))errorCallback
{
    
    _error = nil;
    
    NSRange range;
    range.location=_position;
    range.length=sz;
    _position+=sz;
    
    _download_task = [self downloadUrl:_url withRange:range completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error)
                          {
            if (error==nil){
                DLog(@"<%@> Downloaded %@", [self name], self->_url.host);
                self->_download_task=nil;
                
                successCallback([NSData dataWithContentsOfURL:location]);
                
            } else {
                DLog(@"<%@> Error: %@", [self name], error);
                self->_outSample = nil;
                self->_error = error;
                self->_download_task=nil;
                errorCallback(error);
                dispatch_semaphore_signal(self->_sem1);
            }
           
        }];
        // 4
        [_download_task resume];
    
}

-(void)downloadAndParseNext
{
 

    int64_t chunk_size = [reader nextBytesToRead];
    ///FIXME!!!! and check < header.data_size
    
    
    [self downloadNext:chunk_size withSuccess:^(NSData *data){
        
        if ( self->reader.state == WavReaderStateSample) {
            
            
            self->_outSample = [[KMediaSample alloc] init];
            self->_outSample.type = self->_type;
            self->_outSample.data =  data;
            self->_outSample.ts = (self->_position-chunk_size)/self->reader.format.mBytesPerFrame;
            self->_outSample.timescale = self->reader.format.mSampleRate;
            
            dispatch_semaphore_signal(self->_sem1);
            return ;
        }
        
        KResult res;
        if ((res=[self->reader parseData:data]) != KResult_OK) {
            self->_error = KResult2Error(res);
            self->_outSample = nil;
            self->_position=0;
            self->_start_data_position=0;
            [self->reader reset];
            dispatch_semaphore_signal(self->_sem1);
            return;
        }
        
        if ( self->reader.state == WavReaderStateSample) {
            CMFormatDescriptionRef      cmformat;
            AudioStreamBasicDescription format = self->reader.format;
            if (CMAudioFormatDescriptionCreate(kCFAllocatorDefault,
                                               &format,
                                               0,
                                               NULL,
                                               0,
                                               NULL,
                                               NULL,
                                               &cmformat)!=noErr)
            {
                DErr(@"Could not create format from AudioStreamBasicDescription");
                self->_error = KResult2Error(KResult_ERROR);
                dispatch_semaphore_signal(self->_sem1);
                return;
            }
            
            self->_start_data_position = self->_position;///???
            self->_type = [[KMediaType alloc] initWithName:@"audio/pcm"];
            [self->_type setFormat:cmformat];
            
            
            //dispatch_semaphore_signal(self->_sem1);
            //return;
        }
        
        [self downloadAndParseNext];
        
        
        
    } andError:^(NSError *err){}];
}

-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error;
{
    KResult res;
    
        
    if (_outSample==nil){
        
        _sem1 = dispatch_semaphore_create(0);
        
        [self downloadAndParseNext];
        
        if ( (res = [self waitSemaphoreOrState:_sem1]) != KResult_OK ){
            if (_download_task) {
                [_download_task cancel];
            }
            _position=0;
            _start_data_position=0;
            [reader reset];
            return res;
        }
    }
    

    
    if (_outSample == nil) {
        *error = _error;
        return KResult_ERROR;
    }
    
    *sample = _outSample;
    if (!probe)
        _outSample = nil;
    return KResult_OK;
}


-(KResult)seek:(float)sec
{
    assert(self->reader.state == WavReaderStateSample);
    
    
    
    int64_t bytesPerSec =
        self->reader.format.mSampleRate *
        self->reader.format.mBytesPerFrame *
        self->reader.format.mFramesPerPacket ;//*
       // self->reader->_format.mChannelsPerFrame;
    
    int64_t offset = bytesPerSec * sec;
    offset/=self->reader.format.mBytesPerFrame;
    offset*=self->reader.format.mBytesPerFrame;
    
  
    
    ///FIXME: @sync????? aaa
    _outSample = nil;
    _position = _start_data_position + offset;
//    _position=1114208*2;
    return KResult_OK;
}



///
///  KPlayMediaInfo
///

-(int64_t)duration
{
    if (self->reader.state == WavReaderStateSample )
        return self->reader.duration;
    return 0;
}

-(int64_t)timeScale
{
    if (self->reader.state == WavReaderStateSample)
        return self->reader.format.mSampleRate;
    return 1000;
}

@end




