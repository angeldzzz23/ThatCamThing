//
//  ErrorScreenView.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//

import SwiftUI

public protocol ErrorScreenView: View {
    var error: Error { get }
    var onRetry: () -> Void { get }
    
    init(error: Error, onRetry: @escaping () -> Void)
}
