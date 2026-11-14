#!/usr/bin/env swift
// Renders assets/icon/icon.svg to icon.png (full bleed) and icon-mac.png (macOS rounded-rect grid).
// Usage: swift scripts/build-icons.swift [path/to/icon.svg]
import AppKit

let svgPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "assets/icon/icon.svg"
let outDir = URL(fileURLWithPath: svgPath).deletingLastPathComponent()
guard let svg = NSImage(contentsOfFile: svgPath) else { fatalError("Cannot load \(svgPath)") }

let size = 1024
func render(_ name: String, draw: (NSRect) -> Void) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw(NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()
    let url = outDir.appendingPathComponent(name)
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
    print("wrote \(url.path)")
}

render("icon.png") { svg.draw(in: $0) }

// Apple macOS icon template: 824pt body centered on a 1024 canvas, corner radius ~185.
render("icon-mac.png") { canvas in
    let body = canvas.insetBy(dx: 100, dy: 100)
    NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185).addClip()
    svg.draw(in: body)
}
