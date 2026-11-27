//
//  MMTToolForHUDWindowFinder.swift
//  MMTToolForHUD
//

import UIKit

/// Locates the window that should present the HUD / toast (iOS 13+ UIScene).
enum MMTToolForHUDWindowFinder {

    /// Returns the best window to present on: prefers the key window of an
    /// active foreground scene, then the highest-windowLevel visible window
    /// of any foreground scene.
    static func frontWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let ordered = scenes.filter { $0.activationState == .foregroundActive }
            + scenes.filter { $0.activationState == .foregroundInactive }

        for scene in ordered {
            let visible = scene.windows.filter { !$0.isHidden }
            if let key = visible.first(where: { $0.isKeyWindow }) {
                return key
            }
            if let highest = visible.max(by: { $0.windowLevel < $1.windowLevel }) {
                return highest
            }
        }
        return nil
    }
}
