#!/usr/bin/env swift
// Builds the macOS app icon PNGs from a square, full-bleed source image.
//
// macOS 26+ rounds icons itself, but macOS 14/15 show the PNG as-is, so the
// rounded shape, transparent margin and shadow must be drawn into the image.
// Follows Apple's macOS icon grid: on a 1024 canvas the icon is an 824×824
// rounded square (corner radius ~185) centered with a 100 px margin.
//
// Usage: swift scripts/make_app_icon.swift <source.png> <AppIcon.appiconset> [<more.appiconset> ...]

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write("usage: make_app_icon.swift <source.png> <appiconset>...\n".data(using: .utf8)!)
    exit(1)
}

let sourceURL = URL(fileURLWithPath: args[1])
guard let src = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let sourceImage = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
    FileHandle.standardError.write("cannot read \(sourceURL.path)\n".data(using: .utf8)!)
    exit(1)
}

func renderIcon(size: Int) -> CGImage {
    let s = CGFloat(size)
    let scale = s / 1024
    let ctx = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    ctx.interpolationQuality = .high

    let rect = CGRect(x: 100 * scale, y: 100 * scale, width: 824 * scale, height: 824 * scale)
    let path = CGPath(roundedRect: rect, cornerWidth: 185.4 * scale, cornerHeight: 185.4 * scale, transform: nil)

    // Soft drop shadow under the shape (skipped at tiny sizes, where it only blurs the edge).
    if size >= 64 {
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -10 * scale), blur: 20 * scale,
                      color: CGColor(gray: 0, alpha: 0.3))
        ctx.addPath(path)
        ctx.setFillColor(CGColor(gray: 0, alpha: 1))
        ctx.fillPath()
        ctx.restoreGState()
    }

    // Artwork clipped to the rounded square.
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    ctx.draw(sourceImage, in: rect)
    ctx.restoreGState()

    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) {
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fatalError("cannot write \(url.path)")
    }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("cannot write \(url.path)") }
}

let sizes = [16, 32, 64, 128, 256, 512, 1024]
for size in sizes {
    let image = renderIcon(size: size)
    for dir in args.dropFirst(2) {
        writePNG(image, to: URL(fileURLWithPath: dir).appendingPathComponent("\(size).png"))
    }
}
print("Wrote \(sizes.count) icons to \(args.count - 2) icon set(s).")
