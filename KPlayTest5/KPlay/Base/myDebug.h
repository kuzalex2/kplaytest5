//
//  myDebug.h
//  KPlayer
//
//  Created by test name on 17.04.2019.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#ifndef myDebug_h
#define myDebug_h


#ifdef MYDEBUG
#define DLog(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define DLog(format, ...)
#endif

#ifdef MYDEBUG1
#define DLog1(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define DLog1(format, ...)
#endif

#ifdef MYDEBUG2
#define DLog2(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define DLog2(format, ...)
#endif

#ifdef MYDEBUG3
#define DLog3(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define DLog3(format, ...)
#endif

#ifdef MYWARN
#define WLog(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define WLog(format, ...)
#endif

#define DErr(format, ...) NSLog(format, ## __VA_ARGS__)

#endif /* myDebug_h */
