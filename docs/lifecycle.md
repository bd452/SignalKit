# Lifecycle

Every mounted component owns a `LifecycleScope` that tracks all work requiring cleanup: signal observers, bindings, UIKit event handlers, child components, and custom cleanup closures.

Understanding lifecycle behavior is essential for avoiding leaks, stale callbacks, and orphaned views.

## LifecycleScope

Created when `mount()` is called. Disposed when `unmount()` is called.

The scope tracks:

| Resource | Added via |
| --- | --- |
| Disposables (observers, bindings, events) | `track(_:)` |
| Child components | `trackChild(_:)` (internal, during mount) |
| Cleanup closures | `onCleanup(_:)` (internal) |

### Disposal order

When `scope.dispose()` runs:

```text
1. Mark scope as dead (isAlive = false)
2. Dispose all tracked disposables
3. Unmount all tracked child components
4. Run cleanup closures
```

Child unmounting recursively disposes each child's scope.

### guardAlive

Before running any tracked callback (binding, observation), the scope checks `isAlive`:

```swift
scope.guardAlive(owner: "Counter") {
    handler(value)
}
```

If the scope is dead, the callback is dropped. In debug builds:

```text
[SignalKit] Dropped late callback for Counter
```

This prevents mutations on unmounted components when async delivery races with unmount.

## Component mount lifecycle

```text
mount() called
  │
  ├─ precondition: not already mounted
  ├─ create LifecycleScope → self.scope
  ├─ build() → Node
  ├─ NodeMounter.mount(node, scope, parent) → SKView
  ├─ self.rootView = view
  ├─ isMounted = true
  └─ didMount()
```

## Component unmount lifecycle

```text
unmount() called
  │
  ├─ guard: isMounted
  ├─ willUnmount()
  ├─ scope.dispose()
  │    ├─ dispose disposables (remove event targets, signal observers)
  │    ├─ unmount children (recursive)
  │    └─ run cleanup closures
  ├─ scope = nil
  ├─ rootView.removeFromSuperview()
  ├─ rootView = nil
  └─ isMounted = false
```

## Child component lifetimes

### Static children (stacks)

Children in `VStack` / `HStack` are tracked during parent mount:

```swift
VStack {
    HeaderComponent()  // trackChild → unmounts with parent
    FooterComponent()
}
```

### Dynamic children (Slot, ForEach)

Structural hosts call `trackChild` when mounting and `releaseChild` when replacing:

```swift
// Slot replace flow:
releaseChild(oldChild)   // unmounts old child
mountChild(newChild)     // trackChild(newChild)
```

### Parent unmount cascades

Unmounting a parent automatically unmounts all tracked children:

```swift
parent.unmount()
// → child.willUnmount() called
// → child.scope.dispose()
// → child's root view removed
```

## Disposable protocol

```swift
@MainActor
public protocol Disposable: AnyObject {
    func dispose()
}
```

Implementations:

| Type | Purpose |
| --- | --- |
| `ClosureDisposable` | Wraps a cleanup closure (returned by `signal.observe`) |
| `CompositeDisposable` | Disposes multiple children |
| `ControlEventRegistration` | Removes UIKit target/action |

### Manual disposal

```swift
let disposable = signal.observe { ... }

// Stop observing before unmount:
disposable.dispose()
```

Component-tracked disposables are disposed automatically — manual disposal is optional but harmless.

## What must be called from build()

These methods require an active scope (during `mount()` → `build()`):

| Method | Error if called outside build |
| --- | --- |
| `track(_:)` | Precondition failure |
| `observe(_:_:)` | Precondition failure |
| `bind(_:_:_:)` | Precondition failure |
| `host(_:)` | Precondition failure |

Error message pattern:

```text
track(_:) must be called from build() while the component is mounting
```

## Retain cycles and memory

### Weak targets in bindings

Bindings weakly reference UIKit targets. If the view is deallocated independently, binding callbacks no-op.

### Component retention

- The root view does **not** retain the component
- You must hold a strong reference to mounted components
- `ComponentHostView` retains its hosted component until deinit

```swift
// ✅ Keep a reference
private var counter: Counter?

func showCounter() {
    let counter = Counter()
    _ = counter.mount()
    self.counter = counter
}

func hideCounter() {
    counter?.unmount()
    counter = nil
}
```

### Capture lists in handlers

```swift
// ✅ Capture signals, not self (when possible)
track(button.onTap { [count] in count.update { $0 + 1 } })

// ✅ Weak self for methods
track(button.onTap { [weak self] in self?.submit() })
```

## Observations after unmount

Once unmounted, component `observe` handlers stop firing even if the underlying signal continues to receive updates:

```swift
host.mount()
host.value.set(1)  // observationCount == 2 (initial + update)
host.unmount()
host.value.set(2)  // observationCount still == 2
```

## Debug diagnostics

In debug builds (`#if DEBUG`), SignalKit logs:

| Message | Cause |
| --- | --- |
| `Dropped late callback for <Owner>` | Callback scheduled after scope disposal |
| `Invalid lifecycle operation: track(disposable) on dead scope` | `track` called on disposed scope |
| `Invalid lifecycle operation: trackChild on dead scope` | Child tracking after disposal |

## API reference

```swift
@MainActor
public protocol Disposable: AnyObject {
    func dispose()
}
```

```swift
@MainActor
open class Component: NSObject {
    private(set) var scope: LifecycleScope?
    private(set) var rootView: SKView?

    open func didMount()
    open func willUnmount()

    public func mount() -> SKView
    public func unmount()

    @discardableResult
    public func track(_ disposable: any Disposable) -> any Disposable
}
```

## Related

- [Components](components.md) — mount/unmount API
- [Binding & Observation](binding-and-observation.md) — tracked subscriptions
- [Events](events.md) — tracked event handlers
- [Best Practices](best-practices.md) — memory and lifecycle patterns
