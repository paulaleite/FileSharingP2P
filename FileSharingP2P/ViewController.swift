//
//  ViewController.swift
//  FileSharingP2P
//
//  Created by Paula Leite on 21/06/20.
//  Copyright © 2020 Paula Leite. All rights reserved.
//

import UIKit
import MobileCoreServices
import MultipeerConnectivity

class ViewController: UIViewController {
    
    var files = [Data]()
    
    // How someone's name is shown in other devices
    var peerID = MCPeerID(displayName: UIDevice.current.name)
    var mcSession: MCSession?
    var mcAdvertiserAssistant: MCAdvertiserAssistant?
    
    override func viewDidLoad() {
        title = "File Sharing P2P"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
        
        // How someone's name is shown in other devices
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
    }
    
    func startHosting(action: UIAlertAction) {
        guard let mcSession = mcSession else { return }
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "ptl-fileShare", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant?.start()
    }
    
    func joinSession(action: UIAlertAction) {
        guard let mcSession = mcSession else { return }
        let mcBrowser = MCBrowserViewController(serviceType: "ptl-fileShare", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    
    @objc func showConnectionPrompt() {
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Host a Session", style: .default, handler: startHosting))
        ac.addAction(UIAlertAction(title: "Join a Session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    @IBAction func insertDocument(_ sender: Any) {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypePlainText as String], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
        
    }
    
    
    @IBAction func shareDocument(_ sender: Any) {
        
//        guard let mcSession = mcSession else { return }
//        // Sending data to connected peers
//        if mcSession.connectedPeers.count > 0 {
////            let fileData = sandboxFileURL.dataRepresentation
//            guard let documentData = self.files.first else { return }
//            do {
//                try mcSession.send(documentData, toPeers: mcSession.connectedPeers, with: .reliable)
////                try mcSession.send(fileData, toPeers: mcSession.connectedPeers, with: .reliable)
//            } catch {
//                let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
//                ac.addAction(UIAlertAction(title: "OK", style: .default))
//                present(ac, animated: true)
//            }
//        }
    }
    
}

extension ViewController: MCBrowserViewControllerDelegate, MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected: \(peerID.displayName)")
            
        case .connecting:
            print("Connectting: \(peerID.displayName)")
            
        case .notConnected:
            print("Not Connected: \(peerID.displayName)")
            
        @unknown default:
            print("Unknown state received: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Not sure what should be implemented here...
        self.files.insert(data, at: 0)
        
        let directoryPath =  NSHomeDirectory().appending("/Documents/")
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: directoryPath), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddhhmmss"

        let filename = dateFormatter.string(from: Date()).appending(".txt")
        let filepath = directoryPath.appending(filename)
        let url = NSURL.fileURL(withPath: filepath)
        do {
            try files.first?.write(to: url, options: .atomic)

        } catch {
            print(error)
            print("File cant not be save at path \(filepath), with error : \(error)")
        }
        
//        print("Did receive data")
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
}

extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            return
        }
        
        do {
            let documentText = try String(contentsOf: selectedFileURL, encoding: .utf8)
            let data = documentText.data(using: .utf8)
        } catch {
            print("Error turning getting content.")
        }
        
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sandboxFileURL = dir.appendingPathComponent(selectedFileURL.lastPathComponent)
        
        let documentData = selectedFileURL.dataRepresentation
        files.insert(documentData, at: 0)
        
        if FileManager.default.fileExists(atPath: sandboxFileURL.path) {
            print("File already exists. No need to do anything.")
        } else {
            do {
                try FileManager.default.copyItem(at: selectedFileURL, to: sandboxFileURL)
                
                print("Copied file")
            } catch {
                print("Error: \(error)")
            }
        }
        
        guard let mcSession = mcSession else { return }
                // Sending data to connected peers
        if mcSession.connectedPeers.count > 0 {
            do {
                let documentText = try String(contentsOf: selectedFileURL, encoding: .utf8)
                if let data = documentText.data(using: .utf8) {
                    do {
                        try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
                    } catch {
                        let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        present(ac, animated: true)
                    }
                }
                
            } catch {
                print("Error turning getting content.")
            }
            
        }
        
    }
}

