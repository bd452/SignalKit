import Foundation

@MainActor
final class MultiSignalSubscription<each Value> {
    private let handler: (repeat each Value) -> Void
    private let signals: (repeat Signal<each Value>)

    init(
        handler: @escaping (repeat each Value) -> Void,
        signals: repeat Signal<each Value>
    ) {
        self.handler = handler
        self.signals = (repeat each signals)
    }

    func dispatch() {
        handler(repeat each (each signals).current)
    }

    func subscribe(
        on delivery: ObserverDelivery,
        fireImmediately: Bool,
        invoke: (@escaping @MainActor () -> Void) -> @MainActor () -> Void = { $0 }
    ) -> any Disposable {
        let run = invoke { [self] in self.dispatch() }
        if fireImmediately {
            run()
        }
        var disposables: [any Disposable] = []
        for signal in repeat each signals {
            let disposable = signal.observe(on: delivery) { _ in run() }
            disposables.append(disposable)
        }
        return CompositeDisposable(disposables)
    }
}

/// Runs a side effect whenever any of the given signals changes, passing each signal's
/// current value to the handler.
///
/// The handler receives the latest value from every signal, not only the one that changed.
/// Returns a `Disposable` that unsubscribes from all signals.
@MainActor
@discardableResult
public func observe<each Value>(
    _ signals: repeat Signal<each Value>,
    on delivery: ObserverDelivery = .immediate,
    fireImmediately: Bool = true,
    _ handler: @escaping (repeat each Value) -> Void
) -> any Disposable {
    MultiSignalSubscription(handler: handler, signals: repeat each signals)
        .subscribe(on: delivery, fireImmediately: fireImmediately)
}
