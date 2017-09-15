



//
//  ExampleSpeechRecognizer.m
//  RTCRoomsDemo
//
//  Created by Chris Eagleston on 6/23/17.
//  Copyright © 2017 Twilio, Inc. All rights reserved.
//




#import "ExampleSpeechRecognizer.h"
//#import "IsLiveSharedInstance.h"

#import <AudioToolbox/AudioToolbox.h>
#import <Speech/Speech.h>
//#import "User.swift"

@class MainViewController;
//@class SingletonManager;
//@class Singleton;
//@class User;

@interface ExampleSpeechRecognizer() <TVIAudioSink>


@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *speechRequest;
@property (nonatomic, strong) SFSpeechRecognitionTask *speechTask;
@property (nonatomic, assign) AudioConverterRef speechConverter;

@property (nonatomic, copy) NSString *speechResult;
@property (nonatomic, weak) TVIAudioTrack *audioTrack;
@property (nonatomic, weak) MainViewController *mainViewController;

//@property (assign) BOOL isLive;

@property(nonatomic, assign) int myValue;
@property(nonatomic, assign) int randomInteger;

@property(nonatomic, assign) NSString *localeString;
@property(nonatomic, assign) NSLocale *locale;



@end


@implementation ExampleSpeechRecognizer


static ExampleSpeechRecognizer* _sharedExampleSpeechRecognizer = nil;

+(ExampleSpeechRecognizer*)sharedExampleSpeechRecognizer
{
    //randomInteger = [self random
    
    @synchronized([ExampleSpeechRecognizer class])
    {
        if (!_sharedExampleSpeechRecognizer)
            [[self alloc] init];
        
        return _sharedExampleSpeechRecognizer;
    }
    
    return nil;
}
/*
+ (void)resetSharedInstance {
    @synchronized(self) {
        _sharedExampleSpeechRecognizer = nil;
    }
}*/

+(id)alloc
{
    @synchronized([ExampleSpeechRecognizer class])
    {
        NSAssert(_sharedExampleSpeechRecognizer == nil, @"Attempted to allocate a second instance of a singleton.");
        _sharedExampleSpeechRecognizer = [super alloc];
        return _sharedExampleSpeechRecognizer;
    }
    
    return nil;
}

/*-(id)init {
 self = [super init];
 if (self != nil) {
 // initialize stuff here
 }
 
 return self;
 }*/

-(void)sayHello {
    NSLog(@"Hello World!");
    _randomInteger = [self getRandomNumberBetween:9 to:99];
    NSLog(@"Random: %d", _randomInteger);
}

-(int)getRandomNumberBetween:(int)from to:(int)to {
    
    return (int)from + arc4random() % (to-from+1);
}

//Following not added
- (void)initWithAudioTrack:(TVIAudioTrack *)audioTrack languageId:(NSString*)id andCompletionHandler:(void (^)(NSString* result))completionHandler {
    NSLog(@"init recognition called");
    
    _localeString = id;
    _myValue = 0;
    
    if (self != nil) {
        NSLog(@"%@", _localeString);
        
        _locale = [NSLocale localeWithLocaleIdentifier:_localeString];
        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:_locale];
        _speechRecognizer.defaultTaskHint = SFSpeechRecognitionTaskHintDictation;
        
        _speechRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
        _speechRequest.shouldReportPartialResults = YES;
        
        
        __weak typeof(self) weakSelf = self;
        NSLog(@"Speech recognition will begin...");
        _speechTask = [_speechRecognizer recognitionTaskWithRequest:_speechRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
            
            __strong typeof(self) strongSelf = weakSelf;
            _myValue = _myValue + 1;
            
            if (result) {
                if (result.isFinal) {
                    //Recognizer will restart upon final result
                    strongSelf.speechResult = result.bestTranscription.formattedString;
                    completionHandler(strongSelf.speechResult);
                    completionHandler(@"//isFinal");
                    
                }
                else {
                    strongSelf.speechResult = result.bestTranscription.formattedString;
                    NSLog(@"Results: %@", strongSelf.speechResult);
                    completionHandler(strongSelf.speechResult);
                    
                }
            } else {
                NSLog(@"Speech recognition error: %@", error);
                completionHandler(@"//error");
            }
        }];
        
        _audioTrack = audioTrack;
        [_audioTrack addSink:self];
        _trackId = _audioTrack.trackId;
    }
}

-(void)restartRecognition {
    NSLog(@"restartRecognition called...");
    [self.audioTrack removeSink:self];
    
    [self.speechTask cancel];
    self.speechRequest = nil;
    self.speechRecognizer = nil;
    
    if (self.speechConverter != NULL) {
        AudioConverterDispose(self.speechConverter);
        self.speechConverter = NULL;
    }
    
    NSLog(@"myValue: %d",_myValue);
    NSLog(@"Random: %d", _randomInteger);
    NSLog(@"Speech recognition ready for restart");
}

//- (void)someMethodThatTakesABlock:(returnType (^nullability)(parameterTypes))blockName;

//- (void)initWithAudioTrack:(TVIAudioTrack *)audioTrack languageId:(NSString*)id andCompletionHandler:(void (^)(NSString* result))completionHandler;


- (void)stopRecognizing: (void (^)(NSString* result))completionHandler{
    //_isLive = false;
    NSLog(@"stopRecognizing called...");
    [self.audioTrack removeSink:self];
    
    [self.speechTask cancel];
    self.speechRequest = nil;
    self.speechRecognizer = nil;
    
    if (self.speechConverter != NULL) {
        AudioConverterDispose(self.speechConverter);
        self.speechConverter = NULL;
    }
    
    _sharedExampleSpeechRecognizer = nil;
    
    NSLog(@"myValue: %d",_myValue);
    NSLog(@"Random: %d", _randomInteger);
    NSLog(@"Speech recognition ended");
    completionHandler(@"done");
}
/*
- (void)stopRecognizing {
    //_isLive = false;
    NSLog(@"stopRecognizing called...");
    [self.audioTrack removeSink:self];
    
    [self.speechTask cancel];
    self.speechRequest = nil;
    self.speechRecognizer = nil;
    
    if (self.speechConverter != NULL) {
        AudioConverterDispose(self.speechConverter);
        self.speechConverter = NULL;
    }
    
    _sharedExampleSpeechRecognizer = nil;
    
    NSLog(@"myValue: %d",_myValue);
    NSLog(@"Random: %d", _randomInteger);
    NSLog(@"Speech recognition ended");
}*/

#pragma mark - TVIAudioSink

- (void)renderSample:(CMSampleBufferRef)audioSample {
    CMAudioFormatDescriptionRef coreMediaFormat = (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(audioSample);
    const AudioStreamBasicDescription *basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(coreMediaFormat);
    
    // Detect and discard the initial invalid samples...
    // Waits for the track to start producing stereo audio, and for the timestamp to be reset.
    if (basicDescription->mChannelsPerFrame != 2) {
        return;
    }
    
    AVAudioFrameCount frameCount = (AVAudioFrameCount)CMSampleBufferGetNumSamples(audioSample);
    AVAudioFormat *avAudioFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16
                                                                    sampleRate:basicDescription->mSampleRate
                                                                      channels:1
                                                                   interleaved:YES];
    AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:avAudioFormat frameCapacity:frameCount];
    
    // Allocate an AudioConverter to perform mono downmixing for us.
    if (self.speechConverter == NULL) {
        OSStatus status = AudioConverterNew(basicDescription, avAudioFormat.streamDescription, &_speechConverter);
        if (status != 0) {
            NSLog(@"Failed to create AudioConverter: %d", status);
            return;
        }
    }
    
    // Fill the AVAudioPCMBuffer with downmixed mono audio.
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(audioSample);
    size_t inputBytes = 0;
    char *inputSamples = NULL;
    OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &inputBytes, &inputSamples);
    
    if (status == 0) {
        // Allocate some memory for us...
        pcmBuffer.frameLength = pcmBuffer.frameCapacity;
        AudioBufferList *bufferList = pcmBuffer.mutableAudioBufferList;
        AudioBuffer buffer = bufferList->mBuffers[0];
        void *outputSamples = buffer.mData;
        UInt32 outputBytes = buffer.mDataByteSize;
        
        status = AudioConverterConvertBuffer(_speechConverter, (UInt32)inputBytes, (const void *)inputSamples, &outputBytes, outputSamples);
        
        if (status == 0) {
            [self.speechRequest appendAudioPCMBuffer:pcmBuffer];
        } else {
            NSLog(@"Failed to convert audio: %d", status);
        }
    } else {
        NSLog(@"Failed to get data pointer: %d", status);
    }
}

@end

























/*
#import "ExampleSpeechRecognizer.h"
#import "IsLiveSharedInstance.h"

#import <AudioToolbox/AudioToolbox.h>
#import <Speech/Speech.h>
//#import "User.swift"

@class MainViewController;
//@class SingletonManager;
//@class Singleton;
//@class User;

@interface ExampleSpeechRecognizer() <TVIAudioSink>


@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *speechRequest;
@property (nonatomic, strong) SFSpeechRecognitionTask *speechTask;
@property (nonatomic, assign) AudioConverterRef speechConverter;

@property (nonatomic, copy) NSString *speechResult;
@property (nonatomic, weak) TVIAudioTrack *audioTrack;
@property (nonatomic, weak) MainViewController *mainViewController;

@property (assign) BOOL isLive;

@property(nonatomic, assign) int myValue;
@property(nonatomic, assign) int randomInteger;

@property(nonatomic, assign) NSString *localeString;
@property(nonatomic, assign) NSLocale *locale;



@end


@implementation ExampleSpeechRecognizer


static ExampleSpeechRecognizer* _sharedExampleSpeechRecognizer = nil;

+(ExampleSpeechRecognizer*)sharedExampleSpeechRecognizer
{
    //randomInteger = [self random
    
    @synchronized([ExampleSpeechRecognizer class])
    {
        if (!_sharedExampleSpeechRecognizer)
            [[self alloc] init];
        
        return _sharedExampleSpeechRecognizer;
    }
    
    return nil;
}

+ (void)resetSharedInstance {
    @synchronized(self) {
        _sharedExampleSpeechRecognizer = nil;
    }
}

+(id)alloc
{
    @synchronized([ExampleSpeechRecognizer class])
    {
        NSAssert(_sharedExampleSpeechRecognizer == nil, @"Attempted to allocate a second instance of a singleton.");
        _sharedExampleSpeechRecognizer = [super alloc];
        return _sharedExampleSpeechRecognizer;
    }
    
    return nil;
}

/*-(id)init {
    self = [super init];
    if (self != nil) {
        // initialize stuff here
    }
    
    return self;
}

-(void)sayHello {
    NSLog(@"Hello World!");
    _randomInteger = [self getRandomNumberBetween:9 to:99];
    NSLog(@"Random: %d", _randomInteger);
}

-(int)getRandomNumberBetween:(int)from to:(int)to {
    
    return (int)from + arc4random() % (to-from+1);
}

//Following not added
- (void)initWithAudioTrack:(TVIAudioTrack *)audioTrack languageId:(NSString*)id andCompletionHandler:(void (^)(NSString* result))completionHandler {
    //self = [super init];
    //[self restartRecognition];
    
    NSLog(@"init recognition called");
    _localeString = id;
    _isLive = true;
    _myValue = 0;
    
    if (self != nil) {
        //_speechRecognizer = [[SFSpeechRecognizer alloc] init];
        //[[SFSpeechRecognizer loca
        // locale: Locale(identifier: "en-US")
        NSLog(@"%@", _localeString);
         // _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:];
        _locale = [NSLocale localeWithLocaleIdentifier:_localeString];
        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:_locale];
        _speechRecognizer.defaultTaskHint = SFSpeechRecognitionTaskHintDictation;
        
        _speechRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
        _speechRequest.shouldReportPartialResults = YES;
        
        
        __weak typeof(self) weakSelf = self;
        _speechTask = [_speechRecognizer recognitionTaskWithRequest:_speechRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
            
            //NSLog(@"%@", [_speechRecognizer locale]);
            
            
            if (_isLive == true) {
                __strong typeof(self) strongSelf = weakSelf;
                NSLog(@"Speech recognition running...");
                _myValue = _myValue + 1;
                
                if (result) {
                    if (result.isFinal) {
                        //Recognizer will restart upon final result
                        strongSelf.speechResult = result.bestTranscription.formattedString;
                        NSLog(@"Results: %@", strongSelf.speechResult);
                        completionHandler(result.bestTranscription.formattedString);
                        completionHandler(@"//restart required");
                        
                    } else {
                        strongSelf.speechResult = result.bestTranscription.formattedString;
                        NSLog(@"Results: %@", strongSelf.speechResult);
                        completionHandler(result.bestTranscription.formattedString);
                        
                    }
                    
                } else {
                    NSLog(@"Speech recognition error: %@", error);
                    completionHandler(@"//error");
                    //self.stopRecognizing;
                }
            } else {
                NSLog(@"_isLive = false");
            }
            
            
        }];
        
        //MainViewController.
        
        _audioTrack = audioTrack;
        [_audioTrack addSink:self];
        _trackId = _audioTrack.trackId;
    }
    
    //return self;
}

-(void)restartRecognition {
    [self.audioTrack removeSink:self];
    
    [self.speechTask cancel];
    self.speechRequest = nil;
    self.speechRecognizer = nil;
    
    if (self.speechConverter != NULL) {
        AudioConverterDispose(self.speechConverter);
        self.speechConverter = NULL;
    }
    
    NSLog(@"myValue: %d",_myValue);
    NSLog(@"Random: %d", _randomInteger);
    NSLog(@"Speech recognition ready for restart...");
}


- (void)stopRecognizing {
    _isLive = false;
    
    [self.audioTrack removeSink:self];
    
    [self.speechTask cancel];
    self.speechRequest = nil;
    self.speechRecognizer = nil;
    
    if (self.speechConverter != NULL) {
        AudioConverterDispose(self.speechConverter);
        self.speechConverter = NULL;
    }
    
    NSLog(@"myValue: %d",_myValue);
    NSLog(@"Random: %d", _randomInteger);
    NSLog(@"Speech recognition ended");
}





#pragma mark - TVIAudioSink

- (void)renderSample:(CMSampleBufferRef)audioSample {
    CMAudioFormatDescriptionRef coreMediaFormat = (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(audioSample);
    const AudioStreamBasicDescription *basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(coreMediaFormat);
    
    // Detect and discard the initial invalid samples...
    // Waits for the track to start producing stereo audio, and for the timestamp to be reset.
    if (basicDescription->mChannelsPerFrame != 2) {
        return;
    }
    
    AVAudioFrameCount frameCount = (AVAudioFrameCount)CMSampleBufferGetNumSamples(audioSample);
    AVAudioFormat *avAudioFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16
                                                                    sampleRate:basicDescription->mSampleRate
                                                                      channels:1
                                                                   interleaved:YES];
    AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:avAudioFormat frameCapacity:frameCount];
    
    // Allocate an AudioConverter to perform mono downmixing for us.
    if (self.speechConverter == NULL) {
        OSStatus status = AudioConverterNew(basicDescription, avAudioFormat.streamDescription, &_speechConverter);
        if (status != 0) {
            NSLog(@"Failed to create AudioConverter: %d", status);
            return;
        }
    }
    
    // Fill the AVAudioPCMBuffer with downmixed mono audio.
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(audioSample);
    size_t inputBytes = 0;
    char *inputSamples = NULL;
    OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &inputBytes, &inputSamples);
    
    if (status == 0) {
        // Allocate some memory for us...
        pcmBuffer.frameLength = pcmBuffer.frameCapacity;
        AudioBufferList *bufferList = pcmBuffer.mutableAudioBufferList;
        AudioBuffer buffer = bufferList->mBuffers[0];
        void *outputSamples = buffer.mData;
        UInt32 outputBytes = buffer.mDataByteSize;
        
        status = AudioConverterConvertBuffer(_speechConverter, (UInt32)inputBytes, (const void *)inputSamples, &outputBytes, outputSamples);
        
        if (status == 0) {
            [self.speechRequest appendAudioPCMBuffer:pcmBuffer];
        } else {
            NSLog(@"Failed to convert audio: %d", status);
        }
    } else {
        NSLog(@"Failed to get data pointer: %d", status);
    }
}

@end
*/



















/*
#import "ExampleSpeechRecognizer.h"
#import "IsLiveSharedInstance.h"

#import <AudioToolbox/AudioToolbox.h>
#import <Speech/Speech.h>
//#import "User.swift"

@class MainViewController;
//@class SingletonManager;
//@class Singleton;
//@class User;

@interface ExampleSpeechRecognizer() <TVIAudioSink>


@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *speechRequest;
@property (nonatomic, strong) SFSpeechRecognitionTask *speechTask;
@property (nonatomic, assign) AudioConverterRef speechConverter;

@property (nonatomic, copy) NSString *speechResult;
@property (nonatomic, weak) TVIAudioTrack *audioTrack;
@property (nonatomic, weak) MainViewController *mainViewController;

@property (assign) BOOL isLive;

@property(nonatomic, assign) int myValue;
@property(nonatomic, assign) int randomInteger;

@property(nonatomic, assign) NSString *localeString;
@property(nonatomic, assign) NSLocale *locale;



@end


@implementation ExampleSpeechRecognizer


static ExampleSpeechRecognizer* _sharedExampleSpeechRecognizer = nil;

+(ExampleSpeechRecognizer*)sharedExampleSpeechRecognizer
{
    //randomInteger = [self random
    
    @synchronized([ExampleSpeechRecognizer class])
    {
        if (!_sharedExampleSpeechRecognizer)
            [[self alloc] init];
        
        return _sharedExampleSpeechRecognizer;
    }
    
    return nil;
}

+(id)alloc
{
    @synchronized([ExampleSpeechRecognizer class])
    {
        NSAssert(_sharedExampleSpeechRecognizer == nil, @"Attempted to allocate a second instance of a singleton.");
        _sharedExampleSpeechRecognizer = [super alloc];
        return _sharedExampleSpeechRecognizer;
    }
    
    return nil;
}

-(id)init {
    self = [super init];
    if (self != nil) {
        // initialize stuff here
    }
    
    return self;
}

-(void)sayHello {
    NSLog(@"Hello World!");
    _randomInteger = [self getRandomNumberBetween:9 to:99];
    NSLog(@"Random: %d", _randomInteger);
}

-(int)getRandomNumberBetween:(int)from to:(int)to {
    
    return (int)from + arc4random() % (to-from+1);
}


//Following not added
- (void)initWithAudioTrack:(TVIAudioTrack *)audioTrack andCompletionHandler:(void (^)(NSString* result))completionHandler {
    //self = [super init];
    NSLog(@"init recognition called");
    
    _isLive = true;
    
    _myValue = 0;
    
    if (self != nil) {
        //_speechRecognizer = [[SFSpeechRecognizer alloc] init];
        //[[SFSpeechRecognizer loca
        // locale: Locale(identifier: "en-US")
        
        // _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:];
        _locale = [NSLocale localeWithLocaleIdentifier:_localeString];
        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:_locale];
        _speechRecognizer.defaultTaskHint = SFSpeechRecognitionTaskHintDictation;
        
        _speechRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
        _speechRequest.shouldReportPartialResults = YES;
        
        
        __weak typeof(self) weakSelf = self;
        _speechTask = [_speechRecognizer recognitionTaskWithRequest:_speechRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
            
            if (_isLive == true) {
                __strong typeof(self) strongSelf = weakSelf;
                NSLog(@"Speech recognition running...");
                _myValue = _myValue + 1;
                
                if (result) {
                    if (result.isFinal) {
                        //Recognizer will restart upon final result
                        strongSelf.speechResult = result.bestTranscription.formattedString;
                        //NSLog(@"Results: %@", strongSelf.speechResult);
                        completionHandler(result.bestTranscription.formattedString);
                        completionHandler(@"//restart required");
                        
                    } else {
                        strongSelf.speechResult = result.bestTranscription.formattedString;
                        //NSLog(@"Results: %@", strongSelf.speechResult);
                        completionHandler(result.bestTranscription.formattedString);
                        
                    }
                    
                } else {
                    NSLog(@"Speech recognition error: %@", error);
                    completionHandler(@"//error");
                    //self.stopRecognizing;
                }
            } else {
                NSLog(@"_isLive = false");
            }
            
            
        }];
        
        //MainViewController.
        
        _audioTrack = audioTrack;
        [_audioTrack addSink:self];
        _trackId = _audioTrack.trackId;
    }
    
    //return self;
}

-(void)restartRecognition {
    [self.audioTrack removeSink:self];
    
    [self.speechTask cancel];
    self.speechRequest = nil;
    self.speechRecognizer = nil;
    
    if (self.speechConverter != NULL) {
        AudioConverterDispose(self.speechConverter);
        self.speechConverter = NULL;
    }
    
    NSLog(@"myValue: %d",_myValue);
    NSLog(@"Random: %d", _randomInteger);
    NSLog(@"Speech recognition ready for restart...");
}


- (void)stopRecognizing {
    _isLive = false;
    
    [self.audioTrack removeSink:self];
    
    [self.speechTask cancel];
    self.speechRequest = nil;
    self.speechRecognizer = nil;
    
    if (self.speechConverter != NULL) {
        AudioConverterDispose(self.speechConverter);
        self.speechConverter = NULL;
    }
    
    NSLog(@"myValue: %d",_myValue);
    NSLog(@"Random: %d", _randomInteger);
    NSLog(@"Speech recognition ended");
}





#pragma mark - TVIAudioSink

- (void)renderSample:(CMSampleBufferRef)audioSample {
    CMAudioFormatDescriptionRef coreMediaFormat = (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(audioSample);
    const AudioStreamBasicDescription *basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(coreMediaFormat);
    
    // Detect and discard the initial invalid samples...
    // Waits for the track to start producing stereo audio, and for the timestamp to be reset.
    if (basicDescription->mChannelsPerFrame != 2) {
        return;
    }
    
    AVAudioFrameCount frameCount = (AVAudioFrameCount)CMSampleBufferGetNumSamples(audioSample);
    AVAudioFormat *avAudioFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16
                                                                    sampleRate:basicDescription->mSampleRate
                                                                      channels:1
                                                                   interleaved:YES];
    AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:avAudioFormat frameCapacity:frameCount];
    
    // Allocate an AudioConverter to perform mono downmixing for us.
    if (self.speechConverter == NULL) {
        OSStatus status = AudioConverterNew(basicDescription, avAudioFormat.streamDescription, &_speechConverter);
        if (status != 0) {
            NSLog(@"Failed to create AudioConverter: %d", status);
            return;
        }
    }
    
    // Fill the AVAudioPCMBuffer with downmixed mono audio.
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(audioSample);
    size_t inputBytes = 0;
    char *inputSamples = NULL;
    OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &inputBytes, &inputSamples);
    
    if (status == 0) {
        // Allocate some memory for us...
        pcmBuffer.frameLength = pcmBuffer.frameCapacity;
        AudioBufferList *bufferList = pcmBuffer.mutableAudioBufferList;
        AudioBuffer buffer = bufferList->mBuffers[0];
        void *outputSamples = buffer.mData;
        UInt32 outputBytes = buffer.mDataByteSize;
        
        status = AudioConverterConvertBuffer(_speechConverter, (UInt32)inputBytes, (const void *)inputSamples, &outputBytes, outputSamples);
        
        if (status == 0) {
            [self.speechRequest appendAudioPCMBuffer:pcmBuffer];
        } else {
            NSLog(@"Failed to convert audio: %d", status);
        }
    } else {
        NSLog(@"Failed to get data pointer: %d", status);
    }
}

@end
*/












/*
#import "ExampleSpeechRecognizer.h"
#import "IsLiveSharedInstance.h"

#import <AudioToolbox/AudioToolbox.h>
#import <Speech/Speech.h>
//#import "User.swift"

@class MainViewController;
//@class SingletonManager;
//@class Singleton;
//@class User;

@interface ExampleSpeechRecognizer() <TVIAudioSink>


@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *speechRequest;
@property (nonatomic, strong) SFSpeechRecognitionTask *speechTask;
@property (nonatomic, assign) AudioConverterRef speechConverter;

@property (nonatomic, copy) NSString *speechResult;
@property (nonatomic, weak) TVIAudioTrack *audioTrack;
@property (nonatomic, weak) MainViewController *mainViewController;

@property (nonatomic, weak) NSString *isLive;
@property(nonatomic, assign) int myValue;



@end


@implementation ExampleSpeechRecognizer




+ (id)sharedManager {
    static ExampleSpeechRecognizer *sharedRecognizer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedRecognizer = [[self alloc] init];
        NSLog(@"New instance created");
    });
    return sharedRecognizer;
}

//Following not added
- (instancetype)initWithAudioTrack:(TVIAudioTrack *)audioTrack andCompletionHandler:(void (^)(NSString* result))completionHandler {
    self = [super init];
    
    _sharedRecognizer = self;
    _myValue = 0;
    
    if (self != nil) {
        _speechRecognizer = [[SFSpeechRecognizer alloc] init];
        _speechRecognizer.defaultTaskHint = SFSpeechRecognitionTaskHintDictation;
        
        _speechRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
        _speechRequest.shouldReportPartialResults = YES;
        
        __weak typeof(self) weakSelf = self;
        _speechTask = [_speechRecognizer recognitionTaskWithRequest:_speechRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
            __strong typeof(self) strongSelf = weakSelf;
            NSLog(@"speech recognition running...");
            _myValue = _myValue + 1;
            
            if (result) {
                if (result.isFinal) {
                    //Recognizer will restart upon final result
                    strongSelf.speechResult = result.bestTranscription.formattedString;
                    NSLog(@"Results: %@", strongSelf.speechResult);
                    completionHandler(result.bestTranscription.formattedString);
                    completionHandler(@"//restart required");
                    
                } else {
                    strongSelf.speechResult = result.bestTranscription.formattedString;
                    NSLog(@"Results: %@", strongSelf.speechResult);
                    completionHandler(result.bestTranscription.formattedString);
                    
                }
                
            } else {
                NSLog(@"Speech recognition error: %@", error);
                self.stopRecognizing;
                NSLog(@"Speech recognition ended");
            }
        }];
        
        //MainViewController.
        
        _audioTrack = audioTrack;
        [_audioTrack addSink:self];
        _trackId = _audioTrack.trackId;
    }
    
    return self;
}

- (void)stopRecognizing {
    [self.audioTrack removeSink:self];
    
    [self.speechTask cancel];
    self.speechRequest = nil;
    self.speechRecognizer = nil;
    
    if (self.speechConverter != NULL) {
        AudioConverterDispose(self.speechConverter);
        self.speechConverter = NULL;
    }
    
    NSLog(@"myValue: %d",_myValue);
    
    NSLog(@"Speech recognition ended");
}





#pragma mark - TVIAudioSink

- (void)renderSample:(CMSampleBufferRef)audioSample {
    CMAudioFormatDescriptionRef coreMediaFormat = (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(audioSample);
    const AudioStreamBasicDescription *basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(coreMediaFormat);
    
    // Detect and discard the initial invalid samples...
    // Waits for the track to start producing stereo audio, and for the timestamp to be reset.
    if (basicDescription->mChannelsPerFrame != 2) {
        return;
    }
    
    AVAudioFrameCount frameCount = (AVAudioFrameCount)CMSampleBufferGetNumSamples(audioSample);
    AVAudioFormat *avAudioFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16
                                                                    sampleRate:basicDescription->mSampleRate
                                                                      channels:1
                                                                   interleaved:YES];
    AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:avAudioFormat frameCapacity:frameCount];
    
    // Allocate an AudioConverter to perform mono downmixing for us.
    if (self.speechConverter == NULL) {
        OSStatus status = AudioConverterNew(basicDescription, avAudioFormat.streamDescription, &_speechConverter);
        if (status != 0) {
            NSLog(@"Failed to create AudioConverter: %d", status);
            return;
        }
    }
    
    // Fill the AVAudioPCMBuffer with downmixed mono audio.
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(audioSample);
    size_t inputBytes = 0;
    char *inputSamples = NULL;
    OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &inputBytes, &inputSamples);
    
    if (status == 0) {
        // Allocate some memory for us...
        pcmBuffer.frameLength = pcmBuffer.frameCapacity;
        AudioBufferList *bufferList = pcmBuffer.mutableAudioBufferList;
        AudioBuffer buffer = bufferList->mBuffers[0];
        void *outputSamples = buffer.mData;
        UInt32 outputBytes = buffer.mDataByteSize;
        
        status = AudioConverterConvertBuffer(_speechConverter, (UInt32)inputBytes, (const void *)inputSamples, &outputBytes, outputSamples);
        
        if (status == 0) {
            [self.speechRequest appendAudioPCMBuffer:pcmBuffer];
        } else {
            NSLog(@"Failed to convert audio: %d", status);
        }
    } else {
        NSLog(@"Failed to get data pointer: %d", status);
    }
}

@end
*/



















/*


#import "ExampleSpeechRecognizer.h"
#import "IsLiveSharedInstance.h"

#import <AudioToolbox/AudioToolbox.h>
#import <Speech/Speech.h>
//#import "User.swift"

@class MainViewController;
@class SingletonManager;
@class Singleton;
//@class User;

@interface ExampleSpeechRecognizer() <TVIAudioSink>


@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *speechRequest;
@property (nonatomic, strong) SFSpeechRecognitionTask *speechTask;
@property (nonatomic, assign) AudioConverterRef speechConverter;

@property (nonatomic, copy) NSString *speechResult;
@property (nonatomic, weak) TVIAudioTrack *audioTrack;
@property (nonatomic, weak) MainViewController *mainViewController;

@property (nonatomic, weak) NSString *isLive;

@end



@implementation ExampleSpeechRecognizer

- (instancetype)initWithAudioTrack:(TVIAudioTrack *)audioTrack andCompletionHandler:(void (^)(NSString* result))completionHandler {
    self = [super init];
    
    if (self != nil) {
        _speechRecognizer = [[SFSpeechRecognizer alloc] init];
        _speechRecognizer.defaultTaskHint = SFSpeechRecognitionTaskHintDictation;
        
        _speechRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
        _speechRequest.shouldReportPartialResults = YES;
        
        __weak typeof(self) weakSelf = self;
        _speechTask = [_speechRecognizer recognitionTaskWithRequest:_speechRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
            __strong typeof(self) strongSelf = weakSelf;
            NSLog(@"speech recognition running...");
            if (result) {
                if (result.isFinal) {
                    //Recognizer will restart upon final result
                    strongSelf.speechResult = result.bestTranscription.formattedString;
                    NSLog(@"Results: %@", strongSelf.speechResult);
                    completionHandler(result.bestTranscription.formattedString);
                    completionHandler(@"//restart required");
                    
                } else {
                    strongSelf.speechResult = result.bestTranscription.formattedString;
                    NSLog(@"Results: %@", strongSelf.speechResult);
                    completionHandler(result.bestTranscription.formattedString);
                    
                }
                
            } else {
                NSLog(@"Speech recognition error: %@", error);
                self.stopRecognizing;
                NSLog(@"Speech recognition ended");
            }
        }];
        
        //MainViewController.
        
        _audioTrack = audioTrack;
        [_audioTrack addSink:self];
        _trackId = _audioTrack.trackId;
    }
    
    return self;
}

- (void)stopRecognizing {
    [self.audioTrack removeSink:self];
    
    [self.speechTask cancel];
    self.speechRequest = nil;
    self.speechRecognizer = nil;
    
    if (self.speechConverter != NULL) {
        AudioConverterDispose(self.speechConverter);
        self.speechConverter = NULL;
    }
    
    NSLog(@"Speech recognition ended");
}





#pragma mark - TVIAudioSink

- (void)renderSample:(CMSampleBufferRef)audioSample {
    CMAudioFormatDescriptionRef coreMediaFormat = (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(audioSample);
    const AudioStreamBasicDescription *basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(coreMediaFormat);
    
    // Detect and discard the initial invalid samples...
    // Waits for the track to start producing stereo audio, and for the timestamp to be reset.
    if (basicDescription->mChannelsPerFrame != 2) {
        return;
    }
    
    AVAudioFrameCount frameCount = (AVAudioFrameCount)CMSampleBufferGetNumSamples(audioSample);
    AVAudioFormat *avAudioFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16
                                                                    sampleRate:basicDescription->mSampleRate
                                                                      channels:1
                                                                   interleaved:YES];
    AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:avAudioFormat frameCapacity:frameCount];
    
    // Allocate an AudioConverter to perform mono downmixing for us.
    if (self.speechConverter == NULL) {
        OSStatus status = AudioConverterNew(basicDescription, avAudioFormat.streamDescription, &_speechConverter);
        if (status != 0) {
            NSLog(@"Failed to create AudioConverter: %d", status);
            return;
        }
    }
    
    // Fill the AVAudioPCMBuffer with downmixed mono audio.
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(audioSample);
    size_t inputBytes = 0;
    char *inputSamples = NULL;
    OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &inputBytes, &inputSamples);
    
    if (status == 0) {
        // Allocate some memory for us...
        pcmBuffer.frameLength = pcmBuffer.frameCapacity;
        AudioBufferList *bufferList = pcmBuffer.mutableAudioBufferList;
        AudioBuffer buffer = bufferList->mBuffers[0];
        void *outputSamples = buffer.mData;
        UInt32 outputBytes = buffer.mDataByteSize;
        
        status = AudioConverterConvertBuffer(_speechConverter, (UInt32)inputBytes, (const void *)inputSamples, &outputBytes, outputSamples);
        
        if (status == 0) {
            [self.speechRequest appendAudioPCMBuffer:pcmBuffer];
        } else {
            NSLog(@"Failed to convert audio: %d", status);
        }
    } else {
        NSLog(@"Failed to get data pointer: %d", status);
    }
}

@end

*/












/*
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ExampleSpeechRecognizer.h"

#import <AudioToolbox/AudioToolbox.h>
#import <Speech/Speech.h>
@import TwilioVideo;
//#import "MainViewController.swift"
//#import "MainViewController.swift"
//
//#import "MainViewController.h"

#import <OmniChat-Swift.h>


//@class MainViewController;

@interface ExampleSpeechRecognizer() <TVIAudioSink>


@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *speechRequest;
@property (nonatomic, strong) SFSpeechRecognitionTask *speechTask;
@property (nonatomic, assign) AudioConverterRef speechConverter;

@property (nonatomic, assign) CMSampleBufferRef cmSampleRef;

@property (nonatomic, copy) NSString *speechResult;
@property (nonatomic, copy) NSString *userStatus;
@property (nonatomic, weak) TVIAudioTrack *audioTrack;
@property (assign) BOOL isRunning;
//@property (assign) BOOL active;



@end

@implementation ExampleSpeechRecognizer


/*
- (instancetype)initWithAudioTrack:(TVIAudioTrack *)audioTrack andCompletionHandler:(void (^)(NSString* result))completionHandler {
    self = [super init];
    
    
//    if (_isRunning) {
//        NSLog(@"isRunning");
//        self.stopRecognizing;
//    }
    
    //self.stopRecognizing;
    
//    MainViewController *controller = [[MainViewController alloc] init];
//    
//    _active = controller.isActive;
//    
//    if (_active == NO) {
//        NSLog(@"Not active");
//    }
    
    NSLog(@"RECOGNITION BEGUN");
    
    if (self != nil) {
        
        _isRunning = YES;
        NSLocale* locale = [NSLocale localeWithLocaleIdentifier:(@"es_MX")];
        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:(locale)];
        //_speechRecognizer = [[SFSpeechRecognizer alloc] init];
        _speechRecognizer.defaultTaskHint = SFSpeechRecognitionTaskHintDictation;
        
        _speechRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
        _speechRequest.shouldReportPartialResults = YES;
        
        __weak typeof(self) weakSelf = self;
        _speechTask = [_speechRecognizer recognitionTaskWithRequest:_speechRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
            //NSLog(@"Error: %@",error);
            __strong typeof(self) strongSelf = weakSelf;
            
            
            if (result) {
                strongSelf.speechResult = result.bestTranscription.formattedString;
                NSLog(@"Results: %@", strongSelf.speechResult);
                
                if ([result isFinal]) {
                    completionHandler(result.bestTranscription.formattedString);
                    completionHandler(@"//restart required");
                }
                
//                if ([result isFinal]) {
//                    completionHandler(result.bestTranscription.formattedString);
//                    completionHandler(@"//restart required");
//                    [_speechRequest endAudio];
//                    [_speechTask cancel];
//                    _speechTask = nil;
//                    _speechRequest = nil;
//                }
                
                else {
                    completionHandler(result.bestTranscription.formattedString);
                }
            }
            
            else if (error) {
                //self.stopRecognizing;
                NSLog(@"ERROR: %@",error);
                completionHandler(@"//restart required");
                //self.audioEngine.stop()
                //inputNode.removeTap(onBus: 0)
                
                //self.speechRequest = nil;
                //self.speechTask = nil;
                //[_speechRequest endAudio];
                
                
            }
//            else if (error) {
//                //self.stopRecognizing;
//                NSLog(@"%@",error);
//                completionHandler(@"//restart required");
//                [_speechRequest endAudio];
//                [_speechTask cancel];
//                _speechTask = nil;
//                _speechRequest = nil;
//            }
            
            
//            else if ([error.localizedDescription isEqualToString:@"The operation couldn’t be completed. (kAFAssistantErrorDomain error 216.)"]) {
//                NSLog(@"Speech recognition error: %@", error);
//                NSLog(@"No input yet...");
//                completionHandler(@"//No input yet...");
//            }
        }];
        
        _audioTrack = audioTrack;
        [_audioTrack addSink:self];
        _trackId = _audioTrack.trackId;
    }
    
    return self;
}

//- (void)restartRecording {
//    [ExampleSpeechRecognizer init];
//
//}
 
*/
 
/*
- (instancetype)initWithAudioTrack:(TVIAudioTrack *)audioTrack andCompletionHandler:(void (^)(NSString* result))completionHandler {
    self = [super init];
    
    //self.stopRecognizing;
    
    if (self != nil) {
        //NSLocale* locale = [NSLocale localeWithLocaleIdentifier:(@"es_MX")];
        //_speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:(locale)];
        _speechRecognizer = [[SFSpeechRecognizer alloc] init];
        _speechRecognizer.defaultTaskHint = SFSpeechRecognitionTaskHintDictation;
        
        _speechRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
        _speechRequest.shouldReportPartialResults = YES;
        
        __weak typeof(self) weakSelf = self;
        _speechTask = [_speechRecognizer recognitionTaskWithRequest:_speechRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
            __strong typeof(self) strongSelf = weakSelf;
            if (result) {
                
                if ([result isFinal]) {
                    strongSelf.speechResult = result.bestTranscription.formattedString;
                    completionHandler(result.bestTranscription.formattedString);
                    completionHandler(@"//restart required");
                }
                
                else {
                    strongSelf.speechResult = result.bestTranscription.formattedString;
                    NSLog(@"Results: %@", strongSelf.speechResult);
                    completionHandler(result.bestTranscription.formattedString);
                }
                
            } else if (error != nil) {
                //!!!!!!!! get localizedDescription of error caused upon 2nd call, when error is reached, try calling "stopRecognizing"
                
                //self.audioEngine.stop()
                //inputNode.removeTap(onBus: 0)
                
                self.speechRequest = nil;
                self.speechTask = nil;
                
                completionHandler(@"//restart required");
                
                /*
                if ([error.localizedDescription isEqualToString:@"The operation couldn’t be completed. (kAFAssistantErrorDomain error 209.)"]) {
                    NSLog(@"Speech recognition error: %@", error);
                    self.stopRecognizing;
                    completionHandler(@"//Error 209");
                }
                else if ([error.localizedDescription isEqualToString:@"The operation couldn’t be completed. (kAFAssistantErrorDomain error 216.)"]) {
                    NSLog(@"Speech recognition error: %@", error);
                    NSLog(@"No input yet...");
                    self.stopRecognizing;
                    completionHandler(@"//No input yet...");
                } else {
                    //self.stopRecognizing;
                    NSLog(@"Speech recognition error: %@", error);
                    self.stopRecognizing;
                    completionHandler(@"//stop");
                }*/
/*
                
            } else {
                NSLog(@"nothing");
            }
        }];
        
        _audioTrack = audioTrack;
        [_audioTrack addSink:self];
        _trackId = _audioTrack.trackId;
    }
    
    return self;
}

- (void)stopRecognizing {
    
    [self.audioTrack removeSink:self];
    
    [self.speechTask cancel];
    //Added .endAudio upon suggestions
    //self.speechRequest.endAudio;
    self.speechRequest = nil;
    self.speechRecognizer = nil;
    
    if (self.speechConverter != NULL) {
        AudioConverterDispose(self.speechConverter);
        self.speechConverter = NULL;
    }
    
    
    //This needs to be added into any attempts to stop or restart recognition
    
    //self.audioEngine.stop()
    //inputNode.removeTap(onBus: 0)
    
    //self.recognitionRequest = nil
    //self.recognitionTask = nil
    
    //self.recordButton.isEnabled = true
    //self.recordButton.setTitle("Start Recording", for: [])
}

#pragma mark - TVIAudioSink

- (void)renderSample:(CMSampleBufferRef)audioSample {
    CMAudioFormatDescriptionRef coreMediaFormat = (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(audioSample);
    const AudioStreamBasicDescription *basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(coreMediaFormat);
    
    // Detect and discard the initial invalid samples...
    // Waits for the track to start producing stereo audio, and for the timestamp to be reset.
    if (basicDescription->mChannelsPerFrame != 2) {
        return;
    }
    
    AVAudioFrameCount frameCount = (AVAudioFrameCount)CMSampleBufferGetNumSamples(audioSample);
    AVAudioFormat *avAudioFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16
                                                                    sampleRate:basicDescription->mSampleRate
                                                                      channels:1
                                                                   interleaved:YES];
    AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:avAudioFormat frameCapacity:frameCount];
    
    // Allocate an AudioConverter to perform mono downmixing for us.
    if (self.speechConverter == NULL) {
        OSStatus status = AudioConverterNew(basicDescription, avAudioFormat.streamDescription, &_speechConverter);
        if (status != 0) {
            NSLog(@"Failed to create AudioConverter: %d", status);
            return;
        }
    }
    
    // Fill the AVAudioPCMBuffer with downmixed mono audio.
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(audioSample);
    size_t inputBytes = 0;
    char *inputSamples = NULL;
    OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &inputBytes, &inputSamples);
    
    if (status == 0) {
        // Allocate some memory for us...
        pcmBuffer.frameLength = pcmBuffer.frameCapacity;
        AudioBufferList *bufferList = pcmBuffer.mutableAudioBufferList;
        AudioBuffer buffer = bufferList->mBuffers[0];
        void *outputSamples = buffer.mData;
        UInt32 outputBytes = buffer.mDataByteSize;
        
        status = AudioConverterConvertBuffer(_speechConverter, (UInt32)inputBytes, (const void *)inputSamples, &outputBytes, outputSamples);
        
        if (status == 0) {
            [self.speechRequest appendAudioPCMBuffer:pcmBuffer];
        } else {
            NSLog(@"Failed to convert audio: %d", status);
        }
    } else {
        NSLog(@"Failed to get data pointer: %d", status);
    }
}

@end
*/


/*


//
//  ExampleSpeechRecognizer.m
//  RTCRoomsDemo
//
//  Created by Chris Eagleston on 6/23/17.
//  Copyright © 2017 Twilio, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ExampleSpeechRecognizer.h"

#import <AudioToolbox/AudioToolbox.h>
#import <Speech/Speech.h>
@import TwilioVideo;
//#import "MainViewController.swift"
//#import "MainViewController.swift"
//
//#import "MainViewController.h"

#import <OmniChat-Swift.h>


//@class MainViewController;

@interface ExampleSpeechRecognizer() <TVIAudioSink>


@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *speechRequest;
@property (nonatomic, strong) SFSpeechRecognitionTask *speechTask;
@property (nonatomic, assign) AudioConverterRef speechConverter;

@property (nonatomic, assign) CMSampleBufferRef cmSampleRef;

@property (nonatomic, copy) NSString *speechResult;
@property (nonatomic, copy) NSString *userStatus;
@property (nonatomic, weak) TVIAudioTrack *audioTrack;
@property (assign) BOOL isRunning;
//@property (assign) BOOL active;



@end

@implementation ExampleSpeechRecognizer

- (instancetype)initWithAudioTrack:(TVIAudioTrack *)audioTrack andCompletionHandler:(void (^)(NSString* result))completionHandler {
    self = [super init];
 
    
    //self.stopRecognizing;
    
    //    MainViewController *controller = [[MainViewController alloc] init];
    //
    //    _active = controller.isActive;
    //
    //    if (_active == NO) {
    //        NSLog(@"Not active");
    //    }
    
    NSLog(@"RECOGNITION BEGUN");
    
    if (self != nil) {
        
        _isRunning = YES;
        //NSSet* localeSet = [NSSet];
        NSLocale* locale = [NSLocale localeWithLocaleIdentifier:(@"es_MX")];
        //NSString* language = [locale localizedStringForLanguageCode:locale.languageCode];
        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:(locale)];
        //_speechRecognizer = [[SFSpeechRecognizer alloc] init];
        _speechRecognizer.defaultTaskHint = SFSpeechRecognitionTaskHintDictation;
        
        _speechRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
        _speechRequest.shouldReportPartialResults = YES;
        
        __weak typeof(self) weakSelf = self;
        _speechTask = [_speechRecognizer recognitionTaskWithRequest:_speechRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
            //NSLog(@"Error: %@",error);
            __strong typeof(self) strongSelf = weakSelf;
            
            
            if (result) {
                strongSelf.speechResult = result.bestTranscription.formattedString;
                NSLog(@"Results: %@", strongSelf.speechResult);
                
                if ([result isFinal]) {
                    completionHandler(result.bestTranscription.formattedString);
                    completionHandler(@"//restart required");
                }
 
                else {
                    completionHandler(result.bestTranscription.formattedString);
                }
                
            }
            
            else if (error) {
                //self.stopRecognizing;
                NSLog(@"%@",error);
                completionHandler(@"//restart required");
                //[_speechRequest endAudio];
                
                
            }
        }];
        
        _audioTrack = audioTrack;
        [_audioTrack addSink:self];
        _trackId = _audioTrack.trackId;
    }
    
    return self;
}

//- (void)restartRecording {
//    [ExampleSpeechRecognizer init];
//
//}


#pragma mark - TVIAudioSink

- (void)renderSample:(CMSampleBufferRef)audioSample {
    CMAudioFormatDescriptionRef coreMediaFormat = (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(audioSample);
    const AudioStreamBasicDescription *basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(coreMediaFormat);
    
    // Detect and discard the initial invalid samples...
    // Waits for the track to start producing stereo audio, and for the timestamp to be reset.
    if (basicDescription->mChannelsPerFrame != 2) {
        return;
    }
    
    AVAudioFrameCount frameCount = (AVAudioFrameCount)CMSampleBufferGetNumSamples(audioSample);
    AVAudioFormat *avAudioFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16
                                                                    sampleRate:basicDescription->mSampleRate
                                                                      channels:1
                                                                   interleaved:YES];
    AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:avAudioFormat frameCapacity:frameCount];
    
    // Allocate an AudioConverter to perform mono downmixing for us.
    if (self.speechConverter == NULL) {
        OSStatus status = AudioConverterNew(basicDescription, avAudioFormat.streamDescription, &_speechConverter);
        if (status != 0) {
            NSLog(@"Failed to create AudioConverter: %d", status);
            return;
        }
    }
    
    // Fill the AVAudioPCMBuffer with downmixed mono audio.
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(audioSample);
    size_t inputBytes = 0;
    char *inputSamples = NULL;
    OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &inputBytes, &inputSamples);
    
    if (status == 0) {
        // Allocate some memory for us...
        pcmBuffer.frameLength = pcmBuffer.frameCapacity;
        AudioBufferList *bufferList = pcmBuffer.mutableAudioBufferList;
        AudioBuffer buffer = bufferList->mBuffers[0];
        void *outputSamples = buffer.mData;
        UInt32 outputBytes = buffer.mDataByteSize;
        
        status = AudioConverterConvertBuffer(_speechConverter, (UInt32)inputBytes, (const void *)inputSamples, &outputBytes, outputSamples);
        
        if (status == 0) {
            [self.speechRequest appendAudioPCMBuffer:pcmBuffer];
        } else {
            NSLog(@"Failed to convert audio: %d", status);
        }
    } else {
        NSLog(@"Failed to get data pointer: %d", status);
    }
}

@end
*/








/*

//
//  ExampleSpeechRecognizer.m
//  RTCRoomsDemo
//
//  Created by Chris Eagleston on 6/23/17.
//  Copyright © 2017 Twilio, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ExampleSpeechRecognizer.h"

#import <AudioToolbox/AudioToolbox.h>
#import <Speech/Speech.h>
@import TwilioVideo;
//#import "MainViewController.swift"
//#import "MainViewController.swift"
//
//#import "MainViewController.h"

#import <OmniChat-Swift.h>


//@class MainViewController;

@interface ExampleSpeechRecognizer() <TVIAudioSink>


@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *speechRequest;
@property (nonatomic, strong) SFSpeechRecognitionTask *speechTask;
@property (nonatomic, assign) AudioConverterRef speechConverter;

@property (nonatomic, assign) CMSampleBufferRef cmSampleRef;

@property (nonatomic, copy) NSString *speechResult;
@property (nonatomic, copy) NSString *userStatus;
@property (nonatomic, weak) TVIAudioTrack *audioTrack;
@property (assign) BOOL isRunning;
//@property (assign) BOOL active;



@end

@implementation ExampleSpeechRecognizer

- (instancetype)initWithAudioTrack:(TVIAudioTrack *)audioTrack andCompletionHandler:(void (^)(NSString* result))completionHandler {
    self = [super init];
    

     if (_isRunning) {
     NSLog(@"isRunning");
     self.stopRecognizing;
     }
    
    //self.stopRecognizing;
    
    //    MainViewController *controller = [[MainViewController alloc] init];
    //
    //    _active = controller.isActive;
    //
    //    if (_active == NO) {
    //        NSLog(@"Not active");
    //    }
    
    NSLog(@"RECOGNITION BEGUN");
    
    if (self != nil) {
        
        _isRunning = YES;
        //NSSet* localeSet = [NSSet];
        NSLocale* locale = [NSLocale localeWithLocaleIdentifier:(@"es_MX")];
        //NSString* language = [locale localizedStringForLanguageCode:locale.languageCode];
        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:(locale)];
        //_speechRecognizer = [[SFSpeechRecognizer alloc] init];
        _speechRecognizer.defaultTaskHint = SFSpeechRecognitionTaskHintDictation;
        
        _speechRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
        _speechRequest.shouldReportPartialResults = YES;
        
        __weak typeof(self) weakSelf = self;
        _speechTask = [_speechRecognizer recognitionTaskWithRequest:_speechRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
            //NSLog(@"Error: %@",error);
            __strong typeof(self) strongSelf = weakSelf;
            
            
            if (result) {
                strongSelf.speechResult = result.bestTranscription.formattedString;
                NSLog(@"Results: %@", strongSelf.speechResult);
                
                if ([result isFinal]) {
                    completionHandler(result.bestTranscription.formattedString);
                    completionHandler(@"//restart required");
                }

                 if ([result isFinal]) {
                 completionHandler(result.bestTranscription.formattedString);
                 completionHandler(@"//restart required");
                 [_speechRequest endAudio];
                 [_speechTask cancel];
                 _speechTask = nil;
                 _speechRequest = nil;
                 }
                
                else {
                    completionHandler(result.bestTranscription.formattedString);
                }
                
            }
            
            else if (error) {
                //self.stopRecognizing;
                NSLog(@"%@",error);
                completionHandler(@"//restart required");
                
            }
              else if (error) {
              //self.stopRecognizing;
              NSLog(@"%@",error);
              completionHandler(@"//restart required");
              [_speechRequest endAudio];
              [_speechTask cancel];
              _speechTask = nil;
              _speechRequest = nil;
              }
            
            
            
            else if ([error.localizedDescription isEqualToString:@"The operation couldn’t be completed. (kAFAssistantErrorDomain error 216.)"]) {
             NSLog(@"Speech recognition error: %@", error);
             NSLog(@"No input yet...");
             completionHandler(@"//No input yet...");
             }
        }];
        
        _audioTrack = audioTrack;
        [_audioTrack addSink:self];
        _trackId = _audioTrack.trackId;
    }
    
    return self;
}

//- (void)restartRecording {
//    [ExampleSpeechRecognizer init];
//
//}



- (void)stopRecognizing {
    [_speechRequest endAudio];
    [_speechTask cancel];
    _speechTask = nil;
    _speechRequest = nil;
    
    [self.audioTrack removeSink:self];
    
    [self.speechTask cancel];
    self.speechRequest = nil;
    self.speechRecognizer = nil;
    
    if (self.speechConverter != NULL) {
        AudioConverterDispose(self.speechConverter);
        self.speechConverter = NULL;
    }
}

#pragma mark - TVIAudioSink

- (void)renderSample:(CMSampleBufferRef)audioSample {
    CMAudioFormatDescriptionRef coreMediaFormat = (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(audioSample);
    const AudioStreamBasicDescription *basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(coreMediaFormat);
    
    // Detect and discard the initial invalid samples...
    // Waits for the track to start producing stereo audio, and for the timestamp to be reset.
    if (basicDescription->mChannelsPerFrame != 2) {
        return;
    }
    
    AVAudioFrameCount frameCount = (AVAudioFrameCount)CMSampleBufferGetNumSamples(audioSample);
    AVAudioFormat *avAudioFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16
                                                                    sampleRate:basicDescription->mSampleRate
                                                                      channels:1
                                                                   interleaved:YES];
    AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:avAudioFormat frameCapacity:frameCount];
    
    // Allocate an AudioConverter to perform mono downmixing for us.
    if (self.speechConverter == NULL) {
        OSStatus status = AudioConverterNew(basicDescription, avAudioFormat.streamDescription, &_speechConverter);
        if (status != 0) {
            NSLog(@"Failed to create AudioConverter: %d", status);
            return;
        }
    }
    
    // Fill the AVAudioPCMBuffer with downmixed mono audio.
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(audioSample);
    size_t inputBytes = 0;
    char *inputSamples = NULL;
    OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &inputBytes, &inputSamples);
    
    if (status == 0) {
        // Allocate some memory for us...
        pcmBuffer.frameLength = pcmBuffer.frameCapacity;
        AudioBufferList *bufferList = pcmBuffer.mutableAudioBufferList;
        AudioBuffer buffer = bufferList->mBuffers[0];
        void *outputSamples = buffer.mData;
        UInt32 outputBytes = buffer.mDataByteSize;
        
        status = AudioConverterConvertBuffer(_speechConverter, (UInt32)inputBytes, (const void *)inputSamples, &outputBytes, outputSamples);
        
        if (status == 0) {
            [self.speechRequest appendAudioPCMBuffer:pcmBuffer];
        } else {
            NSLog(@"Failed to convert audio: %d", status);
        }
    } else {
        NSLog(@"Failed to get data pointer: %d", status);
    }
}

@end
*/
