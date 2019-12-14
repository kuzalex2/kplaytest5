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
    - (instancetype)initWithView:(UIView *)view;
@end

@implementation VideoDisplay{
    GLKView *glkView;
    CIContext *ciContext;
    EAGLContext *eaglContext;
    KMediaSample * __block last_sample ;
}

- (instancetype)initWithView:(UIView *)view
{
    self = [super init];
    if (self) {
        self->eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        self->glkView = [[GLKView alloc] initWithFrame:view.bounds context:self->eaglContext];
        self->glkView.delegate = self;
        self->glkView.frame = view.bounds;
        [self->glkView setTranslatesAutoresizingMaskIntoConstraints:FALSE];

        NSArray *viewsToRemove = [view subviews];
        for (UIView *v in viewsToRemove) {
            [v removeFromSuperview];
        }
        
        [view addSubview:self->glkView];
        [view sendSubviewToBack:self->glkView];
        
       
        
        
        NSLayoutConstraint *width =[NSLayoutConstraint
                                    constraintWithItem:self->glkView
                                    attribute:NSLayoutAttributeWidth
                                    relatedBy:0
                                    toItem:view
                                    attribute:NSLayoutAttributeWidth
                                    multiplier:1.0
                                    constant:0];
        NSLayoutConstraint *height =[NSLayoutConstraint
                                     constraintWithItem:self->glkView
                                     attribute:NSLayoutAttributeHeight
                                     relatedBy:0
                                     toItem:view
                                     attribute:NSLayoutAttributeHeight
                                     multiplier:1.0
                                     constant:0];
        NSLayoutConstraint *top = [NSLayoutConstraint
                                   constraintWithItem:self->glkView
                                   attribute:NSLayoutAttributeTop
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:view
                                   attribute:NSLayoutAttributeTop
                                   multiplier:1.0f
                                   constant:0.f];
        NSLayoutConstraint *leading = [NSLayoutConstraint
                                       constraintWithItem:self->glkView
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
                    
        [self->glkView bindDrawable];
        
        
        self->ciContext = [CIContext contextWithEAGLContext:self->eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]} ];
    }
    return self;
}


- (void)dealloc
{
    ///FIXME: deinit from destroy graph!
    dispatch_async(dispatch_get_main_queue(), ^{
       // [self->glkView removeFromSuperview];
    });
}


- (void)glkView:(nonnull GLKView *)view drawInRect:(CGRect)rect
{
    @synchronized (self) {
        
        if (last_sample==nil) {
            glClear(GL_COLOR_BUFFER_BIT);
            return;
        }
      
        @autoreleasepool {
        
            CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)((KMediaSampleImageBuffer *)last_sample).image options:nil];
            CGRect sourceExtent = sourceImage.extent;
        
        
        
        
            CGFloat sourceAspect = sourceExtent.size.width / sourceExtent.size.height;
            CGFloat previewAspect = (CGFloat)glkView.drawableWidth  / glkView.drawableHeight;
       
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
        
            [glkView bindDrawable];
        
            if (eaglContext != [EAGLContext currentContext])
                [EAGLContext setCurrentContext:eaglContext];
        
            // clear eagl view to grey
            //glClearColor(0.5, 0.5, 0.5, 1.0);
            glClear(GL_COLOR_BUFFER_BIT);
            
            // set the blend mode to "source over" so that CI will use that
            glEnable(GL_BLEND);
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        
            [ciContext drawImage:sourceImage inRect:CGRectMake(0, 0, glkView.drawableWidth, glkView.drawableHeight) fromRect:drawRect];
        }
    }
}

- (void)displaySample:(KMediaSample *) s //inView:(UIView *)view
{
    
    @synchronized (self) {
        if (s!=nil){
            last_sample = nil;
            last_sample = (KMediaSampleImageBuffer *)s;
        }
    }
    [glkView display];
}

-(CMTime)position
{
    @synchronized (self) {
        if (last_sample!=nil)
            return last_sample.ts;
        return CMTimeMake(0, 1);
    }
}



-(void)flush
{
    @synchronized (self) {
        last_sample=nil;
    }
    [glkView display];
}

//-(void)onStop
//{
//    if (videoPreviewView!=nil && videoPreviewViewOnView){
//
//        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self->videoPreviewView removeFromSuperview];
//            self->videoPreviewViewOnView=FALSE;
//
//            dispatch_semaphore_signal(sem);
//        });
//
//        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
//    }
//
//
//}



@end




@implementation KVideoPlay {
    VideoDisplay *_video;
    KMediaSample * __block _last_sample ;
}

- (instancetype)initWithUIView:(UIView *)view
{
    self = [super init];
    if (self) {
        [self.inputPins addObject:[[KInputPin alloc] initWithFilter:self]];
        self->_video = [[VideoDisplay alloc] initWithView:view];
        self->_last_sample=nil;
    }
    return self;
}




-(BOOL)isInputMediaTypeSupported:(KMediaType *)type
{
    if ([type.name isEqualToString:@"image/CVImageBufferRef"]){
        //KMediaTypeImageBuffer *itype = (KMediaTypeImageBuffer *)type;
        return TRUE;
    }
    return FALSE;
}


- (void)onStateChanged:(KFilter *)filter state:(KFilterState)state
{
    switch (_state) {
        case KFilterState_STOPPED:
            [_video flush];
            _last_sample = nil;
            
            break;
        default:
            break;
    }
}

- (KResult)displaySample:(KMediaSample *) s// inView:(UIView *)view
{
    if (s.eos) {
        if ([self.events respondsToSelector:@selector(onEOS:)]) {
            [self.events onEOS:self];
        }
        return KResult_OK;
    }
      
    [_video displaySample:s];
    return KResult_OK;
}



-(KResult) onThreadTick:(NSError *__strong*)ppError
{
    KResult res;
    
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
                [self displaySample:_last_sample];
                _last_sample=nil;
                break;
            case KFilterState_STARTED:{
                
                int64_t nowTimeMillisec = CMTimeConvertScale([self.clock position], 1000, kCMTimeRoundingMethod_Default).value;
                int64_t sampleTimeMillisec = CMTimeConvertScale(_last_sample.ts, 1000, kCMTimeRoundingMethod_Default).value;

                if (nowTimeMillisec < sampleTimeMillisec-10){
//                    [self displaySample:nil];//???
                    usleep(10000);
                    return KResult_OK;
                } else if (nowTimeMillisec > sampleTimeMillisec+10){
                    //опоздал
                    WLog(@"%@ skip sample now=%lld sample=%lld", [self name], nowTimeMillisec,sampleTimeMillisec);
                    _last_sample=nil;
                } else {
                    DLog(@"%@ play sample %lld %lld", [self name],nowTimeMillisec,sampleTimeMillisec);
                    [self displaySample:_last_sample];
                    _last_sample=nil;
                }
                
                break;
            }
            
        }
        
    } else {
        WLog(@"%@ play sample %lld/%d", [self name],_last_sample.ts.value, _last_sample.ts.timescale);

        [self displaySample:_last_sample];
        _last_sample=nil;
    }
    
    return KResult_OK;
}

-(KResult)seek:(float)sec
{
    [_video flush];
    _last_sample=nil;
    return KResult_OK;
}

///
///  KPlayPositionInfo
///

-(CMTime)position
{
    return [_video position];
}

- (BOOL)isRunning {
    return TRUE;
}



@end

