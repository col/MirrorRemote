//
//  Config.swift
//  Alexa
//
//  Created by Colin Harris on 22/2/16.
//  Copyright © 2016 Colin Harris. All rights reserved.
//

import Foundation

struct Config {

    struct LoginWithAmazon {
        // Security Profile Client ID
        static let ClientId = "amzn1.application-oa2-client."
        // Application Type ID
        static let ProductId = "smart_mirror_remote"
        // Make it up!
        static let DeviceSerialNumber = "2000-0000-0000-0001"
    }
    
    struct Audio {
        static let SampleRate = 16000 as Float64
    }
    
    struct Debug {
        static let General = true
        static let Errors = true
        static let HTTPRequest = true
        static let HTTPResponse = true
    }

    struct Error {
        static let ErrorDomain = "net.ioncannon.SimplePCMRecorderError"
        
        static let PCMSetupIncompleteErrorCode = 1
        
        static let AVSUploaderSetupIncompleteErrorCode = 2
        static let AVSAPICallErrorCode = 3
        static let AVSResponseBorderParseErrorCode = 4
    }
    
}