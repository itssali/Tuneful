//
//  StatusBarIcon.swift
//  Tuneful
//
//  Created by Martin Fekete on 06/01/2024.
//

import SwiftUI

enum StatusBarIcon: String, Equatable, CaseIterable {
    case albumArt = "Album Art"
    case appIcon = "App Icon"
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}