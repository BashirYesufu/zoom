//
//  SecondaryViewController.swift
//  zoom
//
//  Created by Bash on 03/06/2023.
//

import UIKit

enum CurrentTextType {
    case waiting, participant, share, audio, ready
    
    var literal : String {
        switch self {
        case .waiting:
            return "This is the customised waiting room ui"
        case .participant:
            return "The participants will be displayed here"
        case .share:
            return "The share options will be displayed here"
        case .audio:
            return "The audio should actually not be tampered with as it interupts system services. You can observe the meeting audio is no longer muted/unmuted"
        case .ready:
            return "This is displayed instead of the zoom system UI. It provides a custom interface but is basically reinventing the wheel as zoom has already handled all the tap interactions which this is now blocking"
        }
    }
    
    var color: UIColor {
        switch self {
        case .participant:
            return UIColor.green
        case .waiting:
            return UIColor.systemPink
        case .share:
            return UIColor.orange
        case .audio:
            return UIColor.systemRed
        case .ready:
            return UIColor.gray
        }
    }
}
class SecondaryViewController: UIViewController {

    private var currentTextType: CurrentTextType!
    
    @IBOutlet weak var centerTitle: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.centerTitle.text = currentTextType.literal
    }

}

extension SecondaryViewController {
    static func launch(_ caller: UIViewController, currentText: CurrentTextType) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SecondaryViewController") as! SecondaryViewController
        vc.currentTextType = currentText
       caller.present(vc, animated: true)
        
    }
    static func dropOut() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SecondaryViewController") as! SecondaryViewController
        vc.dismiss(animated: true)
    }
}
