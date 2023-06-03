//
//  ViewController.swift
//  zoom
//
//  Created by Bash on 03/06/2023.
//

import UIKit
import AuthenticationServices
import MobileRTC

class ViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {
    private let codeChallengeHelper = CodeChallengeHelper()
    private let delegate = UIApplication.shared.delegate as! AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()
        startSession()
        self.view.backgroundColor = .brown
//        let nav = UINavigationController(rootViewController: self)
        MobileRTC.shared().setMobileRTCRootController(self.navigationController)
//        joinMeeting(meetingNumber: "7171941112", meetingPassword: "1234567")
    }
    @IBAction func joinAMeetingButtonPressed(_ sender: Any) {
        presentJoinMeetingAlert()
    }
    
    // Function to create an alert dialog where users can enter meeting details.
        func presentJoinMeetingAlert() {
            let alertController = UIAlertController(title: "Join meeting", message: "", preferredStyle: .alert)
            alertController.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "Meeting number"
                textField.keyboardType = .phonePad
                textField.text = "7171941112"
            }
            alertController.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "Meeting password"
                textField.keyboardType = .asciiCapable
                textField.isSecureTextEntry = true
                textField.text = "1s9JxS"
            }
            let joinMeetingAction = UIAlertAction(title: "Join meeting", style: .default, handler: { alert -> Void in
                let numberTextField = alertController.textFields![0] as UITextField
                let passwordTextField = alertController.textFields![1] as UITextField

                if let meetingNumber = numberTextField.text, let password = passwordTextField.text {
                    self.joinMeeting(meetingNumber: meetingNumber, meetingPassword: password)
                }
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (action : UIAlertAction!) -> Void in })
            alertController.addAction(joinMeetingAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    
    @IBAction func startAnInstantMeetingButtonPressed(_ sender: Any) {
        startMeetingZak()
    }
    
    func startMeetingZak() {
        if let meetingService = MobileRTC.shared().getMeetingService() {
            meetingService.delegate = self
            let startMeetingParams = MobileRTCMeetingStartParam4WithoutLoginUser()
            startMeetingParams.zak = "" // TODO: Enter ZAK
            startMeetingParams.vanityID = "xcvbn" // TODO: Enter userID
            startMeetingParams.userName = "Bash" // TODO: Enter your name
            meetingService.startMeeting(with: startMeetingParams)
        }
    }
    func joinMeeting(meetingNumber: String, meetingPassword: String) {
        // Obtain the MobileRTCMeetingService from the Zoom SDK, this service can start meetings, join meetings, leave meetings, etc.
        if let meetingService = MobileRTC.shared().getMeetingService() {
            // Create a MobileRTCMeetingJoinParam to provide the MobileRTCMeetingService with the necessary info to join a meeting.
            // In this case, we will only need to provide a meeting number and password.
            let joinMeetingParameters = MobileRTCMeetingJoinParam()
            joinMeetingParameters.meetingNumber = meetingNumber
            joinMeetingParameters.password = meetingPassword
            meetingService.customizedUImeetingDelegate = self
            meetingService.delegate = self
            // Call the joinMeeting function in MobileRTCMeetingService. The Zoom SDK will handle the UI for you, unless told otherwise.
            // If the meeting number and meeting password are valid, the user will be put into the meeting. A waiting room UI will be presented or the meeting UI will be presented.
            meetingService.joinMeeting(with: joinMeetingParameters)
        } else {
            print("could not join")
        }
    }
    
    func startSession()  {
        codeChallengeHelper.createCodeVerifier()
        guard var oauthUrlComp = URLComponents(string: "https://zoom.us/oauth/authorize") else { return }

        let codeChallenge = URLQueryItem(name: "code_challenge", value: codeChallengeHelper.getCodeChallenge())
        let codeChallengeMethod = URLQueryItem(name: "code_challenge_method", value: "S256")
        let responseType = URLQueryItem(name: "response_type", value: "code")
        let clientId = URLQueryItem(name: "client_id", value: "ndBLV2sjSO2YHkacHeRK7A") // TODO: Enter your OAuth client ID.
        let redirectUri = URLQueryItem(name: "redirect_uri", value: "google.com") // TODO: Enter the redirect URI of your OAuth app.
        oauthUrlComp.queryItems = [responseType, clientId, redirectUri, codeChallenge, codeChallengeMethod]

        let scheme = "" // TODO: Enter the custom scheme of the redirect URI of your OAuth app.

        guard let oauthUrl = oauthUrlComp.url else { return }

        let session = ASWebAuthenticationSession(url: oauthUrl, callbackURLScheme: scheme) { callbackUrl, error in
            self.handleAuthResult(callbackUrl: callbackUrl, error: error)
        }

        session.presentationContextProvider = self
        session.start()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window ?? UIWindow()
    }
    
    private func handleAuthResult(callbackUrl: URL?, error: Error?) {
        guard let callbackUrl = callbackUrl else { return }
        if (error == nil) {
            guard let url = URLComponents(string: callbackUrl.absoluteString) else { return }
            guard let code = url.queryItems?.first(where: { $0.name == "code" })?.value else { return }
            self.delegate.requestAccessToken(code: code, codeChallengeHelper: self.codeChallengeHelper)
        }
    }

}

extension ViewController: MobileRTCMeetingServiceDelegate {
    // Is called upon in-meeting errors, join meeting errors, start meeting errors, meeting connection errors, etc.
    func onMeetingError(_ error: MobileRTCMeetError, message: String?) {
        switch error {
        case .passwordError:
            print("Could not join or start meeting because the meeting password was incorrect.")
        default:
            print("Could not join or start meeting with MobileRTCMeetError: \(error) \(message ?? "")")
        }
    }
    // Is called when the user joins a meeting.
    func onJoinMeetingConfirmed() {
        print("Join meeting confirmed.")
    }
    // Is called upon meeting state changes.
    func onMeetingStateChange(_ state: MobileRTCMeetingState) {
        print("Current meeting state: \(state)")
    }
}

extension ViewController: MobileRTCCustomizedUIMeetingDelegate {
    func onInitMeetingView() {
    }
    
    func onDestroyMeetingView() {
        
    }
    
    func onJBHWaiting(with cmd: JBHCmd) {
        switch cmd {
        case .show:
            SecondaryViewController.launch(self, currentText: .waiting)
        case .hide:
            SecondaryViewController.dropOut()
        default:
            return
        }

    }
    
    func onClickShareScreen(_ parentVC: UIViewController) {
        SecondaryViewController.launch(self, currentText: .share)
    }
    
    func onClickedAudioButton(_ parentVC: UIViewController) -> Bool {
        SecondaryViewController.launch(self, currentText: .audio)
        return true
    }
    
    func onMeetingReady() {
        SecondaryViewController.launch(self, currentText: .ready)
    }
    func onClickedParticipantsButton(_ parentVC: UIViewController) -> Bool {
        var service = MobileRTC.shared().getMeetingService()
        SecondaryViewController.launch(self, currentText: .participant)
         return true
    }
}
