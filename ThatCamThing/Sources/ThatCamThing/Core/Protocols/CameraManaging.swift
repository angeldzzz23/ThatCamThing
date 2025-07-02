//
//  CameraManaging.swift
//  ThatCamThing
//
//  Created by angel zambrano on 7/1/25.
//


protocol CameraManaging: ObservableObject {
    var isSessionRunning: Bool { get }
    var isPaused: Bool { get }
    var isShowingAlert: Bool { get }
    var alertMessage: String { get }

    func requestPermissions()
    func togglePause()
    func capturePhoto()
}
