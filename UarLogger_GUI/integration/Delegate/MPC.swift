import MultipeerConnectivity
import Foundation
import simd

struct MPCSessionConstants {
    static let kKeyIdentity: String = "identity"
}

class MPCSession: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    
    private let localPeerID = MCPeerID(displayName: UIDevice.current.name)
    private let serviceString: String
    private let identityString: String
    private let maxNumPeers: Int
    private let mcSession: MCSession
    private let mcAdvertiser: MCNearbyServiceAdvertiser
    private let mcBrowser: MCNearbyServiceBrowser
    
    var peerDataHandler: ((Data, MCPeerID) -> Void)?
    var peerConnectedHandler: ((MCPeerID) -> Void)?
    var peerDisConnectedHandler: ((MCPeerID) -> Void)?
    
    //initial
    init(service: String, identity: String, maxPeers: Int) {
        serviceString = service
        identityString = identity
        maxNumPeers = maxPeers
        
        mcSession = MCSession(peer: localPeerID,
                              securityIdentity: nil,
                              encryptionPreference: MCEncryptionPreference.required)
        mcAdvertiser = MCNearbyServiceAdvertiser(peer: localPeerID,
                                                 discoveryInfo: [MPCSessionConstants.kKeyIdentity: identityString],
                                                 serviceType: serviceString)
        mcBrowser = MCNearbyServiceBrowser(peer: localPeerID,
                                           serviceType: serviceString)
        
        super.init()
        mcBrowser.delegate = self
        mcSession.delegate = self
        mcAdvertiser.delegate = self
    }
    
    func start() {
        mcAdvertiser.startAdvertisingPeer()
        mcBrowser.startBrowsingForPeers()
        print("start browsing and advertising")
    }
    
    func suspend() {
        mcAdvertiser.stopAdvertisingPeer()
        mcBrowser.stopBrowsingForPeers()
    }
    
    func invalidate() {
        suspend()
        mcSession.disconnect()
    }
    
    var connectedPeers: [MCPeerID] {
        return mcSession.connectedPeers
    }
    
    //send data to peers
    func sendData(_ data: Data, toPeers peerIDs: [MCPeerID], with mode: MCSessionSendDataMode) {
        do {
            try mcSession.send(data, toPeers: peerIDs, with: mode)
        } catch let error {
            NSLog("Error sending data \(error)")
        }
    }
    
    func sendDataToAllPeers(data: Data) {
        sendData(data, toPeers: mcSession.connectedPeers, with: .reliable)
    }
    
    
    //connect to peers
    private func connectToPeers(_ peerID: MCPeerID) {
        if let handler = peerConnectedHandler {
            DispatchQueue.main.async {
                handler(peerID)
                print("connected!")
            }
        }
        if mcSession.connectedPeers.count == maxNumPeers {
            self.suspend()
        }
    }
    
    //disconnect
    private func disconnectToPeers(_ peerID: MCPeerID) {
        if let handler = peerDisConnectedHandler {
            DispatchQueue.main.async {
                handler(peerID)
                print("disconnected")
            }
        }
    }
    
    //monitoring peer state changes
    internal func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            connectToPeers(peerID)
        case .notConnected:
            disconnectToPeers(peerID)
        case .connecting:
            break
        @unknown default:
            fatalError("Can not monitor session state!")
        }
    }
    
    //monitoring data received
    internal func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let handler = peerDataHandler {
            DispatchQueue.main.async {
                handler(data, peerID)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    //dalegate monitor advertiser and set invitationhandler
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        if self.mcSession.connectedPeers.count < maxNumPeers {
            invitationHandler(true, mcSession)
        }
    }
    
    //delegate monitor browser and send invitation
    internal func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard let indentityValue = info?[MPCSessionConstants.kKeyIdentity] else {
            return
        }
        if indentityValue == identityString && mcSession.connectedPeers.count < maxNumPeers {
            browser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 10)
            print("inviting peers~")
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
    }
    
    
}
