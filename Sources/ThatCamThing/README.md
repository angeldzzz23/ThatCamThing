# ThatCamThing

Welcome to **ThatCamThing**! A lightweight, powerful, and easy-to-use camera library for SwiftUI. This package provides a simple way to integrate a custom camera interface into your iOS app, with built-in controls and extensive customization options.

## 📸 Features

- [x] **Simple SwiftUI Integration**: A `CameraView` that works seamlessly within your SwiftUI layouts.
- [x] **Customizable Overlays**: Replace the default camera UI with your own custom SwiftUI view.
- [x] **Custom Error Screens**: Provide a custom view to display when camera errors occur.
- [x] **Full Camera Control**: Programmatically manage flash, camera position (front/back), lens type (wide/ultra-wide), zoom, and frame rate.
- [x] **Image Capture**: A simple closure-based callback to receive captured `UIImage` objects.
- [x] **Default UI Included**: Comes with a sleek, modern, and ready-to-use `DefaultCameraOverlay`.

## 📋 Requirements

- iOS 15.0+
- Swift 5.5+
- Xcode 13.0+

## 📦 Installation

You can add **ThatCamThing** to your Xcode project using the Swift Package Manager.

1.  In Xcode, open your project and navigate to **File > Add Packages...**
2.  The Swift Package Manager dialog will appear.
3.  In the search bar, enter the repository URL: `https://github.com/your-username/CamaragePackageV2.git` (Please replace with your actual repository URL).
4.  Choose the version you want to use and click **Add Package**.
5.  Select the `ThatCamThing` library to be added to your app target.

## 🚀 How to Use

Integrating `ThatCamThing` is designed to be as simple as possible. Follow these steps to get a working camera view in your app.

### Step 1: Import the Library
First, import `ThatCamThing` in the SwiftUI view where you want to use the camera.