//
//  GoogleLogo.swift
//  split
//

import SwiftUI

struct GoogleLogo: View {
    var size: CGFloat = 24

    var body: some View {
        ZStack {
            // Yellow path
            Path { path in
                path.move(to: CGPoint(x: 43.611, y: 20.083))
                path.addLine(to: CGPoint(x: 42, y: 20.083))
                path.addLine(to: CGPoint(x: 42, y: 20))
                path.addLine(to: CGPoint(x: 24, y: 20))
                path.addLine(to: CGPoint(x: 24, y: 28))
                path.addLine(to: CGPoint(x: 35.303, y: 28))
                path.addCurve(to: CGPoint(x: 24, y: 36),
                             control1: CGPoint(x: 33.654, y: 32.657),
                             control2: CGPoint(x: 29.223, y: 36))
                path.addCurve(to: CGPoint(x: 12, y: 24),
                             control1: CGPoint(x: 17.373, y: 36),
                             control2: CGPoint(x: 12, y: 30.627))
                path.addCurve(to: CGPoint(x: 24, y: 12),
                             control1: CGPoint(x: 12, y: 17.373),
                             control2: CGPoint(x: 17.373, y: 12))
                path.addCurve(to: CGPoint(x: 31.961, y: 15.039),
                             control1: CGPoint(x: 27.059, y: 12),
                             control2: CGPoint(x: 29.842, y: 13.154))
                path.addLine(to: CGPoint(x: 37.618, y: 9.382))
                path.addCurve(to: CGPoint(x: 24, y: 4),
                             control1: CGPoint(x: 34.046, y: 6.053),
                             control2: CGPoint(x: 29.268, y: 4))
                path.addCurve(to: CGPoint(x: 4, y: 24),
                             control1: CGPoint(x: 12.955, y: 4),
                             control2: CGPoint(x: 4, y: 12.955))
                path.addCurve(to: CGPoint(x: 24, y: 44),
                             control1: CGPoint(x: 4, y: 35.045),
                             control2: CGPoint(x: 12.955, y: 44))
                path.addCurve(to: CGPoint(x: 44, y: 24),
                             control1: CGPoint(x: 35.045, y: 44),
                             control2: CGPoint(x: 44, y: 35.045))
                path.addCurve(to: CGPoint(x: 43.611, y: 20.083),
                             control1: CGPoint(x: 44, y: 22.659),
                             control2: CGPoint(x: 43.862, y: 21.35))
            }
            .fill(Color(red: 251/255, green: 192/255, blue: 45/255))

            // Red path
            Path { path in
                path.move(to: CGPoint(x: 6.306, y: 14.691))
                path.addLine(to: CGPoint(x: 12.877, y: 19.51))
                path.addCurve(to: CGPoint(x: 24, y: 12),
                             control1: CGPoint(x: 14.655, y: 15.108),
                             control2: CGPoint(x: 18.961, y: 12))
                path.addCurve(to: CGPoint(x: 31.961, y: 15.039),
                             control1: CGPoint(x: 27.059, y: 12),
                             control2: CGPoint(x: 29.842, y: 13.154))
                path.addLine(to: CGPoint(x: 37.618, y: 9.382))
                path.addCurve(to: CGPoint(x: 24, y: 4),
                             control1: CGPoint(x: 34.046, y: 6.053),
                             control2: CGPoint(x: 29.268, y: 4))
                path.addCurve(to: CGPoint(x: 6.306, y: 14.691),
                             control1: CGPoint(x: 16.318, y: 4),
                             control2: CGPoint(x: 9.656, y: 8.337))
            }
            .fill(Color(red: 229/255, green: 57/255, blue: 53/255))

            // Green path
            Path { path in
                path.move(to: CGPoint(x: 24, y: 44))
                path.addCurve(to: CGPoint(x: 37.409, y: 38.808),
                             control1: CGPoint(x: 29.166, y: 44),
                             control2: CGPoint(x: 33.86, y: 42.023))
                path.addLine(to: CGPoint(x: 31.219, y: 33.57))
                path.addCurve(to: CGPoint(x: 24, y: 36),
                             control1: CGPoint(x: 29.211, y: 35.091),
                             control2: CGPoint(x: 26.715, y: 36))
                path.addCurve(to: CGPoint(x: 12.717, y: 28.054),
                             control1: CGPoint(x: 18.798, y: 36),
                             control2: CGPoint(x: 14.381, y: 32.683))
                path.addLine(to: CGPoint(x: 6.195, y: 33.079))
                path.addCurve(to: CGPoint(x: 24, y: 44),
                             control1: CGPoint(x: 9.505, y: 39.556),
                             control2: CGPoint(x: 16.227, y: 44))
            }
            .fill(Color(red: 76/255, green: 175/255, blue: 80/255))

            // Blue path
            Path { path in
                path.move(to: CGPoint(x: 43.611, y: 20.083))
                path.addLine(to: CGPoint(x: 43.595, y: 20))
                path.addLine(to: CGPoint(x: 42, y: 20))
                path.addLine(to: CGPoint(x: 24, y: 20))
                path.addLine(to: CGPoint(x: 24, y: 28))
                path.addLine(to: CGPoint(x: 35.303, y: 28))
                path.addCurve(to: CGPoint(x: 31.216, y: 33.571),
                             control1: CGPoint(x: 34.511, y: 30.237),
                             control2: CGPoint(x: 33.072, y: 32.166))
                path.addLine(to: CGPoint(x: 31.219, y: 33.569))
                path.addLine(to: CGPoint(x: 37.409, y: 38.807))
                path.addCurve(to: CGPoint(x: 44, y: 24),
                             control1: CGPoint(x: 36.971, y: 39.205),
                             control2: CGPoint(x: 44, y: 34))
                path.addCurve(to: CGPoint(x: 43.611, y: 20.083),
                             control1: CGPoint(x: 44, y: 22.659),
                             control2: CGPoint(x: 43.862, y: 21.35))
            }
            .fill(Color(red: 21/255, green: 101/255, blue: 192/255))
        }
        .frame(width: 48, height: 48)
        .scaleEffect(size / 48)
        .frame(width: size, height: size)
        .clipped()
    }
}
