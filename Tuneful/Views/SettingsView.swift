//
//  SettingsView.swift
//  Tuneful
//
//  Created by Martin Fekete on 06/01/2024.
//

import SwiftUI
import LaunchAtLogin
import Settings

struct GeneralSettingsView: View {
    
    @AppStorage("connectedApp") private var connectedApp = ConnectedApps.spotify
    @AppStorage("showPlayerWindow") var showPlayerWindowAppStorage: Bool = false
    
    @State private var alertTitle = Text("Title")
    @State private var alertMessage = Text("Message")
    @State private var showingAlert = false
    
    @State var showshowPlayerWindow: Bool = UserDefaults.standard.bool(forKey: "showPlayerWindow")

    private var name: Text {
        Text(connectedApp.localizedName)
    }
    
    var body: some View {
        Settings.Container(contentWidth: 400) {
            Settings.Section(title: "") {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        
                        LaunchAtLogin
                            .Toggle()
                            .toggleStyle(.switch)
                        
                        HStack {
                            Picker("Connect Tuneful to", selection: $connectedApp) {
                                ForEach(ConnectedApps.allCases, id: \.self) { value in
                                    Text(value.localizedName).tag(value)
                                }
                            }
                            .pickerStyle(.segmented)
                            Button {
                                let consent = Helper.promptUserForConsent(for: connectedApp == .spotify ? Constants.Spotify.bundleID : Constants.AppleMusic.bundleID)
                                switch consent {
                                case .closed:
                                    alertTitle = Text("\(name) is not open")
                                    alertMessage = Text("Please open \(name) to enable permissions")
                                case .granted:
                                    alertTitle = Text("Permission granted for \(name)")
                                    alertMessage = Text("Start playing a song!")
                                case .notPrompted:
                                    return
                                case .denied:
                                    alertTitle = Text("Permission denied")
                                    alertMessage = Text("Please go to System Settings > Privacy & Security > Automation, and check \(name) under Tuneful")
                                }
                                showingAlert = true
                            } label: {
                                Image(systemName: "person.fill.questionmark")
                            }
                            .buttonStyle(.borderless)
                            .alert(isPresented: $showingAlert) {
                                Alert(title: alertTitle, message: alertMessage, dismissButton: .default(Text("Got it!")))
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct AppearanceSettingsView: View {
    
    @AppStorage("showSongInfo") var showSongInfoAppStorage: Bool = true
    @AppStorage("showMenuBarIcon") var showMenuBarIconAppStorage: Bool = false
    @AppStorage("trackInfoLength") var trackInfoLengthAppStorage: Double = 20.0
    @AppStorage("statusBarIcon") var statusBarIconAppStorage: StatusBarIcon = .appIcon
    @AppStorage("trackInfoDetails") var trackInfoDetailsAppStorage: StatusBarTrackDetails = .artistAndSong
    
    // A bit of a hack, binded AppStorage variable doesn't refresh UI, first we read the app storage this way
    // and @AppStorage variable  is updated whenever the state changes using .onChange()
    @State var showSongInfo: Bool = UserDefaults.standard.bool(forKey: "showSongInfo")
    @State var showMenuBarIcon: Bool = UserDefaults.standard.bool(forKey: "showMenuBarIcon")
    @State var trackInfoLength: Double = UserDefaults.standard.double(forKey: "trackInfoLength")
    @State var statusBarIcon: StatusBarIcon = StatusBarIcon(rawValue: UserDefaults.standard.string(forKey: "statusBarIcon")!)!
    @State var trackInfoDetails: StatusBarTrackDetails = StatusBarTrackDetails(rawValue: UserDefaults.standard.string(forKey: "trackInfoDetails")!)!
    
    var body: some View {
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
                .pickerStyle(.menu)
                .disabled(!showMenuBarIcon)
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
    
    private func sendTrackChangedNotification() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateMenuBarItem"), object: nil, userInfo: [:])
    }
}

struct AboutSettingsView: View {
    var body: some View {
        Settings.Container(contentWidth: 400) {
            Settings.Section(title: "", verticalAlignment: .center) {
                VStack(alignment: .center) {
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    VStack(alignment: .leading) {
                        Text("Tuneful")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("Version \(Constants.AppInfo.appVersion ?? "?")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    Divider()
                    HStack {
                        Link("GitHub", destination: URL(string: "https://github.com/martinfekete10/Tuneful")!)
                            .buttonStyle(.bordered)
                        Link("Donate", destination: URL(string: "https://ko-fi.com/martinfekete")!)
                            .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

struct AboutSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AboutSettingsView()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}