//
//  FlvDec.m
//  KPlayTest5
//
//  Created by kuzalex on 12/3/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "FlvDec.h"
//#define MYDEBUG
//#define MYWARN
#include "myDebug.h"
#include "KLinkedList.h"

@implementation FlvStream {
    NSObject   *_samples_lock;
    KLinkedList *_samples;
    CMTime _last_ts;
}


/* bitmasks to isolate specific values */
#define FLV_AUDIO_CHANNEL_MASK    0x01
#define FLV_AUDIO_SAMPLESIZE_MASK 0x02
#define FLV_AUDIO_SAMPLERATE_MASK 0x0c
#define FLV_AUDIO_CODECID_MASK    0xf0

#define FLV_VIDEO_CODECID_MASK    0x0f
#define FLV_VIDEO_FRAMETYPE_MASK  0xf0

/* offsets for packed values */
#define FLV_AUDIO_SAMPLESSIZE_OFFSET 1
#define FLV_AUDIO_SAMPLERATE_OFFSET  2
#define FLV_AUDIO_CODECID_OFFSET     4

#define FLV_VIDEO_FRAMETYPE_OFFSET   4

enum {
    FLV_MONO   = 0,
    FLV_STEREO = 1,
};

enum {
    FLV_SAMPLESSIZE_8BIT  = 0,
    FLV_SAMPLESSIZE_16BIT = 1 << FLV_AUDIO_SAMPLESSIZE_OFFSET,
};

enum {
    FLV_SAMPLERATE_SPECIAL = 0, /**< signifies 5512Hz and 8000Hz in the case of NELLYMOSER */
    FLV_SAMPLERATE_11025HZ = 1 << FLV_AUDIO_SAMPLERATE_OFFSET,
    FLV_SAMPLERATE_22050HZ = 2 << FLV_AUDIO_SAMPLERATE_OFFSET,
    FLV_SAMPLERATE_44100HZ = 3 << FLV_AUDIO_SAMPLERATE_OFFSET,
};

enum {
    FLV_CODECID_PCM                  = 0,
    FLV_CODECID_ADPCM                = 1 << FLV_AUDIO_CODECID_OFFSET,
    FLV_CODECID_MP3                  = 2 << FLV_AUDIO_CODECID_OFFSET,
    FLV_CODECID_PCM_LE               = 3 << FLV_AUDIO_CODECID_OFFSET,
    FLV_CODECID_NELLYMOSER_16KHZ_MONO = 4 << FLV_AUDIO_CODECID_OFFSET,
    FLV_CODECID_NELLYMOSER_8KHZ_MONO = 5 << FLV_AUDIO_CODECID_OFFSET,
    FLV_CODECID_NELLYMOSER           = 6 << FLV_AUDIO_CODECID_OFFSET,
    FLV_CODECID_PCM_ALAW             = 7 << FLV_AUDIO_CODECID_OFFSET,
    FLV_CODECID_PCM_MULAW            = 8 << FLV_AUDIO_CODECID_OFFSET,
    FLV_CODECID_AAC                  = 10<< FLV_AUDIO_CODECID_OFFSET,
    FLV_CODECID_SPEEX                = 11<< FLV_AUDIO_CODECID_OFFSET,
};

enum {
    FLV_CODECID_H263    = 2,
    FLV_CODECID_SCREEN  = 3,
    FLV_CODECID_VP6     = 4,
    FLV_CODECID_VP6A    = 5,
    FLV_CODECID_SCREEN2 = 6,
    FLV_CODECID_H264    = 7,
    FLV_CODECID_REALH263= 8,
    FLV_CODECID_MPEG4   = 9,
};


const int avpriv_mpeg4audio_sample_rates[16] = {
    96000, 88200, 64000, 48000, 44100, 32000,
    24000, 22050, 16000, 12000, 11025, 8000, 7350
};
    
const uint8_t ff_mpeg4audio_channels[8] = {
    0, 1, 2, 3, 4, 5, 6, 8
};


#define GET_BYTE(v,ptr,sz,error) { if ((sz)>=1) {(v)=*ptr++; (sz)--;} else return error;}
#define SKIP_N_BYTES(nb,ptr,sz,error) { if ((sz)>=(nb)) {ptr+=(nb); (sz)-=(nb);} else return error;}

BOOL AudioStreamBasicDescriptionEqual(const AudioStreamBasicDescription *a, const AudioStreamBasicDescription *b)
{
    if (a==nil || b==nil)
        return FALSE;
    return memcmp(a, b, sizeof(a[0])) == 0;
}


-(KResult)processAudioPacket:(RTMPPacket *)p
{
    //KResult res;
    
    uint8_t *ptr = (uint8_t*)p->m_body;
    int restSz = p->m_nBodySize;
        
    uint8_t flags;
    
    GET_BYTE(flags, ptr,    restSz, KResult_ParseError);
    
    CMFormatDescriptionRef      afd;
    
    AudioStreamBasicDescription format;
   
    
    format.mChannelsPerFrame = (flags & FLV_AUDIO_CHANNEL_MASK) == FLV_STEREO ? 2 : 1;
    format.mSampleRate = 44100 << ((flags & FLV_AUDIO_SAMPLERATE_MASK) >>
                                   FLV_AUDIO_SAMPLERATE_OFFSET) >> 3;
    format.mBitsPerChannel  = (flags & FLV_AUDIO_SAMPLESIZE_MASK) ? 16 : 8;
    
    
    
    
    switch (flags & FLV_AUDIO_CODECID_MASK){
        case FLV_CODECID_PCM:
            format.mFormatID = kAudioFormatLinearPCM;
            format.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
            //                apar->codec_id = format.mBitsPerChannel == 8
            //                ? AV_CODEC_ID_PCM_U8
            //#if HAVE_BIGENDIAN
            //                : AV_CODEC_ID_PCM_S16BE;
            //#else
            //                : AV_CODEC_ID_PCM_S16LE;
            //#endif
            break;
        case FLV_CODECID_PCM_LE:
            format.mFormatID = kAudioFormatLinearPCM;
            format.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
            //                apar->codec_id = apar->bits_per_coded_sample == 8
            //                ? AV_CODEC_ID_PCM_U8
            //                : AV_CODEC_ID_PCM_S16LE;
            break;
        case FLV_CODECID_AAC:{
            format.mFormatID          = kAudioFormatMPEG4AAC;
            format.mFormatFlags       = kMPEG4Object_AAC_LC;
            uint8_t type;
            GET_BYTE(type, ptr,    restSz, KResult_ParseError);
            
            //TODO: implement a real AAC AudioSpecificConfig parser
            if (type==0){
               
                if (restSz<2){
                    DErr(@"Unsupported AAC format (2)");
                    return KResult_ParseError;
                }
                uint16_t bytes2 = 0;
                bytes2 = ptr[0];
                bytes2 = bytes2<<8 | ptr[1];
                uint8_t object_type = (bytes2 & 0xf800) >> 11;
                if (object_type == 0x1f){//AOT_ESCAPE
                    DErr(@"Unsupported AAC format (3)");
                    return KResult_ParseError;
                }
                uint8_t sample_rate = (bytes2 & 0x780) >> 7;
                if (sample_rate == 0x0f){
                    DErr(@"Unsupported AAC format (4)");
                    return KResult_ParseError;
                }
                format.mSampleRate = avpriv_mpeg4audio_sample_rates[sample_rate];
                
                uint8_t channel_config = (bytes2 & 0x78) >> 3;
                if (channel_config<=7) {
                    format.mChannelsPerFrame = ff_mpeg4audio_channels[channel_config];
                }
                
                restSz=0;
            }
            break;
        }
            //                DErr(@"Unsupported audio codec FLV_CODECID_AAC");
            //                return KResult_ParseError;
            
        case FLV_CODECID_ADPCM:
            DErr(@"Unsupported audio codec FLV_CODECID_ADPCM");
            return KResult_ParseError;
            //                apar->codec_id = AV_CODEC_ID_ADPCM_SWF;
            //                break;
        case FLV_CODECID_SPEEX:
            DErr(@"Unsupported audio codec FLV_CODECID_SPEEX");
            return KResult_ParseError;
            //                apar->codec_id    = AV_CODEC_ID_SPEEX;
            //                apar->sample_rate = 16000;
            //                break;
        case FLV_CODECID_MP3:
            DErr(@"Unsupported audio codec FLV_CODECID_MP3");
            return KResult_ParseError;
            //                apar->codec_id      = AV_CODEC_ID_MP3;
            //                astream->need_parsing = AVSTREAM_PARSE_FULL;
            //                break;
        case FLV_CODECID_NELLYMOSER_8KHZ_MONO:
            DErr(@"Unsupported audio codec FLV_CODECID_NELLYMOSER_8KHZ_MONO");
            return KResult_ParseError;
            //                // in case metadata does not otherwise declare samplerate
            //                apar->sample_rate = 8000;
            //                apar->codec_id    = AV_CODEC_ID_NELLYMOSER;
            //                break;
        case FLV_CODECID_NELLYMOSER_16KHZ_MONO:
            DErr(@"Unsupported audio codec FLV_CODECID_NELLYMOSER_16KHZ_MONO");
            return KResult_ParseError;
            //                apar->sample_rate = 16000;
            //                apar->codec_id    = AV_CODEC_ID_NELLYMOSER;
            //                break;
        case FLV_CODECID_NELLYMOSER:
            DErr(@"Unsupported audio codec FLV_CODECID_NELLYMOSER");
            return KResult_ParseError;
            //                apar->codec_id = AV_CODEC_ID_NELLYMOSER;
            //                break;
        case FLV_CODECID_PCM_MULAW:
            DErr(@"Unsupported audio codec FLV_CODECID_PCM_MULAW");
            return KResult_ParseError;
            //                apar->sample_rate = 8000;
            //                apar->codec_id    = AV_CODEC_ID_PCM_MULAW;
            //                break;
        case FLV_CODECID_PCM_ALAW:
            DErr(@"Unsupported audio codec FLV_CODECID_PCM_ALAW");
            return KResult_ParseError;
            //                apar->sample_rate = 8000;
            //                apar->codec_id    = AV_CODEC_ID_PCM_ALAW;
            //                break;
            //            default:
            //                avpriv_request_sample(s, "Audio codec (%x)",
            //                                      flv_codecid >> FLV_AUDIO_CODECID_OFFSET);
            //                apar->codec_tag = flv_codecid >> FLV_AUDIO_CODECID_OFFSET;
        default:
            DErr(@"Unsupported audio codec (%x)", flags & FLV_AUDIO_CODECID_MASK);
            return KResult_ParseError;
    }
    
    
    format.mBytesPerFrame    = (UInt32)(format.mBitsPerChannel / 8 * format.mChannelsPerFrame);
    format.mFramesPerPacket  = 1;
    format.mBytesPerPacket   = format.mBytesPerFrame * format.mFramesPerPacket;
    format.mReserved         = 0;
    
//    if (_type!=nil){
//        if (!AudioStreamBasicDescriptionEqual((const AudioStreamBasicDescription*)_type.format, &format))WRONG
//            _type=nil;
//    }
    
    if (_type == nil){
        
        
        if (CMAudioFormatDescriptionCreate(kCFAllocatorDefault,
                                           &format,
                                           0,
                                           NULL,
                                           0,
                                           NULL,
                                           NULL,
                                           &afd)!=noErr)
        {
            DErr(@"Could not create format from AudioStreamBasicDescription");
            
            return KResult_ParseError;
        }
        
        self->_type = [[KMediaType alloc] initWithName:@"audio"];
        [self->_type setFormat:afd];
        return KResult_OK;
    }
       
    if (restSz>0)
    {
        KMediaSample *sample = [[KMediaSample alloc] init];
        sample.ts = CMTimeMake(p->m_nTimeStamp, 1000);
        sample.type = _type;
        
        sample.data = [[NSData alloc] initWithBytes:ptr length:restSz];
        [self pushSample:sample];
    }
   
    
   

    return KResult_OK;
    
}

-(KResult)processVideoPacket:(RTMPPacket *)p
{
    //KResult res;
    
    uint8_t *ptr = (uint8_t*)p->m_body;
    int restSz = p->m_nBodySize;
    int64_t pts = p->m_nTimeStamp;
    
    uint8_t flags;
    
    GET_BYTE(flags,ptr,restSz,KResult_ParseError);
    
    switch (flags & FLV_VIDEO_CODECID_MASK) {
        case FLV_CODECID_H263:
            DErr(@"Unsupported video codec FLV_CODECID_H263");
            return KResult_ParseError;
        case FLV_CODECID_SCREEN:
            DErr(@"Unsupported video codec FLV_CODECID_SCREEN");
            return KResult_ParseError;
        case FLV_CODECID_SCREEN2:
            DErr(@"Unsupported video codec FLV_CODECID_SCREEN2");
            return KResult_ParseError;
        case FLV_CODECID_VP6:
            DErr(@"Unsupported video codec FLV_CODECID_VP6");
            return KResult_ParseError;
        case FLV_CODECID_VP6A:
            DErr(@"Unsupported video codec FLV_CODECID_VP6A");
            return KResult_ParseError;
        case FLV_CODECID_H264: {
            
            uint8_t AVCPacketType;
            uint8_t CompositionTime[3];
            uint8_t byte;
            uint8_t nalusizeminusOne;
            
            GET_BYTE(AVCPacketType,ptr,restSz,KResult_ParseError);
            GET_BYTE(CompositionTime[0],ptr,restSz,KResult_ParseError);
            GET_BYTE(CompositionTime[1],ptr,restSz,KResult_ParseError);
            GET_BYTE(CompositionTime[2],ptr,restSz,KResult_ParseError);
            
            int32_t cts = (((CompositionTime[0]<<16)|(CompositionTime[1]<<8)|CompositionTime[2]) + 0xff800000) ^ 0xff800000;
            pts = pts + cts;
//
//            DLog(@"DTS %d %d %d %d", CompositionTime[0], CompositionTime[1], CompositionTime[2], cts);
            
            if ((flags&0xf0)==0x10 && AVCPacketType==0x0){
                
                uint8_t  *sps_data = NULL;
                uint16_t sps_size = 0;
                uint8_t  *pps_data = NULL;
                uint16_t pps_size = 0;
                
                GET_BYTE(byte,ptr,restSz,KResult_ParseError);
                GET_BYTE(byte,ptr,restSz,KResult_ParseError);
                GET_BYTE(byte,ptr,restSz,KResult_ParseError);
                GET_BYTE(byte,ptr,restSz,KResult_ParseError);
                
                GET_BYTE(nalusizeminusOne,ptr,restSz,KResult_ParseError);
                
                //FIXME: > 1 sps?
                uint8_t spsNum;
                GET_BYTE(spsNum,ptr,restSz,KResult_ParseError);
                GET_BYTE(byte,ptr,restSz,KResult_ParseError);
                sps_size = byte;
                GET_BYTE(byte,ptr,restSz,KResult_ParseError);
                sps_size<<=8;
                sps_size|=byte;
                sps_data=ptr;
                SKIP_N_BYTES(sps_size,ptr,restSz,KResult_ParseError);
                
                uint8_t ppsNum;
                GET_BYTE(ppsNum,ptr,restSz,KResult_ParseError);
                GET_BYTE(byte,ptr,restSz,KResult_ParseError);
                pps_size = byte;
                GET_BYTE(byte,ptr,restSz,KResult_ParseError);
                pps_size<<=8;
                pps_size|=byte;
                pps_data=ptr;
                SKIP_N_BYTES(pps_size,ptr,restSz,KResult_ParseError);
                
                if (_type==nil){
                    const uint8_t* const parameterSetPointers[2] = { sps_data, pps_data };
                    const size_t parameterSetSizes[2] = { sps_size, pps_size };
                    CMFormatDescriptionRef vfd;
                    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                                          2,
                                                                                          parameterSetPointers,
                                                                                          parameterSetSizes,
                                                                                          4,
                                                                                          &vfd);
                    if (status != noErr)
                        return KResult_ParseError;
                    
                    #ifdef MYDEBUG
                    CMVideoDimensions dim = CMVideoFormatDescriptionGetDimensions(vfd);
                    DLog(@"Found %dx%d CMVideoFormatDescription", dim.width, dim.height);
                    #endif
                    UInt32 fourcc = CMVideoFormatDescriptionGetCodecType(vfd);
                    
                    DLog(@"Found %d %d", fourcc, MKBETAG('a','v','c','1'));
                    assert(MKBETAG('a','v','c','1')==fourcc);
                    
                    self->_type = [[KMediaType alloc] initWithName:@"video"];
                    [self->_type setFormat:vfd];
                }
            }
            
            if (_type == nil){
                //SKIP
                return KResult_OK;
            }
            break;
        }
            
        default:
            DErr(@"Unsupported video codec (%x)", flags & FLV_VIDEO_CODECID_MASK);
            return KResult_ParseError;
    }
    

    if (restSz>0)
    {
        KMediaSample *sample = [[KMediaSample alloc] init];
        sample.ts = CMTimeMake(pts, 1000);
        sample.type = _type;
        
        sample.data = [[NSData alloc] initWithBytes:ptr length:restSz];
        [self pushSample:sample];
    }

    return KResult_OK;

}


- (instancetype)init
{
    self = [super init];
    if (self) {
        self->_type = nil;
        self->_samples_lock = [[NSObject alloc]init];
        self->_samples = [[KLinkedList alloc]init];
        self->_last_ts = CMTimeMake(0, 1);
        self->_eos = false;
    }
    return self;
}

-(KResult) parseRtmp:(RTMPPacket *)p
{
    //_sample=nil;
    
    
    if ( p->m_packetType == RTMP_PACKET_TYPE_AUDIO )
        return [self processAudioPacket:p];
    
    
    if ( p->m_packetType == RTMP_PACKET_TYPE_VIDEO )
        return [self processVideoPacket:p];
       
    DErr(@"Unsupported media type");
    
    return KResult_ERROR;
}


    -(void)pushSample:(KMediaSample *)sample
    {
        @synchronized (_samples_lock) {
            [_samples addObjectToTail:sample];
            if (CMTimeCompare(sample.ts, _last_ts) > 0)
                _last_ts = sample.ts;
        }
    }
    -(KMediaSample *)popSamplewithProbe:(BOOL)probe
    {
        KMediaSample *result = nil;
        
        @synchronized (_samples_lock) {
            
            if (![_samples isEmpty]){
                result = _samples.objectAtHead;
        
                if (!probe)
                    [_samples removeObjectFromHead];
            } else {
                if (_eos){
                    KMediaSample *eosSample = [[KMediaSample alloc]init];
                    eosSample.ts = CMTimeAdd(_last_ts, CMTimeMake(1, 1000));
                    eosSample.type = _type;
                    eosSample.eos=true;
                    
                    eosSample.data = [[NSData alloc] initWithBytes:nil length:0];
                    result = eosSample;
                    usleep(100000);
                }
            }
        }
        return result;
    }
     -(void)flush
    {
        @synchronized (_samples_lock) {
            [_samples removeAllObjects];
            self->_eos = false;
            self->_last_ts = CMTimeMake(0, 1);
        }
    }

@end
