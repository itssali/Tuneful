//
//  AboutSettingsView.swift
//  Tuneful
//
//  Created by Martin Fekete on 12/01/2024.
//

import SwiftUI
import Settings
import Luminare

struct AboutSettingsView: View {
    var body: some View {
        Settings.Container(contentWidth: 400) {
            Settings.Section(title: "") {
                LuminareSection {
                    VStack(alignment: .center) {
                        Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                        VStack(alignment: .center) {
                            Text("Tuneful")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Text("Version \(Constants.AppInfo.appVersion ?? "?")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        HStack {
                            Link("❤️ Support", destination: URL(string: "https://ko-fi.com/martinfekete")!)
                                .buttonStyle(LuminareCompactButtonStyle())
                            Link("🧑‍💻 GitHub", destination: URL(string: "https://github.com/martinfekete10/Tuneful")!)
                                .buttonStyle(LuminareCompactButtonStyle())
                            Link("🌐 Website", destination: URL(string: "https://martinfekete.com/Tuneful")!)
                                .buttonStyle(LuminareCompactButtonStyle())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                }
            }
        }
    }
}

#Preview {
    AboutSettingsView()
}
