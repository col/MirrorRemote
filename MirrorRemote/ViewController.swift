//
//  ViewController.swift
//  MirrorRemote
//
//  Created by Col Harris on 08/05/2016.
//  Copyright © 2016 Col Harris. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AIAuthenticationDelegate, AVAudioPlayerDelegate, UIWebViewDelegate {
    
    private var simplePCMRecorder: SimplePCMRecorder!
    private let tempFilename = "\(NSTemporaryDirectory())avs_example.wav"
    private var player: AVAudioPlayer!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var talkButton: UIButton!
    @IBOutlet var webView: UIWebView!
    @IBOutlet var progressView: UIProgressView!
    private var accessToken: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupRecorder()
        checkIsUserSignedIn()
        
        let request = NSURLRequest(URL: NSURL(string: "https://www.tw-mirror.com")!)
        webView.loadRequest(request)
    }
    
    func setupRecorder() {
        // Have the recorder create a first recording that will get tossed so it starts faster later
        self.simplePCMRecorder = SimplePCMRecorder(numberBuffers: 1)
        try! self.simplePCMRecorder.setupForRecording(tempFilename, sampleRate:Config.Audio.SampleRate, channels:1, bitsPerChannel:16, errorHandler: nil)
        try! self.simplePCMRecorder.startRecording()
        try! self.simplePCMRecorder.stopRecording()
        
        self.simplePCMRecorder = SimplePCMRecorder(numberBuffers: 1)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func requestDidSucceed(result: APIResult) {
        print("requestDidSucceed")
        
        let delegate = GetAccessTokenDelegate(
            success: { accessToken in
                print("accessToken: \(accessToken)")
                self.accessToken = accessToken
            },
            error: {
                print("Failed to get accessToken!")
            }
        )
        AIMobileLib.getAccessTokenForScopes(["alexa:all"], withOverrideParams: nil, delegate: delegate)
    }
    
    func requestDidFail(error: APIError) {
        print("requestDidFail")
        print("Error: \(error)")
    }
    
    @IBAction func loginClicked() {
        print("loginClicked")
        print("ClientId: \(AIMobileLib.getClientId())")
        
        let scopeData = [
            "alexa:all": [
                "productID": Config.LoginWithAmazon.ProductId,
                "productInstanceAttributes": [ "deviceSerialNumber": Config.LoginWithAmazon.DeviceSerialNumber ]
            ]
        ]
        
        do
        {
            let data = try NSJSONSerialization.dataWithJSONObject(scopeData, options: [.PrettyPrinted])
            let scopeDataJson = NSString(data: data, encoding: NSUTF8StringEncoding)!
            let options = [
                kAIOptionScopeData: scopeDataJson
            ]
            
            AIMobileLib.authorizeUserForScopes(["alexa:all"], delegate: self, options: options)
        } catch(_) {
            print("ERROR!?!")
        }
    }
    
    func checkIsUserSignedIn() {
        let delegate = GetAccessTokenDelegate(
            success: { accessToken in
                print("accessToken: \(accessToken)")
                self.accessToken = accessToken
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.loginButton.hidden = true
                })
            },
            error: {
                print("Failed to get accessToken!")
            }
        )
        let requestScopes = ["alexa:all"]
        AIMobileLib.getAccessTokenForScopes(requestScopes, withOverrideParams: nil, delegate: delegate)
    }
    
    @IBAction func recordClicked() {
        print("recordClicked")
        
        self.simplePCMRecorder = SimplePCMRecorder(numberBuffers: 1)
        try! self.simplePCMRecorder.setupForRecording(tempFilename, sampleRate:Config.Audio.SampleRate, channels:1, bitsPerChannel:16, errorHandler: { (error:NSError) -> Void in
            print(error)
            try! self.simplePCMRecorder.stopRecording()
        })
        try! self.simplePCMRecorder.startRecording()
        
    }
    
    @IBAction func stopClicked() {
        print("stopClicked")
        
        try! self.simplePCMRecorder.stopRecording()
        
        //        self.player = try! AVAudioPlayer(data: NSData(contentsOfFile: tempFilename)!)
        //        self.player?.delegate = self
        //        self.player?.play()
        upload()
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        print("audioPlayerDidFinishPlaying")
    }
    
    private func upload() {
        let uploader = AVSUploader()
        
        uploader.authToken = self.accessToken
        
        uploader.jsonData = self.createMeatadata()
        
        uploader.audioData = NSData(contentsOfFile: tempFilename)!
        
        uploader.errorHandler = { (error:NSError) in
            if Config.Debug.Errors {
                print("Upload error: \(error)")
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                print("Upload error: \(error.localizedDescription)")
                self.talkButton.hidden = false
            })
        }
        
        uploader.progressHandler = { (progress:Double) in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if progress < 100.0 {
                    print("Upload progress: \(progress)")
                    let progressFloat = Float(progress)
                    self.progressView.setProgress(progressFloat / 10.0, animated: true)
                } else {
                    print("Waiting for response")
                    self.progressView.setProgress(1.0, animated: true)
                }
            })
        }
        
        uploader.successHandler = { (data:NSData, parts:[PartData]) -> Void in
            for part in parts {
                if part.headers["Content-Type"] == "application/json" {
                    if Config.Debug.General {
                        print(NSString(data: part.data, encoding: NSUTF8StringEncoding))
                    }
                } else if part.headers["Content-Type"] == "audio/mpeg" {
                    do {
                        self.player = try AVAudioPlayer(data: part.data)
                        self.player?.delegate = self
                        self.player?.play()
                    } catch let error {
                        print("Playing error: \(error)")
                    }
                }
            }
            
            self.showTalkButton()
        }
        
        self.talkButton.hidden = true
        try! uploader.start()
    }
    
    private func showTalkButton() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.talkButton.hidden = false
            self.progressView.setProgress(0.0, animated: false)
        })
    }
    
    private func createMeatadata() -> String? {
        var rootElement = [String:AnyObject]()
        
        let deviceContextPayload = ["streamId":"", "offsetInMilliseconds":"0", "playerActivity":"IDLE"]
        let deviceContext = ["name":"playbackState", "namespace":"AudioPlayer", "payload":deviceContextPayload]
        rootElement["messageHeader"] = ["deviceContext":[deviceContext]]
        
        let deviceProfile = ["profile":"doppler-scone", "locale":"en-us", "format":"audio/L16; rate=16000; channels=1"]
        rootElement["messageBody"] = deviceProfile
        
        let data = try! NSJSONSerialization.dataWithJSONObject(rootElement, options: NSJSONWritingOptions(rawValue: 0))
        
        return NSString(data: data, encoding: NSUTF8StringEncoding) as String?
    }

}

