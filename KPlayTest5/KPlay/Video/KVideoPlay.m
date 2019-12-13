//
//  KVideoPlay.m
//  KPlayTest5
//
//  Created by kuzalex on 12/4/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "KVideoPlay.h"

#import "KPlayGraph.h"
//#define MYDEBUG
#define MYWARN
#import "myDebug.h"

#import <UIKit/UIScreen.h>
#import <GLKit/GLKit.h>
#import <GLKit/GLKViewController.h>


@interface VideoDisplay : NSObject<GLKViewDelegate>

@end

@implementation VideoDisplay{
    CMVideoDimensions dim;
    GLKView *videoPreviewView;
    BOOL videoPreviewViewOnView;
    CIContext *ciContext;
    EAGLContext *eaglContext;
    CGRect videoPreviewViewBounds; //FIXME: free resources
    CGRect viewBounds;
    
    
    
    CMTime last_sample_ts;
    KMediaSample * __block last_sample ;
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

- (void)glkView:(nonnull GLKView *)view drawInRect:(CGRect)rect
{
    
    
    
    @synchronized (self) {
        
        
        
        if (last_sample==nil)
            return;
        
        self->videoPreviewViewBounds = CGRectZero;
        self->videoPreviewViewBounds.size.width = self->videoPreviewView.drawableWidth;
        self->videoPreviewViewBounds.size.height = self->videoPreviewView.drawableHeight;
        
        BOOL updateContext = FALSE;
        if (!CGRectEqualToRect(viewBounds, self->videoPreviewViewBounds)){
            viewBounds =self->videoPreviewViewBounds;
            self->ciContext = [CIContext contextWithEAGLContext:self->eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]} ];
            updateContext = TRUE;
        }
        
        
      @autoreleasepool {
        
        CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)((KMediaSampleImageBuffer *)last_sample).image options:nil];
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
        
        //    if (s.ts.value <=41){
        [videoPreviewView bindDrawable];
        
        if (eaglContext != [EAGLContext currentContext])
            [EAGLContext setCurrentContext:eaglContext];
        
        // clear eagl view to grey
        glClearColor(0.5, 0.5, 0.5, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        
        // set the blend mode to "source over" so that CI will use that
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        
//        if (updateContext)
//            self->ciContext = [CIContext contextWithEAGLContext:self->eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]} ];

     //   DLog(@" DRAW1 (%f %f) %f x %f | (%f %f) %f x %f %p", videoPreviewViewBounds.origin.x, videoPreviewViewBounds.origin.y, videoPreviewViewBounds.size.width, videoPreviewViewBounds.size.height, drawRect.origin.x, drawRect.origin.y, drawRect.size.width, drawRect.size.height, ciContext);
     //   DLog(@" DRAW2 (%f %f) %f x %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
//        DLog(@" DRAW2 ", );
        [ciContext drawImage:sourceImage inRect:videoPreviewViewBounds fromRect:drawRect];
        //    }
        }
    }
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
            self->videoPreviewView.delegate = self;
//            self->viewBounds = view.bounds;
          //  self->videoPreviewView.enableSetNeedsDisplay = NO;
            
            
            ////
            
            ////
   
            
            self->videoPreviewView.frame = view.bounds;
            [self->videoPreviewView setTranslatesAutoresizingMaskIntoConstraints:FALSE];

            [view addSubview:self->videoPreviewView];
            [view sendSubviewToBack:self->videoPreviewView];
            

                           NSLayoutConstraint *width =[NSLayoutConstraint
                                                       constraintWithItem:self->videoPreviewView
                                                       attribute:NSLayoutAttributeWidth
                                                       relatedBy:0
                                                       toItem:view
                                                       attribute:NSLayoutAttributeWidth
                                                       multiplier:1.0
                                                       constant:0];
                           NSLayoutConstraint *height =[NSLayoutConstraint
                                                        constraintWithItem:self->videoPreviewView
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:0
                                                        toItem:view
                                                        attribute:NSLayoutAttributeHeight
                                                        multiplier:1.0
                                                        constant:0];
                           NSLayoutConstraint *top = [NSLayoutConstraint
                                                      constraintWithItem:self->videoPreviewView
                                                      attribute:NSLayoutAttributeTop
                                                      relatedBy:NSLayoutRelationEqual
                                                      toItem:view
                                                      attribute:NSLayoutAttributeTop
                                                      multiplier:1.0f
                                                      constant:0.f];
                           NSLayoutConstraint *leading = [NSLayoutConstraint
                                                          constraintWithItem:self->videoPreviewView
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                          toItem:view
                                                          attribute:NSLayoutAttributeLeading
                                                          multiplier:1.0f
                                                          constant:0.f];
                           [view addConstraint:width];
                           [view addConstraint:height];
                           [view addConstraint:top];
                           [view addConstraint:leading];
            self->videoPreviewViewOnView=TRUE;
            
            [self->videoPreviewView bindDrawable];
           
            self->videoPreviewViewBounds = CGRectZero;
            self->videoPreviewViewBounds.size.width = self->videoPreviewView.drawableWidth;
            self->videoPreviewViewBounds.size.height = self->videoPreviewView.drawableHeight;
            
            
            self->ciContext = [CIContext contextWithEAGLContext:self->eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]} ];
            dispatch_semaphore_signal(sem);
        });
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    }
    
    
    
    

    
    @synchronized (self) {
        if (s!=nil){
            last_sample = nil;
            last_sample = (KMediaSampleImageBuffer *)s;
            last_sample_ts = last_sample.ts;
        }
        
    }
    [videoPreviewView display];
    
    
    
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
                    [self displaySample:nil inView:self->_view];
                    usleep(10000);
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

