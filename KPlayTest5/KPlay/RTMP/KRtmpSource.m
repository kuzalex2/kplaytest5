//
//  KRtmpSource.m
//  KPlayTest5
//
//  Created by kuzalex on 12/2/19.
//  Copyright © 2019 kuzalex. All rights reserved.
// TODO: server pause on Pause:
//

#import "KRtmpSource.h"

#define MYDEBUG
#define MYWARN
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
    
    
    NSObject *RtmpLockInit;
    NSObject *RtmpLockProcess;
    RTMP *_rtmp;
//    NSError *_error;
}

-(instancetype)initWithUrl:(NSString *)url
{
    self = [super init];
    if (self) {
        self->_stream_audio = nil;
        self->_stream_video = nil;
        self->_audio_pin=nil;
        self->_video_pin=nil;
        self->has_audio=FALSE;
        self->has_video=FALSE;
        
//        self->_outSample=nil;
       // self->_error = nil;
        self->RtmpLockInit = [[NSObject alloc]init];
        self->RtmpLockProcess = [[NSObject alloc]init];
        self->_rtmp = nil;
        self->_url = url;
       
        
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
            }
            @synchronized (RtmpLockProcess) {
                if (_rtmp != nil){
                    RTMP_Close(_rtmp);
                    RTMP_Free(_rtmp);
                    _rtmp = nil;
                }
            }
        }
        default:
            break;
    }
}


    



// сначала pull на аудио, в процессе этого должны создать видео out, если в стриме есть видео
// weak audio_pin video_pin getmediatype pullsample

-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error fromPin:(nonnull KOutputPin *)pin
{
    BOOL needToConnect = false;
    @synchronized (RtmpLockInit) {
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
            RTMP_SetBufferMS(_rtmp, 1  * 1000);
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
            
            if (!RTMP_ConnectStream(_rtmp, 0)) {
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
                
                DLog(@"Got pkt type=%d ts=%d len=%d", (int)packet.m_packetType, (int)packet.m_nTimeStamp, (int)packet.m_nBodySize);
                
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
                    }
                }
                RTMP_ClientPacket(_rtmp, &packet);
                RTMPPacket_Free(&packet);
                
            }
                    
                    
                  

        }
        
       
        
      
           
        if (pin == _audio_pin && _stream_audio!=nil && _stream_audio.sample!=nil){
            *sample = _stream_audio.sample;
            if (!probe)
                _stream_audio.sample = nil;
            return KResult_OK;
        }
        
        if (pin == _video_pin && _stream_video!=nil && _stream_video.sample!=nil){
            *sample = _stream_video.sample;
            if (!probe)
                _stream_video.sample = nil;
            return KResult_OK;
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
                
                DLog(@"Got pkt type=%d ts=%d len=%d", (int)packet.m_packetType, (int)packet.m_nTimeStamp, (int)packet.m_nBodySize);
                
                if ( packet.m_packetType == RTMP_PACKET_TYPE_AUDIO && has_audio){

                    if ( _stream_audio == nil){
                        _stream_audio = [[FlvStream alloc] init];
                    }
                    KResult res;
                    if ( (res = [_stream_audio parseRtmp:&packet])!=KResult_OK){
                        DErr(@"Audio parse failed");
                        return res;
                    }
                    
            
                    if (_stream_audio.sample != nil ) {
                        
                        if (pin == _audio_pin){
                            *sample = _stream_audio.sample;
                        
                            RTMPPacket_Free(&packet);
                            if (!probe)
                                _stream_audio.sample = nil;
                            return KResult_OK;
                        }
                    }else {
                        // enqueue ?
                    }

                    RTMPPacket_Free(&packet);
                    
                } else if (packet.m_packetType == RTMP_PACKET_TYPE_VIDEO && has_video){
                    
                    
                    if ( _stream_video == nil){
                        _stream_video = [[FlvStream alloc] init];
                    }
                    KResult res;
                    if ( (res = [_stream_video parseRtmp:&packet])!=KResult_OK){
                        DErr(@"Video parse failed");
                        return res;
                    }
                    
                
                    if (_stream_video.sample != nil ) {
                        
                        if (pin == _video_pin){
                            *sample = _stream_video.sample;
                            RTMPPacket_Free(&packet);
                            if (!probe)
                                _stream_video.sample = nil;
                            return KResult_OK;
                        } else {
                            // enqueue ?
                        }
                    }

                    RTMPPacket_Free(&packet);
                    
                } else if (packet.m_packetType == RTMP_PACKET_TYPE_INFO) {
                    
                    // ... do some stuf here
                    
                    RTMP_ClientPacket(_rtmp, &packet);
                    RTMPPacket_Free(&packet);
                    
                } else {
                    RTMP_ClientPacket(_rtmp, &packet);
                    RTMPPacket_Free(&packet);
                }
                
                
                    
                 
            }
        }
    }
        
    return KResult_ERROR;

}

-(KResult)seek:(float)sec
{
    @synchronized (RtmpLockProcess) {
//        if (!RTMP_ConnectStream(_rtmp, sec*1000)) {
//            RTMP_Log(RTMP_LOGERROR, "ConnectStream Err\n");
//            return KResult_RTMP_ConnectFailed;
//        }
        if (!RTMP_SendSeek(_rtmp, sec*1000))
        {
            return KResult_ERROR;
        }
        
        RTMPPacket packet = { 0 };
        
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
                
                //DLog(@"Got pkt type=%d ts=%d", (int)packet.m_packetType, (int)packet.m_nTimeStamp);
                
                if (packet.m_packetType == RTMP_PACKET_TYPE_INVOKE) {
                    
                    RTMP_ClientPacket(_rtmp, &packet);
                    RTMPPacket_Free(&packet);
                    
                    ///FIXME -> check  HandleInvoke, onStatus: NetStream.Seek.Notify
                    return KResult_OK;
                    
                } else {
                    RTMP_ClientPacket(_rtmp, &packet);
                    RTMPPacket_Free(&packet);
                }
            }
        }
        
        
    }
    return KResult_OK;
}

///
///  KPlayMediaInfo
///

-(int64_t)duration
{
    @synchronized (RtmpLockInit) {
        if (_rtmp!=nil)
            return _rtmp->m_fDuration*1000;
    }
  
    
    return 0;
}

-(int64_t)timeScale
{
    return 1000;
}




@end
