import SQLiteData
import SwiftUI

#if canImport(UIKit)
import UIKit

typealias NativeColor = UIColor
#elseif canImport(AppKit)
import AppKit

typealias NativeColor = NSColor
#endif

public extension Color {
    struct HexRepresentation: QueryRepresentable {
        public var queryOutput: Color

        public init(queryOutput: Color) {
            self.queryOutput = queryOutput
        }

        public init(hexValue: Int64) {
            self.init(
                queryOutput: Color(
                    red: Double((hexValue >> 24) & 0xFF) / 255.0,
                    green: Double((hexValue >> 16) & 0xFF) / 255.0,
                    blue: Double((hexValue >> 8) & 0xFF) / 255.0,
                    opacity: Double(hexValue & 0xFF) / 255.0
                )
            )
        }

        public var hexValue: Int64? {
            #if canImport(UIKit)
            // --- UIKit (iOS, tvOS, watchOS) ---
            let uiColor = UIColor(queryOutput)
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }

            let ri = Int64(r * 255) << 24
            let gi = Int64(g * 255) << 16
            let bi = Int64(b * 255) << 8
            let ai = Int64(a * 255)

            return ri | gi | bi | ai

            #elseif canImport(AppKit)
            // --- AppKit (macOS) ---
            let nsColor = NSColor(queryOutput)
            guard let rgb = nsColor.usingColorSpace(.deviceRGB) else { return nil }

            let r = rgb.redComponent
            let g = rgb.greenComponent
            let b = rgb.blueComponent
            let a = rgb.alphaComponent

            let ri = Int64(r * 255) << 24
            let gi = Int64(g * 255) << 16
            let bi = Int64(b * 255) << 8
            let ai = Int64(a * 255)

            return ri | gi | bi | ai

            #else
            return nil
            #endif
        }
    }
}

// MARK: - QueryBindable

extension Color.HexRepresentation: QueryBindable {
    public init?(queryBinding: QueryBinding) {
        guard case .int(let hexValue) = queryBinding else { return nil }
        self.init(hexValue: hexValue)
    }

    public var queryBinding: QueryBinding {
        guard let hexValue else {
            struct InvalidColor: Error {}
            return .invalid(InvalidColor())
        }
        return .int(hexValue)
    }
}

// MARK: - QueryDecodable

extension Color.HexRepresentation: QueryDecodable {
    public init(decoder: inout some QueryDecoder) throws {
        try self.init(hexValue: Int64(decoder: &decoder))
    }
}

// MARK: - Convenience Hex -> Color

extension Color {
    static func fromHex(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0

        return Color(red: red, green: green, blue: blue)
    }
}
