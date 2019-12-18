//
//  KRtmpSource.m
//  KPlayTest5
//
//  Created by kuzalex on 12/2/19.
//  Copyright © 2019 kuzalex. All rights reserved.
// TODO: server pause on Pause:
//

#import "KRtmpSource.h"

//#define MYDEBUG
//#define MYWARN
#import "myDebug.h"

#import "librtmp/rtmp_sys.h"
#import "librtmp/log.h"
#import "FlvDec.h"

@implementation KRtmpSource{
    NSString *_url;
    FlvStream *_stream_audio;
    FlvStream *_stream_video;
    __weak KOutputPin *_audio_pin;
    __weak KOutputPin *_video_pin;
    BOOL has_audio;
    BOOL has_video;
    float duration;
    
    
    NSObject *RtmpLockInit;
    NSObject *RtmpLockProcess;
    RTMP *_rtmp;
    float bufferSec;
    float seekPosition;
    BOOL eos;
//    NSError *_error;
}

-(instancetype)initWithUrl:(NSString *)url andBufferSec:(float)bufferSec
{
    self = [super init];
    if (self) {
        self->_stream_audio = [[FlvStream alloc] init];
        self->_stream_video = [[FlvStream alloc] init];
        self->_audio_pin=nil;
        self->_video_pin=nil;
        self->has_audio=FALSE;
        self->has_video=FALSE;
        self->duration=0.0;
        
//        self->_outSample=nil;
       // self->_error = nil;
        self->RtmpLockInit = [[NSObject alloc]init];
        self->RtmpLockProcess = [[NSObject alloc]init];
        self->_rtmp = nil;
        self->_url = url;
        self->bufferSec = bufferSec;
        self->seekPosition = 0;
       
        
        if (!self->_url)
            return nil;
        
        KOutputPin *output = [[KOutputPin alloc] initWithFilter:self ];
        [self.outputPins addObject:output];
        [self onStateChanged:self state:_state];
    }
    return self;
}

-(KMediaType *)getOutputMediaTypeFromPin:(KOutputPin*)pin
{
    if (pin!=nil && pin == _audio_pin){
        if (_stream_audio==nil)
            return nil;
        return _stream_audio.type;
    }
    
    if (pin!=nil && pin == _video_pin){
        if (_stream_video==nil)
            return nil;
        return _stream_video.type;
    }
    
    return nil;
}

void RTMP_Interrupt(RTMP *r)
{
    RTMP_Log(RTMP_LOGDEBUG, "%s ... RTMP_Interrupt", __FUNCTION__);
    char buf[1];
    write(r->m_interruptSign[1], buf, 1);
}

- (void)onStateChanged:(KFilter *)filter state:(KFilterState)state
{
    switch (_state) {
        case KFilterState_STOPPED:{
            @synchronized (RtmpLockInit) {
                if (_rtmp != nil){
                    RTMP_Interrupt(_rtmp);
                }
                
                @synchronized (RtmpLockProcess) {
                    if (_rtmp != nil){
                        RTMP_Close(_rtmp);
                        RTMP_Free(_rtmp);
                        _rtmp = nil;
                    }
                }
            }
            [self flush];
            
        }
        default:
            break;
    }
}


-(NSString *) rtmpPacketStringForType:(uint8_t)type
{
    switch (type) {
        case RTMP_PACKET_TYPE_CHUNK_SIZE:
            return @"[CHUNK_SIZE]";
        case RTMP_PACKET_TYPE_BYTES_READ_REPORT:
            return @"[READ_REPORT]";
        case RTMP_PACKET_TYPE_CONTROL:
            return @"[CONTROL]";
        case RTMP_PACKET_TYPE_SERVER_BW:
            return @"[SERVER_BW]";
        case RTMP_PACKET_TYPE_CLIENT_BW:
            return @"[CLIENT_BW]";
        case RTMP_PACKET_TYPE_AUDIO:
            return @"[AUDIO]";
        case RTMP_PACKET_TYPE_VIDEO:
            return @"[VIDEO]";
        case RTMP_PACKET_TYPE_FLEX_STREAM_SEND:
            return @"[FLEX_STREAM_SEND]";
        case RTMP_PACKET_TYPE_FLEX_SHARED_OBJECT:
            return @"[FLEX_SHARED_OBJECT]";
        case RTMP_PACKET_TYPE_FLEX_MESSAGE:
            return @"[FLEX_MESSAGE]";
        case RTMP_PACKET_TYPE_INFO:
            return @"[INFO]";
        case RTMP_PACKET_TYPE_SHARED_OBJECT:
            return @"[SHARED_OBJECT]";
        case RTMP_PACKET_TYPE_INVOKE:
            return @"[INVOKE]";
        case RTMP_PACKET_TYPE_FLASH_VIDEO:
            return @"[FLASH_VIDEO]";
        
        default:
            return [NSString stringWithFormat:@"[UNKNOWD %d]", (int)type ];
    }
}




// сначала pull на аудио, в процессе этого должны создать видео out, если в стриме есть видео
// weak audio_pin video_pin getmediatype pullsample

-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error fromPin:(nonnull KOutputPin *)pin
{
    if (pin == _audio_pin){
        *sample = [_stream_audio popSamplewithProbe:probe];
        if (*sample!=nil)
            return KResult_OK;
    }
    if (pin == _video_pin){
        *sample = [_stream_video popSamplewithProbe:probe];
        if (*sample!=nil)
            return KResult_OK;
    }
    
    BOOL needToConnect = false;
    @synchronized (RtmpLockInit) {
    @synchronized (RtmpLockProcess) {
    
        if (_rtmp == nil){
            needToConnect=TRUE;
            _rtmp = RTMP_Alloc();
            //memset(_rtmp, 0x0, sizeof(_rtmp[0]));
            RTMP_Init(_rtmp);
            _rtmp->Link.timeout = 30;
            
            #ifdef MYDEBUG
            RTMP_LogLevel loglvl=RTMP_LOGDEBUG;
            RTMP_LogSetLevel(loglvl);
            #endif
            
           // RTMP_SetBufferMS(_rtmp, 5 * 3600 * 1000);
            RTMP_SetBufferMS(_rtmp, bufferSec  * 1000);
        }
    }
    }
    
   
    
    @synchronized (RtmpLockProcess) {
    
        if (needToConnect)
        {
            if (!RTMP_SetupURL(_rtmp, (char *)[_url UTF8String])) {
                RTMP_Log(RTMP_LOGERROR, "SetupURL Err\n");
                return KResult_RTMP_ConnectFailed;
            }
            
            if (!RTMP_Connect(_rtmp, NULL)) {
                RTMP_Log(RTMP_LOGERROR, "Connect Err\n");
                return KResult_RTMP_ConnectFailed;
            }
            
            if (!RTMP_ConnectStream(_rtmp, seekPosition*1000)) {
                RTMP_Log(RTMP_LOGERROR, "ConnectStream Err\n");
                return KResult_RTMP_ConnectFailed;
            }
        }
        
       
        
        RTMPPacket packet = { 0 };
        
        //
        // wait for metadata
        
//        has_audio=1;
//        _audio_pin = self.outputPins[0];
      
           
        while (!has_audio && !has_video)
        {
            if (!RTMP_IsConnected(_rtmp))
                return KResult_RTMP_Disconnected;
            
            int res = RTMP_ReadPacket(_rtmp, &packet);
            if (!res)
                return KResult_RTMP_ReadFailed;
            
            if (RTMPPacket_IsReady(&packet))
            {
                if (!packet.m_nBodySize)
                    continue;
                
                DLog(@"<%@> Got pkt type=%@ ts=%d len=%d", [self name], [self rtmpPacketStringForType:packet.m_packetType], (int)packet.m_nTimeStamp, (int)packet.m_nBodySize);
                
                if (packet.m_packetType == RTMP_PACKET_TYPE_INFO) {
                    
                    if (HandleMetadata(_rtmp, packet.m_body, packet.m_nBodySize))
                    {
                        if (_rtmp->m_fAudioCodecid>0)
                            has_audio=TRUE;
                        if (_rtmp->m_fVideoCodecid>0)
                            has_video=TRUE;
                        
                        if (self.outputPins.count < has_audio + has_video ){
                            [self.outputPins addObject:[[KOutputPin alloc] initWithFilter:self ]];
                        }
                        
                        if (has_audio && has_video){
                            _audio_pin = self.outputPins[0];
                            _video_pin = self.outputPins[1];
                        } else if (has_audio){
                            _audio_pin = self.outputPins[0];
                        } else if (has_video){
                            _video_pin = self.outputPins[0];
                        }
                        
                        duration = _rtmp->m_fDuration;
                    }
                }
                RTMP_ClientPacket(_rtmp, &packet);
                RTMPPacket_Free(&packet);
                
            }
        }
        
        
        
      //  RTMPPacket packet = { 0 };
        
        while (1)
        {
            if (!RTMP_IsConnected(_rtmp))
                return KResult_RTMP_Disconnected;
            
            int res = RTMP_ReadPacket(_rtmp, &packet);
            if (!res)
                return KResult_RTMP_ReadFailed;
            
            if (RTMPPacket_IsReady(&packet))
            {
                if (!packet.m_nBodySize)
                    continue;
                
                DLog(@"<%@> Got pkt type=%@ ts=%d len=%d", [self name], [self rtmpPacketStringForType:packet.m_packetType], (int)packet.m_nTimeStamp, (int)packet.m_nBodySize);
                if ( packet.m_packetType == RTMP_PACKET_TYPE_AUDIO && has_audio){

                    
                    KResult res;
                    if ( (res = [_stream_audio parseRtmp:&packet])!=KResult_OK){
                        DErr(@"Audio parse failed");
                        return res;
                    }
                    
                    RTMPPacket_Free(&packet);
                   
                    if (pin == _audio_pin){
                        *sample = [_stream_audio popSamplewithProbe:probe];
                        if (*sample!=nil)
                            return KResult_OK;
                    }
                    
                    
                } else if (packet.m_packetType == RTMP_PACKET_TYPE_VIDEO && has_video){
                    
                    KResult res;
                    if ( (res = [_stream_video parseRtmp:&packet])!=KResult_OK){
                        DErr(@"Video parse failed");
                        return res;
                    }
                    
                    RTMPPacket_Free(&packet);
                    
                    
                    if (pin == _video_pin){
                        *sample = [_stream_video popSamplewithProbe:probe];
                        if (*sample!=nil)
                            return KResult_OK;
                    }
                    
                } else if (packet.m_packetType == RTMP_PACKET_TYPE_INFO) {
                    
                    if (HandleMetadata(_rtmp, packet.m_body, packet.m_nBodySize))
                    {
                        duration = _rtmp->m_fDuration;
                    }
                    
                    RTMP_ClientPacket(_rtmp, &packet);
                    RTMPPacket_Free(&packet);
                    
                } else {
                    RTMP_ClientPacket(_rtmp, &packet);
                    RTMPPacket_Free(&packet);
                    
                    if (_rtmp->m_eos)
                    {
                        _stream_audio.eos=true;
                        _stream_video.eos=true;
                        
                        if (pin == _audio_pin){
                            *sample = [_stream_audio popSamplewithProbe:probe];
                            if (*sample!=nil)
                                return KResult_OK;
                        }
                        if (pin == _video_pin){
                            *sample = [_stream_video popSamplewithProbe:probe];
                            if (*sample!=nil)
                                return KResult_OK;
                        }
                    }
                }
                
                
                    
                 
            }
        }
    }
        
    return KResult_ERROR;

}

-(void)disconnectRTMP
{
    @synchronized (RtmpLockProcess) {
        
        @synchronized (RtmpLockInit) {
            if (_rtmp != nil){
                RTMP_Interrupt(_rtmp);
            }
            
            @synchronized (RtmpLockProcess) {
                if (_rtmp != nil){
                    RTMP_Close(_rtmp);
                    RTMP_Free(_rtmp);
                    _rtmp = nil;
                }
            }
        }
    }
}


-(KResult)flushEOS
{
    [self disconnectRTMP];
   
    return KResult_OK;
}

-(KResult)seek:(float)sec
{
    self->seekPosition = sec;
        
    return KResult_OK;
}

-(KResult)flush
{
    [_stream_video flush];
    [_stream_audio flush];
    seekPosition = 0;
    duration=0.0;
    
    [self disconnectRTMP];
    
    return KResult_OK;
}
        


///
///  KPlayMediaInfo
///

-(CMTime)duration
{
    return CMTimeMake(duration*1000,1000);
}






@end
