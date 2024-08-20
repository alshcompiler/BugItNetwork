import Foundation
import Combine

public class URLSessionHTTPClient: HTTPClient {

    private let session: URLSession

        public init(session: URLSession = .shared) {
            self.session = session
        }


    public func performRequest<T: Decodable>(method: HTTPMethod,
                                             url: String,
                                             parameters: [String: Any] = [:],
                                             encoding: ParameterEncoding = .urlEncoding,
                                             headers: [String: String] = [:],
                                             responseType: T.Type) async throws -> T {
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers

        // Encode parameters
        switch encoding {
        case .urlEncoding:
            if method == .get {
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
                if let urlWithParams = components?.url {
                    request.url = urlWithParams
                }
            } else {
                request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
            }
        case .jsonEncoding:
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Perform request and return data
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        do {
            if T.self == Data.self {
                return data as! T
            }
            let decodedResponse = try JSONDecoder().decode(T.self, from: data)
            return decodedResponse
        } catch {
            // Handle any decoding errors
            throw NetworkError.invalidData
        }
    }

    public func uploadMultipart<T: Decodable>(url: String,
                                              fileName: String?,
                                              fileData: Data,
                                              parameters: [String: String],
                                              headers: [String: String] = [:],
                                              responseType: T.Type) async throws -> T {
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = headers
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let fileNameResult = fileName ?? String.generateRandomString(length: .fileNameLength) + ".jpg"
        let body = createMultipartBody(boundary: boundary,
                                       fileData: fileData,
                                       fileName: fileNameResult)
        request.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        do {
            let decodedResponse = try JSONDecoder().decode(T.self, from: data)
            return decodedResponse
        } catch {
            // Handle any decoding errors
            throw NetworkError.invalidData
        }
    }
}

private extension URLSessionHTTPClient {
    func createMultipartBody(boundary: String, fileData: Data, fileName: String, additionalFields: [String: String] = [:]) -> Data {
        var body = Data()

        // Add additional fields
            for (key, value) in additionalFields {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }

        // Add file data
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \"content-type header\"\r\n\r\n")
        body.append(fileData)
        body.append("\r\n")

        // End the multipart form data
        body.append("--\(boundary)--\r\n")

        return body
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

private extension Int {
    static let fileNameLength = 20
}

extension String {
    static func generateRandomString(length: Int) -> String {
            let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            return String((0..<length).compactMap { _ in characters.randomElement() })
        }
}
