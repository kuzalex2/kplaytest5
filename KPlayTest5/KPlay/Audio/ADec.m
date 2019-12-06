//
//  ADec.m
//  KPlayTest5
//
//  Created by kuzalex on 12/5/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

#import "ADec.h"
#import "KTestFilters.h"


///FIXME: FREE resources

#define MYDEBUG
#define MYWARN
#include "myDebug.h"


#include <AudioToolbox/AudioToolbox.h>



@implementation ADec{
    AudioConverterRef _audioConverter;
    
    //;
}


    - (OSStatus)setupAudioConverter:(const AudioStreamBasicDescription *)inputASBD{
        AudioStreamBasicDescription outFormat;
        memset(&outFormat, 0, sizeof(outFormat));
        
        outFormat.mChannelsPerFrame = inputASBD->mChannelsPerFrame;
        outFormat.mSampleRate = 44100 ;
        outFormat.mBitsPerChannel  = 16;
        outFormat.mFormatID         = kAudioFormatLinearPCM;
        outFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger;
        
        outFormat.mBytesPerFrame    = (UInt32)(outFormat.mBitsPerChannel / 8 * outFormat.mChannelsPerFrame);
        outFormat.mFramesPerPacket  = 1;
        outFormat.mBytesPerPacket   = outFormat.mBytesPerFrame * outFormat.mFramesPerPacket;
        outFormat.mReserved         = 0;
        
        
        AudioStreamBasicDescription inFormat;
        memset(&inFormat, 0, sizeof(inFormat));
        inFormat = *inputASBD;
     //   inFormat.mSampleRate        = 22050;
//        inFormat.mFormatID          = kAudioFormatMPEG4AAC;
//        inFormat.mFormatFlags       = kMPEG4Object_AAC_LC;
        inFormat.mBytesPerPacket    = 0;
        inFormat.mFramesPerPacket   = 1024;
        inFormat.mBytesPerFrame     = 0;
      //      inFormat.mChannelsPerFrame  = 1;
        inFormat.mBitsPerChannel    = 0;
        inFormat.mReserved          = 0;
        
        OSStatus status =  AudioConverterNew(&inFormat, &outFormat, &_audioConverter);
        if (status != noErr) {
            printf("setup converter error, status: %i\n", (int)status);
            return status;
        }
        
        CMFormatDescriptionRef      cmformat;
       
        if ( (status=CMAudioFormatDescriptionCreate(kCFAllocatorDefault,
                                           &outFormat,
                                           0,
                                           NULL,
                                           0,
                                           NULL,
                                           NULL,
                                           &cmformat))!=noErr)
        {
            DErr(@"Could not create format from AudioStreamBasicDescription");
            return status;
        }
        _out_type = [[KMediaType alloc]initWithName:@"audio/pcm"];
        [_out_type setFormat:cmformat];
        
        return status;
    }

    -(BOOL)isInputMediaTypeSupported:(KMediaType *)type
    {
        if (type.name!=nil && [type.name compare:@"audio"]>=0)
        {
            const AudioStreamBasicDescription  * _Nullable pformat  = CMAudioFormatDescriptionGetStreamBasicDescription(type.format);
            if (pformat==nil){
                DErr(@"VTDec format is audio, but no CMFormatDescriptionRef");
                return FALSE;
            }
            
            if (pformat->mFormatID==kAudioFormatMPEG4AAC) {
                if ([self setupAudioConverter:pformat]==noErr){
                    
                    return TRUE;
                }
                
            }
            DLog(@"Not supported format");

            return FALSE;
        }
        
        return FALSE;
        
    }

    

    struct PassthroughUserData {
        UInt32 mChannels;
        UInt32 mDataSize;
        const void* mData;
        AudioStreamPacketDescription mPacket;
    };

    OSStatus inInputDataProc(AudioConverterRef aAudioConverter,
                             UInt32* aNumDataPackets /* in/out */,
                             AudioBufferList* aData /* in/out */,
                             AudioStreamPacketDescription** aPacketDesc,
                             void* aUserData)
    {

        struct PassthroughUserData* userData = (struct PassthroughUserData*)aUserData;
        if (!userData->mDataSize) {
            *aNumDataPackets = 0;
            return 'nmda';
        }

        if (aPacketDesc) {
            userData->mPacket.mStartOffset = 0;
            userData->mPacket.mVariableFramesInPacket = 0;
            userData->mPacket.mDataByteSize = userData->mDataSize;
            *aPacketDesc = &userData->mPacket;
        }

        aData->mBuffers[0].mNumberChannels = userData->mChannels;
        aData->mBuffers[0].mDataByteSize = userData->mDataSize;
//        aData->mBuffers[0].mData = const_cast<void*>(userData->mData);
        aData->mBuffers[0].mData = (void*)(userData->mData);

        // No more data to provide following this run.
        userData->mDataSize = 0;

        return noErr;
    }

    -(void)flush
    {
        ///FIXME: TODO
    }

    -(KResult)decodeSample:(KMediaSample *)sample andCallback:(OnMediaSampleCallback)onSuccess
    {

    //- (KResult)decodeAudioFrame:(NSData *)frame withPts:(NSInteger)pts

        if(!_audioConverter){
            DErr(@"no audio converter");
            return KResult_ERROR;
        }
        
        if (sample==nil || sample.data==nil){
            DErr(@"sample==nil || sample.data==nil");
            return KResult_ERROR;
        }

        struct PassthroughUserData userData = { 1, (UInt32)sample.data.length, [sample.data bytes]};
//        {
//            int sz = (int)sample.data.length;
//            printf("Sample len=%d [ ",sz);
//            char *ptr = (char *)[sample.data bytes];
//            for (int i=0;i<sz;i++){
//                printf("%x ",*ptr++ & 0xff);
//            }
//            printf("]\n");
//        }
        
        NSMutableData *decodedData = [NSMutableData new];

        const uint32_t MAX_AUDIO_FRAMES = 128;
        const uint32_t maxDecodedSamples = MAX_AUDIO_FRAMES * 1;

        do{
            uint8_t *buffer = (uint8_t *)malloc(maxDecodedSamples * sizeof(short int));
            AudioBufferList decBuffer;
            decBuffer.mNumberBuffers = 1;
            decBuffer.mBuffers[0].mNumberChannels = 1;
            decBuffer.mBuffers[0].mDataByteSize = maxDecodedSamples * sizeof(short int);
            decBuffer.mBuffers[0].mData = buffer;

            UInt32 numFrames = MAX_AUDIO_FRAMES;

            AudioStreamPacketDescription outPacketDescription;
            memset(&outPacketDescription, 0, sizeof(AudioStreamPacketDescription));
            outPacketDescription.mDataByteSize = MAX_AUDIO_FRAMES;
            outPacketDescription.mStartOffset = 0;
            outPacketDescription.mVariableFramesInPacket = 0;

            OSStatus rv = AudioConverterFillComplexBuffer(_audioConverter,
                                                          inInputDataProc,
                                                          &userData,
                                                          &numFrames /* in/out */,
                                                          &decBuffer,
                                                          &outPacketDescription);

            if (rv!=noErr){
                if ( rv != 'nmda') {
                    DErr(@"Error decoding audio stream: %d\n", rv);
                    return KResult_ERROR;
                }
            }

            if (numFrames) {
                [decodedData appendBytes:decBuffer.mBuffers[0].mData length:decBuffer.mBuffers[0].mDataByteSize];
            }

            if (rv == 'nmda') {
                if (onSuccess!=nil && decodedData.length>0){
                    KMediaSample *out_sample = [[KMediaSample alloc]init];
                    out_sample.type = _out_type;

                    ///FIXME: calculate it
                    out_sample.ts = sample.ts;
                    out_sample.timescale = sample.timescale;
                    out_sample.data = decodedData;
                
                
                    onSuccess(out_sample);
                }
                //void *pData = (void *)[decodedData bytes];
                //audioRenderer->Render(&pData, decodedData.length, pts);
                return KResult_OK;
            }

        } while (true);
    }

@end
