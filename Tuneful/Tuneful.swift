//
//  TunefulApp.swift
//  Tuneful
//
//  Created by Martin Fekete on 27/07/2023.
//

import os
import SwiftUI
import KeyboardShortcuts
import Settings
import Luminare
import Combine
import Defaults

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    // Windows
    private var onboardingWindow: OnboardingWindow!
    private var miniPlayerWindow: MiniPlayerWindow!
    
    // Popover
    private var popover: NSPopover!
    static let popoverWidth: CGFloat = 210
    
    // Status bar
    private var statusBarItem: NSStatusItem!
    public var statusBarMenu: NSMenu!
    
    // Managers
    private var playerManager: PlayerManager!
    private var statusBarItemManager: StatusBarItemManager!
    private var statusBarPlaybackManager: StatusBarPlaybackManager!
    
    // MARK: Settings
    
    private var settingsWindow = LuminareTrafficLightedWindow<SettingsView>(view: { SettingsView() })
    
    let GeneralSettingsViewController: () -> SettingsPane = {
        let paneView = Settings.Pane(
            identifier: .general,
            title: "General",
            toolbarIcon: NSImage(systemSymbolName: "switch.2", accessibilityDescription: "General settings")!
        ) {
            GeneralSettingsView()
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    
    let MenuBarSettingsViewController: () -> SettingsPane = {
        let paneView = Settings.Pane(
            identifier: .menuBar,
            title: "Menu bar",
            toolbarIcon: NSImage(systemSymbolName: "menubar.rectangle", accessibilityDescription: "Menu bar settings")!
        ) {
            MenuBarSettingsView()
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    
    let AppearanceSettingsViewController: () -> SettingsPane = {
        let paneView = Settings.Pane(
            identifier: .appearance,
            title: "Appearance",
            toolbarIcon: NSImage(systemSymbolName: "paintbrush", accessibilityDescription: "Appearance settings")!
        ) {
            AppearanceSettingsView()
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    
    let NotchSettingsViewController: () -> SettingsPane = {
        let paneView = Settings.Pane(
            identifier: .notch,
            title: "Notch",
            toolbarIcon: NSImage(systemSymbolName: "button.roundedbottom.horizontal", accessibilityDescription: "Notch settings")!
        ) {
            NotchSettingsView()
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    
    let KeyboardShortcutsSettingsViewController: () -> SettingsPane = {
        let paneView = Settings.Pane(
            identifier: .keyboard,
            title: "Keyboard",
            toolbarIcon: NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Keyboard shortcuts settings")!
        ) {
            KeyboardShortcutsSettingsView()
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    
    let AboutSettingsViewController: () -> SettingsPane = {
        let paneView = Settings.Pane(
            identifier: .about,
            title: "About",
            toolbarIcon: NSImage(systemSymbolName: "info.circle", accessibilityDescription: "About settings")!
        ) {
            AboutSettingsView()
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
//        if let bundleID = Bundle.main.bundleIdentifier {
//            UserDefaults.standard.removePersistentDomain(forName: bundleID)
//        }
        
        self.settingsWindow.isReleasedWhenClosed = false
        self.playerManager = PlayerManager()
        self.statusBarItemManager = StatusBarItemManager(playerManager: playerManager)
        self.statusBarPlaybackManager = StatusBarPlaybackManager(playerManager: playerManager)
        self.miniPlayerWindow = MiniPlayerWindow(playerManager: playerManager)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.updateStatusBarItem),
            name: NSNotification.Name("UpdateMenuBarItem"),
            object: nil
        )
        
        if !Defaults[.viewedOnboarding] {
            self.showOnboarding()
        } else {
            self.mainSetup()
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }
    
    private func mainSetup() {
        self.setupPopover()
        self.setupMiniPlayer()
        self.setupMenuBar()
        self.updateStatusBarItem(nil)
        self.setupKeyboardShortcuts()
        self.setupNotch()
    }
    
    // MARK: Music player
    
    private func changeMusicPlayer() {
        if !ConnectedApps.spotify.selectable {
            return
        }
        
        // TODO: System player
        switch Defaults[.connectedApp] {
        case .spotify:
            Defaults[.connectedApp] = .appleMusic
        case .appleMusic:
            Defaults[.connectedApp] = .spotify
        }
    }
    
    // MARK: Keyboard shortcuts
    
    private func setupKeyboardShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .playPause) {
            self.playerManager.togglePlayPause()
        }
        
        KeyboardShortcuts.onKeyUp(for: .nextTrack) {
            self.playerManager.nextTrack()
        }
        
        KeyboardShortcuts.onKeyUp(for: .previousTrack) {
            self.playerManager.previousTrack()
        }
        
        KeyboardShortcuts.onKeyUp(for: .showMiniPlayer) {
            self.toggleMiniPlayer()
        }
        
        KeyboardShortcuts.onKeyUp(for: .changeMusicPlayer) {
            self.changeMusicPlayer()
        }
        
        KeyboardShortcuts.onKeyUp(for: .toggleMenuBarItemVisibility) {
            self.toggleMenuBarItemVisibilityFromShortcut()
        }
        
        KeyboardShortcuts.onKeyUp(for: .togglePopover) {
            self.handlePopover(self.statusBarItem.button)
        }
        KeyboardShortcuts.onKeyUp(for: .openSettings) {
            self.openSettings(self)
        }
        KeyboardShortcuts.onKeyUp(for: .likeSong) {
            self.playerManager.toggleLoveTrack()
        }
    }
    
    // MARK: Menu bar
    
    private func setupMenuBar() {
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        statusBarMenu = NSMenu()
        statusBarMenu.delegate = self
        
        statusBarMenu.addItem(
            withTitle: "♡ Support",
            action: #selector(support),
            keyEquivalent: ""
        )
        
        statusBarMenu.addItem(
            withTitle: "Show mini player",
            action: #selector(showHideMiniPlayer),
            keyEquivalent: ""
        )
        .state = Defaults[.showPlayerWindow] ? .on : .off
        
        statusBarMenu.addItem(.separator())
        
        statusBarMenu.addItem(
            withTitle: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ""
        )
        
        statusBarMenu.addItem(.separator())
        
        statusBarMenu.addItem(
            withTitle: "Quit",
            action: #selector(NSApplication.terminate),
            keyEquivalent: ""
        )
        
        if let statusBarItemButton = statusBarItem.button {
            statusBarItemButton.action = #selector(didClickStatusBarItem)
            statusBarItemButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc func didClickStatusBarItem(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent else { return }
        
        switch event.type {
        case .rightMouseUp:
            statusBarItem.menu = statusBarMenu
            statusBarItem.button?.performClick(nil)
        default:
            handlePopover(statusBarItem.button)
        }
    }
    
    @objc func toggleMiniPlayer() {
        showHideMiniPlayer(statusBarMenu.item(withTitle: "Show mini player")!)
    }
    
    @IBAction func showHideMiniPlayer(_ sender: NSMenuItem) {
        if sender.state == .on {
            sender.state = .off
            shouldShowMiniPlayer(show: false)
        } else {
            sender.state = .on
            shouldShowMiniPlayer(show: true)
        }
    }
    
    private func shouldShowMiniPlayer(show: Bool) {
        if !show {
            Defaults[.showPlayerWindow] = false
            playerManager.timerStopSignal.send()
            miniPlayerWindow.close()
        } else {
            Defaults[.showPlayerWindow] = true
            playerManager.timerStartSignal.send()
            miniPlayerWindow.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
    
    @IBAction func openURL(_ sender: AnyObject) {
        let url = URL(string: "https://github.com/martinfekete10/Tuneful")
        NSWorkspace.shared.open(url!)
    }
    
    @IBAction func support(_ sender: AnyObject) {
        let url = URL(string: "https://ko-fi.com/martinfekete")
        NSWorkspace.shared.open(url!)
    }
    
    func menuDidClose(_: NSMenu) {
        statusBarItem.menu = nil
    }
    
    // MARK: Status bar item title
    
    @objc func updateStatusBarItem(_ notification: NSNotification?) {
        guard Defaults[.viewedOnboarding] else { return }
        
        var playerAppIsRunning = playerManager.isRunning
        if notification?.userInfo?["PlayerAppIsRunning"] != nil {
            playerAppIsRunning = notification?.userInfo?["PlayerAppIsRunning"] as? Bool == true
        }
        
        let menuBarView = self.statusBarItemManager.getMenuBarView(
            track: playerManager.track,
            playerAppIsRunning: playerAppIsRunning,
            isPlaying: playerManager.isPlaying
        )
        
        if let button = self.statusBarItem.button {
            button.subviews.forEach { $0.removeFromSuperview() }
            button.addSubview(menuBarView)
            button.frame = menuBarView.frame
        }
        
        self.toggleMenuBarItemVisibility()
        self.statusBarPlaybackManager.updateStatusBarPlaybackItem(playerAppIsRunning: playerAppIsRunning)
        self.statusBarPlaybackManager.toggleStatusBarVisibility()
    }
    
    @objc func toggleMenuBarItemVisibility() {
        if Defaults[.hideMenuBarItemWhenNotPlaying] && (!playerManager.isRunning || !playerManager.isPlaying) {
            self.statusBarItem.isVisible = false
        } else {
            self.statusBarItem.isVisible = true
        }
    }
    
    @objc func toggleMenuBarItemVisibilityFromShortcut() {
        self.statusBarItem.isVisible = !self.statusBarItem.isVisible
    }
    
    @objc func menuBarPlaybackControls() {
        self.statusBarPlaybackManager.toggleStatusBarVisibility()
    }
    
    
    // MARK: Popover
        
    @objc func setupPopover() {
        let frameSize: NSSize
        let rootView: AnyView
        let popoverWidth = 210
        let popoverHeigth = 310
        
        switch Defaults[.popoverType] {
        case .full:
            frameSize = NSSize(width: popoverWidth, height: popoverHeigth)
            rootView = AnyView(PopoverView().environmentObject(self.playerManager))
        case .minimal:
            frameSize = NSSize(width: popoverWidth, height: popoverHeigth)
            rootView = AnyView(CompactPopoverView().environmentObject(self.playerManager))
        }
        
        let hostedContentView = NSHostingView(rootView: rootView)
        hostedContentView.frame = NSRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
        
        popover = NSPopover()
        popover.contentSize = frameSize
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = hostedContentView
        popover.contentViewController?.view.window?.makeKey()
        
        playerManager.popoverIsShown = popover.isShown
    }
    
    @objc func handlePopover(_ sender: NSStatusBarButton?) {
        if Defaults[.popoverIsEnabled] {
            self.togglePopover(sender)
        } else {
            self.playerManager.openMusicApp()
        }
    }
    
    @objc func togglePopover(_ sender: NSStatusBarButton?) {
        guard let statusBarItemButton = sender else { return }

        if popover.isShown {
            popover.close()
        } else {
            popover.show(relativeTo: statusBarItemButton.bounds, of: statusBarItemButton, preferredEdge: .minY)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
    
    // MARK: Mini player
    
    @objc func setupMiniPlayer() {
        let rootView = MiniPlayerView().environmentObject(playerManager)
        miniPlayerWindow.contentView = NSHostingView(rootView: rootView)
        
        // This is ugly but we can't correctly set the frame as window is not fully loaded
        // Running this one sec later should ensure we have the window fully loaded -> correctly placed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let position = NSPoint.fromString(Defaults[.windowPosition]) ?? NSPoint(x: 10, y: 10)
            self.miniPlayerWindow.setFrameOrigin(position)
            self.miniPlayerWindow.contentView?.layer?.cornerRadius = 12.5
            self.miniPlayerWindow.contentView?.layer?.masksToBounds = true
            self.shouldShowMiniPlayer(show: Defaults[.showPlayerWindow])
        }
    }
    
    @objc func toggleMiniPlayerWindowLevel() {
        if Defaults[.miniPlayerWindowOnTop] {
            self.miniPlayerWindow.level = .floating
        } else {
            self.miniPlayerWindow.level = .normal
        }
    }

    // MARK: New settings
    
    @objc func openNewSettings() {
        settingsWindow.orderFrontRegardless()
        settingsWindow.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    // MARK: Settings
    
    @objc func openSettings(_ sender: AnyObject) {
        SettingsWindowController(
            panes: [
                GeneralSettingsViewController(),
                AppearanceSettingsViewController(),
                MenuBarSettingsViewController(),
                NotchSettingsViewController(),
                KeyboardShortcutsSettingsViewController(),
                AboutSettingsViewController()
            ],
            style: .toolbarItems,
            animated: true,
            hidesToolbarForSingleItem: true
        ).show()
    }
    
    // MARK: Setup
    
    public func showOnboarding() {
        if onboardingWindow == nil {
            onboardingWindow = OnboardingWindow()
            let rootView = OnboardingView().cornerRadius(12.5)
            let hostedOnboardingView = NSHostingView(rootView: rootView)
            onboardingWindow.contentView = hostedOnboardingView
        }
        
        onboardingWindow.center()
        onboardingWindow.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    @objc func finishOnboarding(_ sender: AnyObject) {
        onboardingWindow.close()
        self.mainSetup()
    }
    
    // MARK: Notch
    
    private func setupNotch() {
        let notchEnabled = Defaults[.notchEnabled]
        if !notchEnabled {
            hideNotch()
        }
    }
    
    @objc func showNotch() {
        playerManager.initializeNotch()
    }
    
    @objc func hideNotch() {
        playerManager.deinitializeNotch()
    }
}

@main
struct Tuneful: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
        }
    }
}
