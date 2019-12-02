//#include <stdio.h>
//#include <stdlib.h>
//#include <stdint.h>
//#include <stdbool.h>
//#include <string.h>
//
//#include "rtmp_sys.h"
//#include "log.h"
//#include <pthread.h>
//#include <stdio.h>
//
//
//void *stopRtmpFoo(void *rtmp)
//{
//    sleep(2);
//    fprintf(stderr, "Stopping...\n");
//    RTMP_Close(rtmp);
//    return NULL;
//}
//
//
//
//
//int main(int argc, char *argv[]) {
//
////    double duration = -1;
//    int nread = 0;
//    //is live stream ?
//    bool b_live_stream = true;
//
//    int bufsize = 1024 * 1024 * 10;
//    char *buf = (char *) malloc(bufsize);
//    memset(buf, 0, bufsize);
//    long countbufsize = 0;
//
//    FILE *fp = fopen("receive.flv", "wb");
//    if (NULL == fp) {
//        RTMP_LogPrintf("Open File Error.\n");
//        return -1;
//    }
//
//    /* set log level */
//    RTMP_LogLevel loglvl=RTMP_LOGDEBUG;
//
//
//    RTMP_LogSetLevel(loglvl);
//
//    RTMP *rtmp = RTMP_Alloc();
//    RTMP_Init(rtmp);
//    //set connection timeout,default 30s
//    rtmp->Link.timeout = 60;
//    // HKS's live URL
////    if (!RTMP_SetupURL(rtmp, "rtmp://176.9.99.77/vod/test.mp4")) {
//    if (!RTMP_SetupURL(rtmp, "rtmp://176.9.99.77:1936/vod/test.mp4")) {
//        RTMP_Log(RTMP_LOGERROR, "SetupURL Err\n");
//        RTMP_Free(rtmp);
//        return -1;
//    }
//    if (b_live_stream) {
//        rtmp->Link.lFlags |= RTMP_LF_LIVE;
//    }
//
//    //1hour
//    RTMP_SetBufferMS(rtmp, 3600 * 1000);
//
//
//
//	////////////////////
//	pthread_t stopRtmpThread;
//
//	/* create a second thread which executes inc_x(&x) */
//	if(pthread_create(&stopRtmpThread, NULL, stopRtmpFoo, rtmp)) {
//
//		fprintf(stderr, "Error creating thread\n");
//		return 1;
//
//	}
//
//
////	RTMP_Close(rtmp);
//	/////////////////////
//
//
//    if (!RTMP_Connect(rtmp, NULL)) {
//        RTMP_Log(RTMP_LOGERROR, "Connect Err\n");
//        RTMP_Free(rtmp);
//        return -1;
//    }
//
//    if (!RTMP_ConnectStream(rtmp, 0)) {
//        RTMP_Log(RTMP_LOGERROR, "ConnectStream Err\n");
//        RTMP_Free(rtmp);
//        RTMP_Close(rtmp);
//        return -1;
//    }
//
//    while ((nread = RTMP_Read(rtmp, buf, bufsize)) != 0) {
//        fwrite(buf, 1, (size_t)nread, fp);
//
//        countbufsize += nread;
//        RTMP_LogPrintf("Receive: %5dByte, Total: %5.2fkB\n", nread, countbufsize * 1.0 / 1024);
//    }
//
//    if (fp != NULL) {
//        fclose(fp);
//        fp = NULL;
//    }
//
//    if (buf != NULL) {
//        free(buf);
//        buf = NULL;
//    }
//
//    if (rtmp != NULL) {
//        RTMP_Close(rtmp);
//        RTMP_Free(rtmp);
//        rtmp = NULL;
//    }
//    return 0;
//}
//
