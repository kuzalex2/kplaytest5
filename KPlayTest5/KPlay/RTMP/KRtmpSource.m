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
            
            RTMP_SetBufferMS(_rtmp, 5 * 3600 * 1000);
            
            
            
           
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
                
                DLog(@"Got pkt type=%d", (int)packet.m_packetType);
                
                if ( packet.m_packetType == RTMP_PACKET_TYPE_AUDIO ){
                    
                    ///FIXME
                    if ( self->_type == nil) {
                        self->_type = [[KMediaType alloc] initWithName:@"rtmpaudiodata/xxx"];
                    }
                    
                    
                    KMediaSample *outSample = [[KMediaSample alloc] init];
                    outSample.ts = packet.m_nTimeStamp;
                    outSample.timescale = 1000;
                    outSample.type = _type;
                    
                    outSample.data = [[NSData alloc] initWithBytes:packet.m_body length:packet.m_nBodySize];
                    
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
    assert("NOT IMPLEMENTED"==nil);
    return KResult_ERROR;
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