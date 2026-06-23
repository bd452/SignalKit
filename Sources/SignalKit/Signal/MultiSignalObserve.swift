import Foundation

@MainActor
private func combineSignalObservers(
    on delivery: ObserverDelivery,
    fireImmediately: Bool,
    invoke: @escaping @MainActor () -> Void,
    observers: [any Disposable]
) -> any Disposable {
    if fireImmediately {
        invoke()
    }
    return CompositeDisposable(observers)
}

@MainActor
private func observeSignal<Value>(
    _ signal: Signal<Value>,
    on delivery: ObserverDelivery,
    invoke: @escaping @MainActor () -> Void
) -> any Disposable {
    signal.observe(on: delivery) { _ in invoke() }
}

@MainActor
@discardableResult
public func observe<A, B>(
    _ a: Signal<A>,
    _ b: Signal<B>,
    on delivery: ObserverDelivery = .immediate,
    fireImmediately: Bool = true,
    _ handler: @escaping (A, B) -> Void
) -> any Disposable {
    let invoke: @MainActor () -> Void = { handler(a.current, b.current) }
    return combineSignalObservers(
        on: delivery,
        fireImmediately: fireImmediately,
        invoke: invoke,
        observers: [
            observeSignal(a, on: delivery, invoke: invoke),
            observeSignal(b, on: delivery, invoke: invoke),
        ]
    )
}

@MainActor
@discardableResult
public func observe<A, B, C>(
    _ a: Signal<A>,
    _ b: Signal<B>,
    _ c: Signal<C>,
    on delivery: ObserverDelivery = .immediate,
    fireImmediately: Bool = true,
    _ handler: @escaping (A, B, C) -> Void
) -> any Disposable {
    let invoke: @MainActor () -> Void = { handler(a.current, b.current, c.current) }
    return combineSignalObservers(
        on: delivery,
        fireImmediately: fireImmediately,
        invoke: invoke,
        observers: [
            observeSignal(a, on: delivery, invoke: invoke),
            observeSignal(b, on: delivery, invoke: invoke),
            observeSignal(c, on: delivery, invoke: invoke),
        ]
    )
}

@MainActor
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
    let invoke: @MainActor () -> Void = { handler(a.current, b.current, c.current, d.current) }
    return combineSignalObservers(
        on: delivery,
        fireImmediately: fireImmediately,
        invoke: invoke,
        observers: [
            observeSignal(a, on: delivery, invoke: invoke),
            observeSignal(b, on: delivery, invoke: invoke),
            observeSignal(c, on: delivery, invoke: invoke),
            observeSignal(d, on: delivery, invoke: invoke),
        ]
    )
}

@MainActor
@discardableResult
public func observe<A, B, C, D, E>(
    _ a: Signal<A>,
    _ b: Signal<B>,
    _ c: Signal<C>,
    _ d: Signal<D>,
    _ e: Signal<E>,
    on delivery: ObserverDelivery = .immediate,
    fireImmediately: Bool = true,
    _ handler: @escaping (A, B, C, D, E) -> Void
) -> any Disposable {
    let invoke: @MainActor () -> Void = { handler(a.current, b.current, c.current, d.current, e.current) }
    return combineSignalObservers(
        on: delivery,
        fireImmediately: fireImmediately,
        invoke: invoke,
        observers: [
            observeSignal(a, on: delivery, invoke: invoke),
            observeSignal(b, on: delivery, invoke: invoke),
            observeSignal(c, on: delivery, invoke: invoke),
            observeSignal(d, on: delivery, invoke: invoke),
            observeSignal(e, on: delivery, invoke: invoke),
        ]
    )
}

@MainActor
@discardableResult
public func observe<A, B, C, D, E, F>(
    _ a: Signal<A>,
    _ b: Signal<B>,
    _ c: Signal<C>,
    _ d: Signal<D>,
    _ e: Signal<E>,
    _ f: Signal<F>,
    on delivery: ObserverDelivery = .immediate,
    fireImmediately: Bool = true,
    _ handler: @escaping (A, B, C, D, E, F) -> Void
) -> any Disposable {
    let invoke: @MainActor () -> Void = { handler(a.current, b.current, c.current, d.current, e.current, f.current) }
    return combineSignalObservers(
        on: delivery,
        fireImmediately: fireImmediately,
        invoke: invoke,
        observers: [
            observeSignal(a, on: delivery, invoke: invoke),
            observeSignal(b, on: delivery, invoke: invoke),
            observeSignal(c, on: delivery, invoke: invoke),
            observeSignal(d, on: delivery, invoke: invoke),
            observeSignal(e, on: delivery, invoke: invoke),
            observeSignal(f, on: delivery, invoke: invoke),
        ]
    )
}

@MainActor
@discardableResult
public func observe<A, B, C, D, E, F, G>(
    _ a: Signal<A>,
    _ b: Signal<B>,
    _ c: Signal<C>,
    _ d: Signal<D>,
    _ e: Signal<E>,
    _ f: Signal<F>,
    _ g: Signal<G>,
    on delivery: ObserverDelivery = .immediate,
    fireImmediately: Bool = true,
    _ handler: @escaping (A, B, C, D, E, F, G) -> Void
) -> any Disposable {
    let invoke: @MainActor () -> Void = { handler(a.current, b.current, c.current, d.current, e.current, f.current, g.current) }
    return combineSignalObservers(
        on: delivery,
        fireImmediately: fireImmediately,
        invoke: invoke,
        observers: [
            observeSignal(a, on: delivery, invoke: invoke),
            observeSignal(b, on: delivery, invoke: invoke),
            observeSignal(c, on: delivery, invoke: invoke),
            observeSignal(d, on: delivery, invoke: invoke),
            observeSignal(e, on: delivery, invoke: invoke),
            observeSignal(f, on: delivery, invoke: invoke),
            observeSignal(g, on: delivery, invoke: invoke),
        ]
    )
}

@MainActor
@discardableResult
public func observe<A, B, C, D, E, F, G, H>(
    _ a: Signal<A>,
    _ b: Signal<B>,
    _ c: Signal<C>,
    _ d: Signal<D>,
    _ e: Signal<E>,
    _ f: Signal<F>,
    _ g: Signal<G>,
    _ h: Signal<H>,
    on delivery: ObserverDelivery = .immediate,
    fireImmediately: Bool = true,
    _ handler: @escaping (A, B, C, D, E, F, G, H) -> Void
) -> any Disposable {
    let invoke: @MainActor () -> Void = { handler(a.current, b.current, c.current, d.current, e.current, f.current, g.current, h.current) }
    return combineSignalObservers(
        on: delivery,
        fireImmediately: fireImmediately,
        invoke: invoke,
        observers: [
            observeSignal(a, on: delivery, invoke: invoke),
            observeSignal(b, on: delivery, invoke: invoke),
            observeSignal(c, on: delivery, invoke: invoke),
            observeSignal(d, on: delivery, invoke: invoke),
            observeSignal(e, on: delivery, invoke: invoke),
            observeSignal(f, on: delivery, invoke: invoke),
            observeSignal(g, on: delivery, invoke: invoke),
            observeSignal(h, on: delivery, invoke: invoke),
        ]
    )
}

@MainActor
@discardableResult
public func observe<A, B, C, D, E, F, G, H, I>(
    _ a: Signal<A>,
    _ b: Signal<B>,
    _ c: Signal<C>,
    _ d: Signal<D>,
    _ e: Signal<E>,
    _ f: Signal<F>,
    _ g: Signal<G>,
    _ h: Signal<H>,
    _ i: Signal<I>,
    on delivery: ObserverDelivery = .immediate,
    fireImmediately: Bool = true,
    _ handler: @escaping (A, B, C, D, E, F, G, H, I) -> Void
) -> any Disposable {
    let invoke: @MainActor () -> Void = { handler(a.current, b.current, c.current, d.current, e.current, f.current, g.current, h.current, i.current) }
    return combineSignalObservers(
        on: delivery,
        fireImmediately: fireImmediately,
        invoke: invoke,
        observers: [
            observeSignal(a, on: delivery, invoke: invoke),
            observeSignal(b, on: delivery, invoke: invoke),
            observeSignal(c, on: delivery, invoke: invoke),
            observeSignal(d, on: delivery, invoke: invoke),
            observeSignal(e, on: delivery, invoke: invoke),
            observeSignal(f, on: delivery, invoke: invoke),
            observeSignal(g, on: delivery, invoke: invoke),
            observeSignal(h, on: delivery, invoke: invoke),
            observeSignal(i, on: delivery, invoke: invoke),
        ]
    )
}

@MainActor
@discardableResult
public func observe<A, B, C, D, E, F, G, H, I, J>(
    _ a: Signal<A>,
    _ b: Signal<B>,
    _ c: Signal<C>,
    _ d: Signal<D>,
    _ e: Signal<E>,
    _ f: Signal<F>,
    _ g: Signal<G>,
    _ h: Signal<H>,
    _ i: Signal<I>,
    _ j: Signal<J>,
    on delivery: ObserverDelivery = .immediate,
    fireImmediately: Bool = true,
    _ handler: @escaping (A, B, C, D, E, F, G, H, I, J) -> Void
) -> any Disposable {
    let invoke: @MainActor () -> Void = { handler(a.current, b.current, c.current, d.current, e.current, f.current, g.current, h.current, i.current, j.current) }
    return combineSignalObservers(
        on: delivery,
        fireImmediately: fireImmediately,
        invoke: invoke,
        observers: [
            observeSignal(a, on: delivery, invoke: invoke),
            observeSignal(b, on: delivery, invoke: invoke),
            observeSignal(c, on: delivery, invoke: invoke),
            observeSignal(d, on: delivery, invoke: invoke),
            observeSignal(e, on: delivery, invoke: invoke),
            observeSignal(f, on: delivery, invoke: invoke),
            observeSignal(g, on: delivery, invoke: invoke),
            observeSignal(h, on: delivery, invoke: invoke),
            observeSignal(i, on: delivery, invoke: invoke),
            observeSignal(j, on: delivery, invoke: invoke),
        ]
    )
}
