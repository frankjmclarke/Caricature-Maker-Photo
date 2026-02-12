//
//  AIService.swift
//  Caricature Maker Photo
//
//  Created by Francis Clarke on 2026-01-08.
//

import Foundation
import Security

// MARK: - AI Response Models

struct AIEstimationResponse: Codable {
    let items: [AIEstimationItem]
    let total: AINutritionTotals
    let confidence: String
}

struct AIEstimationItem: Codable {
    let name: String
    let assumptions: String
    let calories: AIRange
    let protein_g: AIRange?
    let carbs_g: AIRange?
    let fat_g: AIRange?
}

struct AIRange: Codable {
    let low: Int
    let high: Int
    
    // Custom decoder to handle both Int and Double values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode as Int first, if that fails try Double and round
        if let lowInt = try? container.decode(Int.self, forKey: .low) {
            low = lowInt
        } else if let lowDouble = try? container.decode(Double.self, forKey: .low) {
            low = Int(round(lowDouble))
        } else {
            throw DecodingError.typeMismatch(Int.self, DecodingError.Context(codingPath: decoder.codingPath + [CodingKeys.low], debugDescription: "Expected Int or Double for low"))
        }
        
        if let highInt = try? container.decode(Int.self, forKey: .high) {
            high = highInt
        } else if let highDouble = try? container.decode(Double.self, forKey: .high) {
            high = Int(round(highDouble))
        } else {
            throw DecodingError.typeMismatch(Int.self, DecodingError.Context(codingPath: decoder.codingPath + [CodingKeys.high], debugDescription: "Expected Int or Double for high"))
        }
    }
    
    // Standard encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(low, forKey: .low)
        try container.encode(high, forKey: .high)
    }
    
    enum CodingKeys: String, CodingKey {
        case low, high
    }
    
    var midpoint: Int {
        // Ensure valid range and prevent overflow
        let safeLow = max(0, low)
        let safeHigh = max(safeLow, high)
        let sum = safeLow + safeHigh
        return sum / 2
    }
    
    // Validate that the range values are reasonable
    var isValid: Bool {
        return low >= 0 && high >= 0 && high >= low && low < Int.max && high < Int.max
    }
}

struct AINutritionTotals: Codable {
    let calories: AIRange
    let protein_g: AIRange?
    let carbs_g: AIRange?
    let fat_g: AIRange?
}

// MARK: - AI Service

class AIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String? = nil) {
        // Priority: 1) Provided key, 2) Environment variable, 3) Keychain, 4) Config.plist
        let rawKey: String
        let source: String
        
        if let providedKey = apiKey {
            rawKey = providedKey
            source = "provided parameter"
        } else if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            rawKey = envKey
            source = "environment variable"
        } else if let keychainKey = Self.loadAPIKeyFromKeychain() {
            rawKey = keychainKey
            source = "Keychain"
        } else if let configKey = Self.loadAPIKeyFromConfig() {
            rawKey = configKey
            source = "Config.plist"
        } else {
            self.apiKey = ""
            print("ERROR: No API key found from any source")
            return
        }
        
        // Trim whitespace and newlines from the key
        let trimmed = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        print("DEBUG: API key loaded from \(source) - raw length: \(rawKey.count), trimmed length: \(trimmed.count)")
        
        // If key is too long (malformed), clear Keychain and try Config.plist
        if trimmed.count > 60 && source == "Keychain" {
            print("WARNING: Key from Keychain is malformed (too long). Clearing Keychain and trying Config.plist...")
            // Clear the malformed key from Keychain
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "com.caloriesdeficittracker.openai",
                kSecAttrAccount as String: "api_key"
            ]
            SecItemDelete(query as CFDictionary)
            
            // Try loading from Config.plist instead
            if let configKey = Self.loadAPIKeyFromConfig() {
                let trimmedConfig = configKey.trimmingCharacters(in: .whitespacesAndNewlines)
                print("DEBUG: Loaded key from Config.plist after clearing Keychain - length: \(trimmedConfig.count)")
                self.apiKey = trimmedConfig
                Self.saveAPIKeyToKeychain(self.apiKey)
                return
            }
        }
        
        self.apiKey = trimmed
        
        // If we loaded from Config.plist, save the trimmed version to Keychain (replacing any old malformed key)
        if source == "Config.plist" {
            print("DEBUG: Saving trimmed key to Keychain")
            Self.saveAPIKeyToKeychain(self.apiKey)
        }
    }
    
    /// Loads API key from iOS Keychain (most secure)
    private static func loadAPIKeyFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.caloriesdeficittracker.openai",
            kSecAttrAccount as String: "api_key",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8),
              !key.isEmpty else {
            return nil
        }
        return key
    }
    
    /// Saves API key to iOS Keychain
    private static func saveAPIKeyToKeychain(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.caloriesdeficittracker.openai",
            kSecAttrAccount as String: "api_key",
            kSecValueData as String: key.data(using: .utf8)!
        ]
        
        // Delete existing item if any
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    /// Loads API key from Config.plist file (fallback for initial setup)
    private static func loadAPIKeyFromConfig() -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["OPENAI_API_KEY"] as? String,
              !apiKey.isEmpty else {
            return nil
        }
        // Trim whitespace and newlines that might be in the plist
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        print("DEBUG: Loaded key from Config.plist - original length: \(apiKey.count), trimmed length: \(trimmed.count)")
        return trimmed
    }
    
    func estimateMeal(description: String, mealTime: String = "dinner") async throws -> AIEstimationResponse {
        guard !apiKey.isEmpty else {
            print("ERROR: API key is empty")
            throw AIError.missingAPIKey
        }
        
        print("DEBUG: API key loaded (length: \(apiKey.count), starts with: \(apiKey.prefix(7)))")
        
        let systemPrompt = """
        You are a calorie estimation assistant.

        Your job is to estimate calories for a described meal
        using reasonable, typical portions.

        Rules:
        - Always provide estimates, never claim accuracy.
        - Use ranges (low/high) where appropriate.
        - Prefer honesty over precision.
        - If portion size is unclear, assume a typical adult portion.
        - If multiple items are listed, estimate each item separately, then sum.
        - Do NOT give dietary advice.
        - Do NOT moralize food choices.
        - Alcohol, snacks, and "junk food" are allowed.
        - If calories are plausibly zero, return zero.
        - Output JSON only, matching the schema exactly.
        """
        
        let userPrompt = """
        Estimate calories for: "\(description)"
        
        Provide your response in JSON format matching this exact schema:
        {
          "items": [
            {
              "name": "item name",
              "assumptions": "description of assumptions",
              "calories": { "low": 0, "high": 0 }
            }
          ],
          "total": {
            "calories": { "low": 0, "high": 0 }
          },
          "confidence": "low|medium|high"
        }
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "response_format": ["type": "json_object"] as [String: Any],
            "temperature": 0.3
        ]
        
        guard let url = URL(string: baseURL) else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Validate API key format (OpenAI keys are typically ~51 characters)
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedKey.count > 60 {
            print("ERROR: API key appears too long (\(trimmedKey.count) chars). Valid keys are ~51 characters.")
            print("ERROR: Key starts with: \(trimmedKey.prefix(20))")
            print("ERROR: Key might contain extra characters or be malformed")
        }
        
        // Set headers - use allHTTPHeaderFields to ensure it's set
        let authHeader = "Bearer \(trimmedKey)"
        let headers: [String: String] = [
            "Authorization": authHeader,
            "Content-Type": "application/json"
        ]
        
        // Set headers using allHTTPHeaderFields
        request.allHTTPHeaderFields = headers
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Verify header was set
        if let setHeader = request.value(forHTTPHeaderField: "Authorization") {
            print("DEBUG: Authorization header verified, length: \(setHeader.count)")
        } else {
            print("ERROR: Authorization header verification failed!")
            // Try setting it again directly
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.apiError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Provide more detailed error information
            let errorBody = String(data: data, encoding: .utf8) ?? "No error details"
            print("API Error: Status \(httpResponse.statusCode)")
            print("Response: \(errorBody)")
            throw AIError.apiError
        }
        
        // Parse OpenAI response
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            print("ERROR: No content in OpenAI response")
            throw AIError.invalidResponse
        }
        
        // Clean the content - remove markdown code blocks if present
        var cleanedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks (```json ... ``` or ``` ... ```)
        if cleanedContent.hasPrefix("```") {
            let lines = cleanedContent.components(separatedBy: .newlines)
            var jsonLines: [String] = []
            var inCodeBlock = false
            
            for line in lines {
                if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    inCodeBlock = !inCodeBlock
                    continue
                }
                if !inCodeBlock || (inCodeBlock && !line.trimmingCharacters(in: .whitespaces).isEmpty) {
                    jsonLines.append(line)
                }
            }
            cleanedContent = jsonLines.joined(separator: "\n")
        }
        
        guard let jsonData = cleanedContent.data(using: .utf8) else {
            print("ERROR: Could not convert content to data. Content: \(content.prefix(200))")
            throw AIError.invalidResponse
        }
        
        // Parse the actual estimation response
        do {
            let estimationResponse = try JSONDecoder().decode(AIEstimationResponse.self, from: jsonData)
            
            // Validate all ranges are valid (non-negative, reasonable values)
            // If any range is invalid, throw an error
            guard estimationResponse.total.calories.isValid else {
                print("ERROR: Invalid range values in total nutrition")
                throw AIError.invalidResponse
            }
            
            // Validate all item ranges
            for item in estimationResponse.items {
                guard item.calories.isValid else {
                    print("ERROR: Invalid range values in item: \(item.name)")
                    throw AIError.invalidResponse
                }
            }
            
            return estimationResponse
        } catch let decodingError as DecodingError {
            print("ERROR: JSON decoding failed: \(decodingError)")
            print("Content preview: \(cleanedContent.prefix(500))")
            
            // Provide more specific error message
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("Missing key: \(key.stringValue) at path: \(context.codingPath)")
                throw AIError.invalidResponseFormat("Missing required field: \(key.stringValue)")
            case .typeMismatch(let type, let context):
                print("Type mismatch: expected \(type) at path: \(context.codingPath)")
                throw AIError.invalidResponseFormat("Data type mismatch at \(context.codingPath.last?.stringValue ?? "unknown")")
            case .valueNotFound(let type, let context):
                print("Value not found: \(type) at path: \(context.codingPath)")
                throw AIError.invalidResponseFormat("Missing value at \(context.codingPath.last?.stringValue ?? "unknown")")
            case .dataCorrupted(let context):
                print("Data corrupted at path: \(context.codingPath)")
                throw AIError.invalidResponseFormat("Invalid data format")
            @unknown default:
                throw AIError.invalidResponseFormat("Data not in correct format")
            }
        } catch {
            print("ERROR: Unexpected error during JSON parsing: \(error)")
            throw AIError.invalidResponseFormat("Data not in correct format")
        }
    }
}

// MARK: - OpenAI Response Models

private struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

private struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

private struct OpenAIMessage: Codable {
    let content: String
}

// MARK: - AI Errors

enum AIError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case apiError
    case invalidResponse
    case invalidResponseFormat(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is missing. Please set OPENAI_API_KEY environment variable."
        case .invalidURL:
            return "Invalid API URL"
        case .apiError:
            return "API request failed"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .invalidResponseFormat(let message):
            return "Data not in correct format: \(message)"
        }
    }
}
