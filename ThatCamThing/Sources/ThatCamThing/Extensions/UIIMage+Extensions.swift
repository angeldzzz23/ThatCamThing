//
//  UIIMage+Extensions.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//


import SwiftUI

// MARK: - UI Extensions

public extension UIImage {
    func mirrored() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            context.cgContext.translateBy(x: size.width, y: 0)
            context.cgContext.scaleBy(x: -1, y: 1)
            draw(at: .zero)
        }
    }
}
