import Foundation

#if DEBUG
enum LifecycleDebug {
    static func logDroppedCallback(owner: String) {
        print("[SignalKit] Dropped late callback for \(owner)")
    }

    static func logInvalidOperation(_ message: String) {
        print("[SignalKit] Invalid lifecycle operation: \(message)")
    }
}
#endif

@MainActor
final class LifecycleScope {
    private var isAlive = true
    private var disposables: [any Disposable] = []
    private var children: [Component] = []
    private var cleanupClosures: [() -> Void] = []

    @discardableResult
    func track(_ disposable: any Disposable) -> any Disposable {
        guard isAlive else {
            #if DEBUG
            LifecycleDebug.logInvalidOperation("track(disposable) on dead scope")
            #endif
            disposable.dispose()
            return disposable
        }
        disposables.append(disposable)
        return disposable
    }

    func trackChild(_ component: Component) {
        guard isAlive else {
            #if DEBUG
            LifecycleDebug.logInvalidOperation("trackChild on dead scope")
            #endif
            return
        }
        children.append(component)
    }

    func releaseChild(_ component: Component) {
        if let index = children.firstIndex(where: { $0 === component }) {
            children.remove(at: index)
        }
        component.unmount()
    }

    func onCleanup(_ closure: @escaping () -> Void) {
        guard isAlive else {
            #if DEBUG
            LifecycleDebug.logInvalidOperation("onCleanup on dead scope")
            #endif
            return
        }
        cleanupClosures.append(closure)
    }

    func guardAlive(owner: String, _ work: () -> Void) {
        guard isAlive else {
            #if DEBUG
            LifecycleDebug.logDroppedCallback(owner: owner)
            #endif
            return
        }
        work()
    }

    func dispose() {
        guard isAlive else { return }
        isAlive = false

        let toDispose = disposables
        disposables = []
        let toUnmountChildren = children
        children = []
        let toCleanup = cleanupClosures
        cleanupClosures = []

        toDispose.forEach { $0.dispose() }
        toUnmountChildren.forEach { $0.unmount() }
        toCleanup.forEach { $0() }
    }
}
