//
//  Api.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/24/21.
//

import Foundation
import FirebaseCrashlytics

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
    var logKey: String { get }
}

extension ApiRequest where T == EmptyBody {
    var body: EmptyBody { EmptyBody() }
}
extension ApiRequest {
    var query: [URLQueryItem] { [] }
}

struct ApiErrorDetails: Decodable {
    let reason: String
}

struct ApiHttpError {
    let code: Int
    let details: ApiErrorDetails?
}

struct ApiNetworkError {
    let isOffline: Bool
}

enum ApiError: Error {
    case network(ApiNetworkError)
    case http(ApiHttpError)
    case parsing
    case unknown
}

class Api {

    var forbiddenHandler: (() -> Void)?

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
            self.logDebug(request: request, resp: resp, result: result, data: data)
            #endif
            self.logCrashlytics(withKey: request.logKey, result: result)

            if let token = self.getRefreshTokenIfNeeded(with: result), !isRefreshHandled {
                self.refreshToken(with: token) {
                    switch $0 {
                    case let .success(updatedToken):
                        self.auth?.update(token: updatedToken)
                        self.request(for: request, isRefreshHandled: true, completion: completion)
                    case .failure:
                        let errOut = NSError(domain: "com.meetsama.sama.api.token_refresh", code: 1000, userInfo: [:])
                        Crashlytics.crashlytics().record(error: errOut)

                        if result.error?.httpCode == 400 {
                            DispatchQueue.main.async {
                                self.forbiddenHandler?()
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(result)
                            }
                        }
                    }
                }
            } else if result.error?.httpCode == 403 {
                DispatchQueue.main.async {
                    self.forbiddenHandler?()
                }
            } else {
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }.resume()
    }

    private func logCrashlytics<T>(withKey key: String, result: Result<T, ApiError>) where T: Decodable {
        guard case let .failure(err) = result else { return }

        let code: Int
        switch err {
        case .network: code = 1000
        case .unknown: code = 1001
        case .parsing: code = 1002
        case let .http(inner): code = inner.code
        }
        let errOut = NSError(domain: key, code: code, userInfo: [:])
        Crashlytics.crashlytics().record(error: errOut)
    }

    private func logDebug<T>(request: T, resp: URLResponse?, result: Result<T.U, ApiError>, data: Data?) where T: ApiRequest {
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
    }

    private func getResultFrom<T>(_ data: Data?, resp: URLResponse?, err: Error?) -> Result<T, ApiError> where T: Decodable {
        if let networkErr = err {
            let isOffline = networkErr._domain == NSURLErrorDomain && networkErr._code == NSURLErrorNotConnectedToInternet
            return .failure(.network(ApiNetworkError(isOffline: isOffline)))
        }
        guard let httpResp = resp as? HTTPURLResponse else {
            return .failure(.unknown)
        }

        let jsonData = data ?? "{}".data(using: .utf8)!

        switch httpResp.statusCode {
        case 200 ..< 300:
            do {
                return .success(try self.decoder.decode(T.self, from: jsonData))
            } catch {
                return .failure(.parsing)
            }
        default:
            let details = try? self.decoder.decode(ApiErrorDetails.self, from: jsonData)
            let httpErr = ApiHttpError(code: httpResp.statusCode, details: details)
            return .failure(.http(httpErr))
        }
    }

    private func getRefreshTokenIfNeeded<T>(with result: Result<T, ApiError>) -> String? {
        if result.error?.httpCode == 401 {
            return auth?.token.refreshToken
        } else {
            return nil
        }
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
            let result: Result<AuthToken, ApiError> = self.getResultFrom(data, resp: resp, err: err)
            self.logCrashlytics(withKey: "/auth/refresh-token", result: result)
            completion(result)
        }.resume()
    }
}

private extension Result {
    var error: Failure? {
        switch self {
        case .success:
            return nil
        case let .failure(error):
            return error
        }
    }
}

extension ApiError {
    var httpError: ApiHttpError? {
        switch self {
        case let .http(inner):
            return inner
        default:
            return nil
        }
    }
    var httpCode: Int? {
        switch self {
        case let .http(inner):
            return inner.code
        default:
            return nil
        }
    }
}
