//
//  Api.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/24/21.
//

import Foundation

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
        self.request(for: request, isRefreshHandled: false, completion: completion)
    }

    private func request<T>(
        for request: T,
        isRefreshHandled: Bool,
        completion: @escaping (Result<T.U, ApiError>) -> Void
    ) where T: ApiRequest {
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
            var errBody: String = ""
            if case .success = result {
                msg.append("isSuccess: true")
            } else {
                msg.append("isSuccess: false")
            }
            if let httpResp = resp as? HTTPURLResponse {
                msg.append("httpStatusCode: \(httpResp.statusCode)")
                if !(200 ..< 300).contains(httpResp.statusCode) {
                    errBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                }
            }
            print([
                "[API] RESPONSE \(request.uri): {\(msg.joined(separator: ", "))}",
                errBody
            ].filter { !$0.isEmpty }.joined(separator: "\n"))
            #endif

            if let token = self.getRefreshTokenIfNeeded(with: result), !isRefreshHandled {
                self.refreshToken(with: token) {
                    switch $0 {
                    case let .success(updatedToken):
                        self.auth?.update(token: updatedToken)
                        self.request(for: request, isRefreshHandled: true, completion: completion)
                    case .failure:
                        DispatchQueue.main.async {
                            completion(result)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(result)
                }
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
        default:
            return .failure(.http(httpResp.statusCode))
        }
    }

    private func getRefreshTokenIfNeeded<T>(with result: Result<T, ApiError>) -> String? {
        if case let .failure(err) = result {
            if case let .http(status) = err,status == 403 {
                return auth?.token.refreshToken
            }
        }
        return nil
    }

    private func refreshToken(with token: String, completion: @escaping (Result<AuthToken, ApiError>) -> Void) {
        let urlComps = URLComponents(string: "\(baseUri)/auth/refresh-token")!
        var req = URLRequest(url: urlComps.url!)
        req.httpMethod = HttpMethod.post.rawValue
        for (field, value) in defaultHeaders {
            req.setValue(value, forHTTPHeaderField: field)
        }
        req.httpBody = try? encoder.encode(["refreshToken": token])

        session.dataTask(with: req) { (data, resp, err) in
            completion(self.getResultFrom(data, resp: resp, err: err))
        }.resume()
    }
}
