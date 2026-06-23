import Foundation

@MainActor
open class Component: NSObject {
    private(set) var scope: LifecycleScope?
    private(set) var rootView: SKView?
    private var isMounted = false

    public override init() {
        super.init()
    }

    open func build() -> Node {
        fatalError("Subclass must override build()")
    }

    open func didMount() {}

    open func willUnmount() {}

    @discardableResult
    public func mount() -> SKView {
        precondition(!isMounted, "Component is already mounted")
        let scope = LifecycleScope()
        self.scope = scope
        let node = build()
        let view = NodeMounter.mount(node, scope: scope, parent: self)
        rootView = view
        isMounted = true
        didMount()
        return view
    }

    public func unmount() {
        guard isMounted else { return }
        willUnmount()
        scope?.dispose()
        scope = nil
        rootView?.removeFromSuperview()
        rootView = nil
        isMounted = false
    }

    @discardableResult
    public func track(_ disposable: any Disposable) -> any Disposable {
        guard let scope else {
            preconditionFailure(
                "track(_:) must be called from build() while the component is mounting"
            )
        }
        return scope.track(disposable)
    }

    func trackChild(_ component: Component) {
        guard let scope else {
            preconditionFailure(
                "trackChild(_:) must be called from build() while the component is mounting"
            )
        }
        scope.trackChild(component)
    }

    func releaseChild(_ component: Component) {
        guard let scope else {
            preconditionFailure(
                "releaseChild(_:) must be called from build() while the component is mounting"
            )
        }
        scope.releaseChild(component)
    }

    /// Embeds a child component in a container view for APIs that require a view reference.
    /// The child's lifetime is tied to this component's scope.
    public func host(_ child: Component) -> SKView {
        guard let scope else {
            preconditionFailure(
                "host(_:) must be called from build() while the component is mounting"
            )
        }
        scope.trackChild(child)
        return ComponentHostView(component: child)
    }

    @discardableResult
    public func observe<Value>(
        _ signal: Signal<Value>,
        fireImmediately: Bool = true,
        _ handler: @escaping (Value) -> Void
    ) -> any Disposable {
        guard let scope else {
            preconditionFailure(
                "observe(_:_:) must be called from build() while the component is mounting"
            )
        }
        if fireImmediately {
            scope.guardAlive(owner: String(describing: type(of: self))) {
                handler(signal.current)
            }
        }
        let disposable = signal.observe(on: .main) { [weak self] value in
            guard let self, let scope = self.scope else { return }
            scope.guardAlive(owner: String(describing: type(of: self))) {
                handler(value)
            }
        }
        return scope.track(disposable)
    }

    /// Runs a side effect whenever any of the given signals changes.
    ///
    /// The handler receives the latest value from every signal, not only the one that changed.
    @discardableResult
    public func observe<each Value>(
        _ signals: repeat Signal<each Value>,
        fireImmediately: Bool = true,
        _ handler: @escaping (repeat each Value) -> Void
    ) -> any Disposable {
        guard let scope else {
            preconditionFailure(
                "observe(_:_:) must be called from build() while the component is mounting"
            )
        }
        let owner = String(describing: type(of: self))
        let invoke: @MainActor () -> Void = { [weak self] in
            guard let self, let scope = self.scope else { return }
            scope.guardAlive(owner: owner) {
                handler(repeat each (each signals).current)
            }
        }
        let disposable = subscribeToSignals(
            repeat each signals,
            on: .main,
            fireImmediately: fireImmediately,
            invoke: invoke
        )
        return scope.track(disposable)
    }

    @discardableResult
    public func bind<Target: AnyObject, Value>(
        _ target: Target,
        _ keyPath: ReferenceWritableKeyPath<Target, Value>,
        _ signal: Signal<Value>
    ) -> any Disposable {
        bind(target, keyPath, signal, transform: { $0 })
    }

    @discardableResult
    public func bind<Target: AnyObject, SignalValue, PropertyValue>(
        _ target: Target,
        _ keyPath: ReferenceWritableKeyPath<Target, PropertyValue>,
        _ signal: Signal<SignalValue>,
        transform: @escaping (SignalValue) -> PropertyValue
    ) -> any Disposable {
        guard let scope else {
            preconditionFailure(
                "bind(_:_:_:) must be called from build() while the component is mounting"
            )
        }
        target[keyPath: keyPath] = transform(signal.current)
        let disposable = signal.observe(on: .main) { [weak self, weak target] signalValue in
            guard let self, let scope = self.scope, let target else { return }
            scope.guardAlive(owner: String(describing: type(of: self))) {
                target[keyPath: keyPath] = transform(signalValue)
            }
        }
        return scope.track(disposable)
    }
}
