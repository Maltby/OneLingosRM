//
//  ExampleSpeechRecognizer.h
//  RTCRoomsDemo
//
//  Created by Chris Eagleston on 6/23/17.
//  Copyright © 2017 Twilio, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "MainViewController.swift"
//#import "IsLiveSharedInstance.h"
@import TwilioVideo;

//@class MainViewController;

@interface ExampleSpeechRecognizer : NSObject {
    
}

@property (nonatomic, copy, readonly) NSString *speechResult;
@property (nonatomic, copy, readonly) NSString *trackId;


//OLD
//- (instancetype)initWithAudioTrack:(TVIAudioTrack *)audioTrack andCompletionHandler:(void (^)(NSString* result))completionHandler;
//NEW
- (void)initWithAudioTrack:(TVIAudioTrack *)audioTrack languageId:(NSString*)id andCompletionHandler:(void (^)(NSString* result))completionHandler;

//- (void)initWithAudioTrack:(TVIAudioTrack *)audioTrack andCompletionHandler:(void (^)(NSString* result))completionHandler;

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;

-(int)getRandomNumberBetween:(int)from to:(int)to;

+ (void)resetSharedInstance;

+(ExampleSpeechRecognizer*)sharedExampleSpeechRecognizer;
-(void)sayHello;


//- (void)initWithAudioTrack:(TVIAudioTrack *)audioTrack;
//- (void)renderSample:(CMSampleBufferRef)audioSample;

// Breaks the strong reference from TVIAudioTrack by removing its Sink.
- (void)restartRecognition;

//- (void)stopRecognizing: andCompletionHandler:(void (^)(NSString* result))completionHandler;
- (void)stopRecognizing: (void (^)(NSString* result))completionHandler;
//- (void)stopRecognizing;



//- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;



@end
