//
//  GetAccessTokenDelegate.swift
//  Alexa
//
//  Created by Colin Harris on 22/2/16.
//  Copyright © 2016 Colin Harris. All rights reserved.
//

import Foundation

class GetAccessTokenDelegate: NSObject, AIAuthenticationDelegate {
    
    private let successHandler: (String) -> Void
    private let errorHandler: (Void) -> Void
    
    init(success: (String) -> Void, error: (Void) -> Void) {
        self.successHandler = success
        self.errorHandler = error
    }
    
    func requestDidSucceed(result: APIResult) {
        print("GetAccessTokenDelegate.requestDidSucceed")
        let accessToken = result.result
        successHandler(accessToken as! String)
    }
    
    func requestDidFail(error: APIError) {
        print("GetAccessTokenDelegate.requestDidFail")
        print("Error: \(error)")
        print("")
        errorHandler()
    }
    
}