import Foundation

@MainActor
func subscribeToSignals<each Value>(
    _ signals: repeat Signal<each Value>,
    on delivery: ObserverDelivery,
    fireImmediately: Bool,
    invoke: @escaping @MainActor () -> Void
) -> any Disposable {
    if fireImmediately {
        invoke()
    }
    var disposables: [any Disposable] = []
    for signal in repeat each signals {
        let disposable = signal.observe(on: delivery) { _ in invoke() }
        disposables.append(disposable)
    }
    return CompositeDisposable(disposables)
}

/// Runs a side effect whenever any of the given signals changes, passing each signal's
/// current value to the handler.
///
/// The handler receives the latest value from every signal, not only the one that changed.
/// Returns a `Disposable` that unsubscribes from all signals.
@discardableResult
public func observe<each Value>(
    _ signals: repeat Signal<each Value>,
    on delivery: ObserverDelivery = .immediate,
    fireImmediately: Bool = true,
    _ handler: @escaping (repeat each Value) -> Void
) -> any Disposable {
    subscribeToSignals(
        repeat each signals,
        on: delivery,
        fireImmediately: fireImmediately
    ) {
        handler(repeat each (each signals).current)
    }
}
