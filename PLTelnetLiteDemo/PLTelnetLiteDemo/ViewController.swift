//
//  ViewController.swift
//  PLTelnetLiteDemo
//
//  Created by Patrick on 8/12/15.
//  Copyright (c) 2015 Patrick Lin. All rights reserved.
//

import UIKit

class ViewController: UIViewController, PLTelnetClientDelegate {

    var client: PLTelnetClient!;
    
    // MARK: Telnet Delegate Methods
    
    func telnetClient(client: PLTelnetClient!, didConnectToHost host: String!, onPort port: UInt) {
        
        println("didConnectToHost: \(host!):\(port)");
        
    }
    
    func telnetClient(client: PLTelnetClient!, didDisconnectWithError error: NSError!) {
        
        println("didDisconnectWithError: \(error)");
        
    }
    
    func telnetClient(client: PLTelnetClient!, didReceiveData data: NSData!) {
        
        println("didReceiveData: data length: \(data.length)");
        
        client.screen.printScreen();
        
    }
    
    // MARK: Init Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad();
        
        self.client = PLTelnetClient(delegate: self);
        
        self.client.IACHandler = PLTelnetIACHandler();
        
        self.client.CSIHandler = PLTelnetVT100Handler();

        self.client.expectedStringEncodings = [NSNumber(unsignedLong: String.stringEncoding(CFStringEncoding(CFStringEncodings.Big5.rawValue)))];
        
        self.client.connectToHost("ptt.cc", onPort: 23);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), {
           
            self.client.disconnect();
            
            self.client = nil;
            
        });
        
    }

}

extension String {
    
    static func stringEncoding(cStringEncoding: CFStringEncoding) -> NSStringEncoding {
        
        let stringEncoding = CFStringConvertEncodingToNSStringEncoding(cStringEncoding);
        
        return stringEncoding;
        
    }
    
}