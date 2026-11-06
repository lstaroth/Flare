import SwiftUI
import UIKit

/// Covers native presentation setup with one fade, without intercepting image gestures.
@MainActor
final class MediaViewerPresentation {
    weak var window: UIWindow?
    private var snapshot: UIView?
    private var isRevealing = false

    func present(_ update: () -> Void) {
        cancel()
        if !UIAccessibility.isReduceMotionEnabled, let window,
           let snapshot = window.snapshotView(afterScreenUpdates: false) {
            snapshot.frame = window.bounds
            snapshot.isUserInteractionEnabled = false
            snapshot.accessibilityElementsHidden = true
            snapshot.layer.zPosition = 1
            window.addSubview(snapshot)
            self.snapshot = snapshot
        }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, update)
    }

    func reveal() {
        guard let snapshot, !isRevealing else { return }
        isRevealing = true
        UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
            snapshot.alpha = 0
        } completion: { [weak self] _ in
            snapshot.removeFromSuperview()
            if self?.snapshot === snapshot {
                self?.snapshot = nil
                self?.isRevealing = false
            }
        }
    }

    func cancel() {
        snapshot?.layer.removeAllAnimations()
        snapshot?.removeFromSuperview()
        snapshot = nil
        isRevealing = false
    }
}

extension EnvironmentValues {
    @Entry var mediaViewerPresentation: MediaViewerPresentation? = nil
}

/// `onAppear` precedes a modal presentation; wait for UIKit to finish installing it.
struct MediaViewerPresentationReady: UIViewControllerRepresentable {
    let onReady: (UIWindow?) -> Void

    func makeUIViewController(context: Context) -> Controller {
        let controller = Controller()
        controller.onReady = onReady
        controller.view.backgroundColor = .clear
        controller.view.isUserInteractionEnabled = false
        return controller
    }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.onReady = onReady
    }

    final class Controller: UIViewController {
        var onReady: ((UIWindow?) -> Void)?

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            onReady?(view.window)
        }
    }
}
