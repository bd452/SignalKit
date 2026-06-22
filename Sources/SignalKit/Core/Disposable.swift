import Foundation

@MainActor
public protocol Disposable: AnyObject {
    func dispose()
}

@MainActor
final class ClosureDisposable: Disposable {
    private var action: (() -> Void)?

    init(_ action: @escaping () -> Void) {
        self.action = action
    }

    func dispose() {
        action?()
        action = nil
    }
}

@MainActor
final class CompositeDisposable: Disposable {
    private var children: [any Disposable]?

    init(_ children: [any Disposable]) {
        self.children = children
    }

    func dispose() {
        let toDispose = children
        children = nil
        toDispose?.forEach { $0.dispose() }
    }
}
