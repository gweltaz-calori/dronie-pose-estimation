//
//  SuperSocketManager.swift
//  PoseEstimation-CoreML
//
//  Created by Gweltaz calori on 05/03/2019.
//  Copyright © 2019 tucan9389. All rights reserved.
//

import Foundation
import SocketIO

class SuperSocketManager {
    
    static let shared = SuperSocketManager()
    
    let manager = SocketManager(socketURL: URL(string: "https://dronie.vincentriva.fr")!, config: [.log(false), .compress])
    
    func connect(callback:@escaping () -> Void) {
        manager.defaultSocket.connect()
        self.on(eventName: "connect") { (d) in
            callback()
        }
    }
    
    func on(eventName:String, callback : @escaping (_ data:Any) -> Void) {
        manager.defaultSocket.on(eventName) { (dataArray, ack) in
            callback(dataArray)
        }
        
    }
    
    func emit(eventName: String,data:Any) {
        manager.defaultSocket.emit(eventName, with: [data])
    }
}
