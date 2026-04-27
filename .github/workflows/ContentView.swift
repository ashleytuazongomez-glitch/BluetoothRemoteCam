import SwiftUI
import MultipeerConnectivity
import AVFoundation

struct ContentView: View {
    @StateObject var cameraLogic = RemoteCameraManager()
    
    var body: some View {
        VStack(spacing: 40) {
            Text("BT Shutter Remote")
                .font(.largeTitle).bold()
            
            // Connection Status
            Text(cameraLogic.statusMessage)
                .foregroundColor(cameraLogic.isConnected ? .green : .red)
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.1)))

            // Role Selection
            if !cameraLogic.isConnected {
                HStack {
                    Button("Set as Camera") { cameraLogic.startHosting() }
                        .buttonStyle(.borderedProminent)
                    Button("Set as Remote") { cameraLogic.startJoining() }
                        .buttonStyle(.bordered)
                }
            }

            // The Shutter Button
            Button(action: {
                cameraLogic.sendShutterSignal()
            }) {
                ZStack {
                    Circle().fill(Color.red.opacity(0.2)).frame(width: 100, height: 100)
                    Circle().fill(Color.red).frame(width: 80, height: 80)
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                }
            }
            .disabled(!cameraLogic.isConnected)
            .opacity(cameraLogic.isConnected ? 1.0 : 0.3)
            
            Text("Tap to take photo on iPhone")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Combined Manager Logic
class RemoteCameraManager: NSObject, ObservableObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    
    @Published var isConnected = false
    @Published var statusMessage = "Not Connected"
    
    let peerID = MCPeerID(displayName: UIDevice.current.name)
    let session: MCSession
    var advertiser: MCNearbyServiceAdvertiser?
    var browser: MCNearbyServiceBrowser?
    
    override init() {
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        session.delegate = self
    }
    
    func startHosting() {
        statusMessage = "Waiting for iPad..."
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "bt-shutter")
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }
    
    func startJoining() {
        statusMessage = "Searching for iPhone..."
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "bt-shutter")
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }
    
    func sendShutterSignal() {
        let command = "CHEESE".data(using: .utf8)!
        try? session.send(command, toPeers: session.connectedPeers, with: .reliable)
    }

    // This handles the signal when it's received
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message = String(data: data, encoding: .utf8), message == "CHEESE" {
            // Trigger haptic feedback and shutter sound
            DispatchQueue.main.async {
                AudioServicesPlaySystemSound(1108) // Standard camera shutter sound
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }

    // --- Multipeer Delegate Boilerplate ---
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.isConnected = (state == .connected)
            self.statusMessage = state == .connected ? "Connected to \(peerID.displayName)" : "Disconnected"
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
