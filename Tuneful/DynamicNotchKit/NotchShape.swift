//
//  NotchShape.swift
//  DynamicNotchKit
//
//  Created by Kai Azim on 2023-08-24.
//

import SwiftUI

struct NotchShape: Shape {
    var topCornerRadius: CGFloat {
        bottomCornerRadius - 5
    }

    var bottomCornerRadius: CGFloat

    init(cornerRadius: CGFloat? = nil) {
        if cornerRadius == nil {
            self.bottomCornerRadius = 11
        } else {
            self.bottomCornerRadius = cornerRadius!
        }
    }

    var animatableData: CGFloat {
        get { bottomCornerRadius }
        set { bottomCornerRadius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.addArc(center: CGPoint(x: rect.minX, y: topCornerRadius), radius: topCornerRadius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + topCornerRadius, y: rect.maxY - bottomCornerRadius))
        path.addArc(center: CGPoint(x: rect.minX + topCornerRadius + bottomCornerRadius, y: rect.maxY - bottomCornerRadius), radius: bottomCornerRadius, startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
        path.addLine(to: CGPoint(x: rect.maxX - topCornerRadius - bottomCornerRadius, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.maxX - topCornerRadius - bottomCornerRadius, y: rect.maxY - bottomCornerRadius), radius: bottomCornerRadius, startAngle: .degrees(90), endAngle: .degrees(0), clockwise: true)
        path.addLine(to: CGPoint(x: rect.maxX - topCornerRadius, y: rect.minY + bottomCornerRadius))

        path.addArc(center: CGPoint(x: rect.maxX, y: topCornerRadius), radius: topCornerRadius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))

        return path
    }
}

#Preview {
    NotchShape()
        .frame(width: 200, height: 32)
        .padding(10)
}
