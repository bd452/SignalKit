# Components

`Component` is the central lifecycle type in SignalKit. It is an `NSObject` subclass that owns reactive state, constructs UIKit views once in `build()`, and manages subscriptions, bindings, events, and child component lifetimes.

A component is **not** a view. It produces a root `SKView` when mounted.

```swift
import SignalKit
import UIKit

final class MyComponent: Component {
    override func build() -> Node {
        // construct views, attach bindings, return layout
    }
}
```

All `Component` APIs are `@MainActor` isolated.

## Subclassing

Override `build()` to construct your UI. The default implementation calls `fatalError`.

```swift
final class LabelComponent: Component {
    let text: String

    init(text: String) {
        self.text = text
        super.init()
    }

    override func build() -> Node {
        let label = UILabel()
        label.text = text
        return label.node
    }
}
```

### Lifecycle hooks

| Method | When called | Purpose |
| --- | --- | --- |
| `build()` | Once during `mount()` | Construct views, bindings, events; return `Node` |
| `didMount()` | After root view is created | Post-mount setup (analytics, animations, etc.) |
| `willUnmount()` | Before scope disposal | Pre-teardown cleanup |

```swift
override func didMount() {
    analytics.track("screen_viewed")
}

override func willUnmount() {
    saveDraft()
}
```

`build()` must only be called by the framework during mounting. Do not call it manually.

## Mounting and unmounting

### `mount() -> SKView`

Runs `build()`, mounts the node tree, and returns the root view:

```swift
let component = MyComponent()
let rootView = component.mount()
parentView.addSubview(rootView)
```

Calling `mount()` twice triggers a precondition failure: `"Component is already mounted"`.

After mounting, these properties are available:

| Property | Type | Description |
| --- | --- | --- |
| `scope` | `LifecycleScope?` | Active lifecycle scope (internal, `private(set)`) |
| `rootView` | `SKView?` | The mounted root view |

### `unmount()`

Disposes the lifecycle scope, unmounts children, and removes the root view:

```swift
component.unmount()
```

Safe to call on an already-unmounted component (no-op).

## State as signals

Define reactive state as `Signal` properties on the component:

```swift
final class Form: Component {
    let email = Signal("")
    let isValid = Signal(false)

    override func build() -> Node { ... }
}
```

Update state from event handlers:

```swift
track(button.onTap { [email] in
    email.set("user@example.com")
})
```

## Tracking work in `build()`

These methods **must** be called from `build()` while the component is mounting. Calling them outside `build()` triggers a precondition failure.

### `track(_:)`

Registers a `Disposable` with the lifecycle scope. Used for event handlers and manual disposables:

```swift
track(button.onTap { ... })
```

Returns the disposable (also tracked). The `@discardableResult` attribute allows ignoring the return value.

### `bind(_:_:_:)` and `bind(_:_:_:transform:)`

Connect a signal to a UIKit key path. See [Binding & Observation](binding-and-observation.md).

### `observe(_:fireImmediately:_:)`

Lifecycle-tracked signal observation. See [Binding & Observation](binding-and-observation.md).

### `host(_:)`

Embeds a child component in a container view for APIs that require a view reference immediately:

```swift
let childView = host(HeaderComponent(user: user))
someContainer.addSubview(childView)
```

The child's lifetime is tied to this component's scope. Prefer declarative composition in stacks when possible.

## Child components

Child components appear in node composition (stacks, slots, foreach). The parent automatically calls `trackChild` during mount — you do not call this yourself.

```swift
override func build() -> Node {
    VStack {
        HeaderComponent()
        bodyLabel
        FooterComponent()
    }
}
```

`HeaderComponent` and `FooterComponent` are mounted as children. Their lifetimes are tracked by the parent's scope and they unmount when the parent unmounts.

## The `node` property

Any `Component` can be converted to a `Node` for composition:

```swift
HeaderComponent().node  // Node(.component(self))
```

This is used implicitly by `VStack` / `HStack` when you write:

```swift
VStack {
    HeaderComponent()  // buildExpression converts to Node
}
```

## `SKView.node`

UIKit views also convert to nodes:

```swift
let label = UILabel()
return label.node  // equivalent to Node(.view(label))
```

## API reference

```swift
@MainActor
open class Component: NSObject {
    private(set) var scope: LifecycleScope?
    private(set) var rootView: SKView?

    public override init()

    open func build() -> Node
    open func didMount()
    open func willUnmount()

    @discardableResult
    public func mount() -> SKView
    public func unmount()

    @discardableResult
    public func track(_ disposable: any Disposable) -> any Disposable

    public func host(_ child: Component) -> SKView

    @discardableResult
    public func observe<Value>(
        _ signal: Signal<Value>,
        fireImmediately: Bool = true,
        _ handler: @escaping (Value) -> Void
    ) -> any Disposable

    @discardableResult
    public func bind<Target: AnyObject, Value>(
        _ target: Target,
        _ keyPath: ReferenceWritableKeyPath<Target, Value>,
        _ signal: Signal<Value>
    ) -> any Disposable

    @discardableResult
    public func bind<Target: AnyObject, SignalValue, PropertyValue>(
        _ target: Target,
        _ keyPath: ReferenceWritableKeyPath<Target, PropertyValue>,
        _ signal: Signal<SignalValue>,
        transform: @escaping (SignalValue) -> PropertyValue
    ) -> any Disposable

    public var node: Node { get }
}
```

## Related

- [Nodes & Layout](nodes-and-layout.md) — what `build()` returns
- [Lifecycle](lifecycle.md) — scope disposal and safety
- [Structural Hosts](structural-hosts.md) — `Slot`, `ForEach`, dynamic children
