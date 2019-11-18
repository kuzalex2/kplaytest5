//
//  myDebug.h
//  KPlayer
//
//  Created by test name on 17.04.2019.
//  Copyright © 2019 Instreamatic. All rights reserved.
//

#ifndef myDebug_h
#define myDebug_h


#ifdef MYDEBUG
#define DLog(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define DLog(format, ...)
#endif

#ifdef MYWARN
#define WLog(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define WLog(format, ...)
#endif

#define DErr(format, ...) NSLog(format, ## __VA_ARGS__)

#endif /* myDebug_h */
