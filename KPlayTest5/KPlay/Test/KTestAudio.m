//
//  KTestAudio.m
//  KPlayTest5
//
//  Created by kuzalex on 11/26/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KTestAudio.h"
#define MYDEBUG
#define MYWARN
#import "myDebug.h"

#include <AudioToolbox/AudioToolbox.h>




#define BUFFER_SIZE 44100*2*2
#define SAMPLE_TYPE short
#define MAX_NUMBER 32767
#define SAMPLE_RATE 44100

@implementation KAudioSourceToneFilter{
   
    KMediaType *_type;
    long _count;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        AudioStreamBasicDescription format;
        CMFormatDescriptionRef      cmformat;
        format.mSampleRate       = SAMPLE_RATE;
        format.mFormatID         = kAudioFormatLinearPCM;
        format.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        format.mBitsPerChannel   = 8 * sizeof(SAMPLE_TYPE);
        format.mChannelsPerFrame = 2;
        format.mBytesPerFrame    = sizeof(SAMPLE_TYPE) * format.mChannelsPerFrame;
        format.mFramesPerPacket  = 1;
        format.mBytesPerPacket   = format.mBytesPerFrame * format.mFramesPerPacket;
        format.mReserved         = 0;
        
        
       
        if (CMAudioFormatDescriptionCreate(kCFAllocatorDefault,
                      &format,
                      0,
                      NULL,
                      0,
                      NULL,
                      NULL,
                      &cmformat)!=noErr)
        {
            NSLog(@"Could not create format from AudioStreamBasicDescription");
            return nil;
        }
        
        _type = [[KMediaType alloc] initWithName:@"audio/pcm"];
        [_type setFormat:cmformat];
        
        [self.outputPins addObject:[
                                    [KOutputPin alloc] initWithFilter:self]
         ];
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
            _count=0;
            break;
        case KFilterState_STOPPING:
        case KFilterState_PAUSING:
        case KFilterState_STARTED:
        case KFilterState_PAUSED:
            
            break;
    }
}


-(KResult)pullSample:(KMediaSample *_Nonnull  *_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error;
{
    KMediaSample *mySample = [[KMediaSample alloc] init];
    mySample.ts = _count;
    mySample.timescale=SAMPLE_RATE;
    mySample.type=_type;
    
    
    
    unsigned char buffer[BUFFER_SIZE];
   
    SAMPLE_TYPE *casted_buffer = (SAMPLE_TYPE *)buffer;
    for (int i = 0; i < BUFFER_SIZE / sizeof(SAMPLE_TYPE); i += 2)
       {
           double float_sample = sin(_count / 10.0);
           
           SAMPLE_TYPE int_sample = (SAMPLE_TYPE)(float_sample * MAX_NUMBER);
           
           casted_buffer[i]   = int_sample;
           casted_buffer[i+1] = int_sample;
           
           _count++;
       }
    
    
    
    mySample.data = [NSData dataWithBytes:buffer length:BUFFER_SIZE];

    *sample = mySample;
    
    DLog(@"Count=%ld", _count);
    if (_count>200000){
        usleep(1400000);
    }
    
    if (_count>500000){
        NSError *test_error=[NSError errorWithDomain:@"com.kuzalex" code:200 userInfo:@{@"Error reason": @"Test Error"}];
        *error = test_error;
        return KResult_ERROR;
    }
    
    return KResult_OK;
}

@end




//44 bytes!!!
// WAVE file header format
#define HDR_SIZE 44
struct HEADER {
    unsigned char riff[4];                        // RIFF string
    unsigned int overall_size    ;                // overall size of file in bytes
    unsigned char wave[4];                        // WAVE string
    unsigned char fmt_chunk_marker[4];            // fmt string with trailing null char
    unsigned int length_of_fmt;                    // length of the format data
    unsigned int format_type;                    // format type. 1-PCM, 3- IEEE float, 6 - 8bit A law, 7 - 8bit mu law
    unsigned int channels;                        // no.of channels
    unsigned int sample_rate;                    // sampling rate (blocks per second)
    unsigned int byterate;                        // SampleRate * NumChannels * BitsPerSample/8
    unsigned int block_align;                    // NumChannels * BitsPerSample/8
    unsigned int bits_per_sample;                // bits per sample, 8- 8bits, 16- 16 bits etc
    unsigned char data_chunk_header [4];        // DATA string or FLLR string
    unsigned int data_size;                        // NumSamples * NumChannels * BitsPerSample/8 - size of the next chunk that will be read
};



@implementation KAudioSourceWavReaderFilter{
    NSURL *_url;
    KMediaType *_type;
    NSURLSessionDownloadTask *_download_task;
    struct HEADER header;
   // long _count;
    
    dispatch_semaphore_t _semHeader;
    dispatch_semaphore_t _semSample;
    KMediaSample *_outSample;
    NSError *_error;
    AudioStreamBasicDescription _format;
    BOOL _format_is_valid;
    NSUInteger _position;
}

-(instancetype)initWithUrl:(NSString *)url
{
    self = [super init];
    if (self) {
        self->_type = nil;
        //self->outSample = nil;
        self->_download_task=nil;
        self->_url = [[NSURL alloc] initWithString:url];
        self->_format_is_valid=FALSE;
        self->_position=0;
        
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
            self->_position=0;
            self->_format_is_valid=FALSE;
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
   
    NSString *rangeString = [NSString stringWithFormat:@"bytes=%lu-%lu", (unsigned long)range.location, range.location+range.length];
    [request setValue:rangeString forHTTPHeaderField:@"Range"];
    
                                      
    DLog(@"<%@> Downloading %@ %@", [self name], url.host, rangeString);
    return [[NSURLSession sharedSession] downloadTaskWithRequest:request
                                               completionHandler:completionHandler];
                      
}

BOOL readBytes(unsigned char **from, unsigned char *max, void *to, size_t nb)
{
    if (*from + nb > max)
        return FALSE;
    memcpy (to, *from, nb);
    (*from) += nb;
    return TRUE;
}

-(KResult)parseHeader:(NSData *)data
{
    _format_is_valid = FALSE;
    
    
    if (data.length<HDR_SIZE){
        DErr(@"Error 1");
        return KResult_ParseError;
    }
    
    unsigned char *ptr = (unsigned char *)[data bytes];
    unsigned char *stop = ptr + HDR_SIZE;
    
    if (!readBytes(&ptr, stop, header.riff, sizeof(header.riff))){
        DErr(@"Parse Error 2");
        return KResult_ParseError;
    }
    
    // CHECK R I F F
    if (header.riff[0]!='R' || header.riff[1]!='I' || header.riff[2]!='F' || header.riff[3]!='F') {
        DErr(@"Parse Error 3");
        return KResult_ParseError;
    }
    
    unsigned char buffer4[4];
    unsigned char buffer2[2];
    if (!readBytes(&ptr, stop, buffer4, sizeof(buffer4))){
        DErr(@"Parse Error 4");
        return KResult_ParseError;
    }
    
    // convert little endian to big endian 4 byte int
    
    header.overall_size  = buffer4[0] |
    (buffer4[1]<<8) |
    (buffer4[2]<<16) |
    (buffer4[3]<<24);
    
    DLog(@"(5-8) Overall size: bytes:%u, Kb:%u \n", header.overall_size, header.overall_size/1024);
    
    if (!readBytes(&ptr, stop, header.wave, sizeof(header.wave))){
        DErr(@"Parse Error 5");
        return KResult_ParseError;
    }
    
    DLog(@"(9-12) Wave marker: %s\n", header.wave);
    
    if (!readBytes(&ptr, stop, header.fmt_chunk_marker, sizeof(header.fmt_chunk_marker))){
        DErr(@"Parse Error 6");
        return KResult_ParseError;
    }
    
    DLog(@"(13-16) Fmt marker: %s\n", header.fmt_chunk_marker);
    
    
    if (!readBytes(&ptr, stop, buffer4, sizeof(buffer4))){
        DErr(@"Parse Error 7");
        return KResult_ParseError;
    }
    
    // convert little endian to big endian 4 byte integer
    header.length_of_fmt = buffer4[0] |
    (buffer4[1] << 8) |
    (buffer4[2] << 16) |
    (buffer4[3] << 24);
    DLog(@"(17-20) Length of Fmt header: %u \n", header.length_of_fmt);
    
    if (!readBytes(&ptr, stop, buffer2, sizeof(buffer2))){
        DErr(@"Parse Error 8");
        return KResult_ParseError;
    }
    header.format_type = buffer2[0] | (buffer2[1] << 8);
    
    if (header.format_type == 1)
        _format.mFormatID = kAudioFormatLinearPCM;
    else if (header.format_type == 6) {
        // a-law
        DErr(@"Parse Error 9");
        return KResult_UnsupportedFormat;
    }
    else if (header.format_type == 7){
        // mu-law
        DErr(@"Parse Error 10");
        return KResult_UnsupportedFormat;
    }
    
    
    if (!readBytes(&ptr, stop, buffer2, sizeof(buffer2))){
        DErr(@"Parse Error 11");
        return KResult_ParseError;
    }
    DLog(@"%u %u \n", buffer2[0], buffer2[1]);
    
    _format.mChannelsPerFrame = header.channels = buffer2[0] | (buffer2[1] << 8);
    printf("(23-24) Channels: %u \n", _format.mChannelsPerFrame);
    
    
    if (!readBytes(&ptr, stop, buffer4, sizeof(buffer4))){
        DErr(@"Parse Error 12");
        return KResult_ParseError;
    }
    
    _format.mSampleRate = header.sample_rate = buffer4[0] |
                           (buffer4[1] << 8) |
                           (buffer4[2] << 16) |
                           (buffer4[3] << 24);

    DLog(@"(25-28) Sample rate: %u\n", header.sample_rate);
    
    if (!readBytes(&ptr, stop, buffer4, sizeof(buffer4))){
        DErr(@"Parse Error 13");
        return KResult_ParseError;
    }
 
    header.byterate  = buffer4[0] |
                           (buffer4[1] << 8) |
                           (buffer4[2] << 16) |
                           (buffer4[3] << 24);
    DLog(@"(29-32) Byte Rate: %u , Bit Rate:%u\n", header.byterate, header.byterate*8);
    
    if (!readBytes(&ptr, stop, buffer2, sizeof(buffer2))){
        DErr(@"Parse Error 14");
        return KResult_ParseError;
    }
  
    header.block_align = buffer2[0] |
                       (buffer2[1] << 8);
    DLog(@"(33-34) Block Alignment: %u \n", header.block_align);
    
   
    if (!readBytes(&ptr, stop, buffer2, sizeof(buffer2))){
        DErr(@"Parse Error 15");
        return KResult_ParseError;
    }
  
    header.bits_per_sample = buffer2[0] |
                       (buffer2[1] << 8);
    DLog(@"(35-36) Bits per sample: %u \n", header.bits_per_sample);
    
    
    if (!readBytes(&ptr, stop, header.data_chunk_header, sizeof(header.data_chunk_header))){
        DErr(@"Parse Error 16");
        return KResult_ParseError;
    }
 
    DLog(@"(37-40) Data Marker: %s \n", header.data_chunk_header);

    if (!readBytes(&ptr, stop, buffer4, sizeof(buffer4))){
        DErr(@"Parse Error 17");
        return KResult_ParseError;
    }
  
    header.data_size = buffer4[0] |
                   (buffer4[1] << 8) |
                   (buffer4[2] << 16) |
                   (buffer4[3] << 24 );
    DLog(@"(41-44) Size of data chunk: %u \n", header.data_size);


    // calculate no.of samples
    if (header.channels * header.bits_per_sample!=0)
    {
        long num_samples = (8 * header.data_size) / (header.channels * header.bits_per_sample);
        DLog(@"Number of samples:%lu \n", num_samples);
    }

    long size_of_each_sample = (header.channels * header.bits_per_sample) / 8;
    DLog(@"Size of each sample:%ld bytes\n", size_of_each_sample);

    if (header.byterate!=0)
    {
        // calculate duration of file
        float duration_in_seconds = (float) header.overall_size / header.byterate;
        DLog(@"Approx.Duration in seconds=%f\n", duration_in_seconds);
    }
    
    
    ////FIXME!
    
    //_format.mChannelsPerFrame
    //_format.mSampleRate
    
    ////FIXME!
    _format.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    _format.mBitsPerChannel   = (UInt32)(8 * size_of_each_sample);
    _format.mBytesPerFrame    = (UInt32)(size_of_each_sample * _format.mChannelsPerFrame);
    ////FIXME!
    _format.mFramesPerPacket  = 1;
    ////FIXME!
    _format.mBytesPerPacket   = _format.mBytesPerFrame * _format.mFramesPerPacket;
    _format.mReserved         = 0;
    
    
     CMFormatDescriptionRef      cmformat;
     if (CMAudioFormatDescriptionCreate(kCFAllocatorDefault,
                   &_format,
                   0,
                   NULL,
                   0,
                   NULL,
                   NULL,
                   &cmformat)!=noErr)
     {
         DErr(@"Could not create format from AudioStreamBasicDescription");
         return KResult_ERROR;
     }
     
     _type = [[KMediaType alloc] initWithName:@"audio/pcm"];
     [_type setFormat:cmformat];
    
    _format_is_valid=TRUE;
    return KResult_OK;
    
    
    

    
}

-(void)downloadHeader
{
    _semHeader = dispatch_semaphore_create(0);
    _error = nil;
    
    NSRange range;
    range.location=0;
    range.length=HDR_SIZE;
    _position=HDR_SIZE;
    
    _download_task = [self downloadUrl:_url withRange:range completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error)
                      {
        if (error==nil){
            DLog(@"<%@> Downloaded %@", [self name], self->_url.host);
            self->_download_task=nil;
            KResult res;
            if ((res=[self parseHeader:[NSData dataWithContentsOfURL:location]]) != KResult_OK) {
                self->_error = KResult2Error(res);
            }
//
            
        } else {
            DLog(@"<%@> Error: %@", [self name], error);
            self->_outSample = nil;
            self->_error = error;
            self->_download_task=nil;
        }
        dispatch_semaphore_signal(self->_semHeader);
    }];
    // 4
    [_download_task resume];
}

-(void)downloadSample
{
    _semSample = dispatch_semaphore_create(0);
    _error = nil;
    
    NSRange range;
    range.location=_position;
    range.length=1024*64;///FIXME!!!!
    _position+=range.length;
    
    _download_task = [self downloadUrl:_url withRange:range completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error)
                      {
        if (error==nil){
            DLog(@"<%@> Downloaded %@", [self name], self->_url.host);
            self->_download_task=nil;
           // KResult res;
            self->_outSample = [[KMediaSample alloc] init];
            self->_outSample.type = self->_type;
            self->_outSample.data =  [NSData dataWithContentsOfURL:location];

            
        } else {
            DLog(@"<%@> Error: %@", [self name], error);
            self->_outSample = nil;
            self->_error = error;
            self->_download_task=nil;
        }
        dispatch_semaphore_signal(self->_semSample);
    }];
    // 4
    [_download_task resume];
}



-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error;
{
    KResult res;
    
    ///FIXME type format
    if (!_format_is_valid) {
        [self downloadHeader];
                  
        if ( (res = [self waitSemaphoreOrState:_semHeader]) != KResult_OK ){
            if (_download_task) {
                [_download_task cancel];
            }
            _format_is_valid = FALSE;
            return res;
        }
    }
    
    if (_format_is_valid) {
        [self downloadSample];
                  
        if ( (res = [self waitSemaphoreOrState:_semSample]) != KResult_OK ){
            if (_download_task) {
                [_download_task cancel];
            }
            _format_is_valid = FALSE;
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
    
    
//    DErr(@"%lu",sizeof(hdr));
//    if (_outSample==nil)
//    {
//        _sem = dispatch_semaphore_create(0);
//        _outSample = nil;
//        _error = nil;
//
//
//        NSRange range;
//        range.location=0;
//        range.length=sizeof(hdr);
//
//        _download_task = [self downloadUrl:_url withRange:range completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error)
//                          {
//            if (error==nil){
//                DLog(@"<%@> Downloaded %@", [self name], self->_url.host);
//                ///FIXME
//                self->_type = [[KMediaType alloc]initWithName:@"video/mp2t"];
//
//                self->_outSample = [[KMediaSample alloc] init];
//                self->_outSample.type = self->_type;
//                self->_outSample.data =  [NSData dataWithContentsOfURL:location];
//                //sample.discontinuity = insample.discontinuity;
//
//                self->_download_task=nil;
//
//            } else {
//                DLog(@"<%@> Error: %@", [self name], error);
//                self->_outSample = nil;
//                self->_error = error;
//                self->_download_task=nil;
//            }
//            dispatch_semaphore_signal(self->_sem);
//        }];
//        // 4
//        [_download_task resume];
//
//        KResult res;
//        if ( (res = [self waitSemaphoreOrState:_sem]) != KResult_OK ){
//            if (_download_task) {
//                [_download_task cancel];
//            }
//            //*error = res;
//            return res;
//        }
//    }
//
//    if (_outSample == nil) {
//        *error = _error;
//        return KResult_ERROR;
//    }
//
//    *sample = _outSample;
//    if (!probe)
//        _outSample = nil;
//    return KResult_OK;
//}

@end




