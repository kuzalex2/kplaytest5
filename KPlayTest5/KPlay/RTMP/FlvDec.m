//
//  FlvDec.m
//  KPlayTest5
//
//  Created by kuzalex on 12/3/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "FlvDec.h"
#define MYDEBUG
#define MYWARN
#include "myDebug.h"

@implementation FlvStream


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


#define GET_BYTE(v,ptr,sz,error) { if ((sz)>=1) {(v)=*ptr++; (sz)--;} else return error;}
#define SKIP_N_BYTES(nb,ptr,sz,error) { if ((sz)>=(nb)) {ptr+=(nb); (sz)-=(nb);} else return error;}


-(KResult)processAudioPacket:(RTMPPacket *)p
{
    //KResult res;
    
    uint8_t *ptr = (uint8_t*)p->m_body;
    int restSz = p->m_nBodySize;
    
    
    uint8_t flags;
    
    GET_BYTE(flags, ptr,    restSz, KResult_ParseError);
    
    if (_type == nil){
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
//            case FLV_CODECID_PCM_LE:
//                apar->codec_id = apar->bits_per_coded_sample == 8
//                ? AV_CODEC_ID_PCM_U8
//                : AV_CODEC_ID_PCM_S16LE;
//                break;
//            case FLV_CODECID_AAC:
//                apar->codec_id = AV_CODEC_ID_AAC;
//                break;
//            case FLV_CODECID_ADPCM:
//                apar->codec_id = AV_CODEC_ID_ADPCM_SWF;
//                break;
//            case FLV_CODECID_SPEEX:
//                apar->codec_id    = AV_CODEC_ID_SPEEX;
//                apar->sample_rate = 16000;
//                break;
//            case FLV_CODECID_MP3:
//                apar->codec_id      = AV_CODEC_ID_MP3;
//                astream->need_parsing = AVSTREAM_PARSE_FULL;
//                break;
//            case FLV_CODECID_NELLYMOSER_8KHZ_MONO:
//                // in case metadata does not otherwise declare samplerate
//                apar->sample_rate = 8000;
//                apar->codec_id    = AV_CODEC_ID_NELLYMOSER;
//                break;
//            case FLV_CODECID_NELLYMOSER_16KHZ_MONO:
//                apar->sample_rate = 16000;
//                apar->codec_id    = AV_CODEC_ID_NELLYMOSER;
//                break;
//            case FLV_CODECID_NELLYMOSER:
//                apar->codec_id = AV_CODEC_ID_NELLYMOSER;
//                break;
//            case FLV_CODECID_PCM_MULAW:
//                apar->sample_rate = 8000;
//                apar->codec_id    = AV_CODEC_ID_PCM_MULAW;
//                break;
//            case FLV_CODECID_PCM_ALAW:
//                apar->sample_rate = 8000;
//                apar->codec_id    = AV_CODEC_ID_PCM_ALAW;
//                break;
//            default:
//                avpriv_request_sample(s, "Audio codec (%x)",
//                                      flv_codecid >> FLV_AUDIO_CODECID_OFFSET);
//                apar->codec_tag = flv_codecid >> FLV_AUDIO_CODECID_OFFSET;
                default:
                    DErr(@"Unsupported audio format");
                    return KResult_ParseError;
        }
        
        
        format.mBytesPerFrame    = (UInt32)(format.mBitsPerChannel / 8 * format.mChannelsPerFrame);
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
                                           &afd)!=noErr)
        {
            DErr(@"Could not create format from AudioStreamBasicDescription");
            
            return KResult_ParseError;
        }
        
        self->_type = [[KMediaType alloc] initWithName:@"audio"];
        [self->_type setFormat:afd];
        
    }
    
    _sample = [[KMediaSample alloc] init];
    _sample.ts = p->m_nTimeStamp;
    _sample.timescale = 1000;
    _sample.type = _type;
    
    _sample.data = [[NSData alloc] initWithBytes:p->m_body+1 length:p->m_nBodySize-1];

    return KResult_OK;
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self->_type = nil;
        self->_sample = nil;
    }
    return self;
}

-(KResult) parseRtmp:(RTMPPacket *)p
{
    _sample=nil;
    
    
    if ( p->m_packetType == RTMP_PACKET_TYPE_AUDIO )
        return [self processAudioPacket:p];
    
    
    if ( p->m_packetType == RTMP_PACKET_TYPE_VIDEO ){
        DErr(@"Unsupported media type");
        // NOT IMPLEMENTED
        return KResult_OK;
    }
       
    DErr(@"Unsupported media type");
    
    return KResult_ERROR;
}

-(int64_t)duration
{
    ///FIXME!
    
    return 44000;
}


@end
