import Foundation


public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public enum ParameterEncoding {
    case urlEncoding
    case jsonEncoding
}

public protocol HTTPClient {
    func performRequest<T: Decodable>(method: HTTPMethod,
                                      url: String,
                                      parameters: [String: Any],
                                      encoding: ParameterEncoding,
                                      headers: [String: String],
                                      responseType: T.Type) async throws -> T
    func uploadMultipart<T: Decodable>(url: String,
                                       fileName: String?,
                                       fileData: Data,
                                       parameters: [String: String],
                                       headers: [String: String],
                                       responseType: T.Type) async throws -> T
}

public enum NetworkError: LocalizedError {
    case connectivity
    case invalidData
    case unAuthorized
    case notValidURL
    case unDefined

    public var errorDescription: String? {
        switch self {
        case .connectivity:
            return "Please check your internet connection"
        case .unAuthorized:
            return "You have been logged out, please try to login again"
        default:
            return "Something went wrong, please try again later"
        }
    }

}

public extension HTTPClient {
    func performRequest<T: Decodable>(method: HTTPMethod,
                                      url: String,
                                      parameters: [String: Any] = [:],
                                      encoding: ParameterEncoding = .urlEncoding,
                                      headers: [String: String] = [:],
                                      responseType: T.Type) async throws -> T {
        try await performRequest(method: method,
                                 url: url,
                                 parameters: parameters,
                                 encoding: encoding,
                                 headers: headers,
                                 responseType: responseType)
    }

    func uploadMultipart<T: Decodable>(url: String,
                                       fileName: String? = nil,
                                       fileData: Data,
                                       parameters: [String: String] = [:],
                                       headers: [String: String] = [:],
                                       responseType: T.Type) async throws -> T {
        try await uploadMultipart(url: url,
                                  fileName: fileName,
                                  fileData: fileData,
                                  parameters: parameters,
                                  headers: headers,
                                  responseType: responseType)
    }
}
