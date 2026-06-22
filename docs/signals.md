# Signals

`Signal<Value>` is a main-actor observable value container. It owns the current value, an observer registry, and update/delivery behavior. Signals are UI-agnostic — they know nothing about UIKit, components, views, or bindings.

```swift
import SignalKit

let count = Signal(0)
```

All `Signal` APIs are `@MainActor` isolated.

## Reading the current value

```swift
let current = count.current
```

`current` returns the value stored at read time. It does not subscribe to future changes.

## Writing values

### `set(_:)`

Replaces the value and notifies all observers:

```swift
count.set(42)
```

`set` always publishes, even if the new value is equal to the old value (when `Value` is `Equatable`). Use `setIfChanged` to suppress equal-value notifications.

### `setIfChanged(_:)`

Available when `Value: Equatable`. Skips notification if the new value equals the current value:

```swift
count.setIfChanged(42)  // notifies
count.setIfChanged(42)  // silent — no observers called
```

### `update(_:)`

Transforms the current value in place:

```swift
count.update { $0 + 1 }
```

Equivalent to `set(transform(current))`.

### `updateIfChanged(_:)`

Available when `Value: Equatable`. Applies a transform and only publishes if the result differs:

```swift
count.updateIfChanged { $0 + 1 }
```

## Observing changes

### `observe(on:_:)`

Subscribe to value changes. Returns a `Disposable` for cleanup:

```swift
let disposable = count.observe { newValue in
    print("Count is now \(newValue)")
}

// Later, stop observing:
disposable.dispose()
```

#### Delivery modes

The `on` parameter controls when the handler runs:

| Mode | Behavior |
| --- | --- |
| `.immediate` (default) | Runs synchronously from the writer's main-actor context |
| `.main` | Delivers on the main actor; async dispatch when called off the main thread |

```swift
// Default: immediate, synchronous delivery
count.observe { value in ... }

// Explicit main-actor delivery
count.observe(on: .main) { value in ... }
```

Component `bind` and `observe` always use `.main` delivery because UI mutation must be main-threaded.

### Observer identity

Observers are stored by stable `UInt64` IDs, not as a set of closures. This enables predictable removal via `Disposable.dispose()` without requiring `Hashable` closures.

## Nested writes during delivery

If an observer calls `set` while notifications are in flight, SignalKit coalesces nested writes:

- `current` always reflects the **latest** value immediately
- Observers receive at most **one follow-up** notification with the final value, not every intermediate step

```swift
let signal = Signal(0)
var received: [Int] = []

signal.observe { value in
    received.append(value)
    if value == 1 {
        signal.set(2)
        signal.set(3)
    }
}

signal.set(1)

// signal.current == 3
// received == [1, 3]
```

This prevents unbounded observer recursion while ensuring the final state is delivered.

## Where to store signals

### On components (typical)

```swift
final class Profile: Component {
    let user = Signal<User?>(nil)

    override func build() -> Node { ... }
}
```

Signals owned by a component live as long as the component instance. Bindings and observations are disposed on unmount.

### Standalone (for non-UI logic)

```swift
let authState = Signal<AuthState>(.loggedOut)

authState.observe { state in
    // manual side effect
}
```

When using `signal.observe` directly (not through `Component.observe`), you are responsible for calling `dispose()` when done.

### Shared between components

Pass signals via initializer parameters or a shared store/model object:

```swift
final class Child: Component {
    let count: Signal<Int>

    init(count: Signal<Int>) {
        self.count = count
        super.init()
    }
}
```

## Equatable and value semantics

`setIfChanged` and `updateIfChanged` require `Value: Equatable`. There is no built-in equality suppression on plain `set` — this is intentional:

- Avoids baking `Equatable` into every signal
- Preserves the ability to intentionally publish repeated equal values (e.g., "refresh" triggers)

## Threading

Signals are main-actor isolated. All reads and writes must occur on the main actor.

From background work:

```swift
Task.detached {
    let result = await fetchData()
    await MainActor.run {
        dataSignal.set(result)
    }
}
```

## API reference

```swift
@MainActor
public final class Signal<Value> {
    public init(_ value: Value)
    public var current: Value

    public func set(_ newValue: Value)
    public func setIfChanged(_ newValue: Value) where Value: Equatable
    public func update(_ transform: (Value) -> Value)
    public func updateIfChanged(_ transform: (Value) -> Value) where Value: Equatable

    @discardableResult
    public func observe(
        on delivery: ObserverDelivery = .immediate,
        _ handler: @escaping (Value) -> Void
    ) -> any Disposable
}
```

```swift
public enum ObserverDelivery: Sendable {
    case immediate
    case main
}
```

## Related

- [Binding & Observation](binding-and-observation.md) — connecting signals to UIKit
- [Lifecycle](lifecycle.md) — how component-tracked observation differs from raw `observe`
- [Best Practices](best-practices.md) — signal design patterns
