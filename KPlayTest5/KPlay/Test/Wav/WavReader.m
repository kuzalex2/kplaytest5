//
//  WavReader.m
//  KPlayTest5
//
//  Created by kuzalex on 11/30/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "WavReader.h"
#import "KPin.h"

#define MYDEBUG
#define MYWARN
#import "myDebug.h"

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
    //unsigned char data_chunk_header [4];        // DATA string or FLLR string
    unsigned int data_size;                        // NumSamples * NumChannels * BitsPerSample/8 - size of the next chunk that will be read
    
    unsigned char next_chunk_header [4];        // DATA string or FLLR string
    unsigned int next_chunk_size;
    
   // unsigned int data_size2;
};



@implementation WavReader {
    @public struct HEADER header;
}


BOOL readBytes(unsigned char **from, unsigned char *max, void *to, size_t nb)
{
    if (*from + nb > max)
        return FALSE;
    memcpy (to, *from, nb);
    (*from) += nb;
    return TRUE;
}

BOOL read32Size(unsigned char **ptr, unsigned char *stop, unsigned int *res)
{
    unsigned char buffer4[4];

    if (!readBytes(ptr, stop, buffer4, sizeof(buffer4))){
        return FALSE;
    }

    // convert little endian to big endian 4 byte integer
    *res = buffer4[0] | (buffer4[1] << 8) | (buffer4[2] << 16) | (buffer4[3] << 24);
    
    return TRUE;
}

@synthesize nextBytesToRead = _nextBytesToRead;
@synthesize dataSize = _dataSize;

-(int64_t)nextBytesToRead{
    switch (_state) {
        case WavReaderStateNone:
            return 12 + 8;
        case WavReaderState1:
            assert(header.length_of_fmt>=16);
            return header.length_of_fmt+8;
        case WavReaderState2:
            assert(header.next_chunk_size>=0);
            return header.next_chunk_size+8;
        case WavReaderStateSample:
        {
            int64_t bytesPerSec =
                _format.mSampleRate *
                //512 * //FIXME: почему не работапет???
                _format.mBytesPerFrame *
                _format.mFramesPerPacket / 2;
            
            int64_t chunk_size = bytesPerSec;//FIXME!!!
            return chunk_size;
        }
            
    }
}

-(int64_t)dataSize{
    switch (_state) {
        case WavReaderStateSample:
            return header.data_size;
        default:
            assert(0);
            return 0;
    }
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        self->_state = WavReaderStateNone;
    }
    return self;
}

-(void)reset
{
    _state = WavReaderStateNone;
}

-(void)prepareFormat
{
    // calculate no.of samples
    if (header.channels * header.bits_per_sample!=0)
    {
        WLog(@"Number of samples:%u \n", (8 * header.data_size) / (header.channels * header.bits_per_sample));
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
}


-(KResult)parseData:(NSData *)data
{
    
    if (data.length<[self nextBytesToRead]){
        DErr(@"Error 1");
        return KResult_ParseError;
    }
    
    unsigned char buffer4[4];
    unsigned char buffer2[2];


    unsigned char *ptr = (unsigned char *)[data bytes];
    unsigned char *stop = ptr + [self nextBytesToRead];
    
    switch (_state) {
        case WavReaderStateNone: {
            
            if (!readBytes(&ptr, stop, header.riff, sizeof(header.riff))){
                DErr(@"Parse Error 2");
                return KResult_ParseError;
            }
            
            // CHECK R I F F
            if (header.riff[0]!='R' || header.riff[1]!='I' || header.riff[2]!='F' || header.riff[3]!='F') {
                DErr(@"Parse Error 3");
                return KResult_ParseError;
            }
            
            
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
            
            
            
            if (!read32Size(&ptr, stop,&header.length_of_fmt)){
                DErr(@"Parse Error 7");
                return KResult_ParseError;
            }
            WLog(@"(17-20) Length of Fmt header: %u \n", header.length_of_fmt);
            
            
            if (header.length_of_fmt<16){
                DErr(@"Parse Error 7.1");
                return KResult_ParseError;
            }
            
            _state = WavReaderState1;
            
            return KResult_OK;
        }
        case WavReaderState1: {
            
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
            
            if (!readBytes(&ptr, stop, header.next_chunk_header, sizeof(header.next_chunk_header))){
                DErr(@"Parse Error 16");
                return KResult_ParseError;
            }
            
            WLog(@"next_chunk_header: %s \n", header.next_chunk_header);
            
            if (!read32Size(&ptr, stop,&header.next_chunk_size)){
                DErr(@"Parse Error 7");
                return KResult_ParseError;
            }
            
            
            if (strncmp((const char*)header.next_chunk_header, "data", 4)==0){
                header.data_size = header.next_chunk_size;
                [self prepareFormat];
                
                _state = WavReaderStateSample;
                return KResult_OK;
            }
            
            _state = WavReaderState2;
            return KResult_OK;
        }
            
        case WavReaderState2: {

            
            // skip it
            unsigned char bufferx[header.next_chunk_size];
            
            if (!readBytes(&ptr, stop, bufferx, sizeof(bufferx))){
                DErr(@"Parse Error 20");
                return KResult_ParseError;
            }
            
            
            
            if (!readBytes(&ptr, stop, header.next_chunk_header, sizeof(header.next_chunk_header))){
                DErr(@"Parse Error 16");
                return KResult_ParseError;
            }
            
            WLog(@"next_chunk_header: %s \n", header.next_chunk_header);
            
            if (!read32Size(&ptr, stop,&header.next_chunk_size)){
                DErr(@"Parse Error 7");
                return KResult_ParseError;
            }
            
            
            if (strncmp((const char*)header.next_chunk_header, "data", 4)==0){
                header.data_size = header.next_chunk_size;
                [self prepareFormat];
                
                _state = WavReaderStateSample;
                return KResult_OK;
            }
            
            _state = WavReaderState2;
            return KResult_OK;
        }
            
        case WavReaderStateSample: {
            
            
            return KResult_OK;
        }
            
    }
}


@end
