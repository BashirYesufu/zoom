//
//  CodeChallengeHelper.swift
//  zoom
//
//  Created by Bash on 03/06/2023.
//

import Foundation
import CommonCrypto

class CodeChallengeHelper {
    var verifier: String? = nil
    
    init() {
        createCodeVerifier()
    }
    
    func createCodeVerifier() {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        verifier = Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    func getCodeChallenge() -> String {
        guard let data = verifier?.data(using: .ascii) else { return "" }
        var buffer = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(data.count), &buffer)
        }
        let hash = Data(buffer)
        let challenge = hash.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
        return challenge
    }
}
