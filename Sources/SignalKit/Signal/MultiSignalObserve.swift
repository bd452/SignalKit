import Foundation

/// Runs a side effect whenever any of the given signals changes, passing each signal's
/// current value to the handler.
///
/// The handler receives the latest value from every signal, not only the one that changed.
/// Returns a `Disposable` that unsubscribes from all signals.
@discardableResult
public func observe<A, B>(
    _ a: Signal<A>,
    _ b: Signal<B>,
    on delivery: ObserverDelivery = .immediate,
    fireImmediately: Bool = true,
    _ handler: @escaping (A, B) -> Void
) -> any Disposable {
    let invoke: @MainActor () -> Void = {
        handler(a.current, b.current)
    }
    if fireImmediately {
        invoke()
    }
    let da = a.observe(on: delivery) { _ in invoke() }
    let db = b.observe(on: delivery) { _ in invoke() }
    return CompositeDisposable([da, db])
}

/// Runs a side effect whenever any of the given signals changes, passing each signal's
/// current value to the handler.
@discardableResult
public func observe<A, B, C>(
    _ a: Signal<A>,
    _ b: Signal<B>,
    _ c: Signal<C>,
    on delivery: ObserverDelivery = .immediate,
    fireImmediately: Bool = true,
    _ handler: @escaping (A, B, C) -> Void
) -> any Disposable {
    let invoke: @MainActor () -> Void = {
        handler(a.current, b.current, c.current)
    }
    if fireImmediately {
        invoke()
    }
    let da = a.observe(on: delivery) { _ in invoke() }
    let db = b.observe(on: delivery) { _ in invoke() }
    let dc = c.observe(on: delivery) { _ in invoke() }
    return CompositeDisposable([da, db, dc])
}

/// Runs a side effect whenever any of the given signals changes, passing each signal's
/// current value to the handler.
@discardableResult
public func observe<A, B, C, D>(
    _ a: Signal<A>,
    _ b: Signal<B>,
    _ c: Signal<C>,
    _ d: Signal<D>,
    on delivery: ObserverDelivery = .immediate,
    fireImmediately: Bool = true,
    _ handler: @escaping (A, B, C, D) -> Void
) -> any Disposable {
    let invoke: @MainActor () -> Void = {
        handler(a.current, b.current, c.current, d.current)
    }
    if fireImmediately {
        invoke()
    }
    let da = a.observe(on: delivery) { _ in invoke() }
    let db = b.observe(on: delivery) { _ in invoke() }
    let dc = c.observe(on: delivery) { _ in invoke() }
    let dd = d.observe(on: delivery) { _ in invoke() }
    return CompositeDisposable([da, db, dc, dd])
}
