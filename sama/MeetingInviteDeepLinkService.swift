//
//  MeetingInviteDeepLinkService.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/27/21.
//

import Foundation

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

    func setMeetingInviteCode(_ code: String) {
        meetingCode = code
        observer?(self)
    }

    func getAndClear() -> String? {
        let code = meetingCode
        meetingCode = nil
        return code
    }
}
