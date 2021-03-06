//
//  MeetingInviteDeepLinkService.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/27/21.
//

import Foundation
#if !targetEnvironment(macCatalyst)
import FirebaseDynamicLinks
#endif

class MeetingInviteDeepLinkService {
    static let shared = MeetingInviteDeepLinkService()

    var observer: ((MeetingInviteDeepLinkService) -> Void)? {
        didSet {
            if meetingCode != nil {
                observer?(self)
            }
        }
    }

    private var meetingCode: String?

    func getAndClear() -> String? {
        let code = meetingCode
        meetingCode = nil
        return code
    }

    func handleUniversalLink(_ url: URL) {
        if url.host == URL(string: SamaKeys.baseUri)?.host {
            parseAndSetMeetingInviteCode(url)
        } else {
            #if !targetEnvironment(macCatalyst)
            DynamicLinks.dynamicLinks().handleUniversalLink(url) { dynamicLink, _ in
                dynamicLink?.url.flatMap { self.parseAndSetMeetingInviteCode($0) }
            }
            #endif
        }
    }

    private func parseAndSetMeetingInviteCode(_ url: URL) {
        if let code = url.path.split(separator: "/").first {
            meetingCode = String(code)
            observer?(self)
        }
    }
}
