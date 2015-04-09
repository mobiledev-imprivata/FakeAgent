//
//  Logger.swift
//  FakeAgent
//
//  Created by Jay Tucker on 4/9/15.
//  Copyright (c) 2015 Imprivata. All rights reserved.
//

import Foundation

func timestamp() -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss.SSS"
    return dateFormatter.stringFromDate(NSDate())
}

func log(message: String) {
    println("[\(timestamp())] \(message)")
}
