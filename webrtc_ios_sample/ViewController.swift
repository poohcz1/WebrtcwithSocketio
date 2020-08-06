//
//  ViewController.swift
//  webrtc_ios_sample
//
//  Created by justin dongwook Jung on 2020/07/28.
//  Copyright © 2020 justin dongwook Jung. All rights reserved.
//

import UIKit
import AVFoundation
import WebRTC

class ViewController: UIViewController, ShowViewProtocol {
    
    @IBOutlet var ConnectBtn: UIButton!
    @IBOutlet var RegisterBtn: UIButton!
    @IBOutlet var RoomJoinBtn: UIButton!
    @IBOutlet var SendBtn: UIButton!
    @IBOutlet weak var JanusBtn: UIButton!
    @IBOutlet weak var PubBtn: UIButton!
    @IBOutlet var LocalView: UIView!
    @IBOutlet var RemoteView: UIView!
    
    var peersManager: PeersManager?
    var socketListstener: SocketListener?
    var localAudioTrack: RTCAudioTrack?
    var localVideoTrack: RTCVideoTrack?
    var remoteAudioTrack: RTCAudioTrack?
    var remoteVideoTrack: RTCVideoTrack?
    var videoSource: RTCVideoSource?
    private var videoCapturer: RTCVideoCapturer?
    var numberCount:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        
        AVCaptureDevice.requestAccess(for: AVMediaType.video){ response in
            if response {
                print("Camera Permission Granted")
            } else {
                print("Camera Permission Denied")
            }
        }
        
        LocalView.backgroundColor = UIColor.green
        RemoteView.backgroundColor = UIColor.blue
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidApper")
        
        self.peersManager = PeersManager(view: self.view)
        socketListstener = SocketListener(peersManager: self.peersManager!, remoteView: self.RemoteView)
        self.peersManager!.socketListener = socketListstener
        self.peersManager!.start()
        self.createLocalVideoView()
        socketListstener?.delegate = self
    }
    
    @IBAction func connectButton(_sender: Any){
        socketListstener!.establishConnection()
    }
    
    @IBAction func RegisterButton(_sender: Any){
        socketListstener!.Register()
    }
    
    @IBAction func RoomJoinButton(_sender: Any){
        socketListstener!.roomJoin()
    }
    
    @IBAction func sendButton(_sender: Any){
        let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"]
        
        let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        self.peersManager!.createLocalOffer(mediaConstraints: sdpConstraints);
    }
    
    @IBAction func janusButton(_sender: Any){
        socketListstener!.janusJoin()
    }
    
    @IBAction func pubButton(_sender: Any){
        let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"]
        
        let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        self.peersManager!.createjanusOffer(mediaConstraints: sdpConstraints);
    }
        
    func createLocalVideoView(){
        #if arch(arm64)
            let renderer = RTCMTLVideoView(frame: self.LocalView.frame)
        renderer.videoContentMode = .scaleAspectFit
        #else
            let renderer = RTCEAGLVideoView(frame: self.LocalView.frame)
        #endif
    
        startCaptureLocalVideo(renderer: renderer)

        print("1-1-1-1-")
        dump(renderer)
        dump(self.LocalView)
        print("2-2-2-2-")
        self.embedView(renderer, into: self.LocalView)
    }
    
    func startCaptureLocalVideo(renderer: RTCVideoRenderer){
        createMediaSenders()
        
        guard let stream = self.peersManager!.localPeer!.localStreams.first ,
            let capturer = self.videoCapturer as? RTCCameraVideoCapturer else {
                return
        }

        guard
            let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }),

            // choose highest res
            let format = (RTCCameraVideoCapturer.supportedFormats(for: frontCamera).sorted { (f1, f2) -> Bool in
                let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
                let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
                return width1 < width2
            }).last,
            
            // choose highest fps
            let fps = (format.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }.last) else {
                return
        }

        capturer.startCapture(with: frontCamera,
                                    format: format,
                                    fps: Int(fps.maxFrameRate))


        stream.videoTracks.first?.add(renderer)
    }
    
     func createMediaSenders() {
        if numberCount == 0 {
            print("11numbercount")
            let stream = self.peersManager!.peerConnectionFactory!.mediaStream(withStreamId: "stream")
            
            // Audio
            let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            let audioSource = self.peersManager!.peerConnectionFactory!.audioSource(with: audioConstrains)
            let audioTrack = self.peersManager!.peerConnectionFactory!.audioTrack(with: audioSource, trackId: "audio0")
            self.localAudioTrack = audioTrack
            self.peersManager!.localAudioTrack = audioTrack
            stream.addAudioTrack(audioTrack)
            
            // Video
            let videoSource = self.peersManager!.peerConnectionFactory!.videoSource()
            self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
            let videoTrack = self.peersManager!.peerConnectionFactory!.videoTrack(with: videoSource, trackId: "video0")
            self.peersManager!.localVideoTrack = videoTrack
            self.localVideoTrack = videoTrack
            stream.addVideoTrack(videoTrack)
        
            self.peersManager!.localPeer!.add(stream)
            self.peersManager!.localPeer!.delegate = self.peersManager!
            numberCount+=1
            
        }else if numberCount >= 1 {
            print("22numbercount")
            let remoteStream = self.peersManager!.peerConnectionFactory!.mediaStream(withStreamId: "stream1")
            
            // Audio
            let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            let audioSource = self.peersManager!.peerConnectionFactory!.audioSource(with: audioConstrains)
            let audioTrack = self.peersManager!.peerConnectionFactory!.audioTrack(with: audioSource, trackId: "audio1")
            self.localAudioTrack = audioTrack
            self.peersManager!.localAudioTrack = audioTrack
            remoteStream.addAudioTrack(audioTrack)
            
            // Video
            let videoSource = self.peersManager!.peerConnectionFactory!.videoSource()
            self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
            let videoTrack = self.peersManager!.peerConnectionFactory!.videoTrack(with: videoSource, trackId: "video1")
            self.peersManager!.localVideoTrack = videoTrack
            self.localVideoTrack = videoTrack
            remoteStream.addVideoTrack(videoTrack)
            
            self.peersManager!.localPeer!.add(remoteStream)
            self.peersManager!.localPeer!.delegate = self.peersManager!
        
        }
    }
    
    func embedView(_ view: UIView, into containerView: UIView) {
        print("마지막?")
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        let width = (containerView.frame.width)
        let height = (containerView.frame.height)
        print("width: \(width), height: \(height)")

        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[view(" + height.description + ")]",
                                                                    options:NSLayoutConstraint.FormatOptions(),
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[view(" + width.description + ")]",
                                                                    options: NSLayoutConstraint.FormatOptions(),
                                                                    metrics: nil,
                                                                    views: ["view":view]))

        containerView.layoutIfNeeded()
    }
}
