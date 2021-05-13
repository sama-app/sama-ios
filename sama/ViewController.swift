//
//  ViewController.swift
//  sama
//
//  Created by Viktoras Laukevičius on 5/4/21.
//

import UIKit
import AuthenticationServices

class ViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func onConnectCalendar(_ sender: Any) {
        var req = URLRequest(url: URL(string: "https://app.yoursama.com/api/auth/google-authorize")!)
        req.httpMethod = "post"
        URLSession.shared.dataTask(with: req) { (data, resp, err) in
            if let data = data, let directions = try? JSONDecoder().decode(AuthDirections.self, from: data) {
                DispatchQueue.main.async {
                    print(directions)
                    self.authenticate(with: directions.authorizationUrl)
                }
            }
        }.resume()
    }

    private func authenticate(with url: String) {
        let session = ASWebAuthenticationSession(url: URL(string: url)!, callbackURLScheme: "yoursama") { (callbackUrl, err) in
            print(callbackUrl)
            print(err)
        }
        session.presentationContextProvider = self
        session.start()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}
