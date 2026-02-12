//
//  CaricatureAPIClient.swift
//  Caricature Maker Photo
//
//  Job-based REST API: create job, poll until done, download result.
//

import Foundation

enum JobStatus {
    case pending
    case succeeded(resultURL: URL)
    case failed(message: String)
}

final class CaricatureAPIClient {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL? = nil, session: URLSession = .shared) {
        self.baseURL = baseURL ?? CaricatureConfig.baseURL
        self.session = session
    }

    func createJob(image: Data, styleId: String, params: CaricatureWarpParams) async throws -> String {
        let url = baseURL.appendingPathComponent("v1/jobs")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(image)
        body.append("\r\n".data(using: .utf8)!)

        let paramsJSON = try JSONEncoder().encode(params)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"params\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        body.append(paramsJSON)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"style_id\"\r\n\r\n".data(using: .utf8)!)
        body.append(styleId.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

#if DEBUG
        TraceLogger.trace("CaricatureAPIClient", "POST /v1/jobs - creating job")
#endif

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CaricatureAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw CaricatureAPIError.httpError(statusCode: httpResponse.statusCode)
        }

        struct CreateJobResponse: Decodable {
            let id: String
        }
        let decoded = try JSONDecoder().decode(CreateJobResponse.self, from: data)
        return decoded.id
    }

    func pollJob(id: String) async throws -> JobStatus {
        let url = baseURL.appendingPathComponent("v1/jobs/\(id)")
        var delay: TimeInterval = 1
        let maxDelay: TimeInterval = 10
        let maxAttempts = 60

        for attempt in 0..<maxAttempts {
            try Task.checkCancellation()

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CaricatureAPIError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw CaricatureAPIError.httpError(statusCode: httpResponse.statusCode)
            }

            struct JobResponse: Decodable {
                let status: String
                let result_url: String?
                let error: String?
            }
            let decoded = try JSONDecoder().decode(JobResponse.self, from: data)

            switch decoded.status {
            case "succeeded":
                if let resultURLString = decoded.result_url, let resultURL = URL(string: resultURLString) {
#if DEBUG
                    TraceLogger.trace("CaricatureAPIClient", "Job \(id) succeeded")
#endif
                    return .succeeded(resultURL: resultURL)
                }
                return .failed(message: "No result URL")
            case "failed":
#if DEBUG
                TraceLogger.trace("CaricatureAPIClient", "Job \(id) failed: \(decoded.error ?? "unknown")")
#endif
                return .failed(message: decoded.error ?? "Generation failed")
            default:
#if DEBUG
                if attempt % 5 == 0 {
                    TraceLogger.trace("CaricatureAPIClient", "Job \(id) polling attempt \(attempt), status=\(decoded.status)")
                }
#endif
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                delay = min(delay * 1.5, maxDelay)
            }
        }

        throw CaricatureAPIError.timeout
    }

    func downloadResult(url: URL) async throws -> Data {
#if DEBUG
        TraceLogger.trace("CaricatureAPIClient", "Downloading result from \(url)")
#endif

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw CaricatureAPIError.downloadFailed
        }

        return data
    }
}

enum CaricatureAPIError: Error {
    case invalidResponse
    case httpError(statusCode: Int)
    case timeout
    case downloadFailed
}
