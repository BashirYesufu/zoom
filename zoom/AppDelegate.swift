//
//  AppDelegate.swift
//  zoom
//
//  Created by Bash on 03/06/2023.
//

import UIKit
import MobileRTC

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    let sdkKey = "ndBLV2sjSO2YHkacHeRK7A"
    let sdkSecret = "oQhdDErbbJEWdVxjmmM6RJK7QJoU2sJc"
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupSDK(sdkKey: sdkKey, sdkSecret: sdkSecret)
        return true
    }
    
    func setupSDK(sdkKey: String, sdkSecret: String) {
        let context = MobileRTCSDKInitContext()
        context.domain = "zoom.us"
        context.enableLog = true
        let sdkInitializedSuccessfully = MobileRTC.shared().initialize(context)
        if sdkInitializedSuccessfully == true, let authorizationService = MobileRTC.shared().getAuthService() {
            authorizationService.clientKey = sdkKey
            authorizationService.clientSecret = sdkSecret
            authorizationService.delegate = self
            authorizationService.sdkAuth()
            print("done")
        }
    }
    
    func requestAccessToken(code: String, codeChallengeHelper: CodeChallengeHelper) {
        guard let url = self.buildAccessTokenUrl(code: code, verifier: codeChallengeHelper.verifier) else { return }
        let clientKey = sdkKey // TODO: Enter the client key from your OAuth app.
        let clientSecret = sdkSecret // TODO: Enter the client secret from your OAuth app.
        guard let encoded = "\(clientKey):\(clientSecret)".data(using: .utf8)?.base64EncodedString() else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = nil

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard self.checkRequestResult(data: data, response: response, error: error) else { return }

            let response = try! JSONDecoder().decode(AccessTokenResponse.self, from: data!)
            self.requestZak(accessToken: response.access_token)
        }

        task.resume()
    }
    private func buildAccessTokenUrl(code: String, verifier: String?) -> URL? {
        var urlComp = URLComponents()
        urlComp.scheme = "https"
        urlComp.host = "zoom.us"
        urlComp.path = "/oauth/token"

        let grantType = URLQueryItem(name: "grant_type", value: "authorization_code")
        let code = URLQueryItem(name: "code", value: code)
        let redirectUri = URLQueryItem(name: "redirect_uri", value: "google.com") // TODO: Input your redirect URI here
        let codeVerifier = URLQueryItem(name: "code_verifier", value: verifier)
        let params = [grantType, code, redirectUri, codeVerifier]
        urlComp.queryItems = params

        return urlComp.url
    }

    private struct AccessTokenResponse : Decodable {
        public let access_token: String
    }
    
    private func checkRequestResult(data: Data?, response: URLResponse?, error: Error?) -> Bool {
        if error != nil { return false }
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else { return false }
        guard data != nil else { return false }

        return true
    }
    
    private func requestZak(accessToken: String) {
        var urlComp = URLComponents()
        urlComp.scheme = "https"
        urlComp.host = "api.zoom.us"
        urlComp.path = "/v2/users/me/token"

        let tokenType = URLQueryItem(name: "type", value: "zak")
        urlComp.queryItems = [tokenType]

        guard let url = urlComp.url else { return }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard self.checkRequestResult(data: data, response: response, error: error) else { return }

            let response = try! JSONDecoder().decode(ZakResponse.self, from: data!)
            DispatchQueue.main.async {
                self.startMeeting(zak: response.token)
            }
        }

        task.resume()
    }

    private struct ZakResponse : Decodable {
        public let token: String
    }
    
    private func startMeeting(zak: String) {
        let startParams = MobileRTCMeetingStartParam4WithoutLoginUser()
        startParams.zak = zak
        startParams.meetingNumber = "7171941112" // TODO: Add your meeting number
        startParams.userName = "Bash" // TODO: Add your display name

        let meetingService = MobileRTC.shared().getMeetingService()
        meetingService?.delegate = self
        let meetingResult = meetingService?.startMeeting(with: startParams)
        if (meetingResult == .success) {
            print("Entering meeting")
            // The SDK will attempt to join the meeting, see onMeetingStateChange callback.
        } else {
            print("couldn't join")
        }
    }
}

extension AppDelegate: MobileRTCAuthDelegate, MobileRTCMeetingServiceDelegate {
    // Result of calling sdkAuth(). MobileRTCAuthError_Success represents a successful authorization.
    func onMobileRTCAuthReturn(_ returnValue: MobileRTCAuthError) {
        switch returnValue {
        case .success:
            print("SDK successfully initialized.")
        case .keyOrSecretEmpty:
            assertionFailure("SDK Key/Secret was not provided. Replace sdkKey and sdkSecret at the top of this file with your SDK Key/Secret.")
        case .keyOrSecretWrong, .unknown:
            assertionFailure("SDK Key/Secret is not valid.")
        default:
            assertionFailure("SDK Authorization failed with MobileRTCAuthError: \(returnValue).")
        }
    }
    
    func onMeetingStateChange(_ state: MobileRTCMeetingState) {
        if (state == .inMeeting) {
            // You have successfully joined the meeting.
        }
    }
}
    
