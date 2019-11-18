//
//  ViewController.swift
//  KPlayTest5
//
//  Created by kuzalex on 11/18/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//

import UIKit

class ViewController: UIViewController, KPlayerEvents {

    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var stopBtn: UIButton!
    @IBOutlet weak var textLabel: UILabel!
    
    var player:KTestGraph1 = KTestGraph1()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textLabel.text = ""
        player.events = self
    }
    
    func onError(_ error: Error) {
        print("onError")
    }
    
    func onStateChanged(_ state: KGraphState) {
        
        DispatchQueue.main.async {
            
            var stateString: String = ""
        
            switch state {
            case KGraphState_NONE:
                self.playBtn.isEnabled = true
                self.pauseBtn.isEnabled = false
                self.stopBtn.isEnabled = false
                stateString = "none";
            case KGraphState_STOPPED:
                self.playBtn.isEnabled = true
                self.pauseBtn.isEnabled = false
                self.stopBtn.isEnabled = false
                stateString = "stopped";
            case KGraphState_BUILDING:
                self.playBtn.isEnabled = false
                self.pauseBtn.isEnabled = false
                self.stopBtn.isEnabled = true
                stateString = "building...";
            case KGraphState_STOPPING:
                self.playBtn.isEnabled = false
                self.pauseBtn.isEnabled = false
                self.stopBtn.isEnabled = false
                stateString = "stopping...";
            case KGraphState_PAUSING:
                self.playBtn.isEnabled = false
                self.pauseBtn.isEnabled = false
                self.stopBtn.isEnabled = false
                stateString = "pausing...";
            case KGraphState_PAUSED:
                self.playBtn.isEnabled = true
                self.pauseBtn.isEnabled = false
                self.stopBtn.isEnabled = true
                stateString = "paused";
            case KGraphState_STARTED:
                self.playBtn.isEnabled = false
                self.pauseBtn.isEnabled = true
                self.stopBtn.isEnabled = true
                stateString = "started";
            default:
                break
            }
            UIView.transition(with: self.textLabel,
                              duration: 1.25,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in
                                self?.textLabel.text = stateString
                }, completion: nil)
            print("onStateChanged %@", state)
        }
    }
  
    @IBAction func onStopClick(_ sender: Any) {
        NSLog("onStopClick");
        player.stop()
    }
    @IBAction func onPauseClick(_ sender: Any) {
        NSLog("onPauseClick");
        player.pause()
    }
    @IBAction func onPlayClick(_ sender: Any) {
        NSLog("onPlay");
        
        player.play("https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/v9/fileSequence97.ts", autoStart: true)
        //player.play("https://kuzalex.com:8888/videos/streaming/examples/img_bipbop_adv_example_ts/v9/fileSequence97.ts", autoStart: true)
    }
    
    
}

