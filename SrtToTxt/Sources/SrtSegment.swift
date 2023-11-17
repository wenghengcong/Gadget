//
//  File.swift
//  
//
//  Created by Nemo on 2023/11/13.
//

import Foundation

public enum ParseSubtitleError: Error, Decodable {
    case Failed
    case InvalidFormat
}


public class SrtSegment: NSObject, Decodable {
    public var texts: [String] = []
    public var fullText: String = ""
    public var start: TimeInterval = 0
    public var end: TimeInterval = 0
    public var index: Int = 0
    
    public init(index: Int, texts: [String], start: TimeInterval, end: TimeInterval) {
        super.init()
        self.texts = texts
        
        var fullTmp = ""
        for text in self.texts {
            fullTmp = fullTmp + " " + text
        }
        self.fullText = fullTmp
        
        self.start = start
        self.end = end
        self.index = index
    }
}
