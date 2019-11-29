//
//  ViewController.swift
//  KPlayTest5
//
//  Created by kuzalex on 11/18/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//
//
//

import UIKit

class KTestGraph1 : KPlayGraphChainBuilder {
    
    override func play(_ url: String, autoStart: Bool) -> KResult {
       
        
        do {
            objc_sync_enter(super.state_mutex)
            defer { objc_sync_exit(super.state_mutex)}
            if (super.state == KGraphState_NONE){
                super.chain?.removeAllObjects();
                super.chain?.add(KTestUrlSourceFilter(url: url));
                super.chain?.add(KTestTransformFilter());
                //super.chain?.add(KQueueFilter());
                super.chain?.add(KTestSinkFilter());
            }
        }
        
        
       
        return super.play(url, autoStart: autoStart)
    }
}

class KTestAudioGraph : KPlayGraphChainBuilder {
    
    override func play(_ url: String, autoStart: Bool) -> KResult {
       
        
        do {
            objc_sync_enter(super.state_mutex)
            defer { objc_sync_exit(super.state_mutex)}
            if (super.state == KGraphState_NONE){
                super.chain?.removeAllObjects();
                //super.chain?.add(KAudioSourceToneFilter());
                super.chain?.add(KAudioSourceWavReaderFilter(url: "http://p.kuzalex.com/wav/dom17.wav"));
                super.chain?.add(KAudioPlayFilter());
                //super.chain?.add(KTestSinkFilter());
            }
        }
        
        
       
        return super.play(url, autoStart: autoStart)
    }
}
class ViewController: UIViewController, KPlayerEvents {

    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var stopBtn: UIButton!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var progressSlider: UISlider!
    
    
    @IBAction func valueChanged(_ sender: Any) {
         NSLog("valueChanged");
    }
    @IBAction func touchDown(_ sender: Any) {
        NSLog("touchDown");
    }
   
    @IBAction func touchUpI(_ sender: Any) {
        NSLog("touchUpI");
    }
    @IBAction func touchUpO(_ sender: Any) {
        NSLog("touchUpO");
    }
    // var player:KTestGraph1 = KTestGraph1()
    var player = KTestAudioGraph()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textLabel.text = ""
        player.events = self
        onPlayClick(nil)
       // self.onStateChanged(KGraphState_NONE)
    }
    
    func onError(_ error: Error?) {
        
        print("onError \(String(describing: error))")
        
        DispatchQueue.main.async() {
            let alert = UIAlertController(title: "Error", message: "\(String(describing: error))", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
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
    @IBAction func onPlayClick(_ sender: Any?) {
        NSLog("onPlay");
        
        _ = player.play("https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/v9/fileSequence97.ts", autoStart: true)
        //player.play("https://kuzalex.com:8888/videos/streaming/examples/img_bipbop_adv_example_ts/v9/fileSequence97.ts", autoStart: true)
    }
    
    
}

