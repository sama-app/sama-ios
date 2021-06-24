//
//  Api.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/24/21.
//

import Foundation

class AuthContainer {
    private(set) var token: AuthToken

    init(token: AuthToken) {
        self.token = token
    }
}

enum HttpMethod: String {
    case get
    case post
}

struct EmptyBody: Codable {}

protocol ApiRequest {
    associatedtype T: Encodable
    associatedtype U: Decodable
    var uri: String { get }
    var method: HttpMethod { get }
    var body: T { get }
    var query: [URLQueryItem] { get }
}

extension ApiRequest where T == EmptyBody {
    var body: EmptyBody { EmptyBody() }
}
extension ApiRequest {
    var query: [URLQueryItem] { [] }
}

enum ApiError: Error {
    case http(Int)
    case unknown
}

class Api {
    private let session: URLSession
    private let baseUri: String
    private let auth: AuthContainer?
    private let defaultHeaders: [String: String]
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        baseUri: String,
        session: URLSession = .shared,
        defaultHeaders: [String: String],
        auth: AuthContainer?,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseUri = baseUri
        self.session = session
        self.defaultHeaders = defaultHeaders
        self.auth = auth
        self.encoder = encoder
        self.decoder = decoder
    }

    func request<T>(for request: T, completion: @escaping (Result<T.U, ApiError>) -> Void) where T: ApiRequest {
        var urlComps = URLComponents(string: "\(baseUri)\(request.uri)")!
        urlComps.queryItems = request.query

        var req = URLRequest(url: urlComps.url!)
        req.httpMethod = request.method.rawValue
        for (field, value) in defaultHeaders {
            req.setValue(value, forHTTPHeaderField: field)
        }

        switch request.method {
        case .post:
            req.httpBody = try? encoder.encode(request.body)
        case .get:
            break
        }

        if let accessToken = auth?.token.accessToken {
            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        #if DEBUG
        print("[API] REQUEST \(request.uri)")
        #endif
        session.dataTask(with: req) { (data, resp, err) in
            let result: Result<T.U, ApiError> = self.getResultFrom(data, resp: resp, err: err)

            #if DEBUG
            var msg: [String] = []
            if case .success = result {
                msg.append("isSuccess: true")
            } else {
                msg.append("isSuccess: false")
            }
            if let httpResp = resp as? HTTPURLResponse {
                msg.append("httpStatusCode: \(httpResp.statusCode)")
            }
            print("[API] RESPONSE \(request.uri): {\(msg.joined(separator: ", "))}")
            #endif

            DispatchQueue.main.async {
                completion(result)
            }
        }.resume()
    }

    private func getResultFrom<T>(_ data: Data?, resp: URLResponse?, err: Error?) -> Result<T, ApiError> where T: Decodable {
        if err != nil {
            return .failure(.unknown)
        }
        guard let httpResp = resp as? HTTPURLResponse else {
            return .failure(.unknown)
        }

        switch httpResp.statusCode {
        case 200 ..< 300:
            do {
                let jsonData = data ?? "{}".data(using: .utf8)!
                return .success(try self.decoder.decode(T.self, from: jsonData))
            } catch {
                return .failure(.http(httpResp.statusCode))
            }
        case 403:
            // refresh token
            return .failure(.http(httpResp.statusCode))
        default:
            return .failure(.http(httpResp.statusCode))
        }
    }
}
