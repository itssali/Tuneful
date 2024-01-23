//
//  SettingsView.swift
//  Tuneful
//
//  Created by Martin Fekete on 06/01/2024.
//

import SwiftUI
import Settings

struct MenuBarAppearanceSettingsView: View {
    
    @AppStorage("showSongInfo") var showSongInfoAppStorage: Bool = true
    @AppStorage("showMenuBarIcon") var showMenuBarIconAppStorage: Bool = true
    @AppStorage("trackInfoLength") var trackInfoLengthAppStorage: Double = 20.0
    @AppStorage("statusBarIcon") var statusBarIconAppStorage: StatusBarIcon = .albumArt
    @AppStorage("trackInfoDetails") var trackInfoDetailsAppStorage: StatusBarTrackDetails = .artistAndSong
    @AppStorage("popoverBackground") var popoverBackgroundAppStorage: BackgroundType = .transparent
    
    // A bit of a hack, binded AppStorage variable doesn't refresh UI, first we read the app storage this way
    // and @AppStorage variable  is updated whenever the state changes using .onChange()
    @State var showSongInfo: Bool
    @State var showMenuBarIcon: Bool
    @State var trackInfoLength: Double
    @State var statusBarIcon: StatusBarIcon
    @State var trackInfoDetails: StatusBarTrackDetails
    @State var popoverBackground: BackgroundType
    
    init() {
        @AppStorage("showSongInfo") var showSongInfoAppStorage: Bool = true
        @AppStorage("showMenuBarIcon") var showMenuBarIconAppStorage: Bool = true
        @AppStorage("trackInfoLength") var trackInfoLengthAppStorage: Double = 20.0
        @AppStorage("statusBarIcon") var statusBarIconAppStorage: StatusBarIcon = .albumArt
        @AppStorage("trackInfoDetails") var trackInfoDetailsAppStorage: StatusBarTrackDetails = .artistAndSong
        @AppStorage("popoverBackground") var popoverBackgroundAppStorage: BackgroundType = .transparent
        
        self.showSongInfo = showSongInfoAppStorage
        self.showMenuBarIcon = showMenuBarIconAppStorage
        self.trackInfoLength = trackInfoLengthAppStorage
        self.statusBarIcon = statusBarIconAppStorage
        self.trackInfoDetails = trackInfoDetailsAppStorage
        self.popoverBackground = popoverBackgroundAppStorage
    }

    var body: some View {
        VStack {
            Settings.Container(contentWidth: 400) {
                
                Settings.Section(label: {
                    Text("Menu bar icon")
                        .foregroundStyle(!showMenuBarIcon ? .tertiary : .primary)
                }) {
                    Picker("", selection: $statusBarIcon) {
                        ForEach(StatusBarIcon.allCases, id: \.self) { value in
                            Text(value.localizedName).tag(value)
                        }
                    }
                    .onChange(of: statusBarIcon) { _ in
                        self.statusBarIconAppStorage = statusBarIcon
                        self.sendTrackChangedNotification()
                    }
                    .pickerStyle(.segmented)
                    .disabled(!showMenuBarIcon)
                    .frame(width: 200)
                }
                
                Settings.Section(label: {
                    Text("Popover background")
                }) {
                    Picker("", selection: $popoverBackground) {
                        ForEach(BackgroundType.allCases, id: \.self) { value in
                            Text(value.localizedName).tag(value)
                        }
                    }
                    .onChange(of: popoverBackground) { newValue in
                        self.popoverBackgroundAppStorage = popoverBackground
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                
                Settings.Section(title: "Show song info in menu bar") {
                    Toggle(isOn: $showSongInfo) {
                        Text("")
                    }
                    .onChange(of: showSongInfo) { show in
                        self.showSongInfoAppStorage = showSongInfo
                        self.sendTrackChangedNotification()
                        
                        if !show {
                            self.showMenuBarIcon = true
                        }
                    }
                    .toggleStyle(.switch)
                }
                
                Settings.Section(label: {
                    Text("Show icon in menu bar")
                        .foregroundStyle(!showSongInfo ? .tertiary : .primary)
                }) {
                    Toggle(isOn: $showMenuBarIcon) {
                        Text("")
                    }
                    .onChange(of: showMenuBarIcon) { _ in
                        self.showMenuBarIconAppStorage = showMenuBarIcon
                        self.sendTrackChangedNotification()
                    }
                    .toggleStyle(.switch)
                    .disabled(!showSongInfo)
                }
                
                Settings.Section(label: {
                    Text("Song info details")
                        .foregroundStyle(!showSongInfo ? .tertiary : .primary)
                }) {
                    Picker("", selection: $trackInfoDetails) {
                        ForEach(StatusBarTrackDetails.allCases, id: \.self) { value in
                            Text(value.localizedName).tag(value)
                        }
                    }
                    .onChange(of: trackInfoDetails) { newValue in
                        self.trackInfoDetailsAppStorage = trackInfoDetails
                        self.sendTrackChangedNotification()
                    }
                    .pickerStyle(.menu)
                    .frame(width: 200)
                    .disabled(!showSongInfo)
                }
                
                Settings.Section(label: {
                    Text("Song info max length")
                        .foregroundStyle(!showSongInfo ? .tertiary : .primary)
                }) {
                    VStack(alignment: .center) {
                        Slider(value: $trackInfoLength, in: 10...50, step: 5) {
                            Text("")
                        } minimumValueLabel: {
                            Text("10")
                        } maximumValueLabel: {
                            Text("50")
                        }
                        .onChange(of: trackInfoLength) { newValue in
                            self.trackInfoLengthAppStorage = trackInfoLength
                            self.sendTrackChangedNotification()
                            NSHapticFeedbackManager.defaultPerformer.perform(NSHapticFeedbackManager.FeedbackPattern.levelChange, performanceTime: .now)
                        }
                        .frame(width: 200)
                        .disabled(!showSongInfo)
                        
                        Text("Number of characters: \(Int(trackInfoLength))")
                            .foregroundStyle(!showSongInfo ? .tertiary : .secondary)
                            .font(.callout)
                    }
                }
            }
        }
    }
    
    private func sendTrackChangedNotification() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateMenuBarItem"), object: nil, userInfo: [:])
    }
}

struct MenuBarAppearanceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarAppearanceSettingsView()
            .previewLayout(.device)
            .padding()
    }
}