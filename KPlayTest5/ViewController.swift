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

//class KTestGraph : KPlayGraphChainBuilder {
//
//    override func play(_ url: String, autoStart: Bool) -> KResult {
//
//
//        do {
//            objc_sync_enter(super.state_mutex)
//            defer { objc_sync_exit(super.state_mutex)}
//            if (super.state == KGraphState_NONE){
//                super.flowchain.removeAllObjects();
//                super.flowchain.add(KTestUrlSourceFilter(url: url));
//                super.flowchain.add(KTestTransformFilter());
//                //super.chain?.add(KQueueFilter());
//                super.flowchain.add(KTestSinkFilter());
//
//                super.connectchain.add(super.flowchain);
//            }
//        }
//
//
//
//        return super.play(url, autoStart: autoStart)
//    }
//}

///
/// [ KAudioWavSource ] -> [ KBufferQueue ] -> [KAudioPlay]
///
///

class KTestWavGraph : KPlayGraphChainBuilder {
    
    override func play(_ url: String, autoStart: Bool) -> KResult {
        
        
        do {
            objc_sync_enter(super.state_mutex)
            defer { objc_sync_exit(super.state_mutex)}
            if (super.state == KGraphState_NONE){
                super.flowchain.removeAllObjects();
                super.flowchain.add(KAudioWavSource(url: url));
                super.flowchain.add(KBufferQueue(firstStartBufferSec: 0.3, andSecondStartBufferSec: 3, andMaxBufferSec: 120));
//                 super.flowchain.add(KBufferQueue(firstStartBufferSec: 0.1, andSecondStartBufferSec: 3, andMaxBufferSec: 60));
                super.flowchain.add(KAudioPlay());
                super.connectchain.add(super.flowchain);
                
            }
        }
       
        return super.play(url, autoStart: autoStart)
    }
}

///
/// [ KRtmpSource ] -> [KAudioPlay]
///
///

class KTestRtmpAPlayPCMGraph : KPlayGraphChainBuilder {
    
    override func play(_ url: String, autoStart: Bool) -> KResult {
       
        
        do {
            objc_sync_enter(super.state_mutex)
            defer { objc_sync_exit(super.state_mutex)}
            if (super.state == KGraphState_NONE){
                super.flowchain.removeAllObjects();
                super.flowchain.add(KRtmpSource(url: url, andBufferSec: 5));
                super.flowchain.add(KAudioPlay());
                super.connectchain.add(super.flowchain);
            }
        }
        
        
       
        return super.play(url, autoStart: autoStart)
    }
}

///
/// [ KRtmpSource ] -> [KBufferQueue] -> [KAudioDecoder] -> [KAudioPlay]
///
///

class KTestRtmpAPlayGraph : KPlayGraphChainBuilder {
    
    override func play(_ url: String, autoStart: Bool) -> KResult {
       
        
        do {
            objc_sync_enter(super.state_mutex)
            defer { objc_sync_exit(super.state_mutex)}
            if (super.state == KGraphState_NONE){
                super.flowchain.removeAllObjects();
                super.flowchain.add(KRtmpSource(url: url, andBufferSec: 60));
                super.flowchain.add(KBufferQueue(firstStartBufferSec: 0.3, andSecondStartBufferSec: 3, andMaxBufferSec: 20));
                super.flowchain.add(KAudioDecoder());
                super.flowchain.add(KAudioPlay());
                super.connectchain.add(super.flowchain);
            }
        }
        
        
       
        return super.play(url, autoStart: autoStart)
    }
}

///
/// [ KRtmpSource ] -> [KBufferQueue] -> [KVideoDecoder] -> [KVideoPlay]
///
///

class KTestRtmpVPlayGraph : KPlayGraphChainBuilder {
    
    var _view:UIView;
    
    override func play(_ url: String, autoStart: Bool) -> KResult {
       
        
        do {
            objc_sync_enter(super.state_mutex)
            defer { objc_sync_exit(super.state_mutex)}
            if (super.state == KGraphState_NONE){
                super.flowchain.removeAllObjects();
                super.flowchain.add(KRtmpSource(url: url, andBufferSec: 15));
                super.flowchain.add(KBufferQueue(firstStartBufferSec: 1, andSecondStartBufferSec: 1, andMaxBufferSec: 120));
                super.flowchain.add(KVideoDecoder());
                super.flowchain.add(KVideoPlay(uiView: _view));
                
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

///
/// [ KRtmpSource ] -> [KBufferQueue] -> [KAudioDecoder] -> [KAudioPlay]
///              -> [KBufferQueue]  -> [KVideoDecoder] -> [KBufferQueue]  -> [KVideoPlay]
///
///

class KTestRtmpAVPlayGraph : KPlayGraphChainBuilder {
    
    var _view:UIView;
    
    override func play(_ url: String, autoStart: Bool) -> KResult {
       
        
        do {
            objc_sync_enter(super.state_mutex)
            defer { objc_sync_exit(super.state_mutex)}
            if (super.state == KGraphState_NONE){
                super.flowchain.removeAllObjects();
                super.flowchain.add(KRtmpSource(url: url, andBufferSec: 120));                                                   //0
                super.flowchain.add(KBufferQueue(firstStartBufferSec: 0.3, andSecondStartBufferSec: 3, andMaxBufferSec: 120));  //1
//                super.flowchain.add(KBufferQueue(firstStartBufferSec: 15.3, andSecondStartBufferSec: 3, andMaxBufferSec: 120));
                super.flowchain.add(KAudioDecoder());                                                                           //2
                super.flowchain.add(KAudioPlay());                                                                              //3
                
                super.flowchain.add(KBufferQueue(firstStartBufferSec: 0, andSecondStartBufferSec: 0, andMaxBufferSec: 120));  //4
                super.flowchain.add(KVideoDecoder());                                                                           //5
                super.flowchain.add(KBufferQueue(firstStartBufferSec: 1.0, andSecondStartBufferSec: 1.0, andMaxBufferSec: 2));  //6
                super.flowchain.add(KVideoPlay(uiView: _view));                                                                 //7
                
                if let q = super.flowchain.object(at: 6) as? KBufferQueue{
                    q.orderByTimestamp=true;
                }
                
               
                
                super.connectchain.add([super.flowchain[0], super.flowchain[1], super.flowchain[2], super.flowchain[3]]);
                super.connectchain.add([super.flowchain[0], super.flowchain[4], super.flowchain[5], super.flowchain[6], super.flowchain[7]]);
            }
        }
        
        
       
        return super.play(url, autoStart: autoStart)
    }
    
    init(_ view:UIView) {
        self._view = view;
        super.init()
    }
    
   
}




class ViewController: UIViewController, KPlayerEvents {

   
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var stopBtn: UIButton!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    @IBOutlet weak var progressSlider: BufferSlider!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var videoView: UIView!
    
    var positionTimer: Timer?
    var inSeek:Bool = false
    
    @IBOutlet weak var playPauseView: UIView!
    @IBOutlet weak var controlsView: UIView!
    @IBOutlet weak var debugView: UIView!
    @IBOutlet var videoGesture: UITapGestureRecognizer!
    
    @IBAction func onTap(_ sender: Any) {
        
        let isHidden = !(playPauseView?.isHidden ?? false);
        playPauseView?.isHidden  = isHidden;
        controlsView.isHidden = isHidden;
        debugView.isHidden = isHidden;
    }
    
    
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
        inSeek=false;
      //  touchUpI(sender);
    }
    
    
    var player:KPlayGraphChainBuilder? = nil;
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statusLabel?.text = ""
        
        onPlayClick(nil)
        spinner?.startAnimating()
        spinner?.isHidden = true
        spinner?.transform = CGAffineTransform.init(scaleX: 2, y: 2)
        
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
    
//    func onEOS() {
//        player?.stop();
////        player?.seek(0)
//    }
    
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
      //  NSLog("valueChanged");
        
        if (!inSeek) {
            return;
        }
           
        if let mi = self.player?.mediaInfo {
            let durationSec = ts2sec(ts: mi.duration());
            let timeSec = Float(self.progressSlider.value) * durationSec / 1;
            self.timeLabel?.text = timeToString(timeSec)
        }
    }
    
    @IBAction func touchUpI(_ sender: Any) {
        NSLog("touchUpI");
        inSeek=false;
        
        if let mi = self.player?.mediaInfo {
            let durationSec = ts2sec(ts: mi.duration());
            let timeSec = Float(self.progressSlider.value) * durationSec / 1;
            
            player?.seek(timeSec);
           
        }
    }
    
    func ts2sec(ts:CMTime)->Float
    {
        if ts.isValid {
            return Float(ts.value) / Float(ts.timescale);
        }
        return 0.0;
    }
            
            
          
    func showPlayerPosition(valid:Bool)
    {
        if (!valid){
            self.timeLabel?.text =  timeToString(0)
            self.durationLabel?.text  = timeToString(0)
            self.progressSlider?.value=0;
            self.progressSlider?.isEnabled = false;
            return;
        }
        if let mi = self.player?.mediaInfo {
            let durationSec = ts2sec(ts:mi.duration());
            self.durationLabel?.text = timeToString(durationSec);
            
            if let pi = self.player?.positionInfo {
                
                
                if player?.state == KGraphState_STARTED {
                    self.spinner?.isHidden = pi.isRunning()
                }
                
                if (/*!inSeek &&*/ player?.state != KGraphState_SEEKING){
            
                    let timeSec = ts2sec(ts: pi.position());
                    if !inSeek {
                        self.timeLabel?.text = timeToString(timeSec)
                    }
                    
                    self.progressSlider?.isEnabled = true;
                    
                    if durationSec>0 && !inSeek {
                        self.progressSlider?.value = timeSec/Float(durationSec)
                        //NSLog("State=%@ pos=%@", state2String(state:player.state), self.timeLabel.text ?? "");
                    }
                    
                    if let bufInfo = player {
                        let startBufSec = ts2sec(ts: bufInfo.startBufferedPosition()) ;
                        let endBufSec = ts2sec(ts: bufInfo.endBufferedPosition()) ;
                        
                        
                        
                        if startBufSec >= 0 && endBufSec > 0 && durationSec != 0 {
                          //  NSLog("InBuf=%f", endBufSec-startBufSec)
                            self.progressSlider?.bufferEndValue=Double(endBufSec/Float(durationSec));
                            self.progressSlider?.bufferStartValue=Double(startBufSec/Float(durationSec));
                            
                            self.progressSlider?.bufferEndValue=Double(endBufSec/Float(durationSec));
                            self.progressSlider?.bufferStartValue=Double(startBufSec/Float(durationSec));
                        
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
        case KGraphState_EOF:
            return "eof";
        default:
            assert(false);
        }
       
        return "";
    }
    
    func onStateChanged(_ state: KGraphState) {
        
        DispatchQueue.main.async {
            
            let stateString: String = self.state2String(state: state)
            
            self.playBtn?.isEnabled = (state == KGraphState_NONE || state == KGraphState_STOPPED || state == KGraphState_PAUSED || state == KGraphState_EOF);
            self.pauseBtn?.isEnabled = (state == KGraphState_STARTED || state == KGraphState_STOPPED /*|| state == KGraphState_PAUSED*/);
            self.stopBtn?.isEnabled = (state != KGraphState_STOPPED && state != KGraphState_STOPPING && state != KGraphState_NONE);
            
        
            switch state {
            case KGraphState_NONE:
                self.showPlayerPosition(valid: false);
                self.positionTimer?.invalidate();
                self.spinner?.isHidden = true
                self.progressSlider?.bufferStartValue=0;
                self.progressSlider?.bufferEndValue=0;
               
            case KGraphState_STOPPED:
                self.showPlayerPosition(valid: false);
                self.positionTimer?.invalidate();
                self.spinner?.isHidden = true
                self.progressSlider?.bufferStartValue=0;
                self.progressSlider?.bufferEndValue=0;
                self.inSeek=false;
               

            case KGraphState_BUILDING:
                self.spinner?.isHidden = false
            case KGraphState_STOPPING:
                self.spinner?.isHidden = false
            case KGraphState_PAUSING:
                self.spinner?.isHidden = false
            case KGraphState_PAUSED:
                self.showPlayerPosition(valid: true);
                self.positionTimer?.invalidate();
                self.positionTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.runTimedCode), userInfo: nil, repeats: true)

                
                self.spinner?.isHidden = true
            case KGraphState_STARTED:
                
                self.spinner?.isHidden = self.player?.positionInfo?.isRunning() ?? false;
            case KGraphState_SEEKING:
                self.spinner?.isHidden = false
            case KGraphState_EOF:
                self.spinner?.isHidden = true
            default:
                assert(false);
            }
            if let label = self.statusLabel {
                UIView.transition(with: label,
                                  duration: 1.25,
                                  options: .transitionCrossDissolve,
                                  animations: { //[weak self] in
                                    label.text = stateString
                    }, completion: nil)
            }
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
//        playWavSample();
        playRtmpSample();

        return;
    }
    
    
    
    //            player = KTestGraph();
    //            player = KTestWavGraph();
    //            player = KTestRtmpVPlayGraph(self.videoView);
    //            player = KTestRtmpAPlayGraph();
    //            player = KTestRtmpAVPlayGraph(self.videoView);
    
    func playWavSample() {
        if player == nil {
            player = KTestWavGraph();
            player?.events = self
        }
        player?.play("http://flutter-webrtc.kuzalex.com/files/file_example_WAV_1MG.wav", autoStart: true)
        
    }
    
    func playRtmpSample() {
        if player == nil {
            player = KTestRtmpAVPlayGraph(self.videoView);
            player?.events = self
        }
        player?.play("rtmp://flutter-webrtc.kuzalex.com/vod/test1.mp4", autoStart: true)
        
    }
    
    
    
}

