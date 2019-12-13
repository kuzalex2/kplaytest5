//
//  KVideoPlay.m
//  KPlayTest5
//
//  Created by kuzalex on 12/4/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KVideoPlay.h"

#import "KPlayGraph.h"
#define MYDEBUG
#define MYWARN
#import "myDebug.h"

#import <UIKit/UIScreen.h>
#import <GLKit/GLKit.h>
#import <GLKit/GLKViewController.h>


@interface VideoDisplay : NSObject

@end

@implementation VideoDisplay{
    CMVideoDimensions dim;
    GLKView *videoPreviewView;
    BOOL videoPreviewViewOnView;
    CIContext *ciContext;
    EAGLContext *eaglContext;
    CGRect videoPreviewViewBounds;
    
    CMTime last_sample_ts;
}

-(BOOL)isInputMediaTypeSupported:(KMediaType *)type
{
    if ([type.name isEqualToString:@"image/CVImageBufferRef"]){
        KMediaTypeImageBuffer *itype = (KMediaTypeImageBuffer *)type;
        dim=itype.dimension;
        return TRUE;
    }
    return FALSE;
}



- (KResult)displaySample:(KMediaSample *) s inView:(UIView *)view
{
   
  //  [self initVideo:view];
    
    if (videoPreviewView==nil || !videoPreviewViewOnView){
        
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (self->videoPreviewView!=nil){
                [view addSubview:self->videoPreviewView];
                [view sendSubviewToBack:self->videoPreviewView];
                self->videoPreviewViewOnView=TRUE;
                dispatch_semaphore_signal(sem);
                return;
            }
            
            self->eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
            self->videoPreviewView = [[GLKView alloc] initWithFrame:view.bounds context:self->eaglContext];
            self->videoPreviewView.enableSetNeedsDisplay = NO;
            
            
//            if (self->dim.width>self->dim.height){
//                self->videoPreviewView.transform=CGAffineTransformMakeRotation(M_PI_2);
//            } else {
//                self->videoPreviewView.transform=CGAffineTransformMakeRotation(0);
//
//            }
            
            
            
            self->videoPreviewView.frame = view.bounds;
            
            [view addSubview:self->videoPreviewView];
            [view sendSubviewToBack:self->videoPreviewView];
            self->videoPreviewViewOnView=TRUE;
            
            [self->videoPreviewView bindDrawable];
            
//            self->videoPreviewView.transform=CGAffineTransformMakeScale((float)self->dim.width/self->videoPreviewView.drawableWidth, (float)self->dim.height/self->videoPreviewView.drawableHeight);
            
           // float kX = (float)self->videoPreviewView.drawableWidth/self->dim.width;
            
//             self->videoPreviewView.transform=CGAffineTransformMakeScale(kX, kX);
            
           
            self->videoPreviewViewBounds = CGRectZero;
            self->videoPreviewViewBounds.size.width = self->videoPreviewView.drawableWidth;
            self->videoPreviewViewBounds.size.height = self->videoPreviewView.drawableHeight;
            
            
            self->ciContext = [CIContext contextWithEAGLContext:self->eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]} ];
            dispatch_semaphore_signal(sem);
        });
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    }
    
    
   
//    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
//
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self->videoPreviewViewBounds = CGRectZero;
//        self->videoPreviewViewBounds.size.width = view.bounds.size.width * 2 ;
//        self->videoPreviewViewBounds.size.height = view.bounds.size.height * 2;
//
////        self->videoPreviewViewBounds.size.width = self->videoPreviewView.drawableWidth;
////        self->videoPreviewViewBounds.size.height = self->videoPreviewView.drawableHeight;
//
//        DLog(@"aaa %f %f %f %f", self->videoPreviewViewBounds.origin.x, self->videoPreviewViewBounds.origin.y, self->videoPreviewViewBounds.size.width, self->videoPreviewViewBounds.size.height);
//
//        dispatch_semaphore_signal(sem);
//    });
//
//    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    
    
    
    
    
    
    KMediaSampleImageBuffer *sample = (KMediaSampleImageBuffer *)s;
    
    if (videoPreviewView==nil){
        DErr(@"videoPreviewView is NULL");
        return KResult_ERROR;
    }
    // CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)sample.image options:nil];
    CGRect sourceExtent = sourceImage.extent;
    
    
    
    
    CGFloat sourceAspect = sourceExtent.size.width / sourceExtent.size.height;
    CGFloat previewAspect = videoPreviewViewBounds.size.width  / videoPreviewViewBounds.size.height;
//    DLog(@"a1=%f a2=%f", sourceAspect, previewAspect);
//    // we want to maintain the aspect radio of the screen size, so we clip the video image
    CGRect drawRect = sourceExtent;
    if (sourceAspect < previewAspect)
    {
        // use full height of the video image, and center crop the width
        drawRect.origin.x += (drawRect.size.width - drawRect.size.height * previewAspect) / 2.0;
        drawRect.size.width = drawRect.size.height * previewAspect;
    }
    else
    {
        // use full width of the video image, and center crop the height
        drawRect.origin.y += (drawRect.size.height - drawRect.size.width / previewAspect) / 2.0;
        drawRect.size.height = drawRect.size.width / previewAspect;
    }
    
    [videoPreviewView bindDrawable];
    
    if (eaglContext != [EAGLContext currentContext])
        [EAGLContext setCurrentContext:eaglContext];
    
    // clear eagl view to grey
    glClearColor(0.5, 0.5, 0.5, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // set the blend mode to "source over" so that CI will use that
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    //if (filteredImage)
    [ciContext drawImage:sourceImage inRect:videoPreviewViewBounds fromRect:drawRect];
    
    [videoPreviewView display];
    
    last_sample_ts = sample.ts;
    return KResult_OK;
}


-(BOOL)isRunning
{
    return TRUE;
}

-(CMTime)position
{
    return last_sample_ts;
    
}



-(void)flush
{
    last_sample_ts=CMTimeMake(0, 1000);

}

-(void)onStop
{
    if (videoPreviewView!=nil && videoPreviewViewOnView){
        
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->videoPreviewView removeFromSuperview];
            self->videoPreviewViewOnView=FALSE;
            
            dispatch_semaphore_signal(sem);
        });
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    }
    
    
}



@end




@implementation KVideoPlay {
    VideoDisplay *_video;
    UIView *_view;
    KMediaSample * __block _last_sample ;
}

- (instancetype)initWithUIView:(UIView *)view
{
    self = [super init];
    if (self) {
        [self.inputPins addObject:[[KInputPin alloc] initWithFilter:self]];
        self->_video = nil;
        self->_view=view;
        self->_last_sample=nil;
    }
    return self;
}

-(BOOL)isInputMediaTypeSupported:(KMediaType *)type
{
    if (_video==nil)
        _video = [[VideoDisplay alloc] init];
    
    return [_video isInputMediaTypeSupported:type];
}


- (void)onStateChanged:(KFilter *)filter state:(KFilterState)state
{
    switch (_state) {
        case KFilterState_STOPPED:
            if (_video!=nil){
               // [_video deinitVideo];
                //[_video stop_];
                [_video flush];
                [_video onStop];
                _last_sample = nil;
               
            }
            break;
        case KFilterState_STOPPING:
            break;
        case KFilterState_PAUSING:{
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [_video initVideo:_view];
//            });
//            sleep(1);
//            if (_video!=nil){
//                [_video pause_];
//            }
            break;}
        case KFilterState_STARTED:
//            if (_video!=nil){
//                [_video waitForRun_];
//               // _queue = nil;
//            }
            break;
        case KFilterState_PAUSED:
            
            break;
    }
}

- (KResult)displaySample:(KMediaSample *) s inView:(UIView *)view
{
    if (s.eos) {
        if ([self.events respondsToSelector:@selector(onEOS:)]) {
            [self.events onEOS:self];
        }
        return KResult_OK;
    }
      
    return [self->_video displaySample:s inView:view];
}



-(KResult) onThreadTick:(NSError *__strong*)ppError
{
    KResult res;
    
    if (_video==nil){
        DErr(@"No VideoDisplay");
        return KResult_ERROR;
    }
    
    
    if (_last_sample==nil)
    {
        KInputPin *pin = [self getInputPinAt:0];
        
        @autoreleasepool
        {
            KMediaSample *newSample;
            
            res = [pin pullSample:&newSample probe:NO error:ppError];
            
            if (res != KResult_OK) {
                if (*ppError!=nil){
                    DErr(@"%@ %@", [self name], *ppError);
                }
                return res;
            }
            _last_sample = newSample;
            DLog(@"%@ <%@> got sample type=%@ %ld bytes, ts=%lld/%d", self, [self name], _last_sample.type.name, [_last_sample.data length], _last_sample.ts.value, _last_sample.ts.timescale);
        }
    }
    
    if (_last_sample==nil){
        DErr(@"No Sample VideoPlay");
        return KResult_ERROR;
    }
    
    if (self.clock && self.clock!=self) {
        
        switch ([self state]) {
            case KFilterState_STOPPED:
            case KFilterState_STOPPING:
                // skip
                break;
            case KFilterState_PAUSING:
            case KFilterState_PAUSED:
                //show
                [self displaySample:_last_sample inView:self->_view];
                _last_sample=nil;
                break;
            case KFilterState_STARTED:{
                
                int64_t nowTimeMillisec = CMTimeConvertScale([self.clock position], 1000, kCMTimeRoundingMethod_Default).value;
                int64_t sampleTimeMillisec = CMTimeConvertScale(_last_sample.ts, 1000, kCMTimeRoundingMethod_Default).value;

                if (nowTimeMillisec < sampleTimeMillisec-10){
                    usleep(1000);
                    return KResult_OK;
                } else if (nowTimeMillisec > sampleTimeMillisec+10){
                    //опоздал
                    WLog(@"%@ skip sample now=%lld sample=%lld", [self name], nowTimeMillisec,sampleTimeMillisec);
                    _last_sample=nil;
                } else {
                    DLog(@"%@ play sample %lld %lld", [self name],nowTimeMillisec,sampleTimeMillisec);
                    [self displaySample:_last_sample inView:self->_view];
                    _last_sample=nil;
                }
                
                break;
            }
            
        }
        
    } else {
        WLog(@"%@ play sample %lld/%d", [self name],_last_sample.ts.value, _last_sample.ts.timescale);

        [self displaySample:_last_sample inView:self->_view];
        _last_sample=nil;
    }
    
    return KResult_OK;
}

-(KResult)seek:(float)sec
{
  //  [_queue stop_];
    [_video flush];
    _last_sample=nil;
    return KResult_OK;
}

///
///  KPlayPositionInfo
///

-(CMTime)position
{
    if (_video!=nil)
        return [_video position];
    return CMTimeMake(0, 1);
}



- (BOOL)isRunning {
    if (_video!=nil)
        return [_video isRunning];
    return FALSE;
}



@end

