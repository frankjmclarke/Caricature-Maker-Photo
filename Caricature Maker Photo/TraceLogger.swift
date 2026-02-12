//
//  TraceLogger.swift
//  Caricature Maker Photo
//
//  Created by Francis Clarke on 2026-01-13.
//

import Foundation

#if DEBUG
/// Centralized trace logging for debugging Superwall and onboarding flow
class TraceLogger {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    static func trace(_ category: String, _ message: String, file: String = #file, line: Int = #line) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        print("[\(timestamp)] [\(category)] \(message) (\(fileName):\(line))")
    }
    
    static func traceState(_ category: String, _ state: [String: Any]) {
        let timestamp = dateFormatter.string(from: Date())
        let stateString = state.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        print("[\(timestamp)] [\(category)] STATE: \(stateString)")
    }
}
#endif
