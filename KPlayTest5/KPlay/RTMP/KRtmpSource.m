//
//  KRtmpSource.m
//  KPlayTest5
//
//  Created by kuzalex on 12/2/19.
//  Copyright © 2019 kuzalex. All rights reserved.
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

-(KMediaType *)getOutputMediaType
{
    if (_stream_audio==nil)
        return nil;
    return _stream_audio.type;
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


    





-(KResult)pullSample:(KMediaSample *_Nonnull*_Nullable)sample probe:(BOOL)probe error:(NSError *__strong*)error;
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
                
                if ( packet.m_packetType == RTMP_PACKET_TYPE_AUDIO ){

                    if ( _stream_audio == nil){
                        _stream_audio = [[FlvStream alloc] init];
                    }
                    KResult res;
                    if ( (res = [_stream_audio parseRtmp:&packet])!=KResult_OK){
                        DErr(@"Audio parse failed");
                        return res;
                    }
                    
                    if (_stream_audio.sample != nil ) {
                        
                        
                        *sample = _stream_audio.sample;
                        RTMPPacket_Free(&packet);
                        return KResult_OK;
                    }

                    RTMPPacket_Free(&packet);
                    
                } else if (packet.m_packetType == RTMP_PACKET_TYPE_VIDEO){
                    
                    
                    if ( _stream_video == nil){
                        _stream_video = [[FlvStream alloc] init];
                    }
                    KResult res;
                    if ( (res = [_stream_video parseRtmp:&packet])!=KResult_OK){
                        DErr(@"Audio parse failed");
                        return res;
                    }
                    
                    if (_stream_video.sample != nil ) {
                        
                        
                        *sample = _stream_video.sample;
                        RTMPPacket_Free(&packet);
                        return KResult_OK;
                    }

                    RTMPPacket_Free(&packet);
                    
                } else if (packet.m_packetType == RTMP_PACKET_TYPE_INFO) {
                    
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
    if (_stream_audio!=nil)
        return [_stream_audio duration];
    if (_stream_video!=nil)
        return [_stream_video duration];
    
    return 0;
}

-(int64_t)timeScale
{
    return 1000;
}




@end
