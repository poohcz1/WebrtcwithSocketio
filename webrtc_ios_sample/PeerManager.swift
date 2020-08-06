//
//  PeerManager.swift
//  webrtc_ios_sample
//
//  Created by justin dongwook Jung on 2020/07/28.
//  Copyright © 2020 justin dongwook Jung. All rights reserved.
//

import Foundation
import WebRTC
import Starscream
import SocketIO

class PeersManager: NSObject {
    var localPeer: RTCPeerConnection?
    var remotePeer: RTCPeerConnection?
    var peerConnectionFactory: RTCPeerConnectionFactory?
    var connectionConstraints: RTCMediaConstraints?
    var socketListener: SocketListener?
    
    var localVideoTrack: RTCVideoTrack?
    var localAudioTrack: RTCAudioTrack?
    var remoteVideoTrack: RTCVideoTrack?
    var remoteAudioTrack: RTCAudioTrack?
    var peerConnection: RTCPeerConnection?
    var view: UIView!
    var remoteStream: [RTCMediaStream]
    
    init(view: UIView){
        self.view = view
        self.remoteStream = []
    }
    
    func setSocketAdapter(socketAdapter: SocketListener){
        self.socketListener = socketAdapter
    }
    
    
    func start(){
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        peerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
        
        let constraints = [
            "OfferToReceiveAudio": "true",
            "OfferToReceiveVideo": "true"
        ]
        
        let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: constraints, optionalConstraints: nil)
        createLocalPeerConnection(sdpConstraints: sdpConstraints)
    }
    
    func createLocalPeerConnection(sdpConstraints: RTCMediaConstraints){
        let config = RTCConfiguration()
        config.bundlePolicy = .maxCompat
        config.iceServers = [RTCIceServer(urlStrings: ["turn:13.125.217.175:46000"], username: "kpoint", credential: "kpoint01")]
        config.rtcpMuxPolicy = .require
        
        localPeer = peerConnectionFactory!.peerConnection(with: config, constraints: sdpConstraints, delegate: nil)
    }
    
    //상관 없
//    func createRemotePeerConnection() {
//        print("createRemotePeerConnection")
//        let mandatoryConstraints = [
//            "OfferToReceiveAudio": "true",
//            "OfferToReceiveVideo": "true"
//        ]
//        let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
//
//        let config = RTCConfiguration()
//        config.bundlePolicy = .maxCompat
//        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
//        config.rtcpMuxPolicy = .require
//        remotePeer = peerConnectionFactory!.peerConnection(with: config, constraints: sdpConstraints, delegate: nil)
//
//    }
    
    func createLocalOffer(mediaConstraints: RTCMediaConstraints){
        localPeer!.offer(for: mediaConstraints, completionHandler: { (sessionDescription, error) in
            self.localPeer!.setLocalDescription(sessionDescription!, completionHandler: {(error) in
                print("Local Peer Session Description: \(error.debugDescription)")
            })

            var localOfferParams: [String: String] = [:]
            localOfferParams["audioActive"] = "true"
            localOfferParams["videoActive"] = "true"
            localOfferParams["doLoopback"] = "false"
            localOfferParams["frameRate"] = "30"
            localOfferParams["typeOfVideo"] = "CAMERA"
            localOfferParams["sdpOffer"] = sessionDescription!.sdp
            self.socketListener!.sdpOffer(sdp: sessionDescription!.sdp)
        })
    }
    
    func createjanusOffer(mediaConstraints: RTCMediaConstraints){
        localPeer!.offer(for: mediaConstraints, completionHandler: { (sessionDescription, error) in
            self.localPeer!.setLocalDescription(sessionDescription!, completionHandler: {(error) in
                print("Local Peer Session Description: \(error.debugDescription)")
            })

            var localOfferParams: [String: String] = [:]
            localOfferParams["audioActive"] = "true"
            localOfferParams["videoActive"] = "true"
            localOfferParams["doLoopback"] = "false"
            localOfferParams["frameRate"] = "30"
            localOfferParams["typeOfVideo"] = "CAMERA"
            localOfferParams["sdpOffer"] = sessionDescription!.sdp
            self.socketListener!.publish(sdp: sessionDescription!.sdp)
        })
    }
    
}

extension PeersManager: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("peerConnection new signaling state: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if peerConnection == self.localPeer {
            print("remote peerConnection did add stream", stream)
            
            remoteStream.append(stream)
            print("remote:::", remoteStream)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("peerConnection did remote stream")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        if peerConnection == self.localPeer {
            print("local peerConnection should negotiate")
        } else {
            print("remote peerConnection should negotiate")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("peerConnection new connection state: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("peerConnection new gathering state: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        if peerConnection == self.localPeer {
            
        } else {
            
            print("NEW remote ice candidate")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("peerConnection did open data channel")
    }
}
