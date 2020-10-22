//
//  TouchBarController.swift
//  PodcastMenu
//
//  Created by Guilherme Rambo on 12/11/16.
//  Copyright © 2016 Guilherme Rambo. All rights reserved.
//

import Cocoa
import WebKit

class TouchBarController: NSObject {

    let webView: WKWebView
    
    init(webView: WKWebView) {
        self.webView = webView
        
        super.init()
        
        self.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack), options: [.initial, .new], context: nil)
        self.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoForward), options: [.initial, .new], context: nil)
    }
    
    @available(OSX 10.12.2, *)
    lazy var scrubberController = TouchBarScrubberViewController()
    
    var currentEpisodeTitle: String? = nil {
        didSet {
            if #available(OSX 10.12.2, *) {
                scrubberController.currentEpisodeTitle = currentEpisodeTitle
            }
        }
    }
    
    var episodes: [Episode] = [] {
        didSet {
            if #available(OSX 10.12.2, *) {
                scrubberController.episodes = episodes
            }
        }
    }
    
    var podcasts: [Podcast] = [] {
        didSet {
            if #available(OSX 10.12.2, *) {
                scrubberController.podcasts = podcasts
            }
        }
    }
    
    var playbackInfo: PlaybackInfo? {
        didSet {
            if #available(OSX 10.12.2, *) {
                miniPlayer.updateUI(oldInfo: oldValue, newInfo: playbackInfo)
            }
        }
    }
    
    @available(OSX 10.12.2, *)
    lazy var backButton: NSButton = {
        return NSButton(title: "", image: NSImage(named: NSImage.touchBarGoBackTemplateName)!, target: nil, action: #selector(WKWebView.goBack(_:)))
    }()
    
    @available(OSX 10.12.2, *)
    lazy var forwardButton: NSButton = {
        return NSButton(title: "", image: NSImage(named: NSImage.touchBarGoForwardTemplateName)!, target: nil, action: #selector(WKWebView.goForward(_:)))
    }()
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.canGoBack) {
            if #available(OSX 10.12.2, *) {
                backButton.isEnabled = webView.canGoBack;
            }
        } else if keyPath == #keyPath(WKWebView.canGoForward) {
            if #available(OSX 10.12.2, *) {
                forwardButton.isEnabled = webView.canGoForward;
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    @available(OSX 10.12.2, *)
    fileprivate lazy var nowPlayingTouchBar: NSTouchBar = {
        let bar = NSTouchBar()
        
        bar.delegate = self
        
        bar.customizationAllowedItemIdentifiers = [
            .backButton,
            .forwardButton,
        ]

        bar.defaultItemIdentifiers = [.miniPlayer, .scrubber, .otherItemsProxy]
        
        return bar
    }()
    
    @available(OSX 10.12.2, *)
    func installControlStripNowPlayingItem() {
        let nowPlayingItem = NSCustomTouchBarItem(identifier: .nowPlayingControlStrip)
        nowPlayingItem.view = NSButton(image: #imageLiteral(resourceName: "controlStripIcon"), target: self, action: #selector(nowPlayingItemActivated))
        NSTouchBarItem.addSystemTrayItem(nowPlayingItem)
        
        DFRElementSetControlStripPresenceForIdentifier(NSTouchBarItem.Identifier.nowPlayingControlStrip.rawValue, true);
    }
    
    @available(OSX 10.12.2, *)
    @objc private func nowPlayingItemActivated(_ sender: Any) {
        showTouchBar()
    }
    
    @available(OSX 10.12.2, *)
    func showTouchBar() {
        NSTouchBar.presentSystemModalFunctionBar(nowPlayingTouchBar, placement: 0, systemTrayItemIdentifier: "otherTouchBar")
    }
    
    @available(OSX 10.12.2, *)
    func hideTouchBar() {
        NSTouchBar.dismissSystemModalFunctionBar(nowPlayingTouchBar)
    }
    
    @available(OSX 10.12.2, *)
    fileprivate lazy var miniPlayer: TouchBarMiniPlayer = {
        return TouchBarMiniPlayer.instantiate()
    }()
    
    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.canGoForward))
    }
    
}

@available(OSX 10.12.2, *)
extension NSTouchBarItem.Identifier {
    static let backButton = NSTouchBarItem.Identifier("br.com.guilhermerambo.podcastmenu.back")
    static let forwardButton = NSTouchBarItem.Identifier("br.com.guilhermerambo.podcastmenu.forward")
    static let scrubber = NSTouchBarItem.Identifier("br.com.guilhermerambo.podcastmenu.scrubber")
    static let nowPlayingControlStrip = NSTouchBarItem.Identifier("br.com.guilhermerambo.podcastmenu.nowPlaying")
    static let miniPlayer = NSTouchBarItem.Identifier("br.com.guilhermerambo.podcastmenu.miniPlayer")
}

@available(OSX 10.12.2, *)
extension TouchBarController: NSTouchBarDelegate {
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItem.Identifier.backButton:
            let item = NSCustomTouchBarItem(identifier: .backButton)
            item.view = backButton
            return item
        case NSTouchBarItem.Identifier.forwardButton:
            let item = NSCustomTouchBarItem(identifier: .forwardButton)
            item.view = forwardButton
            return item
        case NSTouchBarItem.Identifier.scrubber:
            let item = NSCustomTouchBarItem(identifier: .scrubber)
            item.viewController = scrubberController
            return item
        case .miniPlayer:
            return miniPlayer.touchBarItem
        default: return nil
        }
    }
    
}
