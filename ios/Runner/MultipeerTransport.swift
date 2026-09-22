import Foundation
import MultipeerConnectivity

class MultipeerTransport: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    private let serviceType = "meshconnect"
    
    private var myPeerId: MCPeerID?
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private let onPeerDiscovered: ([String: Any]) -> Void
    private let onPayloadReceived: (String, Data) -> Void
    private let onConnectionChanged: (String, Bool) -> Void
    
    private var connectedPeersMap = [String: MCPeerID]()
    
    init(
        onPeerDiscovered: @escaping ([String: Any]) -> Void,
        onPayloadReceived: @escaping (String, Data) -> Void,
        onConnectionChanged: @escaping (String, Bool) -> Void
    ) {
        self.onPeerDiscovered = onPeerDiscovered
        self.onPayloadReceived = onPayloadReceived
        self.onConnectionChanged = onConnectionChanged
        super.init()
    }
    
    func initialize(peerIdString: String) {
        let peer = MCPeerID(displayName: peerIdString)
        self.myPeerId = peer
        self.session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .optional)
        self.session?.delegate = self
        
        self.advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: ["meshId": peerIdString], serviceType: serviceType)
        self.advertiser?.delegate = self
        
        self.browser = MCNearbyServiceBrowser(peer: peer, serviceType: serviceType)
        self.browser?.delegate = self
    }
    
    func startDiscovery() -> Bool {
        advertiser?.startAdvertisingPeer()
        browser?.startBrowsingForPeers()
        return true
    }
    
    func stopDiscovery() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
    }
    
    func send(peerId: String, payload: Data) -> Bool {
        guard let targetPeer = connectedPeersMap[peerId], let sess = session else {
            return false
        }
        do {
            try sess.send(payload, toPeers: [targetPeer], with: .reliable)
            return true
        } catch {
            return false
        }
    }
    
    func broadcast(payload: Data) -> Bool {
        guard let sess = session, !sess.connectedPeers.isEmpty else {
            return false
        }
        do {
            try sess.send(payload, toPeers: sess.connectedPeers, with: .reliable)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        let meshId = info?["meshId"] ?? peerID.displayName
        connectedPeersMap[meshId] = peerID
        
        // Automatically invite discovered peers into session
        if let sess = session {
            browser.invitePeer(peerID, to: sess, withContext: nil, timeout: 10)
        }
        
        DispatchQueue.main.async {
            self.onPeerDiscovered([
                "peerId": meshId,
                "deviceName": peerID.displayName,
                "rssi": -55,
                "lastSeen": Int(Date().timeIntervalSince1990 * 1000)
            ])
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        let meshId = peerID.displayName
        connectedPeersMap.removeValue(forKey: meshId)
        DispatchQueue.main.async {
            self.onConnectionChanged(meshId, false)
        }
    }
    
    // MARK: - MCNearbyServiceAdvertiserDelegate
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, self.session)
    }
    
    // MARK: - MCSessionDelegate
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let meshId = peerID.displayName
        let connected = (state == .connected)
        if connected {
            connectedPeersMap[meshId] = peerID
        } else if state == .notConnected {
            connectedPeersMap.removeValue(forKey: meshId)
        }
        DispatchQueue.main.async {
            self.onConnectionChanged(meshId, connected)
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let meshId = peerID.displayName
        DispatchQueue.main.async {
            self.onPayloadReceived(meshId, data)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
