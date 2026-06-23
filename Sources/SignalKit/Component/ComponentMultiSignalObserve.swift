import Foundation

extension Component {
    @discardableResult
    private func trackMultiSignalObserve(
        fireImmediately: Bool,
        fireNow: @escaping @MainActor () -> Void,
        subscribe: () -> any Disposable
    ) -> any Disposable {
        guard let scope else {
            preconditionFailure(
                "observe(_:_:) must be called from build() while the component is mounting"
            )
        }
        let owner = String(describing: type(of: self))
        if fireImmediately {
            scope.guardAlive(owner: owner, fireNow)
        }
        return scope.track(subscribe())
    }

    /// Runs a side effect whenever any of the given signals changes.
    @discardableResult
    public func observe<A, B>(
        _ a: Signal<A>,
        _ b: Signal<B>,
        fireImmediately: Bool = true,
        _ handler: @escaping (A, B) -> Void
    ) -> any Disposable {
        let owner = String(describing: type(of: self))
        let run: (A, B) -> Void = { [weak self] valA, valB in
            guard let self, let scope = self.scope else { return }
            scope.guardAlive(owner: owner) { handler(valA, valB) }
        }
        return trackMultiSignalObserve(
            fireImmediately: fireImmediately,
            fireNow: { handler(a.current, b.current) },
            subscribe: { SignalKit.observe(a, b, on: .main, fireImmediately: false, run) }
        )
    }

    @discardableResult
    public func observe<A, B, C>(
        _ a: Signal<A>,
        _ b: Signal<B>,
        _ c: Signal<C>,
        fireImmediately: Bool = true,
        _ handler: @escaping (A, B, C) -> Void
    ) -> any Disposable {
        let owner = String(describing: type(of: self))
        let run: (A, B, C) -> Void = { [weak self] valA, valB, valC in
            guard let self, let scope = self.scope else { return }
            scope.guardAlive(owner: owner) { handler(valA, valB, valC) }
        }
        return trackMultiSignalObserve(
            fireImmediately: fireImmediately,
            fireNow: { handler(a.current, b.current, c.current) },
            subscribe: { SignalKit.observe(a, b, c, on: .main, fireImmediately: false, run) }
        )
    }

    @discardableResult
    public func observe<A, B, C, D>(
        _ a: Signal<A>,
        _ b: Signal<B>,
        _ c: Signal<C>,
        _ d: Signal<D>,
        fireImmediately: Bool = true,
        _ handler: @escaping (A, B, C, D) -> Void
    ) -> any Disposable {
        let owner = String(describing: type(of: self))
        let run: (A, B, C, D) -> Void = { [weak self] valA, valB, valC, valD in
            guard let self, let scope = self.scope else { return }
            scope.guardAlive(owner: owner) { handler(valA, valB, valC, valD) }
        }
        return trackMultiSignalObserve(
            fireImmediately: fireImmediately,
            fireNow: { handler(a.current, b.current, c.current, d.current) },
            subscribe: { SignalKit.observe(a, b, c, d, on: .main, fireImmediately: false, run) }
        )
    }

    @discardableResult
    public func observe<A, B, C, D, E>(
        _ a: Signal<A>,
        _ b: Signal<B>,
        _ c: Signal<C>,
        _ d: Signal<D>,
        _ e: Signal<E>,
        fireImmediately: Bool = true,
        _ handler: @escaping (A, B, C, D, E) -> Void
    ) -> any Disposable {
        let owner = String(describing: type(of: self))
        let run: (A, B, C, D, E) -> Void = { [weak self] valA, valB, valC, valD, valE in
            guard let self, let scope = self.scope else { return }
            scope.guardAlive(owner: owner) { handler(valA, valB, valC, valD, valE) }
        }
        return trackMultiSignalObserve(
            fireImmediately: fireImmediately,
            fireNow: { handler(a.current, b.current, c.current, d.current, e.current) },
            subscribe: { SignalKit.observe(a, b, c, d, e, on: .main, fireImmediately: false, run) }
        )
    }

    @discardableResult
    public func observe<A, B, C, D, E, F>(
        _ a: Signal<A>,
        _ b: Signal<B>,
        _ c: Signal<C>,
        _ d: Signal<D>,
        _ e: Signal<E>,
        _ f: Signal<F>,
        fireImmediately: Bool = true,
        _ handler: @escaping (A, B, C, D, E, F) -> Void
    ) -> any Disposable {
        let owner = String(describing: type(of: self))
        let run: (A, B, C, D, E, F) -> Void = { [weak self] valA, valB, valC, valD, valE, valF in
            guard let self, let scope = self.scope else { return }
            scope.guardAlive(owner: owner) { handler(valA, valB, valC, valD, valE, valF) }
        }
        return trackMultiSignalObserve(
            fireImmediately: fireImmediately,
            fireNow: { handler(a.current, b.current, c.current, d.current, e.current, f.current) },
            subscribe: { SignalKit.observe(a, b, c, d, e, f, on: .main, fireImmediately: false, run) }
        )
    }

    @discardableResult
    public func observe<A, B, C, D, E, F, G>(
        _ a: Signal<A>,
        _ b: Signal<B>,
        _ c: Signal<C>,
        _ d: Signal<D>,
        _ e: Signal<E>,
        _ f: Signal<F>,
        _ g: Signal<G>,
        fireImmediately: Bool = true,
        _ handler: @escaping (A, B, C, D, E, F, G) -> Void
    ) -> any Disposable {
        let owner = String(describing: type(of: self))
        let run: (A, B, C, D, E, F, G) -> Void = { [weak self] valA, valB, valC, valD, valE, valF, valG in
            guard let self, let scope = self.scope else { return }
            scope.guardAlive(owner: owner) { handler(valA, valB, valC, valD, valE, valF, valG) }
        }
        return trackMultiSignalObserve(
            fireImmediately: fireImmediately,
            fireNow: { handler(a.current, b.current, c.current, d.current, e.current, f.current, g.current) },
            subscribe: { SignalKit.observe(a, b, c, d, e, f, g, on: .main, fireImmediately: false, run) }
        )
    }

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
        fireImmediately: Bool = true,
        _ handler: @escaping (A, B, C, D, E, F, G, H) -> Void
    ) -> any Disposable {
        let owner = String(describing: type(of: self))
        let run: (A, B, C, D, E, F, G, H) -> Void = { [weak self] valA, valB, valC, valD, valE, valF, valG, valH in
            guard let self, let scope = self.scope else { return }
            scope.guardAlive(owner: owner) { handler(valA, valB, valC, valD, valE, valF, valG, valH) }
        }
        return trackMultiSignalObserve(
            fireImmediately: fireImmediately,
            fireNow: { handler(a.current, b.current, c.current, d.current, e.current, f.current, g.current, h.current) },
            subscribe: { SignalKit.observe(a, b, c, d, e, f, g, h, on: .main, fireImmediately: false, run) }
        )
    }

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
        fireImmediately: Bool = true,
        _ handler: @escaping (A, B, C, D, E, F, G, H, I) -> Void
    ) -> any Disposable {
        let owner = String(describing: type(of: self))
        let run: (A, B, C, D, E, F, G, H, I) -> Void = { [weak self] valA, valB, valC, valD, valE, valF, valG, valH, valI in
            guard let self, let scope = self.scope else { return }
            scope.guardAlive(owner: owner) { handler(valA, valB, valC, valD, valE, valF, valG, valH, valI) }
        }
        return trackMultiSignalObserve(
            fireImmediately: fireImmediately,
            fireNow: { handler(a.current, b.current, c.current, d.current, e.current, f.current, g.current, h.current, i.current) },
            subscribe: { SignalKit.observe(a, b, c, d, e, f, g, h, i, on: .main, fireImmediately: false, run) }
        )
    }

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
        fireImmediately: Bool = true,
        _ handler: @escaping (A, B, C, D, E, F, G, H, I, J) -> Void
    ) -> any Disposable {
        let owner = String(describing: type(of: self))
        let run: (A, B, C, D, E, F, G, H, I, J) -> Void = { [weak self] valA, valB, valC, valD, valE, valF, valG, valH, valI, valJ in
            guard let self, let scope = self.scope else { return }
            scope.guardAlive(owner: owner) { handler(valA, valB, valC, valD, valE, valF, valG, valH, valI, valJ) }
        }
        return trackMultiSignalObserve(
            fireImmediately: fireImmediately,
            fireNow: { handler(a.current, b.current, c.current, d.current, e.current, f.current, g.current, h.current, i.current, j.current) },
            subscribe: { SignalKit.observe(a, b, c, d, e, f, g, h, i, j, on: .main, fireImmediately: false, run) }
        )
    }
}
