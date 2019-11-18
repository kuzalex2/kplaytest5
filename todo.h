//
//  todo.h
//  KPlayTest5
//
//  Created by kuzalex on 11/18/19.
//  Copyright © 2019 kuzalex. All rights reserved.
//
/*
 2019-11-18 21:38:19.178356+0300 KPlayTest5[417:15131] onPlay
 2019-11-18 21:38:19.185047+0300 KPlayTest5[417:15163] setStateAndNotify KTestUrlSourceFilter KFilterState_PAUSED
 2019-11-18 21:38:19.185793+0300 KPlayTest5[417:15163] KTestUrlSourceFilter Downloading https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/v9/fileSequence97.ts
 onStateChanged %@ KGraphState(rawValue: 1)
 2019-11-18 21:38:21.634806+0300 KPlayTest5[417:15164] KTestUrlSourceFilter Downloaded https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/v9/fileSequence97.ts
 2019-11-18 21:38:21.644215+0300 KPlayTest5[417:15163] setStateAndNotify KTestTransformFilter KFilterState_PAUSED
 2019-11-18 21:38:21.644633+0300 KPlayTest5[417:15163] State is KFilterState_STOPPED
 2019-11-18 21:38:21.644876+0300 KPlayTest5[417:15163] setStateAndNotify KTestSinkFilter KFilterState_PAUSING
 2019-11-18 21:38:21.645343+0300 KPlayTest5[417:15168] <KTestSinkFilter: 0x280d0c190> KTestSinkFilter got sample type=video/mp2t 5985732 bytes, ts=0/0
 2019-11-18 21:38:21.747364+0300 KPlayTest5[417:15168] setStateAndNotify KTestSinkFilter KFilterState_PAUSED
 2019-11-18 21:38:21.747691+0300 KPlayTest5[417:15163] State is KFilterState_PAUSED
 2019-11-18 21:38:21.748107+0300 KPlayTest5[417:15163] setStateAndNotify KTestUrlSourceFilter KFilterState_STARTED
 onStateChanged %@ KGraphState(2019-11-18 21:38:21.748466+0300 KPlayTest5[417:15163] onStateChanged KTestUrlSourceFilter KFilterState_STARTED
 rawValue: 5)
 2019-11-18 21:38:21.748925+0300 KPlayTest5[417:15163] setStateAndNotify KTestTransformFilter KFilterState_STARTED
 2019-11-18 21:38:21.749663+0300 KPlayTest5[417:15163] onStateChanged KTestTransformFilter KFilterState_STARTED
 2019-11-18 21:38:21.749901+0300 KPlayTest5[417:15163] setStateAndNotify KTestSinkFilter KFilterState_STARTED
 2019-11-18 21:38:21.750100+0300 KPlayTest5[417:15163] onStateChanged KTestSinkFilter KFilterState_STARTED
 2019-11-18 21:38:21.750281+0300 KPlayTest5[417:15163] setStateAndNotify KTestSinkFilter KFilterState_STARTED
 2019-11-18 21:38:21.750933+0300 KPlayTest5[417:15164] KTestUrlSourceFilter Downloading https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/v9/fileSequence97.ts
 onStateChanged %@ KGraphState(rawValue: 6)
 2019-11-18 21:38:21.849022+0300 KPlayTest5[417:15168] KTestUrlSourceFilter Downloading https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/v9/fileSequence97.ts
 2019-11-18 21:38:23.791947+0300 KPlayTest5[417:15131] onStopClick
 2019-11-18 21:38:23.792386+0300 KPlayTest5[417:15131] setStateAndNotify KTestUrlSourceFilter KFilterState_STOPPED
 2019-11-18 21:38:23.792654+0300 KPlayTest5[417:15131] onStateChanged KTestUrlSourceFilter KFilterState_STOPPED
 2019-11-18 21:38:23.792857+0300 KPlayTest5[417:15131] setStateAndNotify KTestTransformFilter KFilterState_STOPPED
 2019-11-18 21:38:23.793068+0300 KPlayTest5[417:15131] onStateChanged KTestTransformFilter KFilterState_STOPPED
 2019-11-18 21:38:23.793272+0300 KPlayTest5[417:15131] setStateAndNotify KTestSinkFilter KFilterState_STOPPING
 2019-11-18 21:38:23.793455+0300 KPlayTest5[417:15131] onStateChanged KTestSinkFilter KFilterState_STOPPING
 2019-11-18 21:38:23.855547+0300 KPlayTest5[417:15168] onError KTestSinkFilter 1 (null)
 2019-11-18 21:38:23.855903+0300 KPlayTest5[417:15168] KTestSinkFilter threadProc stopping
 2019-11-18 21:38:23.856170+0300 KPlayTest5[417:15168] setStateAndNotify KTestSinkFilter KFilterState_STOPPED
 2019-11-18 21:38:23.856387+0300 KPlayTest5[417:15168] onStateChanged KTestSinkFilter KFilterState_STOPPED
 onStateChanged %@ KGraphState(rawValue: 2)
 2019-11-18 21:38:23.866037+0300 KPlayTest5[417:15163] Task <2485F2F7-445C-4D19-A3D9-8E0704931645>.<3> finished with error [-999] Error Domain=NSURLErrorDomain Code=-999 "cancelled" UserInfo={NSErrorFailingURLStringKey=https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/v9/fileSequence97.ts, NSLocalizedDescription=cancelled, NSErrorFailingURLKey=https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/v9/fileSequence97.ts}
 2019-11-18 21:38:23.866419+0300 KPlayTest5[417:15163] KTestUrlSourceFilter Error: Error Domain=NSURLErrorDomain Code=-999 "cancelled" UserInfo={NSErrorFailingURLStringKey=https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/v9/fileSequence97.ts, NSLocalizedDescription=cancelled, NSErrorFailingURLKey=https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/v9/fileSequence97.ts}
 2019-11-18 21:38:24.264927+0300 KPlayTest5[417:15164] onError KTestSinkFilter 1 (null)
 Assertion failed: (0), function -[KThreadFilter threadProc], file /Users/kuzalex/projects/KPlayTest5/KPlayTest5/KPlay/KFilter.m, line 299.
 (lldb) 
 */
