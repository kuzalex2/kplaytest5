//
//  KTestAudio.m
//  KPlayTest5
//
//  Created by kuzalex on 11/26/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KTestAudio.h"
#define MYDEBUG
//#define MYWARN
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




#define HDR_SIZE0 20
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
    unsigned char _data_chunk_header [4];        // DATA string or FLLR string
    unsigned int _data_size;                        // NumSamples * NumChannels * BitsPerSample/8 - size of the next chunk that will be read
   // unsigned int data_size2;
};

@interface WavReader : NSObject{
    @public struct HEADER header;
    //  NSError *_error;
    @public AudioStreamBasicDescription _format;
}
@end

@implementation WavReader {
    
}
    BOOL readBytes(unsigned char **from, unsigned char *max, void *to, size_t nb)
    {
        if (*from + nb > max)
            return FALSE;
        memcpy (to, *from, nb);
        (*from) += nb;
        return TRUE;
    }
    -(KResult)parseHeader0:(NSData *)data
    {
    
        if (data.length<HDR_SIZE0){
            DErr(@"Error 1");
            return KResult_ParseError;
        }
        
        unsigned char *ptr = (unsigned char *)[data bytes];
        unsigned char *stop = ptr + HDR_SIZE0;
        
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
        
        if (!readBytes(&ptr, stop, buffer4, sizeof(buffer4))){
            DErr(@"Parse Error 4");
            return KResult_ParseError;
        }
        
        // convert little endian to big endian 4 byte int
        
        header.overall_size  = buffer4[0] |
        (buffer4[1]<<8) |
        (buffer4[2]<<16) |
        (buffer4[3]<<24);
        
        WLog(@"(5-8) Overall size: bytes:%u, Kb:%u \n", header.overall_size, header.overall_size/1024);
        
        if (!readBytes(&ptr, stop, header.wave, sizeof(header.wave))){
            DErr(@"Parse Error 5");
            return KResult_ParseError;
        }
        
        WLog(@"(9-12) Wave marker: %s\n", header.wave);
        
        // CHECK F M T 0x0
        if (header.wave[0]!='W' || header.wave[1]!='A' || header.wave[2]!='V' || header.wave[3]!='E') {
            DErr(@"Parse Error 5.1");
            return KResult_ParseError;
        }
        
        if (!readBytes(&ptr, stop, header.fmt_chunk_marker, sizeof(header.fmt_chunk_marker))){
            DErr(@"Parse Error 6");
            return KResult_ParseError;
        }
        
        WLog(@"(13-16) Fmt marker: %s\n", header.fmt_chunk_marker);
        
        // CHECK F M T 0x0
        if (header.fmt_chunk_marker[0]!='f' || header.fmt_chunk_marker[1]!='m' || header.fmt_chunk_marker[2]!='t' || header.fmt_chunk_marker[3]!=' ') {
            DErr(@"Parse Error 6.1");
            return KResult_ParseError;
        }
        
        
        
        if (!readBytes(&ptr, stop, buffer4, sizeof(buffer4))){
            DErr(@"Parse Error 7");
            return KResult_ParseError;
        }
        
        // convert little endian to big endian 4 byte integer
        header.length_of_fmt = buffer4[0] |
        (buffer4[1] << 8) |
        (buffer4[2] << 16) |
        (buffer4[3] << 24);
        WLog(@"(17-20) Length of Fmt header: %u \n", header.length_of_fmt);
        
        if (header.length_of_fmt<16){
            DErr(@"Parse Error 7.1");
            return KResult_ParseError;
        }
        
        return KResult_OK;
    }
    
    -(KResult)parseHeader1:(NSData *)data
    {

        assert(header.length_of_fmt>=16);
        
        if (data.length<header.length_of_fmt+8){
            DErr(@"Error 1");
            return KResult_ParseError;
        }
        
        unsigned char *ptr = (unsigned char *)[data bytes];
        unsigned char *stop = ptr + header.length_of_fmt + 8;
        
        unsigned char buffer2[2];
        unsigned char buffer4[4];
        
        
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
        WLog(@"%u %u \n", buffer2[0], buffer2[1]);
        
        header.channels = buffer2[0] | (buffer2[1] << 8);
        WLog(@"(23-24) Channels: %u \n", _format.mChannelsPerFrame);
        
        
        if (!readBytes(&ptr, stop, buffer4, sizeof(buffer4))){
            DErr(@"Parse Error 12");
            return KResult_ParseError;
        }
        
        header.sample_rate = buffer4[0] |
        (buffer4[1] << 8) |
        (buffer4[2] << 16) |
        (buffer4[3] << 24);
        
        WLog(@"(25-28) Sample rate: %u\n", header.sample_rate);
        
        if (!readBytes(&ptr, stop, buffer4, sizeof(buffer4))){
            DErr(@"Parse Error 13");
            return KResult_ParseError;
        }
        
        header.byterate  = buffer4[0] |
        (buffer4[1] << 8) |
        (buffer4[2] << 16) |
        (buffer4[3] << 24);
        WLog(@"(29-32) Byte Rate: %u , Bit Rate:%u\n", header.byterate, header.byterate*8);
        
        if (!readBytes(&ptr, stop, buffer2, sizeof(buffer2))){
            DErr(@"Parse Error 14");
            return KResult_ParseError;
        }
        
        header.block_align = buffer2[0] |
        (buffer2[1] << 8);
        WLog(@"(33-34) Block Alignment: %u \n", header.block_align);
        
        
        if (!readBytes(&ptr, stop, buffer2, sizeof(buffer2))){
            DErr(@"Parse Error 15");
            return KResult_ParseError;
        }
        
        header.bits_per_sample = buffer2[0] |
        (buffer2[1] << 8);
        WLog(@"(35-36) Bits per sample: %u \n", header.bits_per_sample);
        
        
        if (!readBytes(&ptr, stop, header._data_chunk_header, sizeof(header._data_chunk_header))){
            DErr(@"Parse Error 16");
            return KResult_ParseError;
        }
        
        WLog(@"(37-40) Data Marker: %s \n", header._data_chunk_header);
        
        // CHECK data
        //    if (header.data_chunk_header[0]!='d' || header.data_chunk_header[1]!='a' || header.data_chunk_header[2]!='t' || header.data_chunk_header[3]!='a') {
        //        DErr(@"Parse Error 16.1");
        //        return KResult_ParseError;
        //    }
        
        if (!readBytes(&ptr, stop, buffer4, sizeof(buffer4))){
            DErr(@"Parse Error 17");
            return KResult_ParseError;
        }
        
        header._data_size = buffer4[0] |
        (buffer4[1] << 8) |
        (buffer4[2] << 16) |
        (buffer4[3] << 24 );
        WLog(@"(41-44) Size of data chunk: %u \n", header._data_size);
        
        
        //fixme: save start position
        
        
        return KResult_OK;
    }

    -(KResult)parseHeader2:(NSData *)data
    {
        
        if (strncmp((const char*)header._data_chunk_header, "data", 4)!=0){
            
            assert(header._data_size>=0);
             
             if (data.length<header._data_size+8){
                 DErr(@"Error 19");
                 return KResult_ParseError;
             }
             
             unsigned char *ptr = (unsigned char *)[data bytes];
             unsigned char *stop = ptr + header._data_size + 8;
             
             unsigned char bufferx[header._data_size];
             
             
             if (!readBytes(&ptr, stop, bufferx, sizeof(bufferx))){
                 DErr(@"Parse Error 20");
                 return KResult_ParseError;
             }
             
             unsigned char buffer4[4];
             
             if (!readBytes(&ptr, stop, header._data_chunk_header, sizeof(header._data_chunk_header))){
                 DErr(@"Parse Error 21");
                 return KResult_ParseError;
             }
             
             WLog(@" Data Marker: %s \n", header._data_chunk_header);
             
             // CHECK data
            if (strncmp((const char*)header._data_chunk_header, "data", 4)!=0){
                 DErr(@"Parse Error 22");
                 return KResult_ParseError;
             }
             
             if (!readBytes(&ptr, stop, buffer4, sizeof(buffer4))){
                 DErr(@"Parse Error 22");
                 return KResult_ParseError;
             }
             
             header._data_size = buffer4[0] |
             (buffer4[1] << 8) |
             (buffer4[2] << 16) |
             (buffer4[3] << 24 );
             WLog(@"Size of data chunk: %u \n", header._data_size);
        }
        
       
        
        
        
        
        // calculate no.of samples
        if (header.channels * header.bits_per_sample!=0)
        {
            WLog(@"Number of samples:%lu \n", (8 * header._data_size) / (header.channels * header.bits_per_sample));
        }
        
        long size_of_each_sample = (header.channels * header.bits_per_sample) / 8;
        WLog(@"Size of each sample:%ld bytes\n", size_of_each_sample);
        
        if (header.byterate!=0)
        {
            WLog(@"Approx.Duration in seconds=%f\n", (float) header.overall_size / header.byterate);
        }
        
        _format.mSampleRate = header.sample_rate;
        _format.mChannelsPerFrame = header.channels;
        _format.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        _format.mBitsPerChannel   = (UInt32)(8 * size_of_each_sample / _format.mChannelsPerFrame);
        _format.mBytesPerFrame    = (UInt32)(size_of_each_sample /** _format.mChannelsPerFrame*/);
        _format.mFramesPerPacket  = 1;
        _format.mBytesPerPacket   = _format.mBytesPerFrame * _format.mFramesPerPacket;
        _format.mReserved         = 0;
        
        
        
        
//        _type = [[KMediaType alloc] initWithName:@"audio/pcm"];
//        [_type setFormat:cmformat];
//
//        _format_is_valid=TRUE;
        return KResult_OK;

    }


@end

//@protocol KPlayMediaInfo<NSObject>
//    //-(NSInteger)durationSec;
//    @property int32_t duration;
//    @property int32_t timeScale;
//@end

@implementation KAudioSourceWavReaderFilter{
    NSURL *_url;
    KMediaType *_type;
    NSURLSessionDownloadTask *_download_task;
    WavReader *reader;
    dispatch_semaphore_t _sem1;
    KMediaSample *_outSample;
    NSError *_error;
    BOOL _format_is_valid;
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
        self->_format_is_valid=FALSE;
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
            self->_position=0;
            self->_start_data_position=0;
            self->_format_is_valid = FALSE;
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


-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error;
{
    KResult res;
    
    ///FIXME type format
    if (!_format_is_valid) {
        
        _sem1 = dispatch_semaphore_create(0);
        _position=0;
        [self downloadNext:HDR_SIZE0 withSuccess:^(NSData *data){
            KResult res;
            if ((res=[self->reader parseHeader0:data]) != KResult_OK) {
                self->_error = KResult2Error(res);
                self->_outSample = nil;
                dispatch_semaphore_signal(self->_sem1);
                return;
            }
            [self downloadNext:self->reader->header.length_of_fmt+8 withSuccess:^(NSData *data){
                KResult res;
                if ((res=[self->reader parseHeader1:data]) != KResult_OK) {
                    self->_error = KResult2Error(res);
                    self->_outSample = nil;
                    dispatch_semaphore_signal(self->_sem1);
                    return;
                }
                
                ///FIXME???
                [self downloadNext:self->reader->header._data_size+8 withSuccess:^(NSData *data){
                    KResult res;
                    if ((res=[self->reader parseHeader2:data]) != KResult_OK) {
                        self->_error = KResult2Error(res);
                        self->_outSample = nil;
                        dispatch_semaphore_signal(self->_sem1);
                        return;
                    }
                    
                    CMFormatDescriptionRef      cmformat;
                    if (CMAudioFormatDescriptionCreate(kCFAllocatorDefault,
                                                       &self->reader->_format,
                                                       0,
                                                       NULL,
                                                       0,
                                                       NULL,
                                                       NULL,
                                                       &cmformat)!=noErr)
                    {
                        DErr(@"Could not create format from AudioStreamBasicDescription");
                        self->_error = KResult2Error(KResult_ERROR);
                        return;
                    }
                    
                    self->_start_data_position = self->_position;///???
                    self->_type = [[KMediaType alloc] initWithName:@"audio/pcm"];
                    [self->_type setFormat:cmformat];
                    
                    self->_format_is_valid=TRUE;
                    
                    dispatch_semaphore_signal(self->_sem1);
                    
                    
                } andError:^(NSError *err){}];
                
                
                
            } andError:^(NSError *err){}];
            
        } andError:^(NSError *err){}];
        
        if ( (res = [self waitSemaphoreOrState:_sem1]) != KResult_OK ){
            if (_download_task) {
                [_download_task cancel];
            }
            _format_is_valid = FALSE;
            return res;
        }
        
    }

        
        
        
      
    if (_format_is_valid) {
        if (_outSample==nil){
            
            int64_t bytesPerSec =
                self->reader->_format.mSampleRate *
                //512 * //FIXME: почему не работапет???
                self->reader->_format.mBytesPerFrame *
                self->reader->_format.mFramesPerPacket / 8;
            
            int64_t chunk_size = bytesPerSec;//FIXME!!!
            ///FIXME!!!! and check < header.data_size
            [self downloadNext:chunk_size withSuccess:^(NSData *data){
               // KResult res;
                self->_outSample = [[KMediaSample alloc] init];
                self->_outSample.type = self->_type;
                self->_outSample.data =  data;
                self->_outSample.ts = (self->_position-chunk_size)/self->reader->_format.mBytesPerFrame;
                self->_outSample.timescale = self->reader->_format.mSampleRate;
                
                dispatch_semaphore_signal(self->_sem1);
                
                
            } andError:^(NSError *err){}];
            
            if ( (res = [self waitSemaphoreOrState:_sem1]) != KResult_OK ){
                if (_download_task) {
                    [_download_task cancel];
                }
                _format_is_valid = FALSE;
                return res;
            }
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
    assert(_format_is_valid);
    
    
    
    int64_t bytesPerSec =
        self->reader->_format.mSampleRate *
        self->reader->_format.mBytesPerFrame *
        self->reader->_format.mFramesPerPacket ;//*
       // self->reader->_format.mChannelsPerFrame;
    
    int64_t offset = bytesPerSec * sec;
    offset/=self->reader->_format.mBytesPerFrame;
    offset*=self->reader->_format.mBytesPerFrame;
    
  
    
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
    if (_format_is_valid && self->reader->_format.mBytesPerFrame!=0)
        return self->reader->header._data_size/self->reader->_format.mBytesPerFrame;
    return 0;
}

-(int64_t)timeScale
{
    if (_format_is_valid)
        return self->reader->_format.mSampleRate;
    return 1000;
}

@end




