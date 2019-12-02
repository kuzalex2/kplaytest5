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

@implementation KRtmpSource{
    NSString *_url;
    KMediaType *_type;
    
    NSObject *RtmpLockInit;
    NSObject *RtmpLockProcess;
    RTMP *_rtmp;
//    KMediaSample *_outSample;
//    NSError *_error;
}

-(instancetype)initWithUrl:(NSString *)url
{
    self = [super init];
    if (self) {
        self->_type = nil;
        
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
    return _type;
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
                    
                    ///FIXME!!!
                    ///FIXME!!!
                    ///FIXME!!!
                    ///FIXME!!!
                    ///FIXME!!!
                    if ( self->_type == nil) {
                        ///fixme
                        AudioStreamBasicDescription format;
                        format.mSampleRate = 44100;
                        format.mFormatID = kAudioFormatLinearPCM;
                        format.mChannelsPerFrame = 2;
                        format.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
                        format.mBitsPerChannel   = (UInt32)(8 * 2 );
                        format.mBytesPerFrame    = (UInt32)(2 * format.mChannelsPerFrame);
                        format.mFramesPerPacket  = 1;
                        format.mBytesPerPacket   = format.mBytesPerFrame * format.mFramesPerPacket;
                        format.mReserved         = 0;
                        
                        
                                           
                        CMFormatDescriptionRef      cmformat;
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
                            
                            return KResult_ERROR;
                        }
                        
                        self->_type = [[KMediaType alloc] initWithName:@"audio/pcm"];
                        [self->_type setFormat:cmformat];
                        
                       // self->_type = [[KMediaType alloc] initWithName:@"rtmpaudiodata/xxx"];
                    }
                    
                    
                    KMediaSample *outSample = [[KMediaSample alloc] init];
                    outSample.ts = packet.m_nTimeStamp;
                    outSample.timescale = 1000;
                    outSample.type = _type;
                    
                    outSample.data = [[NSData alloc] initWithBytes:packet.m_body+1 length:packet.m_nBodySize-1];
                    
                    RTMPPacket_Free(&packet);
                    
                    *sample = outSample;
                    return KResult_OK;
                    
                    
                   
                    
                    
                    
                } else if (packet.m_packetType == RTMP_PACKET_TYPE_VIDEO){
                    
                    
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
    
    
//    KResult res;
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
    //assert("NOT IMPLEMENTED"==nil);
    return 44650;
}

-(int64_t)timeScale
{
    return 1000;
}




@end
