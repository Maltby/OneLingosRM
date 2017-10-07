//
//  MainViewController.swift
//  OmniChat
//
//  Created by Brice Maltby on 6/2/17.
//  Copyright © 2017 Brice Maltby. All rights reserved.
//

import UIKit
import TwilioVideo
import Firebase
import Contacts
import Speech
import MediaPlayer
import AudioToolbox
import CoreAudioKit
import AudioKit

@objc class MainViewController: UIViewController {
    
    // Video SDK components
    var room: TVIRoom?
    var camera: TVICameraCapturer?
    var localVideoTrack: TVILocalVideoTrack?
    var localAudioTrack: TVILocalAudioTrack?
    var participant: TVIParticipant?
    var remoteView: TVIVideoView?
    var isActive: Bool = true
    var ref: DatabaseReference!
    var speechResult = NSString()
    weak var audioTrack: TVIAudioTrack?
    var trackId = String()
    
    //passed from HomeContactViewController
    var contactName = String()
    var contactPhone = String()
    var receiverUid = String()
    var callerOrReceiver = String()
    var receiverToken = String()
    var roomUid = String()
    var callerLanguage: String = ""
    var receiverLanguage: String = ""
    var localLanguage: String = ""
    let speechSynthesizer = AVSpeechSynthesizer()
    
    // `TVIVideoView` created from a storyboard
    @IBOutlet weak var previewView: TVIVideoView!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet var textView : UITextView!
    @IBOutlet weak var buttonLayoutView: UIView!
    @IBOutlet var fullScreenView: UIView!
    @IBOutlet weak var recordButton: UIButton!
    
    @IBAction func recordTouchDown(_ sender: UIButton) {
        print("touchdown")
        try! startRecording()
        recordButton.setImage(UIImage(named: "recordFilled"), for: .normal)
    }
    
    @IBAction func recordTouchUpInside(_ sender: Any) {
        print("touchup")
        recordButton.setImage(UIImage(named: "recordEmpty"), for: .normal)
        if audioEngine.isRunning {
            recognitionRequest?.endAudio()
            recordButton.isEnabled = true
        }
    }
    
    var speechRecognizer = SFSpeechRecognizer()
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    
    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        
        Auth.auth().addStateDidChangeListener { (Auth, user) in
            if user == nil {
                self.performSegue(withIdentifier: "mainToSignUpView", sender: self)
            }
        }
        
        if PlatformUtils.isSimulator {
            self.previewView.removeFromSuperview()
        } else {
            // Preview our local camera track in the local video preview view.
            self.startPreview()
        }
        
        // Disconnect and mic button will be displayed when the Client is connected to a Room.
        self.disconnectButton.isHidden = true
        self.recordButton.isHidden = true
        
        //caller or receiver
        if callerOrReceiver == "caller" {
            DispatchQueue.main.async {
                self.callerConnect()
            }
        } else if callerOrReceiver == "receiver"{
            DispatchQueue.main.async {
                self.receiverConnect(accessToken: self.receiverToken)
            }
        } else {
            print("not caller nor receiver")
        }
        
        //NotificationCenter.default.addObserver(self, selector: #selector(self.appWillResignActive), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.appWillTerminate), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localLanguage))!
        speechRecognizer?.delegate = self as? SFSpeechRecognizerDelegate
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            /*
             The callback may not be called on the main thread. Add an
             operation to the main queue to update the record button's state.
             */
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.recordButton.isEnabled = true
                    
                case .denied:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("User denied access to speech recognition", for: .disabled)
                    
                case .restricted:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("Speech recognition restricted on this device", for: .disabled)
                    
                case .notDetermined:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("Speech recognition not yet authorized", for: .disabled)
                }
            }
        }
    }
    
    /*
    func appWillResignActive(_ note: Notification) {
        print("disconnecting from call")
        self.room!.disconnect()
        if self.room != nil {
            self.room = nil
        }
        if (self.participant == participant) {
            if remoteView != nil {
                self.remoteView?.removeFromSuperview()
                self.remoteView = nil
            }
        }
        self.showRoomUI(inRoom: false)
        callerOrReceiver = String()
        callerLanguage = ""
        receiverLanguage = ""
        
        ref.child("listener").child((Auth.auth().currentUser?.uid)!).removeValue()
        print("Disconnected")
    }*/
    
    func appWillTerminate(_ note: Notification) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        (MPVolumeView().subviews.filter{NSStringFromClass($0.classForCoder) == "MPVolumeSlider"}.first as? UISlider)?.setValue(1, animated: false)
    }
    
    public func getUserStatus() -> String {
        return callerOrReceiver
    }
    
    func setupRemoteVideoView() {
        // Creating `TVIVideoView` programmatically
        self.remoteView = TVIVideoView.init(frame: CGRect.zero, delegate:self)
        self.view.insertSubview(self.remoteView!, at: 0)
        
        // `TVIVideoView` supports scaleToFill, scaleAspectFill and scaleAspectFit
        // scaleAspectFit is the default mode when you create `TVIVideoView` programmatically.
        self.remoteView!.contentMode = .scaleAspectFit;
        
        // Get the superview's layout
        let mainViewMargins = view.layoutMarginsGuide
        let textViewMargins = textView.layoutMarginsGuide
        let buttonLayoutViewMargins = buttonLayoutView.layoutMarginsGuide
        
        self.remoteView?.topAnchor.constraint(equalTo: textViewMargins.bottomAnchor).isActive = true
        self.remoteView?.bottomAnchor.constraint(equalTo: buttonLayoutViewMargins.topAnchor).isActive = true
        self.remoteView?.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.remoteView?.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        
        let lightAquaColor = UIColor(red: 111.0/255.0, green: 196.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        
        self.view.backgroundColor = lightAquaColor
    }
    
    @IBAction func disconnect(sender: AnyObject) {
        disconnectButton.setImage(UIImage(named: "hangupFilled"), for: .normal)
        
        let disconnectConfirmation = UIAlertController(title: "End call?", message: "Are you sure you'd like to end the call?", preferredStyle: UIAlertControllerStyle.alert)
        
        disconnectConfirmation.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            self.disconnectFromCall()
        }))
        
        disconnectConfirmation.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            self.disconnectButton.setImage(UIImage(named: "hangupEmpty"), for: .normal)
        }))
        
        self.present(disconnectConfirmation, animated: true, completion: nil)
    }
    
    func callerConnect() {
        if let callerUid = Auth.auth().currentUser?.uid {
            
            print("Contact Info:")
            print(contactName)
            print(contactPhone)
            print(receiverUid)
            
            roomUid = randomString(length: 10)
            
            let connectionsRoomRef = ref.child("connections").child(roomUid)
            connectionsRoomRef.child("callerUid").setValue(callerUid)
            connectionsRoomRef.child("receiverUid").setValue(receiverUid)
            connectionsRoomRef.child("timestamp").setValue(ServerValue.timestamp())
            
            let listenerRef = ref.child("listener")
            listenerRef.child(receiverUid).child("roomUid").setValue(roomUid)
            
            self.ref.child("connections").child(self.roomUid).child("transcription").child("callerLanguage").setValue(self.callerLanguage)
            print("language set")
            
            let tokenCreatorRoomRef = ref.child("tokenCreator").child(roomUid)
            tokenCreatorRoomRef.child("callerToken").observe(.value, with: { (snap) in
                if snap.exists() {
                    let accessToken = snap.value as! String
                    print("callerToken: "+accessToken)
                    
                    // Preparing the connect options with the access token that we fetched (or hardcoded).
                    self.prepareLocalMedia()
                    let connectOptions = TVIConnectOptions.init(token: accessToken) { (builder) in
                        
                        // Use the local media that we prepared earlier.
                        builder.audioTracks = self.localAudioTrack != nil ? [self.localAudioTrack!] : [TVILocalAudioTrack]()
                        builder.videoTracks = self.localVideoTrack != nil ? [self.localVideoTrack!] : [TVILocalVideoTrack]()
                        
                        // The name of the Room where the Client will attempt to connect to.
                        builder.roomName = self.roomUid
                        print("room name")
                        print(self.roomUid)
                    }
                    
                    // Connect to the Room using the options we provided.
                    self.room = TwilioVideo.connect(with: connectOptions, delegate: self)
                    self.showRoomUI(inRoom: true)
                }
                
            }, withCancel: { (err) in
                print(err)
            })
        }
    }
    
    func receiverConnect(accessToken: String) {
        self.ref.child("connections").child(self.roomUid).child("transcription").child("receiverLanguage").setValue(self.receiverLanguage)
        
        print("language set")
        self.prepareLocalMedia()
        print("receiver token: "+receiverToken)
        // Preparing the connect options with the access token that we fetched (or hardcoded).
        let connectOptions = TVIConnectOptions.init(token: accessToken) { (builder) in
            
            // Use the local media that we prepared earlier.
            builder.audioTracks = self.localAudioTrack != nil ? [self.localAudioTrack!] : [TVILocalAudioTrack]()
            builder.videoTracks = self.localVideoTrack != nil ? [self.localVideoTrack!] : [TVILocalVideoTrack]()
            print("roomUid")
            print(self.roomUid)
            builder.roomName = self.roomUid
        }
        
        // Connect to the Room using the options we provided.
        self.room = TwilioVideo.connect(with: connectOptions, delegate: self)
        self.showRoomUI(inRoom: true)
    }
    
    func disconnectFromCall() {
        print("disconnecting from call")
        recognitionRequest?.endAudio()
        speechSynthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        
        self.showRoomUI(inRoom: false)
        self.textView.isHidden = true
        self.buttonLayoutView.isHidden = true
        self.previewView.isHidden = true
        
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        if self.room != nil {
            self.room!.disconnect()
            self.room = nil
        }
        if (self.participant == participant) {
            if remoteView != nil {
                self.remoteView?.removeFromSuperview()
                self.remoteView = nil
            }
        }
        
        callerOrReceiver = String()
        callerLanguage = ""
        receiverLanguage = ""
        
        ref.child("listener").child((Auth.auth().currentUser?.uid)!).removeValue()
        dismiss(animated: true, completion: nil)
    }
    
    private func startRecording() throws {
        
        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true
        
        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                if result.isFinal == false {
                    print(result.bestTranscription.formattedString)
                } else {
                    print("isFinal")
                    self.transcriptionUpload(transcription: result.bestTranscription.formattedString, language: self.localLanguage)
                    
                }
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordButton.isEnabled = true
                self.recordButton.setTitle("Start Recording", for: [])
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    func transcriptionUpload(transcription: String, language: String) {
        if callerOrReceiver == "caller" {
            if receiverLanguage == "" {
                self.ref.child("connections").child(self.roomUid).child("transcription").child("receiverLanguage").observe(.value, with: { (snap) in
                    if snap.exists() {
                        self.receiverLanguage = snap.value as! String
                        self.ref.child("connections").child(self.roomUid).child("transcription").child("callerDidTalk").child("callerLanguage").child(self.callerLanguage).child("receiverLanguage").child(self.receiverLanguage).child("text").child(self.callerLanguage).setValue(transcription)
                    }
                })
            } else {
                self.ref.child("connections").child(self.roomUid).child("transcription").child("callerDidTalk").child("callerLanguage").child(self.callerLanguage).child("receiverLanguage").child(self.receiverLanguage).child("text").child(self.callerLanguage).setValue(transcription)
            }
        }
        else if callerOrReceiver == "receiver" {
            if callerLanguage == "" {
                self.ref.child("connections").child(self.roomUid).child("transcription").child("callerLanguage").observe(.value, with: { (snap) in
                    if snap.exists() {
                        self.callerLanguage = snap.value as! String
                        self.ref.child("connections").child(self.roomUid).child("transcription").child("receiverDidTalk").child("receiverLanguage").child(self.receiverLanguage).child("callerLanguage").child(self.callerLanguage).child("text").child(self.receiverLanguage).setValue(transcription)
                    }
                })
            } else {
                self.ref.child("connections").child(self.roomUid).child("transcription").child("receiverDidTalk").child("receiverLanguage").child(self.receiverLanguage).child("callerLanguage").child(self.callerLanguage).child("text").child(self.receiverLanguage).setValue(transcription)
            }
        }
    }
    
    func speak(speechOutput: String, language: String) {
        //Disable local audio track to ensure speech synthesis is not send to participant
        self.localAudioTrack?.isEnabled = false
        
        prepareAudioSession()
        
        let utterance = AVSpeechUtterance(string: speechOutput)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.volume = 1.0
        
        print("will synthesize: ")
        print(speechOutput)
        
        speechSynthesizer.speak(utterance)
    }
    
    func prepareAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with:  AVAudioSessionCategoryOptions.defaultToSpeaker)
            try AVAudioSession.sharedInstance().setActive(true, with: .notifyOthersOnDeactivation)
        }
        catch {
            print(error)
        }
    }
    
    func dbTranscriptUpdate() {
        if callerOrReceiver == "caller" {
            ref.child("connections").child(self.roomUid).child("transcription").child("receiverDidTalk").child("receiverLanguage").child(self.receiverLanguage).child("callerLanguage").child(self.callerLanguage).child("translated").child(self.callerLanguage).observe(.value, with: { (snap) in
                    if snap.exists() {
                        let translatedText = snap.value as! String
                        let decodedString = String(htmlEncodedString: translatedText) + String(". ")
                        self.textView.text = self.textView.text + decodedString
                        self.speak(speechOutput: decodedString, language: self.callerLanguage)
                    }
            })
        } else if callerOrReceiver == "receiver" {
            ref.child("connections").child(self.roomUid).child("transcription").child("callerDidTalk").child("callerLanguage").child(self.callerLanguage).child("receiverLanguage").child(self.receiverLanguage).child("translated").child(self.receiverLanguage).observe(.value, with: { (snap) in
                    if snap.exists() {
                        let translatedText = snap.value as! String
                        let decodedString = String(htmlEncodedString: translatedText) + String(". ")
                        self.textView.text = self.textView.text + decodedString
                        self.speak(speechOutput: decodedString, language: self.receiverLanguage)
                    }
            })
        }
    }
    
    // MARK: Private
    func startPreview() {
        if PlatformUtils.isSimulator {
            return
        }
        
        // Preview our local camera track in the local video preview view.
        camera = TVICameraCapturer(source: .frontCamera, delegate: self)
        localVideoTrack = TVILocalVideoTrack.init(capturer: camera!)
        if (localVideoTrack == nil) {
            print("failed to create audio track")
        } else {
            // Add renderer to video track for local preview
            localVideoTrack!.addRenderer(self.previewView)
            print("audio track created")
            
            // We will flip camera on tap.
            let tap = UITapGestureRecognizer(target: self, action: #selector(MainViewController.flipCamera))
            self.previewView.addGestureRecognizer(tap)
        }
    }
    
    func flipCamera() {
        if (self.camera?.source == .frontCamera) {
            self.camera?.selectSource(.backCameraWide)
        } else {
            self.camera?.selectSource(.frontCamera)
        }
    }
    
    func prepareLocalMedia() {
        // We will share local audio and video when we connect to the Room.
        // Create an audio track.
        if (localAudioTrack == nil) {
            localAudioTrack = TVILocalAudioTrack.init()
            if (localAudioTrack == nil) {
                print("failed to create audio track")
            }
        }
        
        // Create a video track which captures from the camera.
        if (localVideoTrack == nil) {
            self.startPreview()
        }
    }
    
    func getVideoFeedDimensions() -> (CGFloat, CGFloat) {
        let feedHeight = fullScreenView.frame.size.height - textView.frame.size.height - buttonLayoutView.frame.size.height
        let feedWidth = fullScreenView.frame.size.width
        return(feedHeight, feedWidth)
    }
    
    // Update our UI based upon if we are in a Room or not
    func showRoomUI(inRoom: Bool) {
        self.disconnectButton.isHidden = !inRoom
        self.recordButton.isHidden = !inRoom
        UIApplication.shared.isIdleTimerDisabled = inRoom
    }
    
    func cleanupRemoteParticipant() {
        if ((self.participant) != nil) {
            if ((self.participant?.videoTracks.count)! > 0) {
                self.participant?.videoTracks[0].removeRenderer(self.remoteView!)
                self.remoteView?.removeFromSuperview()
                self.remoteView = nil
            }
        }
        self.participant = nil
    }
    
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        return randomString
    }
}

// MARK: TVIRoomDelegate
extension MainViewController : TVIRoomDelegate {
    func didConnect(to room: TVIRoom) {
        // At the moment, this example only supports rendering one Participant at a time.
        print("Connected to room \(room.name) as \(String(describing: room.localParticipant?.identity))")
        if (room.participants.count > 0) {
            self.participant = room.participants[0]
            self.participant?.delegate = self
        }
    }
    
    func room(_ room: TVIRoom, didDisconnectWithError error: Error?) {
        print("Disconncted from room \(room.name), error = \(String(describing: error))")
        self.cleanupRemoteParticipant()
        disconnectFromCall()
    }
    
    func room(_ room: TVIRoom, didFailToConnectWithError error: Error) {
        print("Failed to connect to room with error")
        disconnectFromCall()

    }
    
    func room(_ room: TVIRoom, participantDidConnect participant: TVIParticipant) {
        if (self.participant == nil) {
            self.participant = participant
            self.participant?.delegate = self
        }
        print("Room \(room.name), Participant \(participant.identity) connected")
    }
    
    func room(_ room: TVIRoom, participantDidDisconnect participant: TVIParticipant) {
        if (self.participant == participant) {
            cleanupRemoteParticipant()
        }
        print("Room \(room.name), Participant \(participant.identity) disconnected")
        disconnectFromCall()
    }
}

// MARK: TVIParticipantDelegate
extension MainViewController : TVIParticipantDelegate {
    func participant(_ participant: TVIParticipant, addedVideoTrack videoTrack: TVIVideoTrack) {
        print("Participant \(participant.identity) added video track")
        
        if (self.participant == participant) {
            setupRemoteVideoView()
            videoTrack.addRenderer(self.remoteView!)
        }
    }
    
    func participant(_ participant: TVIParticipant, removedVideoTrack videoTrack: TVIVideoTrack) {
        print("Participant \(participant.identity) removed video track")
        
        if (self.participant == participant) {
            videoTrack.removeRenderer(self.remoteView!)
            self.remoteView?.removeFromSuperview()
            self.remoteView = nil
        }
    }
    
    func participant(_ participant: TVIParticipant, addedAudioTrack audioTrack: TVIAudioTrack) {
        print("Participant \(participant.identity) added audio track")
        
        if callerOrReceiver == "caller" {
            self.ref.child("connections").child(self.roomUid).child("transcription").child("receiverLanguage").observe(.value, with: { (snap) in
                if snap.exists() {
                    self.receiverLanguage = snap.value as! String
                    self.dbTranscriptUpdate()
                }
            })
        } else if callerOrReceiver == "receiver" {
            self.ref.child("connections").child(self.roomUid).child("transcription").child("callerLanguage").observe(.value, with: { (snap) in
                if snap.exists() {
                    self.callerLanguage = snap.value as! String
                    self.dbTranscriptUpdate()
                }
            })
        }
    }
    
    func participant(_ participant: TVIParticipant, removedAudioTrack audioTrack: TVIAudioTrack) {
        print("Participant \(participant.identity) removed audio track")
    }
    
    func participant(_ participant: TVIParticipant, enabledTrack track: TVITrack) {
        var type = ""
        if (track is TVIVideoTrack) {
            type = "video"
        } else {
            type = "audio"
        }
    }
    
    func participant(_ participant: TVIParticipant, disabledTrack track: TVITrack) {
        var type = ""
        if (track is TVIVideoTrack) {
            type = "video"
        } else {
            type = "audio"
        }
    }
}

// MARK: TVIVideoViewDelegate
extension MainViewController : TVIVideoViewDelegate {
    func videoView(_ view: TVIVideoView, videoDimensionsDidChange dimensions: CMVideoDimensions) {
        self.view.setNeedsLayout()
    }
}

// MARK: TVICameraCapturerDelegate
extension MainViewController : TVICameraCapturerDelegate {
    func cameraCapturer(_ capturer: TVICameraCapturer, didStartWith source: TVICameraCaptureSource) {
        self.previewView.shouldMirror = (source == .frontCamera)
    }
}

extension String {
    init(htmlEncodedString: String) {
        self.init()
        guard let encodedData = htmlEncodedString.data(using: .utf8) else {
            self = htmlEncodedString
            return
        }
        
        let attributedOptions: [String : Any] = [
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
            NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue
        ]
        
        do {
            let attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
            self = attributedString.string
        } catch {
            print("Error: \(error)")
            self = htmlEncodedString
        }
    }
}


extension MainViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        
        self.localAudioTrack?.isEnabled = false
        print("local audio back on")
    }
}
