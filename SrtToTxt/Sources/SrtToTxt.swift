// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser
import Foundation

/// execu command :
/// swift run SrtToTxt  -i ~/Desktop/TestSrt  -o ~/Desktop/TestSrt

@main
struct SrtToTxt: ParsableCommand {
    
    @Option(name: [.short, .customLong("i")])
    public var input: String
    
    @Option(name: [.short, .customLong("o")])
    public var output: String
    
    var srtSegments: [SrtSegment] = []
    
    /// 多少句合并成一段
    let paragraphLineCount = 25
    
    public mutating func run() throws {
        let fileUrls = readInputFilePath()
        for url in fileUrls {
            let filename = url.deletingPathExtension().lastPathComponent
            
            print("converting file:  = \(filename)")
            let content = fileToString(file: url)
            
            saveToFile(filename: filename, content: content)
            print("save: \(filename)")
        }
    }
    
    
    func readInputFilePath() -> [URL] {
        let srtExtension = "srt"
        let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let inputUrl = URL(fileURLWithPath: input, relativeTo: currentDirectoryURL)
        print("Input path is:" + inputUrl.path)
        
        var files = [URL]()
        if let enumerator = FileManager.default.enumerator(at: inputUrl, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile! && fileURL.pathExtension == srtExtension {
                        files.append(fileURL)
                    }
                } catch { print(error, fileURL) }
            }
        }
        return files
    }
    
    func fileToString(file: URL) -> String {
        var readString = ""
        do {
            readString = try String(contentsOf: file)
        } catch let error as NSError {
            print("error: reading from URL: (fileURL), Error: " + error.localizedDescription)
        }
        return readString
    }
    
    func saveToFile(filename: String, content: String) {
        var toOutputStr = ""
        do {
            let segements = try self.parseSRTSub(content)
            for seg in segements {
                if seg.index % paragraphLineCount == 0 {
                    toOutputStr = toOutputStr + "\n\n"
                }
                toOutputStr = toOutputStr + seg.fullText
            }
            let outDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            let outDirectoryUrl = URL(fileURLWithPath: input, relativeTo: outDirectory)
            let tofileURL=outDirectoryUrl.appendingPathComponent(filename).appendingPathExtension("txt")
            try? toOutputStr.write(to: tofileURL, atomically: true, encoding: String.Encoding.utf8)
            
        } catch let error as NSError {
            print("error: save file: \(filename), Error: " + error.localizedDescription)
        }
    }
    
    
    func parseSRTSub(_ rawSub: String) throws -> [SrtSegment] {
        var allTitles = [SrtSegment]()
        var components = rawSub.components(separatedBy: "\r\n\r\n")
        
        // Fall back to \n\n separation
        if components.count == 1 {
            components = rawSub.components(separatedBy: "\n\n")
        }
        
        for component in components {
            if component.isEmpty {
                continue
            }
            
            let scanner = Scanner(string: component)
            
            var indexResult: Int = -99
            var startResult: NSString?
            var endResult: NSString?
            var textResult: NSString?
            
            let indexScanSuccess = scanner.scanInt(&indexResult)
            let startTimeScanResult = scanner.scanUpToCharacters(from: CharacterSet.whitespaces, into: &startResult)
            let dividerScanSuccess = scanner.scanUpTo("> ", into: nil)
            scanner.scanLocation += 2
            let endTimeScanResult = scanner.scanUpToCharacters(from: CharacterSet.newlines, into: &endResult)
            scanner.scanLocation += 1
            
            var textLines = [String]()
            
            // Iterate over text lines
            while scanner.isAtEnd == false {
                let textLineScanResult = scanner.scanUpToCharacters(from: CharacterSet.newlines, into: &textResult)
                
                guard textLineScanResult else {
                    throw ParseSubtitleError.InvalidFormat
                }
                textLines.append(textResult as! String)
            }
            
            guard indexScanSuccess && startTimeScanResult && dividerScanSuccess && endTimeScanResult else {
                throw ParseSubtitleError.InvalidFormat
            }
            
            let startTimeInterval: TimeInterval = timeIntervalFromString(startResult! as String)
            let endTimeInterval: TimeInterval = timeIntervalFromString(endResult! as String)
            
            let srtSeg = SrtSegment(index: indexResult, texts: textLines, start: startTimeInterval, end: endTimeInterval)
            allTitles.append(srtSeg)
        }
        
        return allTitles
    }
    
    // TODO: Throw
    func timeIntervalFromString(_ timeString: String) -> TimeInterval {
        let scanner = Scanner(string: timeString)
        
        var hoursResult: Int = 0
        var minutesResult: Int = 0
        var secondsResult: NSString?
        var millisecondsResult: NSString?
        
        // Extract time components from string
        scanner.scanInt(&hoursResult)
        scanner.scanLocation += 1
        scanner.scanInt(&minutesResult)
        scanner.scanLocation += 1
        scanner.scanUpTo(",", into: &secondsResult)
        scanner.scanLocation += 1
        scanner.scanUpToCharacters(from: CharacterSet.newlines, into: &millisecondsResult)
        
        let secondsString = secondsResult! as String
        let seconds = Int(secondsString)
        
        let millisecondsString = millisecondsResult! as String
        let milliseconds = Int(millisecondsString)
        
        let timeInterval: Double = Double(hoursResult) * 3600 + Double(minutesResult) * 60 + Double(seconds!) + Double(Double(milliseconds!)/1000)
        
        return timeInterval as TimeInterval
    }
}
