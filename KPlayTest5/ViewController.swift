//
//  ViewController.swift
//  KPlayTest5
//
//  Created by kuzalex on 11/18/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//
//
// TODO: EOF
// TODO: обработчик ошибок в  returns NSError KRESULTOK=nil
// TODO: AVDec common iface baseclass
//





import UIKit
import BufferSlider

class KTestGraph : KPlayGraphChainBuilder {
    
    override func play(_ url: String, autoStart: Bool) -> KResult {
       
        
        do {
            objc_sync_enter(super.state_mutex)
            defer { objc_sync_exit(super.state_mutex)}
            if (super.state == KGraphState_NONE){
                super.flowchain.removeAllObjects();
                super.flowchain.add(KTestUrlSourceFilter(url: url));
                super.flowchain.add(KTestTransformFilter());
                //super.chain?.add(KQueueFilter());
                super.flowchain.add(KTestSinkFilter());
                
                super.connectchain.add(super.flowchain);
            }
        }
        
        
       
        return super.play(url, autoStart: autoStart)
    }
}

class KTestRtmpAPlayGraph : KPlayGraphChainBuilder {
    
    override func play(_ url: String, autoStart: Bool) -> KResult {
       
        
        do {
            objc_sync_enter(super.state_mutex)
            defer { objc_sync_exit(super.state_mutex)}
            if (super.state == KGraphState_NONE){
                super.flowchain.removeAllObjects();
                super.flowchain.add(KRtmpSource(url: url));
                
                super.flowchain.add(KAudioPlay());
                
                super.connectchain.add(super.flowchain);
            }
        }
        
        
       
        return super.play(url, autoStart: autoStart)
    }
}

class KTestRtmpAPlayAACGraph : KPlayGraphChainBuilder {
    
    override func play(_ url: String, autoStart: Bool) -> KResult {
       
        
        do {
            objc_sync_enter(super.state_mutex)
            defer { objc_sync_exit(super.state_mutex)}
            if (super.state == KGraphState_NONE){
                super.flowchain.removeAllObjects();
                super.flowchain.add(KRtmpSource(url: url));
                super.flowchain.add(KAudioDecoder());
                super.flowchain.add(KAudioPlay());
                
                super.connectchain.add(super.flowchain);
            }
        }
        
        
       
        return super.play(url, autoStart: autoStart)
    }
}


class KTestRtmpVPlayGraph : KPlayGraphChainBuilder {
    
    var _view:UIView;
    
    override func play(_ url: String, autoStart: Bool) -> KResult {
       
        
        do {
            objc_sync_enter(super.state_mutex)
            defer { objc_sync_exit(super.state_mutex)}
            if (super.state == KGraphState_NONE){
                super.flowchain.removeAllObjects();
                super.flowchain.add(KRtmpSource(url: url));
              
                super.flowchain.add(KVideoDecoder());
                super.flowchain.add(KVideoPlay(uiView: _view));
                
                //super.chain?.add(KQueueFilter());
                //super.chain?.add(KTestSinkFilter());
                
                super.connectchain.add(super.flowchain);
            }
        }
        
        
       
        return super.play(url, autoStart: autoStart)
    }
    
    init(_ view:UIView) {
        self._view = view;
        super.init()
    }
    
   
}

class KTestRtmpAVPlayGraph : KPlayGraphChainBuilder {
    
    var _view:UIView;
    
    override func play(_ url: String, autoStart: Bool) -> KResult {
       
        
        do {
            objc_sync_enter(super.state_mutex)
            defer { objc_sync_exit(super.state_mutex)}
            if (super.state == KGraphState_NONE){
                super.flowchain.removeAllObjects();
                super.flowchain.add(KRtmpSource(url: url)); //0
                super.flowchain.add(KAudioDecoder());       //1
              //  super.flowchain.add(KQueueFilter());        //2
                super.flowchain.add(KAudioPlay());          //2
                              
                super.flowchain.add(KVideoDecoder());       //3
             //   super.flowchain.add(KQueueFilter());        //5

                super.flowchain.add(KVideoPlay(uiView: _view));//4
                
                super.connectchain.add([super.flowchain[0], super.flowchain[1], super.flowchain[2]]);
                super.connectchain.add([super.flowchain[0], super.flowchain[3], super.flowchain[4]]);
            }
        }
        
        
       
        return super.play(url, autoStart: autoStart)
    }
    
    init(_ view:UIView) {
        self._view = view;
        super.init()
    }
    
   
}

class KTestRtmpAVQueuePlayGraph : KPlayGraphChainBuilder {
    
    var _view:UIView;
    
    override func play(_ url: String, autoStart: Bool) -> KResult {
       
        
        do {
            objc_sync_enter(super.state_mutex)
            defer { objc_sync_exit(super.state_mutex)}
            if (super.state == KGraphState_NONE){
                super.flowchain.removeAllObjects();
                super.flowchain.add(KRtmpSource(url: url)); //0
                super.flowchain.add(KAudioDecoder());       //1
                super.flowchain.add(KQueueFilter());        //2
                super.flowchain.add(KAudioPlay());          //3
                              
                super.flowchain.add(KVideoDecoder());       //4
                super.flowchain.add(KQueueFilter());        //5
                super.flowchain.add(KVideoPlay(uiView: _view));//6
                
                super.connectchain.add([super.flowchain[0], super.flowchain[1], super.flowchain[2], super.flowchain[3]]);
                super.connectchain.add([super.flowchain[0], super.flowchain[4], super.flowchain[5], super.flowchain[6]]);
            }
        }
        
        
       
        return super.play(url, autoStart: autoStart)
    }
    
    init(_ view:UIView) {
        self._view = view;
        super.init()
    }
    
   
}

class KTestAudioGraph : KPlayGraphChainBuilder {
    
    override func play(_ url: String, autoStart: Bool) -> KResult {
        
        
        do {
            objc_sync_enter(super.state_mutex)
            defer { objc_sync_exit(super.state_mutex)}
            if (super.state == KGraphState_NONE){
                super.flowchain.removeAllObjects();
                super.flowchain.add(KAudioWavSource(url: url));
                //super.chain?.add(KQueueFilter());
//                 super.chain?.add(KQueueFilter());
//                 super.chain?.add(KQueueFilter());
//                 super.chain?.add(KQueueFilter());
                //super.chain?.add(KTestTransformFilter());
                super.flowchain.add(KAudioPlay());
                
                 super.connectchain.add(super.flowchain);
                
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
    @IBOutlet weak var progressSlider: BufferSlider!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var videoView: UIView!
    
    var positionTimer: Timer?
    var inSeek:Bool = false
    
   
    
    @IBAction func onDestroyTouchDown(_ sender: Any) {
        player?.stop();
        player=nil;
        
    }
    
    
    
    @IBAction func touchDown(_ sender: Any) {
        NSLog("touchDown");
        inSeek=true;
    }
    
    @IBAction func touchUpO(_ sender: Any) {
        NSLog("touchUpO");
        touchUpI(sender);
    }
    
    
    var player:KPlayGraphChainBuilder? = nil;
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textLabel.text = ""
        
        onPlayClick(nil)
        spinner.startAnimating()
        spinner.isHidden = true
        
        //timeToString(612.587952)
    }
    
    func timeToString(_ timeSec_:Float) -> String {
        var timeMicrosec:Int = Int(timeSec_ * 1000);
        var minutes:Int=0
        var seconds:Int=0
        
        if timeMicrosec>=60000 {
            minutes = Int(timeMicrosec / 60000);
            timeMicrosec-=(minutes*60000);
        }
        seconds = Int(timeMicrosec / 1000)
        timeMicrosec-=(seconds*1000)
        
       // if timeSec
        
        
        return String(format: "%.02d:%.02d.%.02d", minutes, seconds, timeMicrosec/10);
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
           
        if let mi = self.player?.mediaInfo {
            let durationSec = Float(mi.duration() / mi.timeScale());
            let timeSec = Float(self.progressSlider.value) * durationSec / 1;
            self.timeLabel.text = timeToString(timeSec)
        }
    }
    
    @IBAction func touchUpI(_ sender: Any) {
        NSLog("touchUpI");
        inSeek=false;
        
        if let mi = self.player?.mediaInfo {
            let durationSec = Float(mi.duration() / mi.timeScale());
            let timeSec = Float(self.progressSlider.value) * durationSec / 1;
            
            player?.seek(timeSec);
           
        }
    }
            
            
          
    func showPlayerPosition(valid:Bool)
    {
        if (!valid){
            self.timeLabel.text =  timeToString(0)
            self.durationLabel.text  = timeToString(0)
            self.progressSlider.value=0;
            self.progressSlider.isEnabled = false;
            return;
        }
        if let mi = self.player?.mediaInfo {
            let durationSec = Float(mi.duration() / mi.timeScale());
            self.durationLabel.text = timeToString(durationSec);
            
            if let pi = self.player?.positionInfo {
                
                
                if player?.state == KGraphState_STARTED {
                    self.spinner.isHidden = pi.isRunning()
                }
                
                if (!inSeek && player?.state != KGraphState_SEEKING){
            
                    let timeSec = Float(pi.position()) / Float(pi.timeScale());
                    self.timeLabel.text = timeToString(timeSec)
                    
                    self.progressSlider.isEnabled = true;
                    
                    if durationSec>0 {
                        self.progressSlider.value = timeSec/Float(durationSec)
                        //NSLog("State=%@ pos=%@", state2String(state:player.state), self.timeLabel.text ?? "");
                    }
                    
                    if let bufInfo = player?.bufferPositionInfo {
                        let startBufSec = Float(bufInfo.startBufferedPosition()) / Float(bufInfo.timeScale());
                        let endBufSec = Float(bufInfo.endBufferedPosition()) / Float(bufInfo.timeScale());
                        
                        if startBufSec > 0 && endBufSec > 0 && durationSec != 0 {
                            self.progressSlider.bufferEndValue=Double(endBufSec/Float(durationSec));
                            self.progressSlider.bufferStartValue=Double(startBufSec/Float(durationSec));
                            
                            self.progressSlider.bufferEndValue=Double(endBufSec/Float(durationSec));
                            self.progressSlider.bufferStartValue=Double(startBufSec/Float(durationSec));
                        
                           // NSLog("BuffInfo: \(startBufSec) \(endBufSec) \(self.progressSlider.bufferStartValue) \(self.progressSlider.bufferEndValue) \(durationSec)");
                        }
                    
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
       
        return "";
    }
    
    func onStateChanged(_ state: KGraphState) {
        
        DispatchQueue.main.async {
            
            var stateString: String = ""
            
            self.playBtn.isEnabled = (state == KGraphState_NONE || state == KGraphState_STOPPED || state == KGraphState_PAUSED);
            self.pauseBtn.isEnabled = (state == KGraphState_STARTED || state == KGraphState_STOPPED);
            self.stopBtn.isEnabled = (state != KGraphState_STOPPED && state != KGraphState_STOPPING && state != KGraphState_NONE);
            
        
            switch state {
            case KGraphState_NONE:
                self.showPlayerPosition(valid: false);
                self.positionTimer?.invalidate();
                stateString = "none";
                self.spinner.isHidden = true
                self.progressSlider.bufferStartValue=0;
                self.progressSlider.bufferEndValue=0;
               
            case KGraphState_STOPPED:
                stateString = "stopped";
                self.showPlayerPosition(valid: false);
                self.positionTimer?.invalidate();
                self.spinner.isHidden = true
                self.progressSlider.bufferStartValue=0;
                self.progressSlider.bufferEndValue=0;
                self.inSeek=false;
               

            case KGraphState_BUILDING:
                stateString = "building...";
                self.spinner.isHidden = false
            case KGraphState_STOPPING:
                stateString = "stopping...";
                self.spinner.isHidden = false
            case KGraphState_PAUSING:
                stateString = "pausing...";
                self.spinner.isHidden = false
            case KGraphState_PAUSED:
                self.showPlayerPosition(valid: true);
                self.positionTimer?.invalidate();
                self.positionTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.runTimedCode), userInfo: nil, repeats: true)

                
                stateString = "paused";
                self.spinner.isHidden = true
            case KGraphState_STARTED:
                stateString = "started";
                
                self.spinner.isHidden = self.player?.positionInfo?.isRunning() ?? false;
//                NSLog("hidd %d", self.spinner.isHidden);
            case KGraphState_SEEKING:
                stateString = "seeking";
                self.spinner.isHidden = false
            default:
                assert(false);
            }
            UIView.transition(with: self.textLabel,
                              duration: 1.25,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in
                                self?.textLabel.text = stateString
                }, completion: nil)
            print("onStateChanged %@", self.state2String(state: state))
        }
    }
  
    @IBAction func onStopClick(_ sender: Any) {
        NSLog("onStopClick");
        player?.stop()
    }
    @IBAction func onPauseClick(_ sender: Any) {
        NSLog("onPauseClick");
        player?.pause()
    }
    @IBAction func onPlayClick(_ sender: Any?) {
        NSLog("onPlay");
        
//        UIApplication.shared.delegate?.window
        
//        UIView *window = ((AppDelegate *)  ( [UIApplication sharedApplication].delegate)).window;
        
        if player == nil {
//            player = KTestGraph();
//            player = KTestAudioGraph();
//            player = KTestRtmpAPlayGraph();
//            player = KTestRtmpVPlayGraph(self.videoView);
//            player = KTestRtmpAPlayAACGraph();
            player = KTestRtmpAVPlayGraph(self.videoView);
//            player = KTestRtmpAVQueuePlayGraph(self.videoView);
            
            player?.events = self
        }

//        player?.play("rtmp://176.9.99.77:1935/vod/testa2.flv", autoStart: true);
//        player?.play("rtmp://176.9.99.77:1935/vod/testa.mp4", autoStart: true);
//        player?.play("rtmp://176.9.99.77:1935/vod/testa.flv", autoStart: true);
//        player?.play("rtmp://176.9.99.77:1935/vod/bb.mp4", autoStart: false);
        player?.play("rtmp://176.9.99.77:1935/vod/starwars_1080p.mp4", autoStart: false);
//        player?.play("rtmp://176.9.99.77:1935/vod/bb.flv", autoStart: true);
//        player?.play("rtmp://176.9.99.77:1935/vod/testamonoaac.flv", autoStart: true);
//        player?.play("rtmp://176.9.99.77:1935/vod/test.mp4", autoStart: true);
//        player?.play("rtmp://176.9.99.77:1935/vod/testv.mp4", autoStart: false);
//        player?.play("rtmp://176.9.99.77:1936/vod/test.mp4", autoStart: true);

//        _ = player?.play("http://p.kuzalex.com/wav/gr.wav", autoStart: true)
//        _ = player?.play("http://p.kuzalex.com/wav/testa2.wav", autoStart: true)
//        _ = player?.play("http://p.kuzalex.com/wav/dom17.wav", autoStart: true)
//        _ = player?.play("http://p.kuzalex.com/wav/pipe0.wav", autoStart: true)
//        _ = player?.play("http://p.kuzalex.com/wav/pipe.wav", autoStart: false)
//        _ = player?.play("http://p.kuzalex.com/wav/2.wav", autoStart: true)

    }
    
    
}

