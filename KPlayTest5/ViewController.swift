//
//  ViewController.swift
//  KPlayTest5
//
//  Created by kuzalex on 11/18/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//
//
// TODO: pipe0.wav переписать parser wav data_size2
// TODO: обработчик ошибок в  returns NSError KRESULTOK=nil
// TODO: from stop -> to play with PAUSE
// pause seek play



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
            //super.chain?.add(KAudioSourceWavReaderFilter(url: "http://p.kuzalex.com/wav/pipe0.wav"));
            //super.chain?.add(KAudioSourceWavReaderFilter(url: "http://p.kuzalex.com/wav/pipe.wav"));
            //super.chain?.add(KAudioSourceWavReaderFilter(url: "http://p.kuzalex.com/wav/2.wav"));

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
    @IBOutlet weak var durationLabel: UILabel!
    
    var positionTimer: Timer?
    var inSeek:Bool = false
    
   
    
    
    
    
    @IBAction func touchDown(_ sender: Any) {
        NSLog("touchDown");
        inSeek=true;
    }
    
    @IBAction func touchUpO(_ sender: Any) {
        NSLog("touchUpO");
        touchUpI(sender);
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
    
    @objc func runTimedCode()
    {
        showPlayerPosition(valid: true);
    }
    
    @IBAction func valueChanged(_ sender: Any) {
        NSLog("valueChanged");
        
        if (!inSeek) {
            return;
        }
           
        if let mi = self.player.mediaInfo {
            let durationSec = Float(mi.duration() / mi.timeScale());
            let timeSec = Float(self.progressSlider.value) * durationSec / 1;
            self.timeLabel.text = String(format: "%.02f", timeSec);
        }
    }
    
    @IBAction func touchUpI(_ sender: Any) {
        NSLog("touchUpI");
        inSeek=false;
        
        if let mi = self.player.mediaInfo {
            let durationSec = Float(mi.duration() / mi.timeScale());
            let timeSec = Float(self.progressSlider.value) * durationSec / 1;
            
            player.seek(timeSec);
           
        }
    }
            
            
          
    func showPlayerPosition(valid:Bool)
    {
        if (!valid){
            self.timeLabel.text = "-";
            self.durationLabel.text = "-";
            self.progressSlider.value=0;
            self.progressSlider.isEnabled = false;
            return;
        }
        if let mi = self.player.mediaInfo {
            let durationSec = mi.duration() / mi.timeScale();
            self.durationLabel.text = "\(durationSec)";
            
            if let pi = self.player.positionInfo {
                
                if (!inSeek && player.state != KGraphState_SEEKING){
            
                    let timeSec = Float(pi.position()) / Float(pi.timeScale());
                    self.timeLabel.text = String(format: "%.02f", timeSec)
                    
                    self.progressSlider.isEnabled = true;
                    
                    if durationSec>0 {
                        self.progressSlider.value = timeSec/Float(durationSec)
                        NSLog("State=%@ pos=%@", state2String(state:player.state), self.timeLabel.text ?? "");
                    }
                }
            }
            
        } else {
            showPlayerPosition(valid: false)
        }
    }
    
    func state2String(state:KGraphState)->String{
        switch state {
        case KGraphState_NONE:
            return "none";
           
        case KGraphState_STOPPED:
            return "stopped";
            

        case KGraphState_BUILDING:
            return "building...";
        case KGraphState_STOPPING:
            return "stopping...";
        case KGraphState_PAUSING:
            return "pausing...";
        case KGraphState_PAUSED:
           
            
            return "paused";
        case KGraphState_STARTED:
            return "started";
        case KGraphState_SEEKING:
            return "seeking";
        default:
            assert(false);
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
                self.showPlayerPosition(valid: false);
                self.positionTimer?.invalidate();
                stateString = "none";
               
            case KGraphState_STOPPED:
                stateString = "stopped";
                self.showPlayerPosition(valid: false);
                self.positionTimer?.invalidate();
               

            case KGraphState_BUILDING:
                stateString = "building...";
            case KGraphState_STOPPING:
                stateString = "stopping...";
            case KGraphState_PAUSING:
                stateString = "pausing...";
            case KGraphState_PAUSED:
                self.showPlayerPosition(valid: true);
                self.positionTimer?.invalidate();
                self.positionTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.runTimedCode), userInfo: nil, repeats: true)

                
                stateString = "paused";
            case KGraphState_STARTED:
                stateString = "started";
            case KGraphState_SEEKING:
                stateString = "seeking";
            default:
                assert(false);
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

