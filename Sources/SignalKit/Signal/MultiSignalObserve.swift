import Foundation

@MainActor
func observeMultiSignal<each Value>(
    _ signals: repeat Signal<each Value>,
    on delivery: ObserverDelivery,
    fireImmediately: Bool,
    wrapInvoke: (@escaping @MainActor () -> Void) -> @MainActor () -> Void,
    _ handler: @escaping (repeat each Value) -> Void
) -> any Disposable {
    final class Subscription {
        let handler: (repeat each Value) -> Void
        let signals: (repeat Signal<each Value>)

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
            wrapInvoke: (@escaping @MainActor () -> Void) -> @MainActor () -> Void
        ) -> any Disposable {
            let run = wrapInvoke { [self] in self.dispatch() }
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

    return Subscription(handler: handler, signals: repeat each signals)
        .subscribe(on: delivery, fireImmediately: fireImmediately, wrapInvoke: wrapInvoke)
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
    observeMultiSignal(
        repeat each signals,
        on: delivery,
        fireImmediately: fireImmediately,
        wrapInvoke: { $0 },
        handler
    )
}
