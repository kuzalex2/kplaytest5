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
       // self.onStateChanged(KGraphState_NONE)
    }
    
    func onError(_ error: Error) {
        print("onError \(error)")
    }
    
    func onStateChanged(_ state: KGraphState) {
        
        DispatchQueue.main.async {
            
            var stateString: String = ""
            
            self.playBtn.isEnabled = (state == KGraphState_NONE || state == KGraphState_STOPPED || state == KGraphState_PAUSED);
            self.pauseBtn.isEnabled = (state == KGraphState_STARTED);
            self.stopBtn.isEnabled = (state == KGraphState_STARTED || state == KGraphState_PAUSED || state == KGraphState_BUILDING);
            
        
            switch state {
            case KGraphState_NONE:
                stateString = "none";
            case KGraphState_STOPPED:
                stateString = "stopped";
            case KGraphState_BUILDING:
                stateString = "building...";
            case KGraphState_STOPPING:
                stateString = "stopping...";
            case KGraphState_PAUSING:
                stateString = "pausing...";
            case KGraphState_PAUSED:
                stateString = "paused";
            case KGraphState_STARTED:
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

